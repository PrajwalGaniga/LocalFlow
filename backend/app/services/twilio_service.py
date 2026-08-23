import json
import logging
from typing import Optional, Dict, Any
from twilio.rest import Client

from app.config import (
    TWILIO_ACCOUNT_SID,
    TWILIO_AUTH_TOKEN,
    TWILIO_WHATSAPP_NUMBER,
    TWILIO_SMS_NUMBER,
    TWILIO_CONTENT_SID,
)

logger = logging.getLogger(__name__)


def get_twilio_client() -> Optional[Client]:
    """Initializes and returns the Twilio Client using account_sid and auth_token."""
    try:
        if TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN:
            return Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        else:
            logger.warning("Twilio credentials are not fully configured.")
            return None
    except Exception as e:
        logger.error(f"Error initializing Twilio client: {e}")
        return None


def format_whatsapp_number(phone: str) -> str:
    """Ensures the phone number is prefixed with 'whatsapp:' and country code."""
    clean_phone = phone.strip()
    if not clean_phone.startswith("whatsapp:"):
        if not clean_phone.startswith("+"):
            clean_phone = f"+{clean_phone}"
        return f"whatsapp:{clean_phone}"
    return clean_phone


def send_whatsapp_message(
    to_number: str,
    message_body: str,
    from_number: Optional[str] = None
) -> Dict[str, Any]:
    """Sends a WhatsApp text message via Twilio API."""
    client = get_twilio_client()
    if not client:
        logger.info(f"[Mock WhatsApp] To: {to_number}, Body: {message_body}")
        return {"status": "mock_sent", "to": to_number, "body": message_body}

    sender = from_number or TWILIO_WHATSAPP_NUMBER
    formatted_to = format_whatsapp_number(to_number)

    try:
        message = client.messages.create(
            from_=sender,
            to=formatted_to,
            body=message_body,
        )
        logger.info(f"Twilio WhatsApp sent. SID: {message.sid}")
        return {
            "status": "sent",
            "sid": message.sid,
            "to": formatted_to,
            "from": sender,
        }
    except Exception as e:
        logger.error(f"Failed to send Twilio WhatsApp message to {formatted_to}: {e}")
        return {
            "status": "error",
            "error": str(e),
            "to": formatted_to,
        }


def send_template_whatsapp(
    to_number: str,
    content_sid: Optional[str] = None,
    content_variables: Optional[Dict[str, str]] = None,
    from_number: Optional[str] = None
) -> Dict[str, Any]:
    """Sends a WhatsApp message using Twilio Content Template (content_sid)."""
    client = get_twilio_client()
    if not client:
        logger.info(f"[Mock Template] To: {to_number}, Content SID: {content_sid}")
        return {"status": "mock_sent", "to": to_number, "content_sid": content_sid}

    sender = from_number or TWILIO_WHATSAPP_NUMBER
    formatted_to = format_whatsapp_number(to_number)
    template_sid = content_sid or TWILIO_CONTENT_SID
    variables_str = json.dumps(content_variables or {"1": "Today", "2": "Now"})

    try:
        message = client.messages.create(
            from_=sender,
            to=formatted_to,
            content_sid=template_sid,
            content_variables=variables_str,
        )
        logger.info(f"Twilio WhatsApp Template sent. SID: {message.sid}")
        return {
            "status": "sent",
            "sid": message.sid,
            "to": formatted_to,
            "from": sender,
        }
    except Exception as e:
        logger.error(f"Failed to send template message to {formatted_to}: {e}")
        return {
            "status": "error",
            "error": str(e),
            "to": formatted_to,
        }


def notify_provider_lead(provider_phone: str, service_name: str, location: str, request_id: int):
    """
    Notify a service provider about a new job opportunity.
    Tries standard message first; falls back to template if WhatsApp window requires it.
    """
    body = (
        f"🔔 *New Lead from LocalFlow!*\n\n"
        f"A customer in *{location.title()}* requested *{service_name.title()}*.\n"
        f"Request ID: #{request_id}\n\n"
        f"Reply *ACCEPT {request_id}* to take this job."
    )
    result = send_whatsapp_message(provider_phone, body)
    
    # If standard text messaging failed due to session/template policy, attempt template send
    if result.get("status") == "error" and TWILIO_CONTENT_SID:
        logger.info("Attempting template message fallback for provider lead...")
        template_res = send_template_whatsapp(
            to_number=provider_phone,
            content_sid=TWILIO_CONTENT_SID,
            content_variables={"1": service_name.title(), "2": location.title()}
        )
        return template_res
    return result


def notify_consumer_provider_assigned(consumer_phone: str, provider_name: str, provider_phone: str, rate: str):
    """Notify the consumer that their service request has been assigned."""
    body = (
        f"🎉 *LocalFlow Update: Service Provider Assigned!*\n\n"
        f"Provider: *{provider_name}*\n"
        f"Phone: *{provider_phone}*\n"
        f"Estimated Rate: *{rate}*\n\n"
        f"The provider will contact you shortly."
    )
    return send_whatsapp_message(consumer_phone, body)
