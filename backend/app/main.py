from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.routers import providers, requests, consumers, registration, twilio_webhook, whatsapp_webhook, locations
from migrate_db import run_migrations

# Create database tables and execute column migrations automatically on startup
run_migrations()

app = FastAPI(
    title="LocalFlow API",
    description="Hyperlocal Service Provider Discovery, Matching & WhatsApp Workflow Engine",
    version="0.1.0-mvp",
)

# Enable CORS for local frontend development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(locations.router)
app.include_router(providers.router)
app.include_router(requests.router)
app.include_router(consumers.router)
app.include_router(registration.router)
app.include_router(twilio_webhook.router)
app.include_router(whatsapp_webhook.router)


@app.get("/")
def root():
    return {
        "message": "LocalFlow Backend is running",
        "docs_url": "/docs",
        "health_url": "/health",
        "webhook_url": "/webhooks/twilio/whatsapp",
    }


@app.get("/health")
def health():
    return {"status": "ok"}
