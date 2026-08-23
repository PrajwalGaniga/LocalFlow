from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from app.config import DATABASE_URL

# Create SQLAlchemy engine with pool_pre_ping for resilient connections
engine = create_engine(DATABASE_URL, pool_pre_ping=True, echo=False, future=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """FastAPI dependency — yields a DB session per request, closes it after."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
