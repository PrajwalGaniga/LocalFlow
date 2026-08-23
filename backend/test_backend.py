import sys
from sqlalchemy import text
from app.database import engine, Base, SessionLocal
from app import crud, schemas, models
from app.services import twilio_service


def run_tests():
    print("=== 1. Testing Database Connection & Creating Tables ===")
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT current_database();"))
            db_name = result.scalar()
            print(f"[OK] Connected successfully to PostgreSQL database: '{db_name}'")
        
        # Ensure all tables exist
        Base.metadata.create_all(bind=engine)
        print("[OK] Tables created/verified in database.")
    except Exception as e:
        print(f"[ERROR] Database connection failed: {e}")
        return False

    db = SessionLocal()
    try:
        print("\n=== 2. Testing Provider Registration ===")
        test_phone = "+919110687983"
        existing = crud.get_provider_by_phone(db, test_phone)
        if existing:
            # Delete any existing service requests associated with this provider
            for r in existing.requests:
                db.delete(r)
            db.delete(existing)
            db.commit()

        provider_data = schemas.ProviderCreate(
            name="Ramesh Electrician",
            phone=test_phone,
            skill="electrician",
            location="koramangala",
            rate_min=300,
            rate_max=600,
            availability_status=models.AvailabilityStatus.available_now
        )
        provider = crud.create_provider(db, provider_data)
        print(f"[OK] Provider created: ID {provider.id}, Name: {provider.name}, Skill: {provider.skill}")

        print("\n=== 3. Testing Service Request Creation ===")
        request_data = schemas.ServiceRequestCreate(
            consumer_phone="+919876543210",
            skill_requested="electrician",
            description="Fan stopped working",
            location="koramangala"
        )
        req = crud.create_request(db, request_data)
        print(f"[OK] Service request created: ID {req.id}, Status: {req.status.value}")

        print("\n=== 4. Testing Provider Matching Algorithm ===")
        matches = crud.find_matches(db, req)
        print(f"[OK] Found {len(matches)} matching provider(s): {[m.name for m in matches]}")
        assert len(matches) > 0, "Should have found at least one match"

        print("\n=== 5. Testing Provider Selection ===")
        updated_req = crud.select_provider(db, req, provider)
        print(f"[OK] Request #{updated_req.id} updated to status '{updated_req.status.value}', assigned to {provider.name}")

        print("\n=== 6. Testing Job Completion & Rating ===")
        completed_req = crud.complete_request(db, updated_req, rating=5, comment="Great service, fixed fast!")
        print(f"[OK] Request #{completed_req.id} completed. Rating: {completed_req.rating}/5")
        
        # Verify provider reputation stats
        db.refresh(provider)
        print(f"[OK] Provider updated stats -> Rating: {provider.rating_avg} ({provider.rating_count} reviews), Jobs Completed: {provider.jobs_completed}")

        print("\n=== 7. Testing Twilio Configuration ===")
        client = twilio_service.get_twilio_client()
        if client:
            print("[OK] Twilio client initialized with API Key / Secret credentials successfully.")
        else:
            print("[INFO] Twilio credentials not active (fallback mode enabled).")

        print("\n==========================================")
        print(">>> ALL BACKEND CHECKS PASSED SUCCESSFULLY! <<<")
        print("==========================================")
        return True
    except Exception as e:
        print(f"[ERROR] Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.close()


if __name__ == "__main__":
    success = run_tests()
    if not success:
        sys.exit(1)
