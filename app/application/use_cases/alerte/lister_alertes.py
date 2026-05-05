from uuid import UUID

from sqlalchemy import select

from app.application.dtos.alerte_dto import AlerteDTO
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.alerte import AlerteModel


class ListerAlertesUseCase:

    async def executer(
        self,
        patient_id: int | None = None,
        medecin_id: int | None = None,
    ) -> list[AlerteDTO]:
        async with AsyncSessionFactory() as session:

            query = select(AlerteModel).order_by(
                AlerteModel.declenchee_le.desc()
            )

            # Filtrer par patient
            if patient_id:
                query = query.where(AlerteModel.patient_id == patient_id)

            # Filtrer par médecin
            if medecin_id:
                query = query.where(AlerteModel.medecin_id == medecin_id)

            result = await session.execute(query)
            alertes = result.scalars().all()

            return [
                AlerteDTO(
                    id=a.id,
                    patient_id=a.patient_id,
                    medecin_id=a.medecin_id,
                    systolique=a.systolique,
                    diastolique=a.diastolique,
                    niveau=a.niveau,
                    statut=a.statut,
                    message=a.message,
                    declenchee_le=a.declenchee_le,
                    acquittee_le=a.acquittee_le,
                    acquittee_par=a.acquittee_par,
                )
                for a in alertes
            ]