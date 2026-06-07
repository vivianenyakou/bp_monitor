from app.application.dtos.alerte_dto import AlerteDTO
from app.application.services.notification_service import INotificationService
from app.core.exceptions import NotificationDeliveryError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.bp.patient import PatientModel
from app.infrastructure.models.multi_tenant.organisations import OrganisationModel
from app.infrastructure.notifications.afriksms_channel import AfrikSmsChannel

from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.infrastructure.models.auth.role import RoleModel
from sqlalchemy import select
from sqlalchemy.orm import selectinload


class NotificationService(INotificationService):
    """
    Implémentation du service de notifications.
    Notifie le patient ET le médecin en cas d'alerte.
    """

    def __init__(self) -> None:
        self._sms = AfrikSmsChannel()

    async def envoyer_sms(self, telephone: str, message: str) -> None:
        await self._sms.envoyer(telephone, message)

    async def envoyer_push(self, token_fcm: str, message: str) -> None:
        # FCM à implémenter plus tard
        pass

    async def notifier_medecin(self, alerte: AlerteDTO) -> None:
        """Notifie le patient ET le médecin en cas d'alerte."""
        async with AsyncSessionFactory() as session:

            # ── Charger le patient ────────────────────────────────
            patient_result = await session.execute(
                select(PatientModel)
                .where(PatientModel.id == alerte.patient_id)
                .options(selectinload(PatientModel.user))
            )
            patient = patient_result.scalar_one_or_none()
            
            # ── Charger l'organisation ────────────────────────────
            organisation = None
            if patient and patient.organisation_id:
                org_result = await session.execute(
                    select(OrganisationModel)
                    .where(OrganisationModel.id == patient.organisation_id)
                )
                organisation = org_result.scalar_one_or_none()

            # ── Charger le médecin ────────────────────────────────
            medecin = None
            if alerte.medecin_id:
                medecin_result = await session.execute(
                    select(UserModel)
                    .where(UserModel.id == alerte.medecin_id)
                    .options(
                        selectinload(UserModel.roles)
                        .selectinload(RoleModel.permissions)
                    )
                )
                medecin = medecin_result.scalar_one_or_none()

            # ── Notifier le patient ───────────────────────────────
            if patient and patient.user and patient.user.phone_number:
                await self._notifier_patient(alerte, patient.user)

            # ── Notifier le médecin ───────────────────────────────
            if medecin and medecin.phone_number:
                await self._notifier_medecin(alerte, medecin,patient)
            # ── Notifier l'organisation ───────────────────────────
            if organisation and organisation.telephone:
                await self._notifier_organisation(alerte, organisation, patient)
                
    async def _notifier_patient(
        self, alerte: AlerteDTO, user: UserModel
    ) -> None:
        """SMS envoyé au patient."""
        messages = {
            "critique": (
                f"🚨 ALERTE TENSION - G-AutoBP\n"
                f"Votre tension est CRITIQUE : "
                f"{alerte.systolique}/{alerte.diastolique} mmHg.\n"
                f"Consultez votre médecin immédiatement."
            ),
            "avertissement": (
                f"⚠️ Tension élevée - G-AutoBP\n"
                f"Votre tension est élevée : "
                f"{alerte.systolique}/{alerte.diastolique} mmHg.\n"
                f"Une surveillance médicale est recommandée."
            ),
        }
        message = messages.get(
            alerte.niveau.value,
            f"Alerte tension : {alerte.systolique}/{alerte.diastolique} mmHg."
        )
        await self._sms.envoyer(user.phone_number, message)

    async def _notifier_medecin(
            self, alerte: AlerteDTO, medecin: UserModel, patient
        ) -> None:
            """SMS envoyé au médecin."""
            nom_patient = "Patient"
            if patient and patient.user:
                nom_patient = (
                    f"{patient.user.first_name or ''} {patient.user.last_name or ''}".strip()
                    or patient.user.username
                    or "Patient"
                )
            message = (
                f"🚨 Alerte G-AutoBP\n"
                f"Patient : {nom_patient}\n"
                f"Tension : {alerte.systolique}/{alerte.diastolique} mmHg\n"
                f"Niveau : {alerte.niveau.value.upper()}\n"
                f"{alerte.message}"
            )
            await self._sms.envoyer(medecin.phone_number, message)
        
    async def _notifier_organisation(
            self, alerte: AlerteDTO, organisation, patient
        ) -> None:
            """SMS envoyé à l'organisation."""
            nom_patient = "Patient"
            if patient and patient.user:
                nom_patient = (
                    f"{patient.user.first_name or ''} {patient.user.last_name or ''}".strip()
                    or patient.user.username
                    or "Patient"
                )
            message = (
                f"🚨 Alerte G-AutoBP\n"
                f"Votre patient {nom_patient} a une tension {alerte.niveau.value.upper()} : "
                f"{alerte.systolique}/{alerte.diastolique} mmHg.\n"
                f"Un suivi est recommandé."
            )
            await self._sms.envoyer(organisation.telephone, message)