from app.domain.enums.bp_category import CategorieTA, NiveauAlerte
from app.domain.value_objects.seuil import SeuilTA
from app.domain.value_objects.tension_arterielle import TensionArterielle


class AnalyseurTA:
    """
    Service domaine — analyse une tension et détermine
    la catégorie et le niveau d'alerte selon les seuils du patient.
    """

    def __init__(self, seuils: SeuilTA | None = None) -> None:
        self._seuils = seuils or SeuilTA()

    def categoriser(self, tension: TensionArterielle) -> CategorieTA:
        """Détermine la catégorie selon les seuils configurés."""
        s = self._seuils
        if (tension.systolique >= s.systolique_critique
                or tension.diastolique >= s.diastolique_critique):
            return CategorieTA.CRITIQUE
        if (tension.systolique >= s.systolique_hypertension
                or tension.diastolique >= s.diastolique_hypertension):
            return CategorieTA.HYPERTENSION
        if (tension.systolique >= s.systolique_eleve
                or tension.diastolique >= s.diastolique_eleve):
            return CategorieTA.ELEVEE
        return CategorieTA.NORMALE

    def niveau_alerte(self, tension: TensionArterielle) -> NiveauAlerte | None:
        """Retourne le niveau d'alerte ou None si tension normale."""
        categorie = self.categoriser(tension)
        mapping = {
            CategorieTA.CRITIQUE: NiveauAlerte.CRITIQUE,
            CategorieTA.HYPERTENSION: NiveauAlerte.CRITIQUE,
            CategorieTA.ELEVEE: NiveauAlerte.AVERTISSEMENT,
            CategorieTA.NORMALE: None,
        }
        return mapping[categorie]

    def generer_message(self, tension: TensionArterielle) -> str:
        """Génère un message d'alerte lisible pour le médecin."""
        categorie = self.categoriser(tension)
        messages = {
            CategorieTA.CRITIQUE: (
                f"⚠️ TENSION CRITIQUE : {tension} — "
                "Consultation urgente recommandée."
            ),
            CategorieTA.HYPERTENSION: (
                f"Hypertension détectée : {tension} — "
                "Suivi médical nécessaire."
            ),
            CategorieTA.ELEVEE: (
                f"Tension élevée : {tension} — "
                "Surveillance recommandée."
            ),
            CategorieTA.NORMALE: (
                f"Tension normale : {tension}."
            ),
        }
        return messages[categorie]