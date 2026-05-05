from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.auth_dto import CreerUtilisateurDTO
from app.core.exceptions import ConflictError, NotFoundError
from app.domain.enums.role_enum import RoleUtilisateur
from app.infrastructure.auth.password_service import PasswordService
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.role import RoleModel
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.bp.patient import PatientModel



class CreerUtilisateurUseCase:
    async def executer(self, dto: CreerUtilisateurDTO) -> dict:
        async with AsyncSessionFactory() as session:

            # 1. Vérifier que l'email n'existe pas
            result = await session.execute(
                select(UserModel).where(UserModel.email == dto.email)
            )
            if result.scalar_one_or_none():
                raise ConflictError("Un compte avec cet email existe déjà.")

            # 2. Vérifier le rôle
            result = await session.execute(
                select(RoleModel)
                .where(RoleModel.name == dto.role)
                .options(selectinload(RoleModel.permissions))
            )
            role = result.scalar_one_or_none()
            if not role:
                raise NotFoundError(f"Rôle '{dto.role}' introuvable.")

            # 3. Normaliser le téléphone
            phone = None
            if dto.phone_number:
                phone = dto.phone_number.strip().replace(" ", "").replace("-", "")

            # 4. Créer l'utilisateur
            user = UserModel(
                username=dto.username,
                email=dto.email,
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

            # 5. Créer le profil patient si rôle = patient
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
                "message": f"Utilisateur créé avec le rôle '{dto.role}'.",
            }