from dataclasses import dataclass

from app.core.exceptions import InvalidBloodPressureError
from app.core.value_object import ValueObject
from app.domain.enums.bp_category import CategorieTA


@dataclass(frozen=True)
class TensionArterielle(ValueObject):
    """
    Objet valeur représentant une mesure de tension artérielle.
    Immuable — toute modification crée un nouvel objet.
    """
    systolique: int   # pression maximale (mmHg)
    diastolique: int  # pression minimale (mmHg)
    pouls: int | None = None  # battements par minute

    def __post_init__(self) -> None:
        self._validate()

    def _validate(self) -> None:
        if not (60 <= self.systolique <= 250):
            raise InvalidBloodPressureError(
                f"Systolique invalide : {self.systolique} mmHg "
                f"(attendu entre 60 et 250 mmHg)"
            )
        if not (40 <= self.diastolique <= 150):
            raise InvalidBloodPressureError(
                f"Diastolique invalide : {self.diastolique} mmHg "
                f"(attendu entre 40 et 150 mmHg)"
            )
        if self.systolique <= self.diastolique:
            raise InvalidBloodPressureError(
                "La systolique doit être supérieure à la diastolique."
            )
        if self.pouls is not None and not (30 <= self.pouls <= 220):
            raise InvalidBloodPressureError(
                f"Pouls invalide : {self.pouls} bpm (attendu entre 30 et 220 bpm)"
            )

    @property
    def categorie(self) -> CategorieTA:
        """Détermine la catégorie selon les seuils cardiologiques."""
        if self.systolique >= 180 or self.diastolique >= 110:
            return CategorieTA.CRITIQUE
        if self.systolique >= 140 or self.diastolique >= 90:
            return CategorieTA.HYPERTENSION
        if self.systolique >= 130 or self.diastolique >= 85:
            return CategorieTA.ELEVEE
        return CategorieTA.NORMALE

    @property
    def est_critique(self) -> bool:
        return self.categorie == CategorieTA.CRITIQUE

    @property
    def est_normale(self) -> bool:
        return self.categorie == CategorieTA.NORMALE

    def __str__(self) -> str:
        pouls = f" — {self.pouls} bpm" if self.pouls else ""
        return f"{self.systolique}/{self.diastolique} mmHg{pouls}"