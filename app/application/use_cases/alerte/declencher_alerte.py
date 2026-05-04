from app.application.dtos.alerte_dto import AlerteDTO
from app.application.services.notification_service import INotificationService
from app.core.exceptions import AlertNotFoundError
from app.domain.enums.bp_category import StatutAlerte
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.alerte import AlerteModel

from sqlalchemy import select


class DeclencherAlerteUseCase:
    """
    Envoie les notifications d'une alerte en attente
    au médecin via SMS et push.
    """

    def __init__(self, notification_service: INotificationService) -> None:
        self._notifications = notification_service

    async def executer(self, alerte_id: int) -> AlerteDTO:
        async with AsyncSessionFactory() as session:

            alerte = await session.get(AlerteModel, alerte_id)
            if not alerte:
                raise AlertNotFoundError()

            # Marquer comme envoyée
            alerte.statut = StatutAlerte.ENVOYEE
            await session.commit()

            dto = self._to_dto(alerte)

            # Notifier le médecin
            await self._notifications.notifier_medecin(dto)

            return dto

    def _to_dto(self, alerte: AlerteModel) -> AlerteDTO:
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
            acquittee_le=alerte.acquittee_le,
            acquittee_par=alerte.acquittee_par,
        )