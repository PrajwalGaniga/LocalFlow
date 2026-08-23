from sqlalchemy import text
from app.database import engine, Base
import app.models  # Ensure all models are registered

def run_migrations():
    print("Running database migrations and table creation...")
    with engine.connect() as conn:
        # Create ENUM type for paymentstatus if not exists
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

        # Add columns to providers table if not exist
        conn.execute(text("""
            ALTER TABLE providers ADD COLUMN IF NOT EXISTS password VARCHAR(120);
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

        # Add columns to service_requests table if not exist
        conn.execute(text("""
            ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS payment_status paymentstatus NOT NULL DEFAULT 'unpaid';
            ALTER TABLE service_requests ADD COLUMN IF NOT EXISTS paid_at TIMESTAMP;
        """))
        conn.commit()

    # Create any brand new tables (consumers, registration_links)
    Base.metadata.create_all(bind=engine)
    print("Migrations completed successfully.")

if __name__ == "__main__":
    run_migrations()
