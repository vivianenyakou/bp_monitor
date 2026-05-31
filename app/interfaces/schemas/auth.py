from pydantic import BaseModel, EmailStr, Field

from app.domain.enums.role_enum import RoleUtilisateur


class RegisterSchema(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=72)
    first_name: str | None = None
    last_name: str | None = None
    phone_number: str | None = None
    organisation_code: str | None = None
    qr_code_token: str | None = None

    model_config = {
        "json_schema_extra": {
            "example": {
                "password": "motdepasse123",
                "first_name": "Ama",
                "last_name": "Koffi",
                "phone_number": "",
                "qr_code_token": "ZZZaaaAAA111222333",
            }
        }
    }

class LoginSchema(BaseModel):
    identifiant: str = Field(
        ...,
        description="Email, numéro de téléphone ou nom d'utilisateur"
    )
    password: str

    model_config = {
        "json_schema_extra": {
            "example": {
                "identifiant": "ama.koffi",
                "password": "motdepasse123",
            }
        }
    }

class TokenSchema(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UtilisateurConnecteSchema(BaseModel):
    id: int
    username: str | None
    email: str | None
    first_name: str | None
    last_name: str | None
    roles: list[str]
    permissions: list[str]

    model_config = {"from_attributes": True}

class CreerUtilisateurSchema(BaseModel):
    username: str | None = Field(None, min_length=3, max_length=50)
    email: EmailStr | None = None
    password: str = Field(..., min_length=6, max_length=72)
    role: RoleUtilisateur = RoleUtilisateur.PATIENT
    first_name: str | None = None
    last_name: str | None = None
    phone_number: str = Field(..., min_length=1)
    organisation_id: int | None = None
    specialite: str | None = None

    model_config = {
        "json_schema_extra": {
            "example": {
                "username": "dr.ama",
                "email": "dr.ama@hopital.tg",
                "password": "secret123",
                "role": "medecin",
                "first_name": "Ama",
                "last_name": "Sow",
                "phone_number": "+22898295689",
                "organisation_id": 1,
            }
        }
    }
