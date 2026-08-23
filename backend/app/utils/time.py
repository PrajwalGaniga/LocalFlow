from datetime import datetime, timezone, timedelta

try:
    from zoneinfo import ZoneInfo
    IST = ZoneInfo("Asia/Kolkata")
except Exception:
    # Standard UTC+5:30 offset for Indian Standard Time (Windows fallback without tzdata)
    IST = timezone(timedelta(hours=5, minutes=30), name="IST")


def now_ist() -> datetime:
    """Returns the current datetime in Indian Standard Time (IST) with timezone awareness."""
    return datetime.now(IST)
