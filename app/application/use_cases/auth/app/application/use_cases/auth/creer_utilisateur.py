from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.auth_dto import CreerUtilisateurDTO
from app.application.services.phone_number_formatter import normaliser_telephone_togo
from app.core.exceptions import ApplicationException, ConflictError, NotFoundError
from app.domain.enums.role_enum import RoleUtilisateur
from app.infrastructure.auth.password_service import PasswordService
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.role import RoleModel
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.bp.patient import PatientModel


class CreerUtilisateurUseCase:
    async def executer(self, dto: CreerUtilisateurDTO) -> dict:
        async with AsyncSessionFactory() as session:
            email = dto.email.strip() if dto.email else None
            if email:
                result = await session.execute(
                    select(UserModel).where(UserModel.email == email)
                )
                if result.scalar_one_or_none():
                    raise ConflictError("Un compte avec cet email existe deja.")

            result = await session.execute(
                select(RoleModel)
                .where(RoleModel.name == dto.role)
                .options(selectinload(RoleModel.permissions))
            )
            role = result.scalar_one_or_none()
            if not role:
                raise NotFoundError(f"Role '{dto.role}' introuvable.")

            phone = normaliser_telephone_togo(dto.phone_number)
            if not phone:
                raise ApplicationException("Le numero de telephone est obligatoire.")

            user = UserModel(
                username=dto.username.strip() if dto.username else None,
                email=email,
                password_hash=PasswordService.hasher(dto.password),
                first_name=dto.first_name,
                last_name=dto.last_name,
                phone_number=phone,
                is_active=True,
                organisation_id=dto.organisation_id,
            )
            user.roles = [role]
            session.add(user)
            await session.flush()

            if dto.role == RoleUtilisateur.PATIENT:
                patient = PatientModel(
                    user_id=user.id,
                    organisation_id=dto.organisation_id,
                )
                session.add(patient)

            await session.commit()
            await session.refresh(user)

            return {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "role": dto.role,
                "organisation_id": user.organisation_id,
                "message": f"Utilisateur cree avec le role '{dto.role}'.",
            }
