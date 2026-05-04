from dataclasses import dataclass
from datetime import datetime

from app.domain.enums.bp_category import CategorieTA, PeriodeMesure


@dataclass
class CreerMesureDTO:
    """Données reçues pour créer une mesure."""
    patient_id: int
    systolique: int
    diastolique: int
    periode: PeriodeMesure
    jour: int
    numero_mesure: int
    pouls: int | None = None
    notes: str | None = None
    session_id: str | None = None


@dataclass
class MesureDTO:
    """Données retournées après création ou lecture d'une mesure."""
    id: int
    patient_id: int
    systolique: int
    diastolique: int
    pouls: int | None
    periode: PeriodeMesure
    jour: int
    numero_mesure: int
    categorie: CategorieTA
    session_id: str
    prise_le: datetime
    notes: str | None