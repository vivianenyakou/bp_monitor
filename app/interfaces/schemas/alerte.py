from datetime import datetime

from pydantic import BaseModel

from app.domain.enums.bp_category import NiveauAlerte, StatutAlerte


class AlerteSchema(BaseModel):
    """Données d'une alerte."""
    id: int
    patient_id: int
    medecin_id: int | None
    systolique: int
    diastolique: int
    niveau: NiveauAlerte
    statut: StatutAlerte
    message: str
    declenchee_le: datetime
    acquittee_le: datetime | None
    acquittee_par: str | None
    patient_nom_complet: str | None = None
    patient_telephone: str | None = None

    model_config = {"from_attributes": True}


class AcquitterAlerteSchema(BaseModel):
    """Données pour acquitter une alerte."""
    acquittee_par: str

    model_config = {
        "json_schema_extra": {
            "example": {
                "acquittee_par": "Dr Kofi Ama"
            }
        }
    }