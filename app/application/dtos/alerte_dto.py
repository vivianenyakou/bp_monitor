from dataclasses import dataclass
from datetime import datetime

from app.domain.enums.bp_category import NiveauAlerte, StatutAlerte


@dataclass
class AlerteDTO:
    """Données d'une alerte."""
    id: int
    patient_id: int
    medecin_id: int | None
    systolique: int
    diastolique: int
    niveau: NiveauAlerte
    statut: StatutAlerte
    message: str
    declenchee_le: datetime
    acquittee_le: datetime | None
    acquittee_par: str | None
    patient_nom_complet: str | None = None
    patient_telephone: str | None = None


@dataclass
class AcquitterAlerteDTO:
    """Données pour acquitter une alerte."""
    alerte_id: int
    acquittee_par: str