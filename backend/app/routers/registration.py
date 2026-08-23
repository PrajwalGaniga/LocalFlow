import logging
from typing import Optional
from fastapi import APIRouter, Depends, Form, HTTPException, Request, status
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session

from app import crud, models, schemas
from app.database import get_db

logger = logging.getLogger("registration_router")
router = APIRouter(tags=["registration"])


def _render_page(title: str, content: str) -> str:
    """Helper to wrap HTML content in a sleek, ultra-fast, mobile-first responsive layout."""
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>{title} — LocalFlow</title>
    <style>
        :root {{
            --primary: #10b981;
            --primary-dark: #059669;
            --primary-light: #ecfdf5;
            --bg: #0f172a;
            --card-bg: #1e293b;
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --border: #334155;
            --input-bg: #0f172a;
            --focus-ring: rgba(16, 185, 129, 0.4);
            --error-bg: #451a1a;
            --error-border: #ef4444;
        }}
        * {{
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            -webkit-tap-highlight-color: transparent;
        }}
        body {{
            background-color: var(--bg);
            color: var(--text-main);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            padding: 20px 16px;
        }}
        .container {{
            width: 100%;
            max-width: 440px;
            background: var(--card-bg);
            border: 1px solid var(--border);
            border-radius: 20px;
            padding: 28px 24px;
            box-shadow: 0 20px 35px -10px rgba(0, 0, 0, 0.5);
        }}
        .brand-header {{
            text-align: center;
            margin-bottom: 24px;
        }}
        .brand-badge {{
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: var(--primary-light);
            color: var(--primary-dark);
            font-size: 12px;
            font-weight: 700;
            padding: 4px 12px;
            border-radius: 9999px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 10px;
        }}
        .brand-title {{
            font-size: 24px;
            font-weight: 800;
            color: var(--text-main);
            letter-spacing: -0.5px;
        }}
        .brand-subtitle {{
            font-size: 14px;
            color: var(--text-muted);
            margin-top: 4px;
        }}
        .form-group {{
            margin-bottom: 18px;
        }}
        label {{
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: #cbd5e1;
            margin-bottom: 6px;
        }}
        input, select {{
            width: 100%;
            height: 48px;
            padding: 0 14px;
            background-color: var(--input-bg);
            border: 1px solid var(--border);
            border-radius: 12px;
            color: var(--text-main);
            font-size: 15px;
            outline: none;
            transition: border-color 0.2s, box-shadow 0.2s;
        }}
        input:focus, select:focus {{
            border-color: var(--primary);
            box-shadow: 0 0 0 3px var(--focus-ring);
        }}
        input[readonly], input:disabled {{
            background-color: rgba(15, 23, 42, 0.6);
            color: var(--text-muted);
            cursor: not-allowed;
        }}
        .grid-2 {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
        }}
        .btn {{
            width: 100%;
            height: 50px;
            background: var(--primary);
            color: #064e3b;
            font-size: 16px;
            font-weight: 700;
            border: none;
            border-radius: 12px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: background-color 0.2s, transform 0.1s;
            margin-top: 24px;
        }}
        .btn:hover {{
            background: var(--primary-dark);
            color: #ffffff;
        }}
        .btn:active {{
            transform: scale(0.98);
        }}
        .card-message {{
            text-align: center;
            padding: 16px 0;
        }}
        .icon-circle {{
            width: 64px;
            height: 64px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 28px;
            margin: 0 auto 16px;
        }}
        .icon-success {{
            background: rgba(16, 185, 129, 0.2);
            color: var(--primary);
            border: 2px solid var(--primary);
        }}
        .icon-error {{
            background: var(--error-bg);
            color: var(--error-border);
            border: 2px solid var(--error-border);
        }}
        .footer {{
            margin-top: 20px;
            text-align: center;
            font-size: 12px;
            color: var(--text-muted);
        }}
    </style>
</head>
<body>
    <div class="container">
        {content}
    </div>
    <div class="footer">
        ⚡ Powered by <strong>LocalFlow</strong> Hyperlocal Engine
    </div>
