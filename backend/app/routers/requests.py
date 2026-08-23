from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import crud, schemas, models
from app.database import get_db
from app.services.twilio_service import notify_consumer_provider_assigned, notify_provider_lead

router = APIRouter(prefix="/requests", tags=["requests"])


@router.post("/", response_model=schemas.ServiceRequestOut, status_code=201)
def create_request(payload: schemas.ServiceRequestCreate, db: Session = Depends(get_db)):
    """Create a new service request from a consumer."""
    req = crud.create_request(db, payload)
    
    # Check if there are matches and optionally notify the top provider
    matches = crud.find_matches(db, req, limit=1)
    if matches:
        top_provider = matches[0]
        # Notify provider via WhatsApp asynchronously/safely
        notify_provider_lead(
            provider_phone=top_provider.phone,
            service_name=req.skill_requested,
            location=req.location,
            request_id=req.id,
        )
    return req


@router.get("/", response_model=list[schemas.ServiceRequestOut])
def list_requests(db: Session = Depends(get_db)):
    """List all service requests."""
    return crud.list_requests(db)


@router.get("/{request_id}", response_model=schemas.ServiceRequestOut)
def get_request(request_id: int, db: Session = Depends(get_db)):
    """Get service request details by ID."""
    req = crud.get_request(db, request_id)
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    return req


@router.get("/{request_id}/matches", response_model=list[schemas.ProviderOut])
def get_matches(request_id: int, db: Session = Depends(get_db)):
    """Get ranked matching providers for a specific service request."""
    req = crud.get_request(db, request_id)
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    if req.status != models.RequestStatus.pending:
        raise HTTPException(status_code=400, detail=f"Request is already '{req.status.value}'")
    return crud.find_matches(db, req)


@router.post("/{request_id}/select", response_model=schemas.ServiceRequestOut)
def select_provider(request_id: int, payload: schemas.SelectProviderIn, db: Session = Depends(get_db)):
    """Assign a provider to a service request."""
    req = crud.get_request(db, request_id)
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    if req.status != models.RequestStatus.pending:
        raise HTTPException(status_code=400, detail=f"Request is already '{req.status.value}'")

    provider = crud.get_provider(db, payload.provider_id)
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")

    updated_req = crud.select_provider(db, req, provider)
    
    # Notify consumer via WhatsApp that a provider was confirmed
    rate_info = f"₹{provider.rate_min} - ₹{provider.rate_max}" if provider.rate_min else "Standard rates"
    notify_consumer_provider_assigned(
        consumer_phone=updated_req.consumer_phone,
        provider_name=provider.name,
        provider_phone=provider.phone,
        rate=rate_info,
    )
    
    return updated_req


@router.post("/{request_id}/complete", response_model=schemas.ServiceRequestOut)
def complete_request(request_id: int, payload: schemas.CompleteRequestIn, db: Session = Depends(get_db)):
    """Mark a service request as completed and record consumer rating (1-5)."""
    req = crud.get_request(db, request_id)
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    if req.status != models.RequestStatus.matched:
        raise HTTPException(
            status_code=400,
            detail=f"Request must be 'matched' to complete, currently '{req.status.value}'"
        )

    return crud.complete_request(db, req, payload.rating, payload.rating_comment)


@router.post("/{request_id}/cancel", response_model=schemas.CancelRequestResponse)
def cancel_service_request(request_id: int, db: Session = Depends(get_db)):
    """Cancel a pending or matched service request."""
    req = crud.get_request(db, request_id)
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    if req.status == models.RequestStatus.completed:
        raise HTTPException(status_code=400, detail="Cannot cancel an already completed request.")

    was_matched = req.status == models.RequestStatus.matched
    provider = req.provider

    crud.cancel_request(db, req)

    # Notify provider if it was matched
    if was_matched and provider:
        try:
            # pyrefly: ignore [missing-import]
            from app.services.whatsapp_client import send_whatsapp_message
            send_whatsapp_message(
                to_phone=provider.phone,
                body=f"⚠️ Job #{req.id} has been cancelled by the customer.",
            )
        except Exception:
            pass

    return schemas.CancelRequestResponse(
        success=True,
        message=f"Request #{req.id} has been successfully cancelled.",
        request_id=req.id,
        status=models.RequestStatus.cancelled,
    )


@router.post("/{request_id}/mark-paid", response_model=schemas.ServiceRequestOut)
def mark_request_paid(request_id: int, db: Session = Depends(get_db)):
    """
    Self-declared mark as paid button tap.
    Sets payment_status='paid' and paid_at=now(). No verification needed.
    """
    req = crud.get_request(db, request_id)
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    return crud.mark_request_paid(db, req)


@router.get("/meta/skills", response_model=list[str])
def list_available_skills(db: Session = Depends(get_db)):
    """Get list of distinct skills for dropdowns."""
    return crud.get_distinct_skills(db)


@router.get("/meta/locations", response_model=list[str])
def list_available_locations(db: Session = Depends(get_db)):
    """Get list of distinct localities for dropdowns."""
    return crud.get_distinct_locations(db)

