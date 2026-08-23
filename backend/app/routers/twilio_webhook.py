from fastapi import APIRouter, Depends, Form, HTTPException
from fastapi.responses import PlainTextResponse
from sqlalchemy.orm import Session
from typing import Optional

from app import crud, schemas, models
from app.database import get_db
from app.services.twilio_service import send_whatsapp_message

router = APIRouter(prefix="/whatsapp", tags=["whatsapp"])


@router.post("/send", response_model=schemas.WhatsAppMessageResponse)
def send_message(payload: schemas.WhatsAppMessageIn):
    """Directly send a WhatsApp message using Twilio."""
    res = send_whatsapp_message(payload.to_phone, payload.message)
    return schemas.WhatsAppMessageResponse(
        status=res.get("status", "unknown"),
        sid=res.get("sid"),
        error=res.get("error"),
    )


@router.post("/webhook", response_class=PlainTextResponse)
async def twilio_whatsapp_webhook(
    From: Optional[str] = Form(None),
    Body: Optional[str] = Form(None),
    db: Session = Depends(get_db)
):
    """
    Twilio WhatsApp Webhook:
    Receives incoming WhatsApp messages, parses commands:
    - e.g. "NEED electrician in koramangala" -> creates service request
    - e.g. "ACCEPT <request_id>" -> provider accepts request
    - e.g. "STATUS" -> checks status of active requests
    """
    if not Body or not From:
        return PlainTextResponse("Invalid payload", status_code=400)

    from_phone = From.replace("whatsapp:", "").strip()
    text = Body.strip()
    text_lower = text.lower()

    # Twilio Markup response
    twiml_response = ""

    if text_lower.startswith("need "):
        # Format: NEED <skill> in <location> [description]
        parts = text[5:].strip().split(" in ")
        if len(parts) >= 2:
            skill = parts[0].strip()
            loc_and_desc = parts[1].strip().split(" - ")
            location = loc_and_desc[0].strip()
            desc = loc_and_desc[1].strip() if len(loc_and_desc) > 1 else None

            req = crud.create_request(
                db,
                schemas.ServiceRequestCreate(
                    consumer_phone=from_phone,
                    skill_requested=skill,
                    location=location,
                    description=desc,
                ),
            )
            matches = crud.find_matches(db, req)
            if matches:
                provider_list = "\n".join([f"• {p.name} (★{p.rating_avg})" for p in matches])
                twiml_response = (
                    f"✅ Request #{req.id} created for {skill.title()} in {location.title()}.\n\n"
                    f"Top available providers:\n{provider_list}\n\n"
                    f"We're notifying the best match now!"
                )
            else:
                twiml_response = (
                    f"✅ Request #{req.id} created for {skill.title()} in {location.title()}.\n"
                    f"Searching for available providers near you..."
                )
        else:
            twiml_response = "💡 Please format request as: *NEED <skill> in <locality>*\nExample: *NEED electrician in koramangala*"

    elif text_lower.startswith("accept "):
        try:
            req_id = int(text.split()[1])
            req = crud.get_request(db, req_id)
            provider = crud.get_provider_by_phone(db, from_phone)

            if not req:
                twiml_response = f"❌ Request #{req_id} not found."
            elif not provider:
                twiml_response = "❌ You are not registered as a provider with this phone number."
            elif req.status != models.RequestStatus.pending:
                twiml_response = f"ℹ️ Request #{req_id} is already {req.status.value}."
            else:
                crud.select_provider(db, req, provider)
                twiml_response = f"🎉 You have accepted Request #{req_id}! Customer phone: {req.consumer_phone}"
        except Exception:
            twiml_response = "❌ Invalid command. Use *ACCEPT <request_id>*"

    elif text_lower == "status":
        reqs = db.query(models.ServiceRequest).filter(
            models.ServiceRequest.consumer_phone == from_phone
        ).order_by(models.ServiceRequest.id.desc()).limit(3).all()
        if reqs:
            lines = [f"• #{r.id} ({r.skill_requested.title()}): {r.status.value.upper()}" for r in reqs]
            twiml_response = "📋 *Your Recent Requests:*\n" + "\n".join(lines)
        else:
            twiml_response = "ℹ️ No recent service requests found for your number."

    else:
        twiml_response = (
            "👋 *Welcome to LocalFlow!*\n\n"
            "Commands you can use:\n"
            "• *NEED <skill> in <location>*\n"
            "• *ACCEPT <request_id>* (Providers)\n"
            "• *STATUS* (Check active requests)"
        )

    # Return plain response (or Twilio TwiML)
    return PlainTextResponse(f"<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Message>{twiml_response}</Message></Response>", media_type="application/xml")
