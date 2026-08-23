import logging
import re
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Request
from fastapi.responses import PlainTextResponse
from sqlalchemy.orm import Session

from app import crud, models, schemas
from app.database import get_db
from app.phone_utils import normalize_whatsapp_number
from app.whatsapp_client import send_whatsapp_message
from app import message_templates as tmpl

logger = logging.getLogger("whatsapp_webhook")
router = APIRouter(tags=["whatsapp_webhook"])


@router.post("/webhooks/twilio/whatsapp", response_class=PlainTextResponse)
async def twilio_whatsapp_webhook(
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Twilio WhatsApp Webhook Endpoint.
    Receives incoming form-urlencoded data from Twilio.
    Always returns HTTP 200 with empty TwiML <Response></Response>.
    """
    try:
        form_data = await request.form()
        from_raw = form_data.get("From", "")
        body_raw = form_data.get("Body", "")
        message_sid = form_data.get("MessageSid", "")

        logger.info(f"Webhook received: From={from_raw}, SID={message_sid}, Body='{body_raw}'")

        if not message_sid or not from_raw:
            return PlainTextResponse("<Response></Response>", media_type="application/xml")

        # 1. Deduplication check
        if crud.is_message_processed(db, message_sid):
            logger.info(f"Message SID {message_sid} already processed. Skipping.")
            return PlainTextResponse("<Response></Response>", media_type="application/xml")

        # 2. Record MessageSid immediately to avoid race conditions on retry
        crud.record_processed_message(db, message_sid)

        # 3. Normalize sender phone
        sender_phone = normalize_whatsapp_number(from_raw)
        body = body_raw.strip()
        body_upper = body.upper()

        # 4. Check for REGISTER command first (WhatsApp fallback registration flow)
        if body_upper.startswith("REGISTER"):
            provider = crud.get_provider_by_phone(db, sender_phone)
            consumer = crud.get_consumer_by_phone(db, sender_phone)

            if provider:
                send_whatsapp_message(
                    sender_phone,
                    f"You are already registered as a Service Provider on LocalFlow (+91{sender_phone})."
                )
                return PlainTextResponse("<Response></Response>", media_type="application/xml")
            elif consumer:
                send_whatsapp_message(
                    sender_phone,
                    f"You are already registered as a Customer on LocalFlow (+91{sender_phone})."
                )
                return PlainTextResponse("<Response></Response>", media_type="application/xml")

            # Determine role from command (default to 'provider')
            role = "consumer" if "CONSUMER" in body_upper else "provider"
            reg_link = crud.create_registration_link(db, sender_phone, role=role)

            # Determine base host URL for registration link
            forwarded_proto = request.headers.get("x-forwarded-proto", request.url.scheme or "https")
            forwarded_host = request.headers.get("x-forwarded-host", request.headers.get("host", "localhost:8000"))
            base_url = f"{forwarded_proto}://{forwarded_host}"
            reg_url = f"{base_url}/register?token={reg_link.token}"

            role_title = "Service Provider" if role == "provider" else "Customer"
            msg = (
                f"👋 Welcome to LocalFlow!\n\n"
                f"Please complete your {role_title} registration using this link:\n"
                f"{reg_url}\n\n"
                f"Once registered, you'll immediately start receiving matches!"
            )
            send_whatsapp_message(sender_phone, msg)
            return PlainTextResponse("<Response></Response>", media_type="application/xml")

        # 5. Check if sender is a registered Provider or a Consumer
        provider = crud.get_provider_by_phone(db, sender_phone)

        if provider:
            _handle_provider_message(db, provider, body, sender_phone)
        else:
            _handle_consumer_message(db, sender_phone, body)

    except Exception as e:
        logger.error(f"Error handling Twilio webhook: {e}", exc_info=True)

    # Always return 200 OK fast with valid empty TwiML
    return PlainTextResponse("<Response></Response>", media_type="application/xml")


def _handle_provider_message(db: Session, provider: models.Provider, body: str, sender_phone: str):
    """Handles inbound messages from registered service providers."""
    from app.services.matching import accept_notification

    parts = body.strip().split()
    cmd = parts[0].upper() if parts else ""

    if cmd == "ACCEPT" and len(parts) >= 2:
        try:
            request_id = int(re.sub(r"\D", "", parts[1]))
        except ValueError:
            send_whatsapp_message(sender_phone, tmpl.template_j_provider_help())
            return

        # Shared atomic accept service
        accept_notification(db, request_id, provider.id)

    elif cmd == "DECLINE" and len(parts) >= 2:
        try:
            request_id = int(re.sub(r"\D", "", parts[1]))
            crud.decline_notification(db, request_id, provider.id)
        except Exception:
            pass

    else:
        # Unrecognized provider command -> Template J
        send_whatsapp_message(sender_phone, tmpl.template_j_provider_help())



def _handle_consumer_message(db: Session, consumer_phone: str, body: str):
    """Handles inbound messages from consumers."""
    parts = body.strip().split()
    cmd = parts[0].upper() if parts else ""

    # Check for CANCEL command: CANCEL <request_id>
    if cmd == "CANCEL" and len(parts) >= 2:
        try:
            request_id = int(re.sub(r"\D", "", parts[1]))
        except ValueError:
            send_whatsapp_message(consumer_phone, "Please format cancel as: CANCEL <job id>, e.g. 'CANCEL 1'")
            return

        req = crud.get_request(db, request_id)
        if not req:
            send_whatsapp_message(consumer_phone, f"Job #{request_id} was not found.")
            return

        if req.consumer_phone != consumer_phone:
            send_whatsapp_message(consumer_phone, f"Job #{request_id} does not belong to your phone number.")
            return

        if req.status in [models.RequestStatus.completed, models.RequestStatus.cancelled]:
            send_whatsapp_message(consumer_phone, f"Job #{request_id} is already {req.status.value}.")
            return

        was_matched = req.status == models.RequestStatus.matched
        provider = req.provider

        crud.cancel_request(db, req)
        send_whatsapp_message(consumer_phone, f"✅ Request #{request_id} has been cancelled.")

        if was_matched and provider:
            send_whatsapp_message(provider.phone, f"⚠️ Job #{request_id} has been cancelled by the customer.")
        return

    # Check for DONE command: DONE <request_id> [rating 1-5] [optional comment]
    if cmd == "DONE" and len(parts) >= 2:
        try:
            request_id = int(re.sub(r"\D", "", parts[1]))
            rating = int(parts[2]) if len(parts) >= 3 and parts[2].isdigit() else 5
            comment = " ".join(parts[3:]) if len(parts) > 3 else None
        except ValueError:
            send_whatsapp_message(
                consumer_phone,
                "Please format completion as: DONE <job id> [rating 1-5], e.g. 'DONE 1 5 Great service!'"
            )
            return

        if rating < 1 or rating > 5:
            rating = 5

        req = crud.get_request(db, request_id)
        if not req:
            send_whatsapp_message(consumer_phone, f"Job #{request_id} was not found.")
            return

        if req.consumer_phone != consumer_phone:
            send_whatsapp_message(consumer_phone, f"Job #{request_id} does not belong to your phone number.")
            return

        if req.status != models.RequestStatus.matched:
            send_whatsapp_message(
                consumer_phone,
                f"Job #{request_id} cannot be marked complete because it is currently '{req.status.value}'."
            )
            return

        # Complete request and update provider stats
        completed_req = crud.complete_request(db, req, rating, comment)
        provider = completed_req.provider

        # Send Template E to consumer
        prov_name = provider.name if provider else "the provider"
        send_whatsapp_message(consumer_phone, tmpl.template_e_completion_thanks(prov_name))

        # Send Template F to provider
        if provider:
            send_whatsapp_message(
                provider.phone,
                tmpl.template_f_rated_notice(
                    request_id=req.id,
                    rating=rating,
                    new_rating_avg=provider.rating_avg,
                    jobs_completed=provider.jobs_completed,
                ),
            )
        return

    # Otherwise, treat as a new service request
    _parse_and_create_service_request(db, consumer_phone, body)


def _parse_and_create_service_request(db: Session, consumer_phone: str, text: str):
    """Extracts skill and location from free-text using ServiceLocation table and creates a service request."""
    text_lower = text.lower()

    # 1. Extract skill
    skills = crud.get_distinct_skills(db)
    matched_skill = None
    for s in skills:
        if re.search(r"\b" + re.escape(s) + r"\b", text_lower) or s in text_lower:
            matched_skill = s
            break

    # 2. Extract location from ServiceLocation table
    all_locations = db.query(models.ServiceLocation).all()
    matched_location_obj = None
    for loc in all_locations:
        loc_area = loc.area_name.lower()
        if re.search(r"\b" + re.escape(loc_area) + r"\b", text_lower) or loc_area in text_lower:
            matched_location_obj = loc
            break

    # If either is missing, ask for clarification (Template I)
    if not matched_skill or not matched_location_obj:
        send_whatsapp_message(consumer_phone, tmpl.template_i_need_more_info())
        return

    # 3. Create service request
    req_data = schemas.ServiceRequestCreate(
        consumer_phone=consumer_phone,
        skill_requested=matched_skill,
        location_id=matched_location_obj.id,
        description=text.strip(),
    )
    req = crud.create_request(db, req_data)

    # 4. Find matching providers
    matches = crud.find_matches(db, req, limit=3)
    loc_display = matched_location_obj.area_name.title()

    if matches:
        # Notify each matched provider (Template A) and create RequestNotification record
        for prov in matches:
            crud.create_notification(db, req.id, prov.id)
            send_whatsapp_message(
                prov.phone,
                tmpl.template_a_new_lead(
                    location=loc_display,
                    skill=matched_skill.title(),
                    description=req.description or "General service",
                    request_id=req.id,
                ),
            )

        # Notify consumer (Template G)
        send_whatsapp_message(
            consumer_phone,
            tmpl.template_g_searching(
                skill=matched_skill.title(),
                location=loc_display,
                n=len(matches),
            ),
        )
    else:
        # No providers found (Template H)
        send_whatsapp_message(
            consumer_phone,
            tmpl.template_h_no_providers(
                skill=matched_skill.title(),
                location=loc_display,
            ),
        )
