from pydantic import BaseModel, EmailStr, Field


class CreerOrganisationSchema(BaseModel):
    nom: str = Field(..., min_length=2, max_length=100)
    code: str = Field(..., min_length=2, max_length=20)
    adresse: str | None = None
    telephone: str | None = None
    nif_structure: str | None = None
    raison_sociale: str | None = None
    email: EmailStr | None = None

    model_config = {
        "json_schema_extra": {
            "example": {
                "nom": "Hôpital de Lomé",
                "code": "HOPITAL_LOME",
                "adresse": "Boulevard du 13 Janvier, Lomé",
                "telephone": "+228 22 00 00 00",
                "nif_structure": "NIF-123456",
                "raison_sociale": "Hôpital de Lomé S.A.",
                "email": "contact@hopital-lome.tg",
            }
        }
    }


class OrganisationSchema(BaseModel):
    id: int
    nom: str
    code: str
    adresse: str | None
    telephone: str | None
    email: str | None
    est_actif: bool
    nif_structure: str | None
    raison_sociale: str | None

    model_config = {"from_attributes": True}