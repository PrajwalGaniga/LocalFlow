from datetime import datetime
import secrets
from typing import List, Optional

from sqlalchemy.orm import Session
from sqlalchemy import func

from app import models, schemas
from app.phone_utils import normalize_whatsapp_number


# ---------- Provider Operations ----------

def create_provider(db: Session, data: schemas.ProviderCreate) -> models.Provider:
    provider = models.Provider(
        name=data.name.strip(),
        phone=normalize_whatsapp_number(data.phone),
        password=data.password,
        skill=data.skill.strip().lower(),
        location=data.location.strip().lower(),
        rate_min=data.rate_min,
        rate_max=data.rate_max,
        availability_status=data.availability_status,
    )
    db.add(provider)
    db.commit()
    db.refresh(provider)
    return provider


def get_provider(db: Session, provider_id: int) -> Optional[models.Provider]:
    return db.get(models.Provider, provider_id)


def get_provider_by_phone(db: Session, phone: str) -> Optional[models.Provider]:
    clean_phone = normalize_whatsapp_number(phone)
    return db.query(models.Provider).filter(models.Provider.phone == clean_phone).order_by(models.Provider.id.desc()).first()


def get_providers_by_phone(db: Session, phone: str) -> List[models.Provider]:
    clean_phone = normalize_whatsapp_number(phone)
    return db.query(models.Provider).filter(models.Provider.phone == clean_phone).order_by(models.Provider.id.asc()).all()


def update_provider(
    db: Session, provider: models.Provider, data: schemas.ProviderUpdate
) -> models.Provider:
    if data.name is not None:
        provider.name = data.name.strip()
    if data.skill is not None:
        provider.skill = data.skill.strip().lower()
    if data.location is not None:
        provider.location = data.location.strip().lower()
    if data.rate_min is not None:
        provider.rate_min = data.rate_min
    if data.rate_max is not None:
        provider.rate_max = data.rate_max
    if data.password is not None:
        provider.password = data.password
    if data.availability_status is not None:
        provider.availability_status = data.availability_status
    db.commit()
    db.refresh(provider)
    return provider


def list_providers(db: Session) -> List[models.Provider]:
    return db.query(models.Provider).order_by(models.Provider.id).all()


def update_availability(
    db: Session, provider: models.Provider, status: models.AvailabilityStatus
) -> models.Provider:
    provider.availability_status = status
    db.commit()
    db.refresh(provider)
    return provider


def get_provider_wallet_data(db: Session, provider: models.Provider) -> schemas.ProviderWalletOut:
    # Fetch all completed / paid requests for this provider
    requests = db.query(models.ServiceRequest).filter(
        models.ServiceRequest.provider_id == provider.id
    ).order_by(models.ServiceRequest.id.desc()).all()

    transactions = []
    total_earnings = 0

    for req in requests:
        # Payout calculation: rate_min or provider's min rate, default 350
        est_amount = req.provider.rate_min if req.provider and req.provider.rate_min else (provider.rate_min or 350)
        is_paid = req.payment_status == models.PaymentStatus.paid
        is_completed = req.status == models.RequestStatus.completed

        if is_paid or is_completed:
            total_earnings += est_amount

        transactions.append(schemas.ProviderWalletTransaction(
            request_id=req.id,
            consumer_phone=req.consumer_phone,
            skill=req.skill_requested,
            location=req.location,
            amount=est_amount,
            status="Paid" if is_paid else (req.status.value.title()),
            paid_at=req.paid_at,
            completed_at=req.completed_at,
            rating=req.rating,
        ))

    return schemas.ProviderWalletOut(
        provider_id=provider.id,
        provider_name=provider.name,
        total_earnings=total_earnings,
        available_balance=total_earnings,
        jobs_completed=provider.jobs_completed,
        rating_avg=provider.rating_avg,
        transactions=transactions,
    )


def get_distinct_skills(db: Session) -> List[str]:
    """Returns a list of distinct registered skills."""
    skills = db.query(models.Provider.skill).distinct().all()
    result = {s[0].lower() for s in skills if s[0]}
    # Include standard defaults
    defaults = {"electrician", "plumber", "tutor", "tailor", "carpenter", "painter"}
    return sorted(list(result.union(defaults)))


