from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel, Field, ConfigDict

from app.models import AvailabilityStatus, VerificationLevel, RequestStatus, PaymentStatus, NotificationStatus


# ---------- Auth / Login Schemas ----------

class PhoneLoginIn(BaseModel):
    phone: str
    password: Optional[str] = None


# ---------- Location Schemas ----------

class ServiceLocationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    state: str = "Karnataka"
    district: str
    area_name: str
    pincode: str


# ---------- Provider Schemas ----------

class ProviderCreate(BaseModel):
    name: str
    phone: str
    skill: str
    location_id: int
    password: Optional[str] = None
    rate_min: Optional[int] = None
    rate_max: Optional[int] = None
    availability_status: AvailabilityStatus = AvailabilityStatus.available_now


class ProviderAvailabilityUpdate(BaseModel):
    availability_status: AvailabilityStatus


class ProviderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    phone: str
    skill: str
    location_id: Optional[int] = None
    location: Optional[ServiceLocationOut] = None
    rate_min: Optional[int] = None
    rate_max: Optional[int] = None
    availability_status: AvailabilityStatus
    verification_level: VerificationLevel
    rating_avg: float
    rating_count: int
    jobs_completed: int
    created_at: datetime


class ProviderUpdate(BaseModel):
    name: Optional[str] = None
    skill: Optional[str] = None
    location_id: Optional[int] = None
    rate_min: Optional[int] = None
    rate_max: Optional[int] = None
    password: Optional[str] = None
    availability_status: Optional[AvailabilityStatus] = None


class ProviderWalletTransaction(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    request_id: int
    consumer_phone: str
    skill: str
    location: Optional[str] = None
    amount: int
    status: str
    paid_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    rating: Optional[int] = None


class ProviderWalletOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    provider_id: int
    provider_name: str
    total_earnings: int
    available_balance: int
    jobs_completed: int
    rating_avg: float
    transactions: List[ProviderWalletTransaction]


class CancelRequestResponse(BaseModel):
    success: bool
    message: str
    request_id: int
    status: RequestStatus


# ---------- Consumer Schemas ----------

class ConsumerCreate(BaseModel):
    name: str
    phone: str
    password: Optional[str] = None


class ConsumerOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    phone: str
    created_at: datetime


# ---------- Service Request Schemas ----------

class ServiceRequestCreate(BaseModel):
    consumer_phone: str
    skill_requested: str
    location_id: int
    description: Optional[str] = None
    preferred_provider_id: Optional[int] = None


class ServiceRequestOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    consumer_phone: str
    skill_requested: str
    description: Optional[str] = None
    location_id: Optional[int] = None
    location: Optional[ServiceLocationOut] = None
    preferred_provider_id: Optional[int] = None
    status: RequestStatus
    payment_status: PaymentStatus = PaymentStatus.unpaid
    paid_at: Optional[datetime] = None
    provider_id: Optional[int] = None
    rating: Optional[int] = None
    rating_comment: Optional[str] = None
    created_at: datetime
    matched_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class ConsumerRequestOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    consumer_phone: str
    skill_requested: str
    description: Optional[str] = None
    location_id: Optional[int] = None
    location: Optional[ServiceLocationOut] = None
    preferred_provider_id: Optional[int] = None
    status: RequestStatus
    payment_status: PaymentStatus
    paid_at: Optional[datetime] = None
    provider_id: Optional[int] = None
    provider: Optional[ProviderOut] = None
    rating: Optional[int] = None
    rating_comment: Optional[str] = None
    created_at: datetime
    matched_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class SelectProviderIn(BaseModel):
    provider_id: int


class CompleteRequestIn(BaseModel):
    rating: int = Field(ge=1, le=5)
    rating_comment: Optional[str] = None


# ---------- Notification Schemas ----------

class NotificationWithRequestOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    request_id: int
    provider_id: int
    status: NotificationStatus
    notified_at: datetime
    responded_at: Optional[datetime] = None
    request: Optional[ServiceRequestOut] = None


class AcceptNotificationResponse(BaseModel):
    success: bool
    message: str
    request_id: int
    consumer_phone: Optional[str] = None
    consumer_name: Optional[str] = None
    location: Optional[str] = None
    description: Optional[str] = None
    rate_min: Optional[int] = None
    rate_max: Optional[int] = None


# ---------- Registration Link Schemas ----------

class RegistrationLinkOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    token: str
    phone: str
    role: str
    created_at: datetime
    used: bool


# ---------- Twilio / WhatsApp Schemas ----------

class WhatsAppMessageIn(BaseModel):
    to_phone: str
    message: str


class WhatsAppMessageResponse(BaseModel):
    status: str
    sid: Optional[str] = None
    error: Optional[str] = None
