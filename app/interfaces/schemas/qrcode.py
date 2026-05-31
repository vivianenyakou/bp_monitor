from datetime import datetime
from pydantic import BaseModel, Field


class GenererQRCodeSchema(BaseModel):
    organisation_id:    int
    medecin_id:         int | None = None
    description:        str | None = None
    expire_dans_jours:  int | None = Field(None, ge=1, le=365)

    model_config = {
        "json_schema_extra": {
            "example": {
                "organisation_id":   1,
                "medecin_id":        2,
                "description":       "QR code salle d'attente",
                "expire_dans_jours": 30,
            }
        }
    }


class QRCodeSchema(BaseModel):
    id:               int
    token:            str
    organisation_id:  int
    organisation_nom: str
    medecin_id:       int | None
    medecin_nom:      str | None
    est_actif:        bool
    expire_le:        datetime | None
    nombre_scans:     int
    description:      str | None
    url:              str

    model_config = {"from_attributes": True}


class QRCodeInfoSchema(BaseModel):
    token:             str
    organisation_id:   int
    organisation_nom:  str
    organisation_code: str
    medecin_id:        int | None
    medecin_nom:       str | None
    est_valide:        bool
    message:           str | None

    model_config = {"from_attributes": True}