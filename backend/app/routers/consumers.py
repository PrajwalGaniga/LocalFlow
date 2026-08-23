from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import crud, schemas, models
from app.database import get_db

router = APIRouter(prefix="/consumers", tags=["consumers"])


@router.post("/", response_model=schemas.ConsumerOut, status_code=status.HTTP_201_CREATED)
def register_consumer(payload: schemas.ConsumerCreate, db: Session = Depends(get_db)):
    """Register a new consumer profile (App user)."""
    existing = crud.get_consumer_by_phone(db, payload.phone)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A consumer with this phone number is already registered.",
        )
    return crud.create_consumer(db, payload)


@router.post("/login", response_model=schemas.ConsumerOut)
def login_consumer(payload: schemas.PhoneLoginIn, db: Session = Depends(get_db)):
    """Login with phone number and optional password."""
    consumer = crud.get_consumer_by_phone(db, payload.phone)
    if not consumer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consumer not registered. Please sign up.",
        )
    if payload.password and consumer.password and consumer.password != payload.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect password.",
        )
    return consumer


@router.get("/by-phone/{phone}", response_model=schemas.ConsumerOut)
def get_consumer_by_phone(phone: str, db: Session = Depends(get_db)):
    """Lookup a consumer by phone number (login lookup)."""
    consumer = crud.get_consumer_by_phone(db, phone)
    if not consumer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consumer not registered.",
        )
    return consumer


@router.get("/{consumer_id}", response_model=schemas.ConsumerOut)
def get_consumer_by_id(consumer_id: int, db: Session = Depends(get_db)):
    """Get consumer details by ID."""
    consumer = crud.get_consumer(db, consumer_id)
    if not consumer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consumer not found.",
        )
    return consumer


@router.get("/{consumer_id}/requests", response_model=List[schemas.ConsumerRequestOut])
def get_consumer_requests(consumer_id: int, db: Session = Depends(get_db)):
    """Get all requests for a specific consumer with matched provider info."""
    consumer = crud.get_consumer(db, consumer_id)
    if not consumer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consumer not found.",
        )
    requests = crud.get_consumer_requests(db, consumer.phone)
    return requests
