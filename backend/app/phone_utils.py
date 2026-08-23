import re


def normalize_whatsapp_number(raw: str) -> str:
    """
    Normalizes inbound WhatsApp phone numbers to a bare 10-digit Indian phone number.
    
    Examples:
    - 'whatsapp:+919110687983' -> '9110687983'
    - '+91 63622 80470'        -> '6362280470'
    - '9110687983'             -> '9110687983'
    - '+919110687983'          -> '9110687983'
    """
    if not raw:
        return ""
    
    # Remove 'whatsapp:' prefix
    clean = raw.replace("whatsapp:", "").strip()
    
    # Remove any non-digit characters except leading plus if any
    digits = re.sub(r"\D", "", clean)
    
    # If starts with India country code 91 and has 12 digits, strip 91
    if digits.startswith("91") and len(digits) == 12:
        return digits[2:]
    
    # If it has 10 digits, return directly
    if len(digits) == 10:
        return digits
    
    # If larger, take the last 10 digits
    if len(digits) > 10:
        return digits[-10:]
        
    return digits
