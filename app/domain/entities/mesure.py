from dataclasses import dataclass
from datetime import datetime, timezone
from uuid import UUID

from app.core.entity import BaseEntity
from app.domain.enums.bp_category import CategorieTA, PeriodeMesure
from app.domain.value_objects.tension_arterielle import TensionArterielle


@dataclass
class Mesure(BaseEntity):
    """
    Entité représentant une mesure de tension artérielle unique.
    Une session complète = 18 mesures (3 matin + 3 soir × 3 jours).
    """
    patient_id: UUID
    tension: TensionArterielle
    periode: PeriodeMesure
    jour: int                          # 1, 2 ou 3
    numero_mesure: int                 # 1, 2 ou 3 dans la période
    prise_le: datetime | None = None
    notes: str | None = None

    def __post_init__(self) -> None:
        super().__init__()
        if self.prise_le is None:
            self.prise_le = datetime.now(timezone.utc)
        self._valider_session()

    def _valider_session(self) -> None:
        if self.jour not in (1, 2, 3):
            raise ValueError(f"Jour invalide : {self.jour} (attendu 1, 2 ou 3)")
        if self.numero_mesure not in (1, 2, 3):
            raise ValueError(
                f"Numéro de mesure invalide : {self.numero_mesure} (attendu 1, 2 ou 3)"
            )

    @property
    def categorie(self) -> CategorieTA:
        return self.tension.categorie

    @property
    def est_critique(self) -> bool:
        return self.tension.est_critique

    def __str__(self) -> str:
        return (
            f"Mesure {self.numero_mesure} — {self.periode} "
            f"jour {self.jour} : {self.tension}"
        )