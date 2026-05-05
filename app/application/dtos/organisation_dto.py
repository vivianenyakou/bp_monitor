from dataclasses import dataclass


@dataclass
class CreerOrganisationDTO:
    nom: str
    code: str
    adresse: str | None = None
    telephone: str | None = None
    raison_sociale: str | None = None
    nif_structure: str | None = None
    email: str | None = None


@dataclass
class OrganisationDTO:
    id: int
    nom: str
    code: str
    adresse: str | None
    telephone: str | None
    raison_sociale: str | None
    nif_structure: str | None
    email: str | None
    est_actif: bool