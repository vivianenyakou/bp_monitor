from dataclasses import dataclass
from datetime import datetime


@dataclass
class GenererInvitationDTO:
    medecin_id: int
    organisation_id: int | None = None


@dataclass
class AccepterInvitationDTO:
    code: str
    patient_id: int


@dataclass
class InvitationDTO:
    id: int
    code: str
    medecin_id: int
    medecin_nom: str
    est_utilise: bool
    expire_le: datetime


@dataclass
class ChoisirMedecinDTO:
    patient_id: int
    medecin_id: int