</body>
</html>"""


@router.get("/register", response_class=HTMLResponse)
def get_registration_page(token: str, db: Session = Depends(get_db)):
    """Serves the fast-loading, mobile-friendly fallback registration HTML form."""
    if not token:
        html = _render_page(
            "Missing Token",
            """
            <div class="card-message">
                <div class="icon-circle icon-error">⚠️</div>
                <h2 style="margin-bottom: 8px;">Invalid Link</h2>
                <p style="color: var(--text-muted); font-size: 14px;">No registration token provided. Please request a new registration link via WhatsApp by texting <strong>REGISTER</strong>.</p>
            </div>
            """
        )
        return HTMLResponse(content=html, status_code=400)

    link = crud.get_registration_link(db, token)
    if not link:
        html = _render_page(
            "Link Not Found",
            """
            <div class="card-message">
                <div class="icon-circle icon-error">❌</div>
                <h2 style="margin-bottom: 8px;">Link Not Found</h2>
                <p style="color: var(--text-muted); font-size: 14px;">This registration link does not exist. Text <strong>REGISTER</strong> on WhatsApp to get a new one.</p>
            </div>
            """
        )
        return HTMLResponse(content=html, status_code=404)

    if link.used:
        html = _render_page(
            "Link Already Used",
            """
            <div class="card-message">
                <div class="icon-circle icon-success">✅</div>
                <h2 style="margin-bottom: 8px;">Already Registered!</h2>
                <p style="color: var(--text-muted); font-size: 14px;">This phone number (<strong>+91{link.phone}</strong>) is already registered. You are all set to send and receive jobs on WhatsApp.</p>
            </div>
            """.replace("{link.phone}", link.phone)
        )
        return HTMLResponse(content=html, status_code=200)

    # Fetch distinct skills & locations for dropdowns
    skills = crud.get_distinct_skills(db)
    locations = crud.get_locations(db)

    is_provider = (link.role.lower() == "provider")
    badge_text = "Service Provider Registration" if is_provider else "Customer Registration"
    title_text = "Join as Provider" if is_provider else "Create Account"
    subtitle_text = "Start receiving customer leads directly on WhatsApp" if is_provider else "Start finding verified local pros"

    skill_options = "".join([f'<option value="{s}">{s.title()}</option>' for s in skills])
    location_options = "".join([f'<option value="{l.id}">{l.area_name} ({l.district})</option>' for l in locations])

    provider_fields = f"""
        <div class="form-group">
            <label for="skill">Primary Skill / Service *</label>
            <select id="skill" name="skill" required>
                {skill_options}
            </select>
        </div>
        <div class="form-group">
            <label for="location">Your Primary Locality *</label>
            <select id="location" name="location" required>
                {location_options}
            </select>
        </div>
        <div class="grid-2">
            <div class="form-group">
                <label for="rate_min">Min Rate (₹)</label>
                <input type="number" id="rate_min" name="rate_min" placeholder="e.g. 200" value="250">
            </div>
            <div class="form-group">
                <label for="rate_max">Max Rate (₹)</label>
                <input type="number" id="rate_max" name="rate_max" placeholder="e.g. 600" value="500">
            </div>
        </div>
    """ if is_provider else ""

    content = f"""
    <div class="brand-header">
        <div class="brand-badge">{badge_text}</div>
        <h1 class="brand-title">{title_text}</h1>
        <p class="brand-subtitle">{subtitle_text}</p>
    </div>
    <form action="/register/submit" method="POST">
        <input type="hidden" name="token" value="{link.token}">
        <input type="hidden" name="role" value="{link.role}">
        <input type="hidden" name="phone" value="{link.phone}">

        <div class="form-group">
            <label for="phone_display">WhatsApp Phone Number</label>
            <input type="text" id="phone_display" value="+91 {link.phone}" disabled>
        </div>

        <div class="form-group">
            <label for="name">Full Name *</label>
            <input type="text" id="name" name="name" placeholder="e.g. Ramesh Kumar" required autofocus>
        </div>

        {provider_fields}

        <div class="form-group">
            <label for="password">App Password (Optional)</label>
            <input type="password" id="password" name="password" placeholder="Create a password for the mobile app">
        </div>

        <button type="submit" class="btn">
            <span>Complete Registration</span> →
        </button>
    </form>
    """
    return HTMLResponse(content=_render_page(title_text, content))


@router.post("/register/submit", response_class=HTMLResponse)
def submit_registration(
    token: str = Form(...),
    role: str = Form(...),
    phone: str = Form(...),
    name: str = Form(...),
    skill: Optional[str] = Form(None),
    location: Optional[str] = Form(None),
    rate_min: Optional[int] = Form(None),
    rate_max: Optional[int] = Form(None),
    password: Optional[str] = Form(None),
    db: Session = Depends(get_db),
):
    """Processes fallback registration form submission."""
    link = crud.get_registration_link(db, token)
    if not link or link.used:
        html = _render_page(
            "Error",
            """
            <div class="card-message">
                <div class="icon-circle icon-error">⚠️</div>
                <h2 style="margin-bottom: 8px;">Link Expired</h2>
                <p style="color: var(--text-muted); font-size: 14px;">This registration link has already been used or expired.</p>
            </div>
            """
        )
        return HTMLResponse(content=html, status_code=400)

    clean_role = role.lower().strip()
    if clean_role == "provider":
        # Determine location_id
        loc_id = 1
        if location:
            if location.isdigit():
                loc_id = int(location)
            else:
                found_loc = crud.get_location_by_area(db, location)
                if found_loc:
                    loc_id = found_loc.id

        # Create Provider
        provider_data = schemas.ProviderCreate(
            name=name.strip(),
            phone=phone.strip(),
            skill=skill.strip().lower() if skill else "electrician",
            location_id=loc_id,
            rate_min=rate_min,
            rate_max=rate_max,
            password=password.strip() if password else None,
        )
        existing = crud.get_provider_by_phone(db, phone)
        if not existing:
            crud.create_provider(db, provider_data)
        success_msg = "You are now registered as a Service Provider. Whenever customers near your area need your services, you'll receive job offers directly on WhatsApp!"
    else:
        # Create Consumer
        consumer_data = schemas.ConsumerCreate(
            name=name.strip(),
            phone=phone.strip(),
            password=password.strip() if password else None,
        )
        existing = crud.get_consumer_by_phone(db, phone)
        if not existing:
            crud.create_consumer(db, consumer_data)
        success_msg = "You are now registered with LocalFlow! You can request services on WhatsApp anytime or log into the mobile app."

    # Mark token used
    crud.mark_registration_link_used(db, link)

    html = _render_page(
        "Registration Complete",
        f"""
        <div class="card-message">
            <div class="icon-circle icon-success">🎉</div>
            <h2 style="margin-bottom: 8px;">You're Registered!</h2>
            <p style="color: #cbd5e1; font-size: 15px; line-height: 1.5; margin-bottom: 20px;">
                Welcome, <strong>{name.strip()}</strong>! {success_msg}
            </p>
            <div style="background: rgba(15, 23, 42, 0.6); padding: 14px; border-radius: 12px; font-size: 13px; color: var(--text-muted); text-align: left;">
                <p>📱 <strong>Phone:</strong> +91 {phone.strip()}</p>
                <p style="margin-top: 4px;">🛠 <strong>Role:</strong> {clean_role.title()}</p>
            </div>
        </div>
        """
    )
    return HTMLResponse(content=html, status_code=200)
