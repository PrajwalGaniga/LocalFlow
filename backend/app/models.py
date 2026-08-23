import enum
from datetime import datetime

from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    DateTime,
    Enum,
    ForeignKey,
    Text,
    Boolean,
)
from sqlalchemy.orm import relationship

from app.database import Base


class AvailabilityStatus(str, enum.Enum):
    available_now = "available_now"
    available_later = "available_later"
    busy = "busy"
    offline = "offline"


class VerificationLevel(str, enum.Enum):
    registered = "registered"
    identity_verified = "identity_verified"
    skill_verified = "skill_verified"
    trusted = "trusted"


class RequestStatus(str, enum.Enum):
    pending = "pending"      # consumer asked, no provider chosen yet
    matched = "matched"      # provider selected, job in progress
    completed = "completed"  # job done, rated
    cancelled = "cancelled"


class PaymentStatus(str, enum.Enum):
    unpaid = "unpaid"
    paid = "paid"


class NotificationStatus(str, enum.Enum):
    notified = "notified"
    accepted = "accepted"
    declined = "declined"
    expired = "expired"


class Provider(Base):
    __tablename__ = "providers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(120), nullable=False)
    phone = Column(String(20), unique=False, nullable=False, index=True)  # Multiple profiles allowed per phone
    password = Column(String(120), nullable=True)  # Unhashed password as requested
    skill = Column(String(80), nullable=False, index=True)  # e.g. "electrician", "plumber"
    location = Column(String(120), nullable=False, index=True)  # locality / neighborhood

    rate_min = Column(Integer, nullable=True)
    rate_max = Column(Integer, nullable=True)

    availability_status = Column(
        Enum(AvailabilityStatus), nullable=False, default=AvailabilityStatus.available_now
    )
    verification_level = Column(
        Enum(VerificationLevel), nullable=False, default=VerificationLevel.registered
    )

    rating_avg = Column(Float, nullable=False, default=0.0)
    rating_count = Column(Integer, nullable=False, default=0)
    jobs_completed = Column(Integer, nullable=False, default=0)

    created_at = Column(DateTime, default=datetime.utcnow)

    requests = relationship("ServiceRequest", back_populates="provider")
    notifications = relationship("RequestNotification", back_populates="provider", cascade="all, delete-orphan")


class Consumer(Base):
    __tablename__ = "consumers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(120), nullable=False)
    phone = Column(String(20), unique=True, nullable=False, index=True)
    password = Column(String(120), nullable=True)  # Unhashed password as requested
    created_at = Column(DateTime, default=datetime.utcnow)


class ServiceRequest(Base):
    __tablename__ = "service_requests"

    id = Column(Integer, primary_key=True, index=True)
    consumer_phone = Column(String(20), nullable=False, index=True)  # Bare 10-digit phone
    skill_requested = Column(String(80), nullable=False, index=True)
    description = Column(Text, nullable=True)
    location = Column(String(120), nullable=False, index=True)

    status = Column(Enum(RequestStatus), nullable=False, default=RequestStatus.pending)
    payment_status = Column(Enum(PaymentStatus), nullable=False, default=PaymentStatus.unpaid)
    paid_at = Column(DateTime, nullable=True)

    provider_id = Column(Integer, ForeignKey("providers.id"), nullable=True)
    provider = relationship("Provider", back_populates="requests")

    rating = Column(Integer, nullable=True)          # 1-5, set on completion
    rating_comment = Column(Text, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    matched_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)

    notifications = relationship("RequestNotification", back_populates="request", cascade="all, delete-orphan")


class RequestNotification(Base):
    __tablename__ = "request_notifications"

    id = Column(Integer, primary_key=True, index=True)
    request_id = Column(Integer, ForeignKey("service_requests.id"), nullable=False, index=True)
    provider_id = Column(Integer, ForeignKey("providers.id"), nullable=False, index=True)
    status = Column(Enum(NotificationStatus), nullable=False, default=NotificationStatus.notified)
    notified_at = Column(DateTime, default=datetime.utcnow)
    responded_at = Column(DateTime, nullable=True)

    request = relationship("ServiceRequest", back_populates="notifications")
    provider = relationship("Provider", back_populates="notifications")


class RegistrationLink(Base):
    __tablename__ = "registration_links"

    token = Column(String(64), primary_key=True, index=True)
    phone = Column(String(20), nullable=False, index=True)
    role = Column(String(20), nullable=False)  # 'provider' or 'consumer'
    created_at = Column(DateTime, default=datetime.utcnow)
    used = Column(Boolean, default=False)


class ProcessedMessage(Base):
    __tablename__ = "processed_messages"

    message_sid = Column(String(64), primary_key=True, index=True)
    processed_at = Column(DateTime, default=datetime.utcnow)

