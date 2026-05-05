from pydantic import BaseModel, EmailStr, Field


class RegisterSchema(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=72)
    first_name: str | None = None
    last_name: str | None = None
    phone_number: str | None = None
    organisation_code: str | None = Field(
        None,
        description="Code de l'organisation (clinique/hôpital)"
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "username": "ama.koffi",
                "email": "ama.koffi@email.com",
                "password": "motdepasse123",
                "first_name": "Ama",
                "last_name": "Koffi",
                "phone_number": "+22898295689",
                "organisation_code": "HOPITAL_LOME"
            }
        }
    }


# class LoginSchema(BaseModel):
#     email: EmailStr
#     password: str = Field(..., max_length=72)

#     model_config = {
#         "json_schema_extra": {
#             "example": {
#                 "email": "ama.koffi@bpmonitor.com",
#                 "password": "secret",
#             }
#         }
#     }
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
    username: str
    email: str
    first_name: str | None
    last_name: str | None
    roles: list[str]
    permissions: list[str]

    model_config = {"from_attributes": True}