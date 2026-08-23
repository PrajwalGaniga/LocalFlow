from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import crud, schemas, models
from app.database import get_db
from app.services.matching import accept_notification

router = APIRouter(prefix="/providers", tags=["providers"])


@router.post("/", response_model=schemas.ProviderOut, status_code=status.HTTP_201_CREATED)
def register_provider(payload: schemas.ProviderCreate, db: Session = Depends(get_db)):
    """Register a new service provider profile (supports multiple skill profiles per phone)."""
    clean_phone = payload.phone.strip()
    existing_profiles = crud.get_providers_by_phone(db, clean_phone)
    for p in existing_profiles:
        if p.skill.lower() == payload.skill.strip().lower():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"You already have an active profile for the '{payload.skill}' skill.",
            )
    return crud.create_provider(db, payload)


@router.post("/login", response_model=schemas.ProviderOut)
def login_provider(payload: schemas.PhoneLoginIn, db: Session = Depends(get_db)):
    """Login a provider with phone number and optional password."""
    provider = crud.get_provider_by_phone(db, payload.phone)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Provider not registered. Please sign up.",
        )
    if payload.password and provider.password and provider.password != payload.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect password.",
        )
    return provider


@router.get("/", response_model=List[schemas.ProviderOut])
def list_providers(db: Session = Depends(get_db)):
    """List all registered service providers."""
    return crud.list_providers(db)


@router.get("/by-phone/{phone}", response_model=schemas.ProviderOut)
def get_provider_by_phone(phone: str, db: Session = Depends(get_db)):
    """Lookup a provider by phone number (returns latest active profile)."""
    provider = crud.get_provider_by_phone(db, phone)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Provider not registered.",
        )
    return provider


@router.get("/all-by-phone/{phone}", response_model=List[schemas.ProviderOut])
def get_all_providers_by_phone(phone: str, db: Session = Depends(get_db)):
    """Lookup all provider profiles for a given phone number (for multi-skill profile switcher)."""
    providers = crud.get_providers_by_phone(db, phone)
    if not providers:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No provider profiles found for this phone.",
        )
    return providers


@router.get("/{provider_id}", response_model=schemas.ProviderOut)
def get_provider(provider_id: int, db: Session = Depends(get_db)):
    """Get details for a specific provider by ID."""
    provider = crud.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Provider not found",
        )
    return provider


@router.patch("/{provider_id}", response_model=schemas.ProviderOut)
def update_provider_profile(
    provider_id: int, payload: schemas.ProviderUpdate, db: Session = Depends(get_db)
):
    """Edit provider profile (name, skill, location, rate range, availability, password)."""
    provider = crud.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Provider not found",
        )
    return crud.update_provider(db, provider, payload)


@router.get("/{provider_id}/wallet", response_model=schemas.ProviderWalletOut)
def get_provider_wallet(provider_id: int, db: Session = Depends(get_db)):
    """Get provider wallet metrics, total earnings, and transaction ledger."""
    provider = crud.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Provider not found",
        )
    return crud.get_provider_wallet_data(db, provider)


@router.patch("/{provider_id}/availability", response_model=schemas.ProviderOut)
def set_availability(
    provider_id: int, payload: schemas.ProviderAvailabilityUpdate, db: Session = Depends(get_db)
):
    """Update a provider's availability status (available_now, available_later, busy, offline)."""
    provider = crud.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Provider not found",
        )
    return crud.update_availability(db, provider, payload.availability_status)


@router.get("/{provider_id}/notifications", response_model=List[schemas.NotificationWithRequestOut])
def get_provider_notifications(provider_id: int, db: Session = Depends(get_db)):
    """
    Get this provider's pending offers:
    RequestNotification rows where status=notified, joined with request details.
    Powers the 'Incoming Requests' screen in the mobile app.
    """
    provider = crud.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Provider not found",
        )
    return crud.get_provider_pending_notifications(db, provider_id)


@router.post("/{provider_id}/notifications/{request_id}/accept", response_model=schemas.AcceptNotificationResponse)
def provider_accept_notification(provider_id: int, request_id: int, db: Session = Depends(get_db)):
    """
    Accept an incoming job notification.
    Calls shared accept_notification() service. Returns consumer contact info on success.
    Returns 409 Conflict if already claimed by another provider.
    """
    provider = crud.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Provider not found",
        )

    result = accept_notification(db, request_id, provider_id)
    if not result.get("success"):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=result.get("message", "Job already claimed or unavailable"),
        )
    return result


@router.post("/{provider_id}/notifications/{request_id}/decline")
def provider_decline_notification(provider_id: int, request_id: int, db: Session = Depends(get_db)):
    """Mark a job offer notification as declined."""
    provider = crud.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Provider not found",
        )
    declined = crud.decline_notification(db, request_id, provider_id)
    return {"status": "declined" if declined else "not_found", "request_id": request_id}


@router.get("/{provider_id}/requests", response_model=List[schemas.ServiceRequestOut])
def get_provider_jobs(provider_id: int, db: Session = Depends(get_db)):
    """List all matched / in-progress and completed jobs assigned to this provider."""
    provider = crud.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Provider not found",
        )
    return db.query(models.ServiceRequest).filter(
        models.ServiceRequest.provider_id == provider_id
    ).order_by(models.ServiceRequest.id.desc()).all()

