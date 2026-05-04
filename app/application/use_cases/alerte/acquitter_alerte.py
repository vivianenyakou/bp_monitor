from datetime import datetime

from app.application.dtos.alerte_dto import AcquitterAlerteDTO, AlerteDTO
from app.core.exceptions import AlertNotFoundError
from app.domain.enums.bp_category import StatutAlerte
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.alerte import AlerteModel


class AcquitterAlerteUseCase:
    """Le médecin acquitte une alerte — elle ne sera plus remontée."""

    async def executer(self, dto: AcquitterAlerteDTO) -> AlerteDTO:
        async with AsyncSessionFactory() as session:

            alerte = await session.get(AlerteModel, dto.alerte_id)
            if not alerte:
                raise AlertNotFoundError()

            alerte.statut = StatutAlerte.ACQUITTEE
            alerte.acquittee_le = datetime.utcnow()
            alerte.acquittee_par = dto.acquittee_par

            await session.commit()
            await session.refresh(alerte)

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