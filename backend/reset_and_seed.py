from sqlalchemy import text
from app.database import engine, Base
from seed_providers import seed


def reset_and_seed():
    with engine.connect() as conn:
        conn.execute(text("TRUNCATE TABLE request_notifications, service_requests, processed_messages, providers RESTART IDENTITY CASCADE;"))
        conn.commit()
    print("Database tables truncated and reset.")
    seed()


if __name__ == "__main__":
    reset_and_seed()
