import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env file from backend folder
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(dotenv_path=env_path, override=True)

# --- Database ---
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg2://postgres:postgres@localhost:5432/localflow",
)

# --- Twilio Credentials & Settings ---
TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID", "")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN", "")

TWILIO_WHATSAPP_NUMBER = os.getenv("TWILIO_WHATSAPP_NUMBER", "whatsapp:+14155238886")
TWILIO_SMS_NUMBER = os.getenv("TWILIO_SMS_NUMBER", "")
TWILIO_CONTENT_SID = os.getenv("TWILIO_CONTENT_SID", "")
TWILIO_SANDBOX_TO_NUMBER = os.getenv("TWILIO_SANDBOX_TO_NUMBER", "")
