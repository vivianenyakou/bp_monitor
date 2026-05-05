from dataclasses import dataclass


@dataclass
class RegisterDTO:
    username: str
    email: str
    password: str
    first_name: str | None = None
    last_name: str | None = None
    phone_number: str | None = None


@dataclass
class LoginDTO:
    email: str
    password: str


@dataclass
class TokenDTO:
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


@dataclass
class UtilisateurDTO:
    id: int
    username: str
    email: str
    first_name: str | None
    last_name: str | None
    phone_number: str | None
    roles: list[str]
    permissions: list[str]