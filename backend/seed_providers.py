from sqlalchemy.orm import Session
from app.database import Base, engine, SessionLocal
from app import crud, models, schemas

# Ensure all new tables are created
Base.metadata.create_all(bind=engine)

PROVIDERS_DATA = [
    {
        "name": "Prajwal",
        "phone": "9110687983",
        "password": "12345678",
        "skill": "electrician",
        "location": "koramangala",
        "rate_min": 300,
        "rate_max": 600,
        "availability_status": models.AvailabilityStatus.available_now,
    },
    {
        "name": "Suresh Babu",
        "phone": "9999900001",
        "password": "12345678",
        "skill": "electrician",
        "location": "koramangala",
        "rate_min": 250,
        "rate_max": 500,
        "availability_status": models.AvailabilityStatus.available_now,
    },
    {
        "name": "Anand Verma",
        "phone": "9999900002",
        "password": "12345678",
        "skill": "plumber",
        "location": "koramangala",
        "rate_min": 200,
        "rate_max": 450,
        "availability_status": models.AvailabilityStatus.available_now,
    },
    {
        "name": "Manjunath Gowda",
        "phone": "9999900003",
        "password": "12345678",
        "skill": "plumber",
        "location": "indiranagar",
        "rate_min": 300,
        "rate_max": 550,
        "availability_status": models.AvailabilityStatus.available_now,
    },
    {
        "name": "Pooja Sharma",
        "phone": "9999900004",
        "password": "12345678",
        "skill": "tutor",
        "location": "koramangala",
        "rate_min": 500,
        "rate_max": 1000,
        "availability_status": models.AvailabilityStatus.available_now,
    },
    {
        "name": "Mohammad Rafiq",
        "phone": "9999900005",
        "password": "12345678",
        "skill": "carpenter",
        "location": "koramangala",
        "rate_min": 400,
        "rate_max": 800,
        "availability_status": models.AvailabilityStatus.available_now,
    },
    {
        "name": "Sunil Naik",
        "phone": "9999900006",
        "password": "12345678",
        "skill": "tailor",
        "location": "koramangala",
        "rate_min": 150,
        "rate_max": 400,
        "availability_status": models.AvailabilityStatus.available_now,
    },
    {
        "name": "Deepak Reddy",
        "phone": "9999900007",
        "password": "12345678",
        "skill": "painter",
        "location": "hsr layout",
        "rate_min": 600,
        "rate_max": 1200,
        "availability_status": models.AvailabilityStatus.available_now,
    },
]

CONSUMERS_DATA = [
    {
        "name": "ashwitha",
        "phone": "6362280370",
        "password": "12345678",
    },
    {
        "name": "ashwitha",
        "phone": "6362280470",
        "password": "12345678",
    },
]


def seed():
    db: Session = SessionLocal()
    try:
        print("Seeding Indian service providers into database...")
        for item in PROVIDERS_DATA:
            existing = crud.get_provider_by_phone(db, item["phone"])
            if not existing:
                prov = crud.create_provider(db, schemas.ProviderCreate(**item))
                print(f"[CREATED PROVIDER] {prov.name} | Skill: {prov.skill.title()} | Area: {prov.location.title()} | Phone: {prov.phone}")
            else:
                existing.name = item["name"]
                existing.password = item.get("password")
                existing.skill = item["skill"].lower()
                existing.location = item["location"].lower()
                existing.rate_min = item["rate_min"]
                existing.rate_max = item["rate_max"]
                existing.availability_status = item["availability_status"]
                db.commit()
                print(f"[UPDATED PROVIDER] {existing.name} | Skill: {existing.skill.title()} | Area: {existing.location.title()} | Phone: {existing.phone}")

        print("\nSeeding consumers into database...")
        for c_item in CONSUMERS_DATA:
            c_existing = crud.get_consumer_by_phone(db, c_item["phone"])
            if not c_existing:
                cons = crud.create_consumer(db, schemas.ConsumerCreate(**c_item))
                print(f"[CREATED CONSUMER] {cons.name} | Phone: {cons.phone}")
            else:
                c_existing.name = c_item["name"]
                c_existing.password = c_item.get("password")
                db.commit()
                print(f"[UPDATED CONSUMER] {c_existing.name} | Phone: {c_existing.phone}")

        print("\nAll sample providers and consumers registered/updated successfully!")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
