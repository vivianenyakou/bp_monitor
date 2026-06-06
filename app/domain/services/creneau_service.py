from datetime import datetime, timezone
from enum import StrEnum


class Creneau(StrEnum):
    MATIN        = "matin"
    SOIR         = "soir"
    HORS_CRENEAU = "hors_creneau"
class CreneauService:
    def __init__(
        self,
        matin_debut: int = 0,
        matin_fin: int = 9,
        soir_fin: int = 22,
        intervalle_matin_soir: int = 8,
        heure_simulee: int | None = None,
    ) -> None:
        self.matin_debut = matin_debut
        self.matin_fin   = matin_fin
        self.soir_fin    = soir_fin
        self.intervalle  = intervalle_matin_soir
        self.heure_simulee = heure_simulee
        self._soir_debut: int | None = None  # défini via definir_ancrage_soir

    @classmethod
    async def pour_organisation(cls, organisation_id: int) -> "CreneauService":
        from app.infrastructure.services.config_service import ConfigService
        matin_debut = await ConfigService.get_int(organisation_id, "creneau_matin_debut", 0)
        matin_fin   = await ConfigService.get_int(organisation_id, "creneau_matin_fin", 9)
        soir_fin    = await ConfigService.get_int(organisation_id, "creneau_soir_fin", 22)
        intervalle  = await ConfigService.get_int(organisation_id, "intervalle_matin_soir", 8)
        heure_str   = await ConfigService.get(organisation_id, "debug_heure_simulee", "")
        return cls(
            matin_debut=matin_debut,
            matin_fin=matin_fin,
            soir_fin=soir_fin,
            intervalle_matin_soir=intervalle,
            heure_simulee=int(heure_str) if heure_str else None,
        )

    def definir_ancrage_soir(self, premiere_mesure_matin: datetime | None) -> None:
        """Ouverture du soir : 1ère mesure matin + intervalle, sinon repli à la fin du matin."""
        if premiere_mesure_matin is not None:
            self._soir_debut = premiere_mesure_matin.hour + self.intervalle
        else:
            self._soir_debut = self.matin_fin

    def _heure_actuelle(self) -> int:
        if self.heure_simulee is not None:
            return self.heure_simulee
        return datetime.now(timezone.utc).hour

    def creneau_actuel(self) -> Creneau:
        heure = self._heure_actuelle()
        if self.matin_debut <= heure < self.matin_fin:
            return Creneau.MATIN
        if self._soir_debut is not None and self._soir_debut <= heure < self.soir_fin:
            return Creneau.SOIR
        return Creneau.HORS_CRENEAU

    def prochain_creneau(self) -> str:
        heure = self._heure_actuelle()
        if heure < self.matin_debut:
            return f"La prochaine prise est prévue à {self.matin_debut:02d}h00 UTC."
        if self._soir_debut is not None and self.matin_fin <= heure < self._soir_debut:
            return f"La prochaine prise est prévue à {self._soir_debut:02d}h00 UTC."
        if heure >= self.soir_fin:
            return f"La prochaine prise est prévue demain à {self.matin_debut:02d}h00 UTC."
        return ""

    def est_disponible(self) -> bool:
        return self.creneau_actuel() != Creneau.HORS_CRENEAU

    def est_matin(self) -> bool:
        return self.creneau_actuel() == Creneau.MATIN

    def est_soir(self) -> bool:
        return self.creneau_actuel() == Creneau.SOIR