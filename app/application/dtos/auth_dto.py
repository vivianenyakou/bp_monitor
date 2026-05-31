from dataclasses import dataclass


@dataclass
class RegisterDTO:
    username: str | None = None
    email: str | None = None
    password: str
    first_name: str | None = None
    last_name: str | None = None
    phone_number: str | None = None
    organisation_code: str | None = None
    qrcode_token: str | None = None


@dataclass
class LoginDTO:
    identifiant: str
    password: str


@dataclass
class TokenDTO:
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    username: str | None = None
    email: str | None = None


@dataclass
class UtilisateurDTO:
    id: int
    username: str | None
    email: str | None
    first_name: str | None
    last_name: str | None
    phone_number: str | None
    organisation_code: str | None
    roles: list[str]
    permissions: list[str]
    organisation_id: int | None

@dataclass
class CreerUtilisateurDTO:
    username: str | None
    email: str | None
    password: str
    role: str                          # patient, medecin, admin
    first_name: str | None = None
    last_name: str | None = None
    phone_number: str | None = None
    organisation_id: int | None = None
    specialite: str | None = None      # si médecin
