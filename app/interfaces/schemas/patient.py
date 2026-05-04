from datetime import date

from pydantic import BaseModel

from app.domain.enums.blood_group import BloodGroup


class PatientSchema(BaseModel):
    """Profil médical d'un patient."""
    id: int
    user_id: int
    gender: str | None
    birth_date: date | None
    blood_group: BloodGroup | None
    address: str | None
    emergency_contact: str | None

    model_config = {"from_attributes": True}


class MettreAJourPatientSchema(BaseModel):
    """Données pour mettre à jour le profil patient."""
    gender: str | None = None
    birth_date: date | None = None
    blood_group: BloodGroup | None = None
    address: str | None = None
    emergency_contact: str | None = None
    seuil_systolique_critique: int | None = None
    seuil_diastolique_critique: int | None = None

    model_config = {
        "json_schema_extra": {
            "example": {
                "gender": "M",
                "birth_date": "1985-06-15",
                "blood_group": "A+",
                "address": "Lomé, Togo",
                "emergency_contact": "+228 90 00 00 00",
            }
        }
    }