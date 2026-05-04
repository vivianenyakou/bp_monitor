from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from app.domain.enums.bp_category import CategorieTA, PeriodeMesure


class CreerMesureSchema(BaseModel):
    """Données reçues pour créer une mesure."""
    patient_id: int
    systolique: int = Field(..., ge=60, le=250, description="Pression systolique (mmHg)")
    diastolique: int = Field(..., ge=40, le=150, description="Pression diastolique (mmHg)")
    pouls: int | None = Field(None, ge=30, le=220, description="Pouls (bpm)")
    periode: PeriodeMesure
    jour: int = Field(..., ge=1, le=3, description="Jour de la session (1, 2 ou 3)")
    numero_mesure: int = Field(..., ge=1, le=3, description="Numéro dans la période (1, 2 ou 3)")
    notes: str | None = Field(None, max_length=500)
    session_id: str | None = None

    @field_validator("systolique", "diastolique")
    @classmethod
    def valider_tension(cls, v: int) -> int:
        return v

    model_config = {
        "json_schema_extra": {
            "example": {
                "patient_id": 1,
                "systolique": 128,
                "diastolique": 82,
                "pouls": 72,
                "periode": "matin",
                "jour": 1,
                "numero_mesure": 1,
                "notes": "Après repos de 5 minutes",
            }
        }
    }


class MesureSchema(BaseModel):
    """Données retournées d'une mesure."""
    id: int
    patient_id: int
    systolique: int
    diastolique: int
    pouls: int | None
    periode: PeriodeMesure
    jour: int
    numero_mesure: int
    categorie: CategorieTA
    session_id: str
    prise_le: datetime
    notes: str | None

    model_config = {"from_attributes": True}


class MoyenneSchema(BaseModel):
    """Moyenne de tension pour une période."""
    systolique: int
    diastolique: int
    pouls: int | None
    categorie: CategorieTA
    nombre_mesures: int


class ResumeSessionSchema(BaseModel):
    """Résumé complet d'une session de 3 jours."""
    session_id: str
    patient_id: int
    nombre_mesures: int
    session_complete: bool
    progression: str
    moyenne_globale: MoyenneSchema | None
    moyenne_matin: MoyenneSchema | None
    moyenne_soir: MoyenneSchema | None
    moyennes_par_jour: dict[int, MoyenneSchema]

    model_config = {"from_attributes": True}