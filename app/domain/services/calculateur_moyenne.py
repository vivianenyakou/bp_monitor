from app.core.exceptions import MeasurementSessionIncompleteError
from app.domain.entities.mesure import Mesure
from app.domain.enums.bp_category import PeriodeMesure
from app.domain.value_objects.tension_arterielle import TensionArterielle

TOTAL_MESURES_SESSION = 18  # 3 matin + 3 soir × 3 jours


class CalculateurMoyenne:
    """
    Service domaine — calcule les moyennes de tension
    selon la règle 3-3-3 (18 mesures sur 3 jours).
    """

    @staticmethod
    def moyenne_session(mesures: list[Mesure]) -> TensionArterielle:
        """
        Calcule la moyenne finale sur les 18 mesures.
        Lève une exception si la session est incomplète.
        """
        if len(mesures) < TOTAL_MESURES_SESSION:
            raise MeasurementSessionIncompleteError(
                f"Session incomplète : {len(mesures)}/{TOTAL_MESURES_SESSION} mesures."
            )
        return CalculateurMoyenne._calculer_moyenne(mesures)

    @staticmethod
    def moyenne_partielle(mesures: list[Mesure]) -> TensionArterielle | None:
        """Calcule une moyenne sur les mesures disponibles (session en cours)."""
        if not mesures:
            return None
        return CalculateurMoyenne._calculer_moyenne(mesures)

    @staticmethod
    def moyenne_par_periode(
        mesures: list[Mesure],
        periode: PeriodeMesure,
    ) -> TensionArterielle | None:
        """Calcule la moyenne pour une période (matin ou soir)."""
        filtrees = [m for m in mesures if m.periode == periode]
        if not filtrees:
            return None
        return CalculateurMoyenne._calculer_moyenne(filtrees)

    @staticmethod
    def moyenne_par_jour(
        mesures: list[Mesure],
        jour: int,
    ) -> TensionArterielle | None:
        """Calcule la moyenne pour un jour donné (1, 2 ou 3)."""
        filtrees = [m for m in mesures if m.jour == jour]
        if not filtrees:
            return None
        return CalculateurMoyenne._calculer_moyenne(filtrees)

    @staticmethod
    def _calculer_moyenne(mesures: list[Mesure]) -> TensionArterielle:
        n = len(mesures)
        moy_sys = round(sum(m.tension.systolique for m in mesures) / n)
        moy_dia = round(sum(m.tension.diastolique for m in mesures) / n)
        pouls = [m.tension.pouls for m in mesures if m.tension.pouls is not None]
        moy_pouls = round(sum(pouls) / len(pouls)) if pouls else None
        return TensionArterielle(
            systolique=moy_sys,
            diastolique=moy_dia,
            pouls=moy_pouls,
        )