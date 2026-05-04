from dataclasses import dataclass

from app.core.exceptions import InvalidThresholdError
from app.core.value_object import ValueObject


@dataclass(frozen=True)
class SeuilTA(ValueObject):
    """
    Seuils de tension artérielle configurables par l'admin.
    Permettent d'adapter les alertes selon le profil du patient.
    """
    systolique_eleve: int = 130
    diastolique_eleve: int = 85
    systolique_hypertension: int = 140
    diastolique_hypertension: int = 90
    systolique_critique: int = 180
    diastolique_critique: int = 110

    def __post_init__(self) -> None:
        self._validate()

    def _validate(self) -> None:
        if not (self.systolique_eleve
                < self.systolique_hypertension
                < self.systolique_critique):
            raise InvalidThresholdError(
                "Les seuils systoliques doivent être croissants : "
                "élevé < hypertension < critique."
            )
        if not (self.diastolique_eleve
                < self.diastolique_hypertension
                < self.diastolique_critique):
            raise InvalidThresholdError(
                "Les seuils diastoliques doivent être croissants : "
                "élevé < hypertension < critique."
            )