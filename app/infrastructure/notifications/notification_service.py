from app.application.dtos.alerte_dto import AlerteDTO
from app.application.services.notification_service import INotificationService
from app.core.exceptions import NotificationDeliveryError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.notifications.afriksms_channel import AfrikSmsChannel

from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.infrastructure.models.auth.role import RoleModel


class NotificationService(INotificationService):
    """
    Implémentation du service de notifications.
    Utilise AfrikSMS pour les SMS.
    """

    def __init__(self) -> None:
        self._sms = AfrikSmsChannel()

    async def envoyer_sms(self, telephone: str, message: str) -> None:
        await self._sms.envoyer(telephone, message)

    async def envoyer_push(self, token_fcm: str, message: str) -> None:
        # FCM à implémenter plus tard
        pass

    async def notifier_medecin(self, alerte: AlerteDTO) -> None:
        """
        Notifie le médecin référent du patient par SMS
        quand une alerte critique est déclenchée.
        """
        if not alerte.medecin_id:
            return

        async with AsyncSessionFactory() as session:
            result = await session.execute(
                select(UserModel)
                .where(UserModel.id == alerte.medecin_id)
                .options(
                    selectinload(UserModel.roles)
                    .selectinload(RoleModel.permissions)
                )
            )
            medecin = result.scalar_one_or_none()

            if not medecin or not medecin.phone_number:
                return

            message = (
                f"🚨 Alerte BP Monitor\n"
                f"Patient ID : {alerte.patient_id}\n"
                f"Tension : {alerte.systolique}/{alerte.diastolique} mmHg\n"
                f"Niveau : {alerte.niveau.upper()}\n"
                f"{alerte.message}"
            )

            await self._sms.envoyer(medecin.phone_number, message)