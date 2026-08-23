import logging
from typing import Optional
from twilio.rest import Client

from app.config import TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_WHATSAPP_NUMBER
from app.phone_utils import normalize_whatsapp_number

logger = logging.getLogger("whatsapp_client")
logging.basicConfig(level=logging.INFO)

# Global flag to allow dry-run testing (logging messages without calling Twilio API)
MOCK_WHATSAPP_SEND = False


def send_whatsapp_message(to_number: str, body: str) -> None:
    """
    Sends a WhatsApp message via Twilio SDK.
    Takes bare 10-digit number or raw number, normalizes to 'whatsapp:+91<10digits>',
    and sends from TWILIO_WHATSAPP_NUMBER.
    Logs each send and catches exceptions so the webhook never crashes.
    """
    bare = normalize_whatsapp_number(to_number)
    if not bare:
        logger.warning(f"Invalid phone number provided: {to_number}")
        return

    formatted_to = f"whatsapp:+91{bare}"
    preview = body.replace("\n", " ")[:40]

    if MOCK_WHATSAPP_SEND:
        logger.info(f"[MOCK SEND] To: {formatted_to} | Body: {preview}...")
        return

    try:
        if not TWILIO_ACCOUNT_SID or not TWILIO_AUTH_TOKEN:
            logger.warning(f"[NO CREDENTIALS] Mocked send to {formatted_to} | Body: {preview}...")
            return

        client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        message = client.messages.create(
            from_=TWILIO_WHATSAPP_NUMBER,
            to=formatted_to,
            body=body,
        )
        logger.info(f"[WHATSAPP SENT] To: {formatted_to} | SID: {message.sid} | Body: {preview}...")
    except Exception as e:
        logger.error(f"[WHATSAPP SEND FAILED] To: {formatted_to} | Error: {e} | Body: {preview}...")
