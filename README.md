# ⚡ LocalFlow

**LocalFlow** is a hyperlocal, on-demand service matching and workflow automation platform connecting local service professionals (electricians, plumbers, carpenters, tutors, painters, tailors) with nearby consumers through a modern **Flutter Mobile App** and an automated **Twilio WhatsApp Webhook** layer.

---

## 📱 Features

### 🛠 For Service Providers
* **Instant Lead Alerts:** Live incoming request feeds in your locality with one-tap *Accept* & *Decline*.
* **Atomic Claiming:** Race-safe job acceptance ensuring only one provider wins the lead.
* **Multi-Skill Profile Switcher:** Register multiple service skills (e.g. Electrician + Plumber) under a single phone number and switch profiles in one tap.
* **Wallet & Earnings Ledger:** Real-time earnings breakdown, available balance, completed jobs metrics, and withdrawal stub.
* **Dynamic UPI Payment QR:** Generates instant UPI QR codes (`upi://pay?...`) with custom amount entry.
* **Profile Management:** Edit service details, localities, standard rates, and live availability status (*Available Now*, *Available Later*, *Busy*, *Offline*).

### 👥 For Customers
* **One-Tap Requests:** Request verified local pros by skill, locality, and optional issue description.
* **Live Status Tracking:** Real-time progression through *Searching*, *Matched*, *Paid*, and *Completed*.
* **UPI Payment Settlement:** Scan pro's UPI QR code with GPay/PhonePe/Paytm with direct "Done" confirmation.
* **Ratings & Reviews:** 1–5 star reviews and feedback after work is finished.
* **Instant Request Cancellation:** Cancel active or pending requests directly from the app or via WhatsApp.

### 💬 WhatsApp Integration (No App Needed)
* **Consumers:** Text requests in natural language (e.g. *"Need an electrician in Koramangala"*), complete via `DONE <id> [rating]`, or cancel via `CANCEL <id>`.
* **Providers:** Receive instant job leads via WhatsApp, claim with `ACCEPT <id>`, or decline with `DECLINE <id>`.
* **Fallback Web Onboarding:** Non-app users texting `REGISTER` receive an instant mobile-responsive HTML onboarding form.

---

## 🏗 Architecture

```
localFlow/
├── backend/                  # FastAPI + PostgreSQL + SQLAlchemy Backend
│   ├── app/
│   │   ├── routers/          # REST endpoints (providers, consumers, requests, webhooks, registration)
│   │   ├── services/         # Shared atomic matching, Twilio WhatsApp client, templates
│   │   ├── models.py         # SQLAlchemy ORM models (Provider, Consumer, ServiceRequest, etc.)
│   │   ├── schemas.py        # Pydantic validation schemas
│   │   └── crud.py           # Database CRUD & business logic
│   ├── migrate_db.py         # Idempotent DB migration script
│   └── test_app_flow.py      # Automated E2E test suite (8 test suites)
│
└── mobile/                   # Cross-platform Flutter Mobile Application
    ├── assets/images/        # App logos and visual assets
    ├── lib/
    │   ├── config/           # Dynamic API Base URL & ngrok configuration
    │   ├── models/           # Dart data models (Provider, Consumer, Request, Wallet)
    │   ├── services/         # ApiService & SessionManager
    │   ├── theme/            # Design system (Coral/Orange & Emerald/Green)
    │   └── screens/          # Provider & Consumer screens (Wallet, Leads, Jobs, Profile, QR)
    └── test/                 # Flutter widget test suite
```

---

## 🚀 Getting Started

### 1. Prerequisites
* Python 3.10+
* Flutter SDK 3.x+
* PostgreSQL database

### 2. Backend Setup
```bash
cd backend
python -m venv venv
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt

# Run migrations and seed sample providers
python migrate_db.py
python seed_providers.py

# Start FastAPI server
uvicorn app.main:app --reload
```

### 3. Run Automated Tests
```bash
cd backend
python test_app_flow.py
```

### 4. Mobile App Setup
```bash
cd mobile
flutter pub get
flutter run
# Or for Web:
flutter run -d chrome
```

---

## 📄 License
MIT License.
