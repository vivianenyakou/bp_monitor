from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.invitation_dto import ChoisirMedecinDTO
from app.core.exceptions import DoctorNotFoundError, PatientNotFoundError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.bp.patient import PatientModel
from app.infrastructure.models.auth.role import RoleModel
from app.infrastructure.models.auth.user import UserModel


class ChoisirMedecinUseCase:
    async def executer(self, dto: ChoisirMedecinDTO) -> dict:
        async with AsyncSessionFactory() as session:

            # 1. Vérifier le patient (dto.patient_id est le user_id)
            result = await session.execute(
                select(PatientModel).where(PatientModel.user_id == dto.patient_id)
            )
            patient = result.scalar_one_or_none()
            if not patient:
                raise PatientNotFoundError()

            # 2. Vérifier le médecin
            result = await session.execute(
                select(UserModel)
                .where(UserModel.id == dto.medecin_id)
                .where(UserModel.is_active == True)
                .options(selectinload(UserModel.roles))
            )
            medecin = result.scalar_one_or_none()

            if not medecin or "medecin" not in medecin.role_names:
                raise DoctorNotFoundError()

            # 3. Lier le patient au médecin
            patient.medecin_id = dto.medecin_id
            await session.commit()

            return {
                "message": f"Vous êtes maintenant suivi par le Médecin "
                           f"{medecin.first_name} {medecin.last_name}.",
                "medecin_id": medecin.id,
                "patient_id": patient.id,
            }