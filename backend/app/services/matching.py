import logging
from datetime import datetime
from typing import Optional, Dict, Any
from sqlalchemy.orm import Session

from app import crud, models
from app import message_templates as tmpl
from app.whatsapp_client import send_whatsapp_message

logger = logging.getLogger("matching_service")


def accept_notification(db: Session, request_id: int, provider_id: int) -> Dict[str, Any]:
    """
    Shared atomic acceptance logic for WhatsApp Webhook and Mobile App endpoints.
    
    1. Validates request and provider exist.
    2. Atomically attempts to claim the request using crud.try_claim_request.
    3. If won:
       - Updates winning provider's RequestNotification to 'accepted'.
       - Sends Template B (Job Confirmed) to the winning provider.
       - Sends Template C (Provider Assigned) to the consumer.
       - Expires notifications for all other providers and sends Template D (Already Taken).
       - Returns structured success result.
    4. If lost:
       - Sends Template D (Already Taken) to the attempting provider if they were notified.
       - Returns structured failure result.
    """
    req = crud.get_request(db, request_id)
    if not req:
        return {
            "success": False,
            "message": f"Job #{request_id} does not exist.",
            "request_id": request_id,
        }

    provider = crud.get_provider(db, provider_id)
    if not provider:
        return {
            "success": False,
            "message": f"Provider #{provider_id} does not exist.",
            "request_id": request_id,
        }

    # Attempt atomic claim
    won = crud.try_claim_request(db, request_id, provider.id)

    if won:
        # Refresh request object to reflect matched status & provider_id
        db.refresh(req)

        # Update this provider's notification row
        notif = crud.get_notification(db, request_id, provider.id)
        if notif:
            notif.status = models.NotificationStatus.accepted
            notif.responded_at = datetime.utcnow()
            db.commit()

        # Send Template B to this provider (Job Confirmed)
        msg_b = tmpl.template_b_job_confirmed(
            request_id=req.id,
            consumer_phone=req.consumer_phone,
            location=req.location.title(),
            description=req.description or "General service",
            rate_min=provider.rate_min or 0,
            rate_max=provider.rate_max or 0,
        )
        send_whatsapp_message(provider.phone, msg_b)

        # Send Template C to the consumer (Provider Assigned)
        msg_c = tmpl.template_c_provider_assigned(
            provider_name=provider.name,
            rating=provider.rating_avg,
            jobs_completed=provider.jobs_completed,
            provider_phone=provider.phone,
            request_id=req.id,
        )
        send_whatsapp_message(req.consumer_phone, msg_c)

        # For every other notified provider on this request: mark expired and send Template D
        all_notifs = crud.get_request_notifications(db, request_id)
        for other_notif in all_notifs:
            if other_notif.provider_id != provider.id and other_notif.status == models.NotificationStatus.notified:
                other_notif.status = models.NotificationStatus.expired
                other_notif.responded_at = datetime.utcnow()
                db.commit()

                other_prov = crud.get_provider(db, other_notif.provider_id)
                if other_prov:
                    send_whatsapp_message(other_prov.phone, tmpl.template_d_already_taken(request_id))

        # Check if consumer profile exists
        consumer = crud.get_consumer_by_phone(db, req.consumer_phone)
        consumer_name = consumer.name if consumer else None

        return {
            "success": True,
            "message": f"Job #{request_id} successfully accepted.",
            "request_id": req.id,
            "consumer_phone": req.consumer_phone,
            "consumer_name": consumer_name,
            "location": req.location,
            "description": req.description,
            "rate_min": provider.rate_min,
            "rate_max": provider.rate_max,
        }

    else:
        # Lost the race or already matched
        send_whatsapp_message(provider.phone, tmpl.template_d_already_taken(request_id))
        return {
            "success": False,
            "message": f"Job #{request_id} has already been accepted by another provider.",
            "request_id": request_id,
        }