def get_distinct_locations(db: Session) -> List[str]:
    """Returns a list of distinct registered localities."""
    locs = db.query(models.Provider.location).distinct().all()
    result = {l[0].lower() for l in locs if l[0]}
    defaults = {"koramangala", "indiranagar", "hsr layout", "whitefield", "jayanagar", "marathahalli"}
    return sorted(list(result.union(defaults)))


# ---------- Consumer Operations ----------

def create_consumer(db: Session, data: schemas.ConsumerCreate) -> models.Consumer:
    consumer = models.Consumer(
        name=data.name.strip(),
        phone=normalize_whatsapp_number(data.phone),
        password=data.password,
    )
    db.add(consumer)
    db.commit()
    db.refresh(consumer)
    return consumer


def get_consumer(db: Session, consumer_id: int) -> Optional[models.Consumer]:
    return db.get(models.Consumer, consumer_id)


def get_consumer_by_phone(db: Session, phone: str) -> Optional[models.Consumer]:
    clean_phone = normalize_whatsapp_number(phone)
    return db.query(models.Consumer).filter(models.Consumer.phone == clean_phone).first()


def list_consumers(db: Session) -> List[models.Consumer]:
    return db.query(models.Consumer).order_by(models.Consumer.id).all()


# ---------- Service Request Operations ----------

def create_request(db: Session, data: schemas.ServiceRequestCreate) -> models.ServiceRequest:
    req = models.ServiceRequest(
        consumer_phone=normalize_whatsapp_number(data.consumer_phone),
        skill_requested=data.skill_requested.strip().lower(),
        description=data.description,
        location=data.location.strip().lower(),
    )
    db.add(req)
    db.commit()
    db.refresh(req)
    return req


def get_request(db: Session, request_id: int) -> Optional[models.ServiceRequest]:
    return db.get(models.ServiceRequest, request_id)


def list_requests(db: Session) -> List[models.ServiceRequest]:
    return db.query(models.ServiceRequest).order_by(models.ServiceRequest.id.desc()).all()


def get_consumer_requests(db: Session, consumer_phone: str) -> List[models.ServiceRequest]:
    clean_phone = normalize_whatsapp_number(consumer_phone)
    return db.query(models.ServiceRequest).filter(
        models.ServiceRequest.consumer_phone == clean_phone
    ).order_by(models.ServiceRequest.id.desc()).all()


def find_matches(db: Session, request: models.ServiceRequest, limit: int = 3) -> List[models.Provider]:
    """
    Matching algorithm:
    1. Filter by matching skill and location (case-insensitive)
    2. Exclude offline providers
    3. Sort by:
       - Availability (available_now preferred first)
       - Rating average (descending)
       - Jobs completed count (descending)
    """
    query = db.query(models.Provider).filter(
        models.Provider.skill == request.skill_requested,
        models.Provider.location == request.location,
        models.Provider.availability_status != models.AvailabilityStatus.offline,
    )
    providers = query.all()

    def sort_key(p: models.Provider):
        availability_rank = 0 if p.availability_status == models.AvailabilityStatus.available_now else 1
        return (availability_rank, -p.rating_avg, -p.jobs_completed)

    providers.sort(key=sort_key)
    return providers[:limit]


def try_claim_request(db: Session, request_id: int, provider_id: int) -> bool:
    """
    Atomically assigns provider_id to request_id only if the request is still pending.
    Returns True if this call won the claim, False if someone/something already claimed it.
    Must be a single UPDATE ... WHERE status = 'pending' ... — not a read then a write.
    """
    affected_rows = db.query(models.ServiceRequest).filter(
        models.ServiceRequest.id == request_id,
        models.ServiceRequest.status == models.RequestStatus.pending,
    ).update(
        {
            models.ServiceRequest.status: models.RequestStatus.matched,
            models.ServiceRequest.provider_id: provider_id,
            models.ServiceRequest.matched_at: datetime.utcnow(),
        },
        synchronize_session=False,
    )
    db.commit()
    return affected_rows > 0


def select_provider(
    db: Session, request: models.ServiceRequest, provider: models.Provider
) -> models.ServiceRequest:
    request.provider_id = provider.id
    request.status = models.RequestStatus.matched
    request.matched_at = datetime.utcnow()
    db.commit()
    db.refresh(request)
    return request


