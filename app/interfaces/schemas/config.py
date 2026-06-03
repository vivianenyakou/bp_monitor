from pydantic import BaseModel, Field


class ConfigSchema(BaseModel):
    cle:         str
    valeur:      str
    description: str

    model_config = {"from_attributes": True}


class MettreAJourConfigSchema(BaseModel):
    valeur: str = Field(..., description="Nouvelle valeur")

    model_config = {
        "json_schema_extra": {
            "example": {
                "valeur": "8"
            }
        }
    }

class BulkConfigSchema(BaseModel):
    """Mettre à jour plusieurs configs en une seule requête."""
    configs: dict[str, str]

    model_config = {
        "json_schema_extra": {
            "example": {
                "configs": {
                    "creneau_matin_debut":  "0",
                    "creneau_matin_fin":    "9",
                    "creneau_soir_debut":   "18",
                    "creneau_soir_fin":     "22",
                    "debug_heure_simulee":  "14",
                    "seuil_sys_critique":   "180",
                    "qrcode_expiration_jours": "30",
                }
            }
        }
    }