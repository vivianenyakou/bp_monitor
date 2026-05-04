from dataclasses import dataclass
from datetime import date

from app.domain.enums.blood_group import BloodGroup


@dataclass
class PatientDTO:
    """Profil médical d'un patient."""
    id: int
    user_id: int
    nom_complet: str
    email: str
    gender: str | None
    birth_date: date | None
    blood_group: BloodGroup | None
    medecin_id: int | None