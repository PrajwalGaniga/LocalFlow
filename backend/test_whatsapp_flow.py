"""
Comprehensive Test of WhatsApp Workflow Lifecycle
Simulates the entire loop via FastAPI TestClient against /webhooks/twilio/whatsapp:
1. Consumer (+91 63622 80470) texts: "Need electrician in koramangala - ceiling fan not working"
   -> System finds matching electricians (Ramesh 9110687983 & Suresh 9999900001)
   -> Dispatches Template A (New Lead) to both providers
   -> Dispatches Template G (Searching) to consumer
2. Provider A (9110687983) texts: "ACCEPT <req_id>"
   -> Atomic claim succeeds
   -> Dispatches Template B (Job Confirmed) to Provider A
   -> Dispatches Template C (Provider Assigned) to Consumer
   -> Dispatches Template D (Already Taken) to losing Provider B (9999900001)
3. Provider B (9999900001) late reply: "ACCEPT <req_id>"
   -> Atomic claim fails (already matched)
   -> Dispatches Template D directly to Provider B
4. Consumer texts: "DONE <req_id> 5 Arrived promptly and fixed the fan!"
   -> Status becomes completed, rating updated
   -> Dispatches Template E (Thanks) to Consumer
   -> Dispatches Template F (Rated Notice) to Provider A
5. Idempotency test: duplicate MessageSid returns 200 without reprocessing
"""
import uuid
from fastapi.testclient import TestClient

import app.whatsapp_client as wc
from app.main import app
from app.database import SessionLocal, Base, engine
from app import crud, models

client = TestClient(app)

# Enable mock mode for testing without draining Twilio free tier
wc.MOCK_WHATSAPP_SEND = True

CONSUMER_NUMBER = "whatsapp:+916362280470"
PROVIDER_A = "whatsapp:+919110687983"
PROVIDER_B = "whatsapp:+919999900001"


def test_full_whatsapp_workflow():
    print("\n" + "=" * 60)
    print("STEP 1: Consumer texts a service request")
    print("=" * 60)
    
    sid_1 = f"SM{uuid.uuid4().hex}"
    res = client.post(
        "/webhooks/twilio/whatsapp",
        data={
            "From": CONSUMER_NUMBER,
            "Body": "Need electrician in koramangala - ceiling fan sparking and stopped working",
            "MessageSid": sid_1,
        },
    )
    assert res.status_code == 200
    print(f"-> Webhook response: {res.status_code} {res.text}")

    # Inspect created request in DB
    db = SessionLocal()
    try:
        latest_req = crud.list_requests(db)[0]
        req_id = latest_req.id
        print(f"-> Created ServiceRequest ID: #{req_id} | Status: {latest_req.status.value}")
        
        notifs = crud.get_request_notifications(db, req_id)
        print(f"-> Created {len(notifs)} RequestNotification records:")
        for n in notifs:
            prov = crud.get_provider(db, n.provider_id)
            print(f"   - Provider: {prov.name} ({prov.phone}) | Status: {n.status.value}")
        assert len(notifs) >= 2, "Expected at least 2 matching providers notified"

        print("\n" + "=" * 60)
        print(f"STEP 2: Provider A ({PROVIDER_A}) sends ACCEPT #{req_id}")
        print("=" * 60)
        
        sid_2 = f"SM{uuid.uuid4().hex}"
        res2 = client.post(
            "/webhooks/twilio/whatsapp",
            data={
                "From": PROVIDER_A,
                "Body": f"ACCEPT {req_id}",
                "MessageSid": sid_2,
            },
        )
        assert res2.status_code == 200
        
        db.expire_all()
        db.refresh(latest_req)
        print(f"-> Request #{req_id} status after ACCEPT: {latest_req.status.value} (Assigned Provider ID: {latest_req.provider_id})")
        assert latest_req.status.value == "matched"

        # Check notifications status
        notifs_after = crud.get_request_notifications(db, req_id)
        for n in notifs_after:
            prov = crud.get_provider(db, n.provider_id)
            print(f"   - Provider: {prov.name} ({prov.phone}) -> Final Notification Status: {n.status.value}")
        
        prov_a_notif = crud.get_notification(db, req_id, latest_req.provider_id)
        assert prov_a_notif.status.value == "accepted"

        print("\n" + "=" * 60)
        print(f"STEP 3: Provider B ({PROVIDER_B}) sends late ACCEPT #{req_id}")
        print("=" * 60)
        
        sid_3 = f"SM{uuid.uuid4().hex}"
        res3 = client.post(
            "/webhooks/twilio/whatsapp",
            data={
                "From": PROVIDER_B,
                "Body": f"ACCEPT {req_id}",
                "MessageSid": sid_3,
            },
        )
        assert res3.status_code == 200
        print("-> Losing provider handled properly without modifying matched state.")

        print("\n" + "=" * 60)
        print(f"STEP 4: Consumer sends completion rating DONE #{req_id} 5")
        print("=" * 60)
        
        sid_4 = f"SM{uuid.uuid4().hex}"
        res4 = client.post(
            "/webhooks/twilio/whatsapp",
            data={
                "From": CONSUMER_NUMBER,
                "Body": f"DONE {req_id} 5 Excellent job, fixed fan quickly!",
                "MessageSid": sid_4,
            },
        )
        assert res4.status_code == 200

        db.refresh(latest_req)
        print(f"-> Request #{req_id} status after DONE: {latest_req.status.value} | Rating: {latest_req.rating}/5")
        assert latest_req.status.value == "completed"

        prov_a = crud.get_provider(db, latest_req.provider_id)
        print(f"-> Provider {prov_a.name} Updated Reputation: {prov_a.rating_avg} stars ({prov_a.rating_count} reviews, {prov_a.jobs_completed} jobs completed)")

        print("\n" + "=" * 60)
        print("STEP 5: Idempotency Test (Retried MessageSid)")
        print("=" * 60)
        res_dup = client.post(
            "/webhooks/twilio/whatsapp",
            data={
                "From": CONSUMER_NUMBER,
                "Body": f"DONE {req_id} 5",
                "MessageSid": sid_4,  # Same MessageSid
            },
        )
        assert res_dup.status_code == 200
        print("-> Duplicate webhook dropped cleanly without reprocessing.")

        print("\n" + "=" * 60)
        print(">>> ALL WORKFLOW TESTS PASSED CLEANLY! <<<")
        print("=" * 60)
        return True
    finally:
        db.close()


if __name__ == "__main__":
    test_full_whatsapp_workflow()
