from datetime import datetime, timezone
from enum import StrEnum


class Creneau(StrEnum):
    MATIN        = "matin"
    SOIR         = "soir"
    HORS_CRENEAU = "hors_creneau"


class CreneauService:
    """
    Gère les créneaux horaires UTC.
    Les heures sont configurables par organisation.
    """

    def __init__(
        self,
        matin_debut:   int = 0,
        matin_fin:     int = 9,
        soir_debut:    int = 18,
        soir_fin:      int = 22,
        heure_simulee: int | None = None,
    ) -> None:
        self.matin_debut   = matin_debut
        self.matin_fin     = matin_fin
        self.soir_debut    = soir_debut
        self.soir_fin      = soir_fin
        self.heure_simulee = heure_simulee

    @classmethod
    async def pour_organisation(cls, organisation_id: int) -> "CreneauService":
        """Crée un CreneauService avec les configs de l'organisation."""
        from app.infrastructure.services.config_service import ConfigService

        matin_debut   = await ConfigService.get_int(organisation_id, "creneau_matin_debut",   0)
        matin_fin     = await ConfigService.get_int(organisation_id, "creneau_matin_fin",      9)
        soir_debut    = await ConfigService.get_int(organisation_id, "creneau_soir_debut",    18)
        soir_fin      = await ConfigService.get_int(organisation_id, "creneau_soir_fin",      22)

        # Heure simulée pour les tests
        heure_simulee_str = await ConfigService.get(
            organisation_id, "debug_heure_simulee", ""
        )
        heure_simulee = int(heure_simulee_str) if heure_simulee_str else None

        return cls(
            matin_debut=   matin_debut,
            matin_fin=     matin_fin,
            soir_debut=    soir_debut,
            soir_fin=      soir_fin,
            heure_simulee= heure_simulee,
        )

    def _heure_actuelle(self) -> int:
        """Retourne l'heure actuelle ou simulée."""
        if self.heure_simulee is not None:
            return self.heure_simulee
        return datetime.now(timezone.utc).hour

    def creneau_actuel(self) -> Creneau:
        """Retourne le créneau actuel."""
        heure = self._heure_actuelle()

        if self.matin_debut <= heure < self.matin_fin:
            return Creneau.MATIN
        if self.soir_debut <= heure < self.soir_fin:
            return Creneau.SOIR
        return Creneau.HORS_CRENEAU

    def prochain_creneau(self) -> str:
        """Retourne un message sur le prochain créneau."""
        heure = self._heure_actuelle()

        if heure < self.matin_debut:
            return f"La prochaine prise est prévue à {self.matin_debut:02d}h00 UTC."
        if self.matin_fin <= heure < self.soir_debut:
            return f"La prochaine prise est prévue à {self.soir_debut:02d}h00 UTC."
        if heure >= self.soir_fin:
            return f"La prochaine prise est prévue demain à {self.matin_debut:02d}h00 UTC."
        return ""

    def est_disponible(self) -> bool:
        return self.creneau_actuel() != Creneau.HORS_CRENEAU

    def est_matin(self) -> bool:
        return self.creneau_actuel() == Creneau.MATIN

    def est_soir(self) -> bool:
        return self.creneau_actuel() == Creneau.SOIR