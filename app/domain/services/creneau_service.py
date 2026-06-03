from datetime import datetime, timezone
from enum import StrEnum


class Creneau(StrEnum):
    MATIN       = "matin"
    SOIR        = "soir"
    HORS_CRENEAU = "hors_creneau"


class CreneauService:
    """
    Gère les créneaux horaires UTC.
    Matin : 00h00 - 09h00 UTC
    Soir  : 18h00 - 22h00 UTC
    """

    MATIN_DEBUT = 0   # 00h00 UTC
    MATIN_FIN   = 9   # 09h00 UTC
    SOIR_DEBUT  = 18  # 18h00 UTC
    SOIR_FIN    = 22  # 22h00 UTC

    @staticmethod
    def creneau_actuel() -> Creneau:
        """Retourne le créneau actuel en UTC."""
        heure = datetime.now(timezone.utc).hour

        if CreneauService.MATIN_DEBUT <= heure < CreneauService.MATIN_FIN:
            return Creneau.MATIN
        if CreneauService.SOIR_DEBUT <= heure < CreneauService.SOIR_FIN:
            return Creneau.SOIR
        return Creneau.HORS_CRENEAU

    @staticmethod
    def prochain_creneau() -> str:
        """Retourne un message sur le prochain créneau."""
        heure = datetime.now(timezone.utc).hour

        if heure < CreneauService.MATIN_DEBUT:
            return "La prochaine prise est prévue à partir de00h00 GMT."
        if CreneauService.MATIN_FIN <= heure < CreneauService.SOIR_DEBUT:
            return "La prochaine prise est prévue à partir de 18h00 GMT."
        if heure >= CreneauService.SOIR_FIN:
            return "La prochaine prise est prévue demain à 00h00 GMT."
        return ""

    @staticmethod
    def est_matin() -> bool:
        return CreneauService.creneau_actuel() == Creneau.MATIN

    @staticmethod
    def est_soir() -> bool:
        return CreneauService.creneau_actuel() == Creneau.SOIR

    @staticmethod
    def est_disponible() -> bool:
        return CreneauService.creneau_actuel() != Creneau.HORS_CRENEAU