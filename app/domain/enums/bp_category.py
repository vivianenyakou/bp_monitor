from enum import StrEnum


class CategorieTA(StrEnum):
    """Catégories de tension artérielle selon les normes cardiologiques."""
    NORMALE = "normale"
    ELEVEE = "elevee"
    HYPERTENSION = "hypertension"
    CRITIQUE = "critique"


class NiveauAlerte(StrEnum):
    """Niveau de sévérité d'une alerte."""
    INFO = "info"
    AVERTISSEMENT = "avertissement"
    CRITIQUE = "critique"


class PeriodeMesure(StrEnum):
    """Période de la journée pour la mesure."""
    MATIN = "matin"
    SOIR = "soir"


class StatutAlerte(StrEnum):
    """Statut de traitement d'une alerte."""
    EN_ATTENTE = "en_attente"
    ENVOYEE = "envoyee"
    ACQUITTEE = "acquittee"
    IGNOREE = "ignoree"
