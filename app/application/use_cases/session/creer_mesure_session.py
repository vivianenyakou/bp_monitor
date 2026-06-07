from datetime import date, datetime, timezone
from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.session_dto import CreerMesureAvecSessionDTO
from app.application.dtos.mesure_dto import MesureDTO
from app.application.dtos.alerte_dto import AlerteDTO
from app.application.services.notification_service import INotificationService
from app.core.exceptions import (
    ApplicationException,
    PatientNotFoundError,
)
from app.domain.enums.bp_category import (
    CategorieTA,
    NiveauAlerte,
    PeriodeMesure,
    StatutAlerte,
)
from app.domain.services.analyseur_ta import AnalyseurTA
from app.domain.services.creneau_service import Creneau, CreneauService
from app.domain.value_objects.seuil import SeuilTA
from app.domain.value_objects.tension_arterielle import TensionArterielle
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.alerte import AlerteModel
from app.infrastructure.models.bp.mesure import MesureModel
from app.infrastructure.models.bp.patient import PatientModel
from app.infrastructure.models.bp.session import SessionModel
from app.infrastructure.services.config_service import ConfigService

class CreerMesureSessionUseCase:
    """
    Enregistre une mesure dans le cadre du protocole 3 jours.
    Gère automatiquement :
    - La création de session si première mesure
    - Le créneau horaire (matin/soir)
    - Le jour calendaire (1/2/3)
    - Le verrouillage des jours
    - Les alertes si tension critique
    """

    def __init__(
        self,
        notification_service: INotificationService | None = None,
    ) -> None:
        from app.infrastructure.notifications.notification_service import (
            NotificationService,
        )
        self._notifications = notification_service or NotificationService()

    async def executer(self, dto: CreerMesureAvecSessionDTO) -> dict:
        async with AsyncSessionFactory() as db:

            # 1. Patient
            result = await db.execute(
                select(PatientModel)
                .where(PatientModel.user_id == dto.patient_id)
                .options(selectinload(PatientModel.user))
            )
            patient = result.scalar_one_or_none()
            if not patient:
                raise PatientNotFoundError()            
            patient_org_id = patient.organisation_id or 1
            
            seuils = await ConfigService.get_seuils(patient_org_id, patient.est_hypertendu)
            self._analyseur = AnalyseurTA(seuils)

            creneau_service = await CreneauService.pour_organisation(patient_org_id)

            # 2. Session existante (SANS créer) — pour l'ancrage du soir
            res_sess = await db.execute(
                select(SessionModel)
                .where(SessionModel.patient_id == patient.id)
                .where(SessionModel.protocole_termine == False)
                .order_by(SessionModel.id.desc())
            )
            sess_existante = res_sess.scalar_one_or_none()

            # 3. Ancrage : 1ère mesure matin du jour actif
            premiere_matin = None
            if sess_existante:
                jour_actuel = self._calculer_jour(sess_existante, date.today())
                res_m = await db.execute(
                    select(MesureModel)
                    .where(MesureModel.session_id == sess_existante.session_id)
                    .where(MesureModel.periode == PeriodeMesure.MATIN)
                    .where(MesureModel.jour == jour_actuel)
                    .where(MesureModel.numero_mesure == 1)
                )
                mesure_ref = res_m.scalar_one_or_none()
                premiere_matin = mesure_ref.prise_le if mesure_ref else None
            creneau_service.definir_ancrage_soir(premiere_matin)

            # 4. Vérifier le créneau (soir dynamique)
            creneau = creneau_service.creneau_actuel()
            if creneau == Creneau.HORS_CRENEAU:
                raise ApplicationException(creneau_service.prochain_creneau())

            # 5. Créer/obtenir la session
            sess = await self._obtenir_ou_creer_session(db, patient.id)

            # 6. Jour actuel + vérifier qu'il est autorisé
            jour = self._calculer_jour(sess, date.today())
            if jour == 2 and not sess.jour1_complete:
                raise ApplicationException("Vous devez compléter le Jour 1 avant le Jour 2.")
            if jour == 3 and not sess.jour2_complete:
                raise ApplicationException("Vous devez compléter le Jour 2 avant le Jour 3.")

            # 7. Mesures restantes dans le créneau
            mesures_faites = self._mesures_faites(sess, jour, creneau)
            if mesures_faites >= 3:
                raise ApplicationException(
                    f"Vous avez déjà effectué vos 3 mesures du "
                    f"{'matin' if creneau == Creneau.MATIN else 'soir'} pour le Jour {jour}."
                )

            # 8. Tension
            periode = self._periode_depuis_creneau(creneau)
            tension = TensionArterielle(
                systolique=dto.systolique, diastolique=dto.diastolique, pouls=dto.pouls,
            )
            categorie     = self._analyseur.categoriser(tension)
            numero_mesure = mesures_faites + 1

            # 9. Enregistrer la mesure
            mesure = MesureModel(
                patient_id=patient.id,
                systolique=dto.systolique,
                diastolique=dto.diastolique,
                pouls=dto.pouls,
                periode=periode,
                jour=jour,
                numero_mesure=numero_mesure,
                categorie=categorie,
                session_id=sess.session_id,
                prise_le=datetime.utcnow(),
                notes=dto.notes,
            )
            db.add(mesure)

            # 10. Compteur
            self._incrementer_compteur(sess, jour, creneau)

            # 11. Créneau complet → moyenne + alerte
            alerte_dto       = None
            popup_medicament = False
            mesures_apres = self._mesures_faites(sess, jour, creneau)
            if mesures_apres >= 3:
                await db.flush()
                moyenne = await self._calculer_moyenne_creneau(
                    db, patient.id, sess.session_id, jour, creneau
                )
                if moyenne:
                    categorie_moyenne = self._analyseur.categoriser(moyenne)
                    niveau = self._analyseur.niveau_alerte(moyenne)
                    
                    if niveau == (NiveauAlerte.CRITIQUE or NiveauAlerte.AVERTISSEMENT):
                        alerte_dto = await self._creer_alerte(db, patient, moyenne, niveau)

                    if categorie_moyenne in (CategorieTA.ELEVEE,CategorieTA.HYPERTENSION,CategorieTA.CRITIQUE,
                                        ):
                                            popup_medicament = True

            # 12. Jour complet ?
            self._verifier_completion_jour(sess, jour)

            # 13. Protocole terminé ?
            message_fin = None
            if sess.jour1_complete and sess.jour2_complete and sess.jour3_complete:
                sess.protocole_termine = True
                sess.termine_le = datetime.utcnow()
                message_fin =  await ConfigService.get(patient_org_id, "message_felicitations")

            await db.commit()

            # 14. Notifications
            if alerte_dto and self._notifications:
                try:
                    await self._notifications.notifier_medecin(alerte_dto)
                except Exception as e:
                    print(f"[Notification] Erreur : {e}")

            return {
                "mesure_id": mesure.id,
                "session_id": sess.session_id,
                "jour": jour,
                "creneau": creneau.value,
                "numero_mesure": numero_mesure,
                "categorie": categorie.value,
                "mesures_restantes": max(0, 3 - mesures_apres),
                "popup_medicament": popup_medicament,
                "message_fin": message_fin,
                "jour1_complete": sess.jour1_complete,
                "jour2_complete": sess.jour2_complete,
                "jour3_complete": sess.jour3_complete,
                "protocole_termine": sess.protocole_termine,
            }
            
    async def _obtenir_ou_creer_session(
        self, db, patient_id: int
    ) -> SessionModel:
        """Obtient la session active ou en crée une nouvelle."""
        result = await db.execute(
            select(SessionModel)
            .where(SessionModel.patient_id == patient_id)
            .where(SessionModel.protocole_termine == False)
            .order_by(SessionModel.id.desc())
        )
        sess = result.scalar_one_or_none()

        if not sess:
            aujourd_hui = date.today()
            from datetime import timedelta
            sess = SessionModel(
                patient_id=       patient_id,
                session_id=       str(uuid4()),
                date_jour1=       aujourd_hui,
                date_jour2=       aujourd_hui + timedelta(days=1),
                date_jour3=       aujourd_hui + timedelta(days=2),
                demarre_le=       datetime.utcnow(),
                protocole_termine= False,
            )
            db.add(sess)
            await db.flush()

        return sess

    def _calculer_jour(self, sess: SessionModel, aujourd_hui: date) -> int:
        if aujourd_hui == sess.date_jour1: return 1
        if aujourd_hui == sess.date_jour2: return 2
        if aujourd_hui == sess.date_jour3: return 3
        return 1

    def _mesures_faites(
        self, sess: SessionModel, jour: int, creneau: Creneau
    ) -> int:
        mapping = {
            (1, Creneau.MATIN): sess.mesures_j1_matin,
            (1, Creneau.SOIR):  sess.mesures_j1_soir,
            (2, Creneau.MATIN): sess.mesures_j2_matin,
            (2, Creneau.SOIR):  sess.mesures_j2_soir,
            (3, Creneau.MATIN): sess.mesures_j3_matin,
            (3, Creneau.SOIR):  sess.mesures_j3_soir,
        }
        return mapping.get((jour, creneau), 0)

    def _incrementer_compteur(
        self, sess: SessionModel, jour: int, creneau: Creneau
    ) -> None:
        if jour == 1 and creneau == Creneau.MATIN:
            sess.mesures_j1_matin += 1
        elif jour == 1 and creneau == Creneau.SOIR:
            sess.mesures_j1_soir += 1
        elif jour == 2 and creneau == Creneau.MATIN:
            sess.mesures_j2_matin += 1
        elif jour == 2 and creneau == Creneau.SOIR:
            sess.mesures_j2_soir += 1
        elif jour == 3 and creneau == Creneau.MATIN:
            sess.mesures_j3_matin += 1
        elif jour == 3 and creneau == Creneau.SOIR:
            sess.mesures_j3_soir += 1

    def _periode_depuis_creneau(self, creneau: Creneau) -> PeriodeMesure:
        if creneau == Creneau.MATIN:
            return PeriodeMesure.MATIN
        if creneau == Creneau.SOIR:
            return PeriodeMesure.SOIR
        raise ApplicationException("Aucun créneau de mesure disponible.")

    def _verifier_completion_jour(
        self, sess: SessionModel, jour: int
    ) -> None:
        if jour == 1:
            if sess.mesures_j1_matin >= 3 and sess.mesures_j1_soir >= 3:
                sess.jour1_complete = True
        elif jour == 2:
            if sess.mesures_j2_matin >= 3 and sess.mesures_j2_soir >= 3:
                sess.jour2_complete = True
        elif jour == 3:
            if sess.mesures_j3_matin >= 3 and sess.mesures_j3_soir >= 3:
                sess.jour3_complete = True

    async def _calculer_moyenne_creneau(
        self, db, patient_id: int, session_id: str, jour: int, creneau: Creneau
    ):
        from sqlalchemy import select as sel
        result = await db.execute(
            sel(MesureModel)
            .where(MesureModel.patient_id == patient_id)
            .where(MesureModel.session_id == session_id)
            .where(MesureModel.jour == jour)
            .where(MesureModel.periode == self._periode_depuis_creneau(creneau))
        )
        mesures = result.scalars().all()
        if not mesures:
            return None

        moy_sys = round(sum(m.systolique  for m in mesures) / len(mesures))
        moy_dia = round(sum(m.diastolique for m in mesures) / len(mesures))
        pouls   = [m.pouls for m in mesures if m.pouls]
        moy_pouls = round(sum(pouls) / len(pouls)) if pouls else None

        return TensionArterielle(
            systolique=  moy_sys,
            diastolique= moy_dia,
            pouls=       moy_pouls,
        )

    async def _creer_alerte(
        self, db, patient, tension, niveau
    ) -> AlerteDTO:
        message = self._analyseur.generer_message(tension)
        alerte  = AlerteModel(
            patient_id=   patient.id,
            medecin_id=   patient.medecin_id,
            systolique=   tension.systolique,
            diastolique=  tension.diastolique,
            niveau=       niveau,
            statut=       StatutAlerte.EN_ATTENTE,
            message=      message,
            declenchee_le= datetime.utcnow(),
        )
        db.add(alerte)
        await db.flush()

        return AlerteDTO(
            id=           alerte.id,
            patient_id=   alerte.patient_id,
            medecin_id=   alerte.medecin_id,
            systolique=   alerte.systolique,
            diastolique=  alerte.diastolique,
            niveau=       alerte.niveau,
            statut=       alerte.statut,
            message=      alerte.message,
            declenchee_le= alerte.declenchee_le,
            acquittee_le= None,
            acquittee_par= None,
        )
