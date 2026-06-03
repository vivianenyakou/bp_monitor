from datetime import date, datetime, timezone
from uuid import uuid4

from sqlalchemy import select

from app.application.dtos.session_dto import SessionDTO
from app.core.exceptions import PatientNotFoundError
from app.domain.services.creneau_service import Creneau, CreneauService
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.patient import PatientModel
from app.infrastructure.models.bp.session import SessionModel

class ObtenirSessionUseCase:
    """
    Retourne la session active du patient.
    Crée une nouvelle session si aucune n'est active.
    """

    async def executer(self, patient_id: int) -> SessionDTO:
        async with AsyncSessionFactory() as session:

            # 1. Vérifier le patient (patient_id = user.id côté mobile)
            result_p = await session.execute(
                select(PatientModel)
                .where(PatientModel.user_id == patient_id)
            )
            patient = result_p.scalar_one_or_none()
            if not patient:
                raise PatientNotFoundError()

            # 2. Chercher une session active (patient.id = PK de patients)
            result = await session.execute(
                select(SessionModel)
                .where(SessionModel.patient_id == patient.id)
                .where(SessionModel.protocole_termine == False)
                .order_by(SessionModel.id.desc())
            )
            sess = result.scalar_one_or_none()

            # 3. Vérifier si on doit créer une nouvelle session
            aujourd_hui = date.today()

            if sess:
                # Vérifier si la session date d'avant aujourd'hui
                # et si le protocole est terminé
                if sess.date_jour3 < aujourd_hui and not sess.protocole_termine:
                    sess.protocole_termine = True
                    await session.commit()
                    sess = None

            # 4. Calculer le créneau actuel
            patient_org_id  = patient.organisation_id or 1
            creneau_service = await CreneauService.pour_organisation(patient_org_id)
            creneau         = CreneauService.creneau_actuel()
            message_creneau = ""
            if creneau == Creneau.HORS_CRENEAU:
                message_creneau = CreneauService.prochain_creneau()

            if not sess:
                return SessionDTO(
                    session_id=        "",
                    patient_id=        patient_id,
                    date_jour1=        aujourd_hui,
                    date_jour2=        aujourd_hui,
                    date_jour3=        aujourd_hui,
                    mesures_j1_matin=  0,
                    mesures_j1_soir=   0,
                    mesures_j2_matin=  0,
                    mesures_j2_soir=   0,
                    mesures_j3_matin=  0,
                    mesures_j3_soir=   0,
                    jour1_complete=    False,
                    jour2_complete=    False,
                    jour3_complete=    False,
                    protocole_termine= False,
                    creneau_actuel=    creneau,
                    message_creneau=   message_creneau,
                    jour_actuel=       1,
                    mesures_restantes= 3,
                    medicament_pris=   None,
                    demarre_le=        datetime.now(timezone.utc),
                    termine_le=        None,
                )

            # 5. Déterminer le jour actuel
            jour_actuel = self._calculer_jour(sess, aujourd_hui)

            # 6. Calculer les mesures restantes dans le créneau actuel
            mesures_restantes = self._calculer_mesures_restantes(
                sess, jour_actuel, creneau
            )

            return SessionDTO(
                session_id=        sess.session_id,
                patient_id=        patient_id,
                date_jour1=        sess.date_jour1,
                date_jour2=        sess.date_jour2,
                date_jour3=        sess.date_jour3,
                mesures_j1_matin=  sess.mesures_j1_matin,
                mesures_j1_soir=   sess.mesures_j1_soir,
                mesures_j2_matin=  sess.mesures_j2_matin,
                mesures_j2_soir=   sess.mesures_j2_soir,
                mesures_j3_matin=  sess.mesures_j3_matin,
                mesures_j3_soir=   sess.mesures_j3_soir,
                jour1_complete=    sess.jour1_complete,
                jour2_complete=    sess.jour2_complete,
                jour3_complete=    sess.jour3_complete,
                protocole_termine= sess.protocole_termine,
                creneau_actuel=    creneau,
                message_creneau=   message_creneau,
                jour_actuel=       jour_actuel,
                mesures_restantes= mesures_restantes,
                medicament_pris=   sess.medicament_pris,
                demarre_le=        sess.demarre_le,
                termine_le=        sess.termine_le,
            )

    def _calculer_jour(self, sess: SessionModel, aujourd_hui: date) -> int:
        if aujourd_hui == sess.date_jour1:
            return 1
        if aujourd_hui == sess.date_jour2:
            return 2
        if aujourd_hui == sess.date_jour3:
            return 3
        return 1

    def _calculer_mesures_restantes(
        self,
        sess: SessionModel,
        jour: int,
        creneau: Creneau,
    ) -> int:
        if creneau == Creneau.HORS_CRENEAU:
            return 0

        mapping = {
            (1, Creneau.MATIN): 3 - sess.mesures_j1_matin,
            (1, Creneau.SOIR):  3 - sess.mesures_j1_soir,
            (2, Creneau.MATIN): 3 - sess.mesures_j2_matin,
            (2, Creneau.SOIR):  3 - sess.mesures_j2_soir,
            (3, Creneau.MATIN): 3 - sess.mesures_j3_matin,
            (3, Creneau.SOIR):  3 - sess.mesures_j3_soir,
        }
        return max(0, mapping.get((jour, creneau), 0))