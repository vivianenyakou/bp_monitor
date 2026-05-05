from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.auth_dto import RegisterDTO, TokenDTO, UtilisateurDTO
from app.core.exceptions import ConflictError
from app.infrastructure.auth.jwt_service import JWTService
from app.infrastructure.auth.password_service import PasswordService
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.role import RoleModel
from app.infrastructure.models.auth.token import TokenModel
from app.infrastructure.models.auth.user import UserModel
from sqlalchemy.orm import selectinload


class RegisterUseCase:
    """Crée un nouveau compte utilisateur avec le rôle patient par défaut."""

    async def executer(self, dto: RegisterDTO) -> TokenDTO:
        async with AsyncSessionFactory() as session:

            # 1. Vérifier que l'email n'existe pas déjà
            result = await session.execute(
                select(UserModel).where(UserModel.email == dto.email)
            )
            if result.scalar_one_or_none():
                raise ConflictError("Un compte avec cet email existe déjà.")

            # 2. Récupérer le rôle patient par défaut
            result = await session.execute(
                select(RoleModel)
                .where(RoleModel.name == "patient")
                .options(selectinload(RoleModel.permissions))
            )
            role_patient = result.scalar_one_or_none()

            # 3. Créer l'utilisateur
            user = UserModel(
                username=dto.username,
                email=dto.email,
                password_hash=PasswordService.hasher(dto.password),
                first_name=dto.first_name,
                last_name=dto.last_name,
                phone_number=dto.phone_number,
                is_active=True,
            )
            if role_patient:
                user.roles = [role_patient]

            session.add(user)
            await session.flush()

            # 4. Générer les tokens
            payload = {
                "sub": str(user.id),
                "email": user.email,
                "roles": ["patient"],
            }
            access_token = JWTService.creer_access_token(payload)
            refresh_token = JWTService.creer_refresh_token(payload)

            # 5. Sauvegarder le token
            token = TokenModel(
                user_id=user.id,
                token=access_token,
                refresh_token=refresh_token,
                expires_at=datetime.utcnow(),
                revoked=False,
            )
            session.add(token)
            await session.commit()

            return TokenDTO(
                access_token=access_token,
                refresh_token=refresh_token,
            )