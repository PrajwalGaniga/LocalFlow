"""
Sends a real consumer service request through the webhook to notify provider +919110687983
"""
import uuid
from fastapi.testclient import TestClient

import app.whatsapp_client as wc
from app.main import app

# Ensure real Twilio messaging is enabled
wc.MOCK_WHATSAPP_SEND = False

client = TestClient(app)

CONSUMER_PHONE = "whatsapp:+916362280470"


def send_real_consumer_service_request():
    print(f"Triggering consumer WhatsApp message from {CONSUMER_PHONE}...")
    
    # 1. Simulate consumer WhatsApp inbound message
    sid = f"SM{uuid.uuid4().hex}"
    res = client.post(
        "/webhooks/twilio/whatsapp",
        data={
            "From": CONSUMER_PHONE,
            "Body": "Need electrician in koramangala, power trip issue",
            "MessageSid": sid,
        },
    )
    print(f"Webhook response status: {res.status_code}")
    print(f"Webhook response body: {res.text}")


if __name__ == "__main__":
    send_real_consumer_service_request()
