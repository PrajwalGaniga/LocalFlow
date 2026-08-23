# LocalFlow Backend

Hyperlocal Service Provider Discovery, Matching & WhatsApp Workflow Engine built with FastAPI, PostgreSQL (SQLAlchemy), and Twilio WhatsApp API.

---

## 1. Setup

### 1.1 Requirements
- Python 3.10+
- PostgreSQL 14+ running locally on port `5432` with database `localflow`

### 1.2 Create Database (if not already created)
In pgAdmin or psql:
```sql
CREATE DATABASE localflow;
```

### 1.3 Python Virtual Environment & Dependencies
```bash
cd backend
python -m venv venv

# Windows PowerShell:
.\venv\Scripts\Activate.ps1

# Linux / Mac:
source venv/bin/activate

# Install dependencies:
pip install -r requirements.txt
```

### 1.4 Environment Variables (`.env`)
The `.env` file is already configured with your PostgreSQL connection and Twilio API keys:
```env
DATABASE_URL=postgresql+psycopg2://postgres:postgres@localhost:5432/localflow
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_API_KEY_SID=SKxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_API_SECRET=your_api_secret_here
TWILIO_WHATSAPP_NUMBER=whatsapp:+14155238886
TWILIO_SANDBOX_TO_NUMBER=whatsapp:+91xxxxxxxxxx
```

---

## 2. Running the Server

```bash
uvicorn app.main:app --reload --port 8000
```

- **Interactive Swagger API Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **Health Check**: [http://localhost:8000/health](http://localhost:8000/health)

---

## 3. End-to-End API Flow

### Step 1: Register Service Providers
```bash
# Register an Electrician
curl -X POST http://localhost:8000/providers/ -H "Content-Type: application/json" -d '{
  "name": "Ramesh Kumar",
  "phone": "+919876543210",
  "skill": "electrician",
  "location": "koramangala",
  "rate_min": 300,
  "rate_max": 600,
  "availability_status": "available_now"
}'

# Register a Plumber
curl -X POST http://localhost:8000/providers/ -H "Content-Type: application/json" -d '{
  "name": "Suresh Patel",
  "phone": "+919876543211",
  "skill": "plumber",
  "location": "koramangala",
  "rate_min": 250,
  "rate_max": 500,
  "availability_status": "available_now"
}'
```

### Step 2: Consumer Creates a Service Request
```bash
curl -X POST http://localhost:8000/requests/ -H "Content-Type: application/json" -d '{
  "consumer_phone": "+919999988888",
  "skill_requested": "electrician",
  "description": "Ceiling fan sparking and stopped working",
  "location": "koramangala"
}'
```

### Step 3: Get Ranked Matches for the Request
```bash
curl http://localhost:8000/requests/1/matches
```

### Step 4: Consumer Selects a Provider
```bash
curl -X POST http://localhost:8000/requests/1/select -H "Content-Type: application/json" -d '{
  "provider_id": 1
}'
```

### Step 5: Mark Job Complete and Rate Provider (1 to 5)
```bash
curl -X POST http://localhost:8000/requests/1/complete -H "Content-Type: application/json" -d '{
  "rating": 5,
  "rating_comment": "Excellent work, arrived in 15 mins and fixed the fan safely!"
}'
```

### Step 6: Verify Updated Provider Reputation
```bash
curl http://localhost:8000/providers/1
```

---

## 4. WhatsApp Integration (Twilio)

### Test Outbound WhatsApp Message
```bash
curl -X POST http://localhost:8000/whatsapp/send -H "Content-Type: application/json" -d '{
  "to_phone": "+17372212163",
  "message": "Hello from LocalFlow! Your service request has been received."
}'
```

### Twilio Webhook (Inbound WhatsApp Bot)
Endpoint: `POST /whatsapp/webhook`
Handles user commands:
- `NEED electrician in koramangala` -> Automatically creates a request & ranks providers
- `ACCEPT 1` -> Provider accepts job request #1
- `STATUS` -> Consumer checks status of their recent requests
