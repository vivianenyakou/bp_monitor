def normaliser_telephone_togo(telephone: str | None) -> str | None:
    if not telephone:
        return None

    digits = "".join(char for char in telephone.strip() if char.isdigit())
    if not digits:
        return None

    country_digits = "228"
    if digits.startswith(f"00{country_digits}"):
        digits = digits[len(country_digits) + 2:]
    elif digits.startswith(country_digits) and len(digits) > 8:
        digits = digits[len(country_digits):]
    elif digits.startswith("0") and len(digits) > 8:
        digits = digits.lstrip("0")

    if not digits:
        return None
    return f"+{country_digits}{digits}"
