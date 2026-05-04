from dataclasses import dataclass
from datetime import datetime, timezone
from uuid import UUID

from app.core.entity import BaseEntity
from app.domain.enums.bp_category import NiveauAlerte, StatutAlerte
from app.domain.value_objects.tension_arterielle import TensionArterielle


@dataclass
class Alerte(BaseEntity):
    """
    Entité alerte — créée automatiquement quand une mesure
    ou une moyenne dépasse les seuils définis.
    """
    patient_id: UUID
    medecin_id: UUID | None
    tension: TensionArterielle
    niveau: NiveauAlerte
    message: str
    statut: StatutAlerte = StatutAlerte.EN_ATTENTE
    declenchee_le: datetime | None = None
    acquittee_le: datetime | None = None
    acquittee_par: str | None = None

    def __post_init__(self) -> None:
        super().__init__()
        if self.declenchee_le is None:
            self.declenchee_le = datetime.now(timezone.utc)

    def acquitter(self, par: str) -> None:
        """Le médecin acquitte l'alerte."""
        self.statut = StatutAlerte.ACQUITTEE
        self.acquittee_le = datetime.now(timezone.utc)
        self.acquittee_par = par
        self._touch()

    def marquer_envoyee(self) -> None:
        """Marque l'alerte comme envoyée au médecin."""
        self.statut = StatutAlerte.ENVOYEE
        self._touch()

    @property
    def est_critique(self) -> bool:
        return self.niveau == NiveauAlerte.CRITIQUE