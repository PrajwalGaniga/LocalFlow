from datetime import datetime
from zoneinfo import ZoneInfo

# Indian Standard Time (IST)
IST = ZoneInfo("Asia/Kolkata")


def now_ist() -> datetime:
    """Returns the current datetime in Indian Standard Time (IST) with timezone awareness."""
    return datetime.now(IST)
