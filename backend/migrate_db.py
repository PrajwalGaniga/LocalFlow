from sqlalchemy import text
from app.database import engine, Base, SessionLocal
import app.models
from app.models import ServiceLocation

KARNATAKA_LOCATIONS = [
    # Bengaluru Urban
    ("Bengaluru Urban", "Bengaluru", "560001"),
    ("Bengaluru Urban", "Indiranagar", "560038"),
    ("Bengaluru Urban", "Koramangala", "560034"),
    ("Bengaluru Urban", "Jayanagar", "560041"),
    ("Bengaluru Urban", "Rajajinagar", "560010"),
    ("Bengaluru Urban", "Malleshwaram", "560003"),
    ("Bengaluru Urban", "Whitefield", "560066"),
    ("Bengaluru Urban", "Electronic City", "560100"),
    ("Bengaluru Urban", "Yelahanka", "560064"),
    ("Bengaluru Urban", "Marathahalli", "560037"),
    # Dakshina Kannada
    ("Dakshina Kannada", "Mangaluru", "575001"),
    ("Dakshina Kannada", "Surathkal", "575014"),
    ("Dakshina Kannada", "Ullal", "574129"),
    ("Dakshina Kannada", "Bantwal", "574211"),
    ("Dakshina Kannada", "Puttur", "574201"),
    ("Dakshina Kannada", "Belthangady", "574214"),
    ("Dakshina Kannada", "Sullia", "574239"),
    ("Dakshina Kannada", "Moodbidri", "574227"),
    ("Dakshina Kannada", "Mulki", "574154"),
    ("Dakshina Kannada", "Konaje", "574199"),
    # Udupi
    ("Udupi", "Udupi", "576101"),
    ("Udupi", "Manipal", "576104"),
    ("Udupi", "Kundapura", "576201"),
    ("Udupi", "Karkala", "574104"),
    ("Udupi", "Kaup", "574106"),
    ("Udupi", "Brahmavar", "576213"),
    ("Udupi", "Hebri", "576112"),
    ("Udupi", "Byndoor", "576214"),
    # Mysuru
    ("Mysuru", "Mysuru", "570001"),
    ("Mysuru", "Nanjangud", "571301"),
    ("Mysuru", "Hunsur", "571105"),
    ("Mysuru", "T. Narasipura", "571124"),
]


def seed_locations(db):
    """Seed the 32 Karnataka locations idempotently."""
    count = db.query(ServiceLocation).count()
    if count == 0:
        print(f"Seeding {len(KARNATAKA_LOCATIONS)} Karnataka locations...")
        for district, area, pin in KARNATAKA_LOCATIONS:
            loc = ServiceLocation(
                state="Karnataka",
                district=district,
                area_name=area,
                pincode=pin,
            )
            db.add(loc)
        db.commit()
        print("Locations seeded successfully.")
    else:
        # Check if any missing
        for district, area, pin in KARNATAKA_LOCATIONS:
            exists = db.query(ServiceLocation).filter(
                ServiceLocation.district == district,
                ServiceLocation.area_name == area,
            ).first()
            if not exists:
                loc = ServiceLocation(
                    state="Karnataka",
                    district=district,
                    area_name=area,
                    pincode=pin,
                )
                db.add(loc)
        db.commit()


def run_migrations():
    print("Running database migrations and table creation...")
    with engine.connect() as conn:
        # 1. Create ENUM type for paymentstatus if not exists
        conn.execute(text("""
            DO $$
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'paymentstatus') THEN
                    CREATE TYPE paymentstatus AS ENUM ('unpaid', 'paid');
                END IF;
            END
            $$;
        """))
        conn.commit()

        # 2. Add columns to providers table if not exist
        conn.execute(text("""
            ALTER TABLE providers ADD COLUMN IF NOT EXISTS password VARCHAR(120);
            ALTER TABLE providers ADD COLUMN IF NOT EXISTS location_id INTEGER;
            ALTER TABLE providers ALTER COLUMN location DROP NOT NULL;
            DO $$
            BEGIN
                ALTER TABLE providers DROP CONSTRAINT IF EXISTS providers_phone_key;
                DROP INDEX IF EXISTS ix_providers_phone;
                CREATE INDEX IF NOT EXISTS ix_providers_phone ON providers (phone);
            EXCEPTION WHEN OTHERS THEN
                NULL;
            END $$;
        """))
        conn.commit()

        # 3. Add columns to service_requests table if not exist
        conn.execute(text("""
            ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS payment_status paymentstatus NOT NULL DEFAULT 'unpaid';
            ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS paid_at TIMESTAMP WITH TIME ZONE;
            ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS location_id INTEGER;
            ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS preferred_provider_id INTEGER;
            ALTER TABLE service_requests ALTER COLUMN location DROP NOT NULL;
        """))
        conn.commit()

        # 4. Alter timestamp columns to TIMESTAMP WITH TIME ZONE
        conn.execute(text("""
            DO $$
            BEGIN
                ALTER TABLE providers ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE USING created_at AT TIME ZONE 'UTC';
                ALTER TABLE consumers ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE USING created_at AT TIME ZONE 'UTC';
                ALTER TABLE service_requests ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE USING created_at AT TIME ZONE 'UTC';
                ALTER TABLE service_requests ALTER COLUMN matched_at TYPE TIMESTAMP WITH TIME ZONE USING matched_at AT TIME ZONE 'UTC';
                ALTER TABLE service_requests ALTER COLUMN completed_at TYPE TIMESTAMP WITH TIME ZONE USING completed_at AT TIME ZONE 'UTC';
                ALTER TABLE request_notifications ALTER COLUMN notified_at TYPE TIMESTAMP WITH TIME ZONE USING notified_at AT TIME ZONE 'UTC';
                ALTER TABLE request_notifications ALTER COLUMN responded_at TYPE TIMESTAMP WITH TIME ZONE USING responded_at AT TIME ZONE 'UTC';
                ALTER TABLE registration_links ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE USING created_at AT TIME ZONE 'UTC';
                ALTER TABLE processed_messages ALTER COLUMN processed_at TYPE TIMESTAMP WITH TIME ZONE USING processed_at AT TIME ZONE 'UTC';
            EXCEPTION WHEN OTHERS THEN
                NULL;
            END $$;
        """))
        conn.commit()

    # Create tables if not exist
    Base.metadata.create_all(bind=engine)

    # Seed locations
    db = SessionLocal()
    try:
        seed_locations(db)

        # Backfill location_id for existing providers and requests if location string matches
        koramangala = db.query(ServiceLocation).filter(ServiceLocation.area_name == "Koramangala").first()
        if koramangala:
            db.execute(text("UPDATE providers SET location_id = :lid WHERE location_id IS NULL"), {"lid": koramangala.id})
            db.execute(text("UPDATE service_requests SET location_id = :lid WHERE location_id IS NULL"), {"lid": koramangala.id})
            db.commit()
    finally:
        db.close()

    print("Migrations and seed completed successfully.")


if __name__ == "__main__":
    run_migrations()
