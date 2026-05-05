from uuid import uuid4

from sqlalchemy.orm import selectinload

from app.application.dtos import alerte_dto
from app.application.dtos.mesure_dto import CreerMesureDTO, MesureDTO
from app.application.dtos.alerte_dto import AlerteDTO
from app.application.services.notification_service import INotificationService
from app.core.exceptions import PatientNotFoundError
from app.domain.enums.bp_category import CategorieTA, NiveauAlerte, StatutAlerte
from app.domain.services.analyseur_ta import AnalyseurTA
from app.domain.services.calculateur_moyenne import CalculateurMoyenne
from app.domain.value_objects.tension_arterielle import TensionArterielle
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.alerte import AlerteModel
from app.infrastructure.models.bp.mesure import MesureModel
from app.infrastructure.models.bp.patient import PatientModel

from datetime import datetime
from sqlalchemy import select

from datetime import datetime
from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.mesure_dto import CreerMesureDTO, MesureDTO
from app.application.services.notification_service import INotificationService
from app.core.exceptions import PatientNotFoundError
from app.domain.enums.bp_category import NiveauAlerte, StatutAlerte
from app.domain.services.analyseur_ta import AnalyseurTA
from app.domain.value_objects.tension_arterielle import TensionArterielle
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.notifications.notification_service import NotificationService

from datetime import datetime
from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.alerte_dto import AlerteDTO
from app.application.dtos.mesure_dto import CreerMesureDTO, MesureDTO
from app.application.services.notification_service import INotificationService
from app.core.exceptions import PatientNotFoundError
from app.domain.enums.bp_category import NiveauAlerte, StatutAlerte
from app.domain.services.analyseur_ta import AnalyseurTA
from app.domain.value_objects.tension_arterielle import TensionArterielle
from app.infrastructure.db.session import AsyncSessionFactory

class CreerMesureUseCase:

    def __init__(
        self,
        notification_service: INotificationService | None = None,
    ) -> None:
        from app.infrastructure.notifications.notification_service import NotificationService
        self._notifications = notification_service or NotificationService()
        self._analyseur = AnalyseurTA()

    async def executer(self, dto: CreerMesureDTO) -> MesureDTO:
        async with AsyncSessionFactory() as session:

            # 1. Vérifier que le patient existe
            result = await session.execute(
                select(PatientModel)
                .where(PatientModel.id == dto.patient_id)
                .options(selectinload(PatientModel.user))
            )
            patient = result.scalar_one_or_none()
            if not patient:
                raise PatientNotFoundError()

            # 2. Créer la tension
            tension = TensionArterielle(
                systolique=dto.systolique,
                diastolique=dto.diastolique,
                pouls=dto.pouls,
            )
            categorie = self._analyseur.categoriser(tension)
            niveau = self._analyseur.niveau_alerte(tension)

            # 3. Générer session_id si non fourni
            session_id = dto.session_id or str(uuid4())

            # 4. Enregistrer la mesure
            mesure = MesureModel(
                patient_id=dto.patient_id,
                systolique=dto.systolique,
                diastolique=dto.diastolique,
                pouls=dto.pouls,
                periode=dto.periode,
                jour=dto.jour,
                numero_mesure=dto.numero_mesure,
                categorie=categorie,
                session_id=session_id,
                prise_le=datetime.utcnow(),
                notes=dto.notes,
            )
            session.add(mesure)
            await session.flush()

            # 5. Créer l'alerte si nécessaire
            alerte_dto: AlerteDTO | None = None
            if niveau in (NiveauAlerte.CRITIQUE, NiveauAlerte.AVERTISSEMENT):
                alerte_dto = await self._creer_alerte(
                    session=session,
                    patient=patient,
                    tension=tension,
                    niveau=niveau,
                )

            await session.commit()
            await session.refresh(mesure)

        # 6. Envoyer les notifications APRÈS le commit
        if alerte_dto and self._notifications:
            try:
                await self._notifications.notifier_medecin(alerte_dto)
            except Exception as e:
                print(f"[Notification] Erreur envoi SMS : {e}")

        return MesureDTO(
            id=mesure.id,
            patient_id=mesure.patient_id,
            systolique=mesure.systolique,
            diastolique=mesure.diastolique,
            pouls=mesure.pouls,
            periode=mesure.periode,
            jour=mesure.jour,
            numero_mesure=mesure.numero_mesure,
            categorie=mesure.categorie,
            session_id=mesure.session_id,
            prise_le=mesure.prise_le,
            notes=mesure.notes,
        )

    async def _creer_alerte(
        self, session, patient, tension, niveau
    ) -> AlerteDTO:
        message = self._analyseur.generer_message(tension)
        alerte = AlerteModel(
            patient_id=patient.id,
            medecin_id=None,
            systolique=tension.systolique,
            diastolique=tension.diastolique,
            niveau=niveau,
            statut=StatutAlerte.EN_ATTENTE,
            message=message,
            declenchee_le=datetime.utcnow(),
        )
        session.add(alerte)
        await session.flush()

        return AlerteDTO(
            id=alerte.id,
            patient_id=alerte.patient_id,
            medecin_id=alerte.medecin_id,
            systolique=alerte.systolique,
            diastolique=alerte.diastolique,
            niveau=alerte.niveau,
            statut=alerte.statut,
            message=alerte.message,
            declenchee_le=alerte.declenchee_le,
            acquittee_le=None,
            acquittee_par=None,
        )