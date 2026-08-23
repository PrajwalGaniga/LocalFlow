import json
from twilio.rest import Client
from sqlalchemy.orm import Session

from app.config import (
    TWILIO_ACCOUNT_SID,
    TWILIO_AUTH_TOKEN,
    TWILIO_WHATSAPP_NUMBER,
    TWILIO_CONTENT_SID,
)
from app.database import SessionLocal, Base, engine
from app import crud, schemas, models
from app.services.twilio_service import notify_provider_lead


def send_direct_twilio_message():
    print("\n--- 1. Testing Direct Twilio WhatsApp Message with Content Template ---")
    try:
        client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        message = client.messages.create(
            from_=TWILIO_WHATSAPP_NUMBER,
            content_sid=TWILIO_CONTENT_SID,
            content_variables=json.dumps({"1": "12/1", "2": "3pm"}),
            to='whatsapp:+919110687983'
        )
        print(f"[OK] Direct WhatsApp message dispatched successfully!")
        print(f"     Message SID: {message.sid}")
        print(f"     Status: {message.status}")
        print(f"     To: whatsapp:+919110687983")
        return message.sid
    except Exception as e:
        print(f"[ERROR] Direct Twilio message failed: {e}")
        return None


def simulate_consumer_request_to_provider():
    print("\n--- 2. Setting Up Provider and Sending Consumer Service Request ---")
    Base.metadata.create_all(bind=engine)
    db: Session = SessionLocal()
    try:
        target_phone = "+919110687983"
        
        # 1. Register or update provider in DB
        provider = crud.get_provider_by_phone(db, target_phone)
        if not provider:
            provider_data = schemas.ProviderCreate(
                name="Ramesh Electrician",
                phone=target_phone,
                skill="electrician",
                location="koramangala",
                rate_min=300,
                rate_max=600,
                availability_status=models.AvailabilityStatus.available_now
            )
            provider = crud.create_provider(db, provider_data)
            print(f"[OK] Registered provider '{provider.name}' with phone {provider.phone} (ID: {provider.id})")
        else:
            provider.availability_status = models.AvailabilityStatus.available_now
            db.commit()
            print(f"[OK] Provider already registered: '{provider.name}', phone: {provider.phone} (ID: {provider.id})")

        # 2. Consumer sends a request
        consumer_phone = "+919876543210"
        request_data = schemas.ServiceRequestCreate(
            consumer_phone=consumer_phone,
            skill_requested="electrician",
            location="koramangala",
            description="Short circuit in kitchen switchboard and ceiling fan"
        )
        req = crud.create_request(db, request_data)
        print(f"[OK] Consumer created Service Request #{req.id}:")
        print(f"     Skill: {req.skill_requested}")
        print(f"     Location: {req.location}")
        print(f"     Description: {req.description}")

        # 3. Matching
        matches = crud.find_matches(db, req)
        print(f"[OK] Found {len(matches)} matching provider(s): {[p.name for p in matches]}")

        # 4. Dispatch WhatsApp notification to the provider
        print(f"\n--- 3. Dispatched WhatsApp Lead Alert to Provider {target_phone} ---")
        lead_result = notify_provider_lead(
            provider_phone=target_phone,
            service_name=req.skill_requested,
            location=req.location,
            request_id=req.id
        )
        print(f"[OK] Notification response: {lead_result}")

        return True
    except Exception as e:
        print(f"[ERROR] Consumer to provider simulation failed: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.close()


if __name__ == "__main__":
    send_direct_twilio_message()
    simulate_consumer_request_to_provider()