def mark_request_paid(db: Session, request: models.ServiceRequest) -> models.ServiceRequest:
    request.payment_status = models.PaymentStatus.paid
    request.paid_at = datetime.utcnow()
    db.commit()
    db.refresh(request)
    return request


def complete_request(
    db: Session, request: models.ServiceRequest, rating: int, comment: Optional[str]
) -> models.ServiceRequest:
    request.status = models.RequestStatus.completed
    request.rating = rating
    request.rating_comment = comment
    request.completed_at = datetime.utcnow()

    provider = request.provider
    if provider is not None:
        total_points = provider.rating_avg * provider.rating_count + rating
        provider.rating_count += 1
        provider.rating_avg = round(total_points / provider.rating_count, 2)
        provider.jobs_completed += 1

    db.commit()
    db.refresh(request)
    return request


def cancel_request(db: Session, request: models.ServiceRequest) -> models.ServiceRequest:
    request.status = models.RequestStatus.cancelled
    # Expire any pending notifications for this request
    db.query(models.RequestNotification).filter(
        models.RequestNotification.request_id == request.id,
        models.RequestNotification.status == models.NotificationStatus.notified,
    ).update(
        {models.RequestNotification.status: models.NotificationStatus.expired},
        synchronize_session=False,
    )
    db.commit()
    db.refresh(request)
    return request


# ---------- Notification & Message Deduplication Operations ----------

def is_message_processed(db: Session, message_sid: str) -> bool:
    """Checks if a Twilio message SID was already recorded."""
    return db.query(models.ProcessedMessage).filter(models.ProcessedMessage.message_sid == message_sid).first() is not None


def record_processed_message(db: Session, message_sid: str) -> models.ProcessedMessage:
    """Records a processed message SID for deduplication."""
    msg = models.ProcessedMessage(message_sid=message_sid)
    db.add(msg)
    try:
        db.commit()
    except Exception:
        db.rollback()
    return msg


def create_notification(db: Session, request_id: int, provider_id: int) -> models.RequestNotification:
    """Creates a notification record pairing a request with a notified provider."""
    notif = models.RequestNotification(
        request_id=request_id,
        provider_id=provider_id,
        status=models.NotificationStatus.notified,
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)
    return notif


def get_notification(db: Session, request_id: int, provider_id: int) -> Optional[models.RequestNotification]:
    return db.query(models.RequestNotification).filter(
        models.RequestNotification.request_id == request_id,
        models.RequestNotification.provider_id == provider_id,
    ).first()


def get_request_notifications(db: Session, request_id: int) -> List[models.RequestNotification]:
    return db.query(models.RequestNotification).filter(
        models.RequestNotification.request_id == request_id
    ).all()


def get_provider_pending_notifications(db: Session, provider_id: int) -> List[models.RequestNotification]:
    """Returns all pending notifications for a provider (status=notified)."""
    return db.query(models.RequestNotification).filter(
        models.RequestNotification.provider_id == provider_id,
        models.RequestNotification.status == models.NotificationStatus.notified,
    ).order_by(models.RequestNotification.id.desc()).all()


def decline_notification(db: Session, request_id: int, provider_id: int) -> bool:
    """Marks a provider's notification as declined."""
    notif = get_notification(db, request_id, provider_id)
    if notif:
        notif.status = models.NotificationStatus.declined
        notif.responded_at = datetime.utcnow()
        db.commit()
        return True
    return False


# ---------- Registration Link Operations ----------

def create_registration_link(db: Session, phone: str, role: str = "provider") -> models.RegistrationLink:
    token = secrets.token_urlsafe(16)
    link = models.RegistrationLink(
        token=token,
        phone=normalize_whatsapp_number(phone),
        role=role.lower(),
        used=False,
    )
    db.add(link)
    db.commit()
    db.refresh(link)
    return link


def get_registration_link(db: Session, token: str) -> Optional[models.RegistrationLink]:
    return db.get(models.RegistrationLink, token)


def mark_registration_link_used(db: Session, link: models.RegistrationLink) -> models.RegistrationLink:
    link.used = True
    db.commit()
    db.refresh(link)
    return link

