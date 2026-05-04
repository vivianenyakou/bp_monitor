from dataclasses import dataclass, field

from app.domain.enums.bp_category import CategorieTA


@dataclass
class MoyenneDTO:
    """Moyenne de tension pour une période donnée."""
    systolique: int
    diastolique: int
    pouls: int | None
    categorie: CategorieTA
    nombre_mesures: int


@dataclass
class ResumeSessionDTO:
    """
    Résumé complet d'une session de 3 jours.
    Contient les moyennes globale, par jour et par période.
    """
    session_id: str
    patient_id: int
    nombre_mesures: int
    session_complete: bool                          # True si 18 mesures

    moyenne_globale: MoyenneDTO | None
    moyenne_matin: MoyenneDTO | None
    moyenne_soir: MoyenneDTO | None
    moyennes_par_jour: dict[int, MoyenneDTO] = field(default_factory=dict)

    @property
    def progression(self) -> str:
        return f"{self.nombre_mesures}/18 mesures"