from datetime import datetime
from pydantic import BaseModel, Field


class ChoisirMedecinSchema(BaseModel):
    medecin_id: int

    model_config = {
        "json_schema_extra": {
            "example": {"medecin_id": 2}
        }
    }


class AccepterInvitationSchema(BaseModel):
    code: str = Field(..., min_length=8, max_length=8)

    model_config = {
        "json_schema_extra": {
            "example": {"code": "ABC12345"}
        }
    }


class InvitationSchema(BaseModel):
    id: int
    code: str
    medecin_id: int
    medecin_nom: str
    est_utilise: bool
    expire_le: datetime

    model_config = {"from_attributes": True}


class MedecinSchema(BaseModel):
    id: int
    nom_complet: str
    email: str
    telephone: str | None
    specialite: str | None

    model_config = {"from_attributes": True}