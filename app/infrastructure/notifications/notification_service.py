from app.application.dtos.alerte_dto import AlerteDTO
from app.application.services.notification_service import INotificationService
from app.core.exceptions import NotificationDeliveryError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.bp.patient import PatientModel
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
                await self._notifier_medecin(alerte, medecin)

    async def _notifier_patient(
        self, alerte: AlerteDTO, user: UserModel
    ) -> None:
        """SMS envoyé au patient."""
        messages = {
            "hypertension": (
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
        self, alerte: AlerteDTO, medecin: UserModel
    ) -> None:
        """SMS envoyé au médecin."""
        message = (
            f"🚨 Alerte G-AutoBP\n"
            f"Patient : {alerte.patient_nom_complet}\n"
            f"Tension : {alerte.systolique}/{alerte.diastolique} mmHg\n"
            f"Niveau : {alerte.niveau.upper()}\n"
            f"{alerte.message}"
        )
        await self._sms.envoyer(medecin.phone_number, message)