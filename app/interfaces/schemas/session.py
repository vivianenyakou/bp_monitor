from datetime import date, datetime
from pydantic import BaseModel, Field


class SessionSchema(BaseModel):
    session_id:        str
    patient_id:        int
    date_jour1:        date
    date_jour2:        date
    date_jour3:        date
    mesures_j1_matin:  int
    mesures_j1_soir:   int
    mesures_j2_matin:  int
    mesures_j2_soir:   int
    mesures_j3_matin:  int
    mesures_j3_soir:   int
    jour1_complete:    bool
    jour2_complete:    bool
    jour3_complete:    bool
    protocole_termine: bool
    creneau_actuel:    str
    message_creneau:   str
    jour_actuel:       int
    mesures_restantes: int
    medicament_pris:   bool | None
    heure_soir:        int | None = None
    demarre_le:        datetime
    termine_le:        datetime | None

    model_config = {"from_attributes": True}


class CreerMesureSessionSchema(BaseModel):
    patient_id:      int
    systolique:      int = Field(..., ge=60,  le=250)
    diastolique:     int = Field(..., ge=40,  le=150)
    pouls:           int | None = Field(None, ge=30, le=220)
    notes:           str | None = None
    medicament_pris: bool | None = None

    model_config = {
        "json_schema_extra": {
            "example": {
                "patient_id":  1,
                "systolique":  128,
                "diastolique": 82,
                "pouls":       72,
            }
        }
    }


class MedicamentSchema(BaseModel):
    patient_id:      int
    session_id:      str
    medicament_pris: bool