from app.database import SessionLocal, engine, Base
from app import models, crud
from app.phone_utils import normalize_whatsapp_number


def clean():
    db = SessionLocal()
    try:
        # Delete old non-normalized providers
        providers = db.query(models.Provider).all()
        seen_phones = set()
        for p in providers:
            clean_phone = normalize_whatsapp_number(p.phone)
            if clean_phone in seen_phones:
                print(f"Removing duplicate provider: {p.name} ({p.phone})")
                # remove notifications and requests first
                for notif in p.notifications:
                    db.delete(notif)
                for req in p.requests:
                    db.delete(req)
                db.delete(p)
            else:
                p.phone = clean_phone
                seen_phones.add(clean_phone)
        db.commit()
        print("Database provider phone numbers normalized and cleaned!")
    finally:
        db.close()


if __name__ == "__main__":
    clean()
