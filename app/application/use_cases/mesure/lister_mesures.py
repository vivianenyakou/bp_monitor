from app.application.dtos.mesure_dto import MesureDTO
from app.core.exceptions import PatientNotFoundError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.mesure import MesureModel
from app.infrastructure.models.bp.patient import PatientModel

from sqlalchemy import select


class ListerMesuresUseCase:
    """Retourne toutes les mesures d'un patient."""

    async def executer(self, patient_id: int) -> list[MesureDTO]:
        async with AsyncSessionFactory() as session:

            # patient_id est le user_id
            lookup = await session.execute(
                select(PatientModel).where(PatientModel.user_id == patient_id)
            )
            patient = lookup.scalar_one_or_none()
            if not patient:
                raise PatientNotFoundError()

            result = await session.execute(
                select(MesureModel)
                .where(MesureModel.patient_id == patient.id)
                .order_by(MesureModel.prise_le.desc())
            )
            models = result.scalars().all()

            return [
                MesureDTO(
                    id=m.id,
                    patient_id=m.patient_id,
                    systolique=m.systolique,
                    diastolique=m.diastolique,
                    pouls=m.pouls,
                    periode=m.periode,
                    jour=m.jour,
                    numero_mesure=m.numero_mesure,
                    categorie=m.categorie,
                    session_id=m.session_id,
                    prise_le=m.prise_le,
                    notes=m.notes,
                )
                for m in models
            ]