from abc import ABC, abstractmethod

from app.application.dtos.alerte_dto import AlerteDTO


class INotificationService(ABC):
    """
    Interface du service de notifications.
    Implémentée dans Infrastructure (Twilio, FCM).
    """

    @abstractmethod
    async def envoyer_sms(self, telephone: str, message: str) -> None: ...

    @abstractmethod
    async def envoyer_push(self, token_fcm: str, message: str) -> None: ...

    @abstractmethod
    async def notifier_medecin(self, alerte: AlerteDTO) -> None: ...