from app.application.dtos.summary_dto import MoyenneDTO, ResumeSessionDTO
from app.core.exceptions import PatientNotFoundError
from app.domain.enums.bp_category import PeriodeMesure
from app.domain.entities.mesure import Mesure
from app.domain.services.analyseur_ta import AnalyseurTA
from app.domain.services.calculateur_moyenne import CalculateurMoyenne
from app.domain.value_objects.tension_arterielle import TensionArterielle
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.mesure import MesureModel
from app.infrastructure.models.bp.patient import PatientModel

from sqlalchemy import select


class ObtenirResumeUseCase:
    """
    Calcule les moyennes d'une session (partielle ou complète)
    et retourne un résumé complet au patient ou au médecin.
    """

    def __init__(self) -> None:
        self._calculateur = CalculateurMoyenne()
        self._analyseur = AnalyseurTA()

    async def executer(self, patient_id: int, session_id: str) -> ResumeSessionDTO:
        async with AsyncSessionFactory() as session:

            # 1. Vérifier le patient
            patient = await session.get(PatientModel, patient_id)
            if not patient:
                raise PatientNotFoundError()

            # 2. Récupérer toutes les mesures de la session
            result = await session.execute(
                select(MesureModel).where(
                    MesureModel.patient_id == patient_id,
                    MesureModel.session_id == session_id,
                )
            )
            models = result.scalars().all()

            # 3. Convertir en entités domain
            mesures = [self._to_entity(m) for m in models]
            nombre = len(mesures)
            session_complete = nombre >= 18

            # 4. Calculer les moyennes
            moyenne_globale = self._calculateur.moyenne_partielle(mesures)
            moyenne_matin = self._calculateur.moyenne_par_periode(
                mesures, PeriodeMesure.MATIN
            )
            moyenne_soir = self._calculateur.moyenne_par_periode(
                mesures, PeriodeMesure.SOIR
            )
            moyennes_par_jour = {
                j: self._calculateur.moyenne_par_jour(mesures, j)
                for j in (1, 2, 3)
                if self._calculateur.moyenne_par_jour(mesures, j)
            }

            return ResumeSessionDTO(
                session_id=session_id,
                patient_id=patient_id,
                nombre_mesures=nombre,
                session_complete=session_complete,
                moyenne_globale=self._to_moyenne_dto(moyenne_globale),
                moyenne_matin=self._to_moyenne_dto(moyenne_matin),
                moyenne_soir=self._to_moyenne_dto(moyenne_soir),
                moyennes_par_jour={
                    j: self._to_moyenne_dto(m)
                    for j, m in moyennes_par_jour.items()
                },
            )

    def _to_entity(self, model: MesureModel) -> Mesure:
        from app.domain.entities.mesure import Mesure
        return Mesure(
            patient_id=model.patient_id,
            tension=TensionArterielle(
                systolique=model.systolique,
                diastolique=model.diastolique,
                pouls=model.pouls,
            ),
            periode=model.periode,
            jour=model.jour,
            numero_mesure=model.numero_mesure,
            prise_le=model.prise_le,
        )

    def _to_moyenne_dto(
        self, tension: TensionArterielle | None
    ) -> MoyenneDTO | None:
        if not tension:
            return None
        return MoyenneDTO(
            systolique=tension.systolique,
            diastolique=tension.diastolique,
            pouls=tension.pouls,
            categorie=self._analyseur.categoriser(tension),
            nombre_mesures=0,
        )