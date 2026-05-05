from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.auth_dto import LoginDTO, TokenDTO
from app.core.exceptions import InvalidCredentialsError
from app.infrastructure.auth.jwt_service import JWTService
from app.infrastructure.auth.password_service import PasswordService
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.role import RoleModel
from app.infrastructure.models.auth.token import TokenModel
from app.infrastructure.models.auth.user import UserModel
from sqlalchemy.orm import selectinload

class LoginUseCase:
    """Authentifie un utilisateur et retourne ses tokens JWT."""

    async def executer(self, dto: LoginDTO) -> TokenDTO:
        async with AsyncSessionFactory() as session:

            # 1. Trouver l'utilisateur par email
            result = await session.execute(
                select(UserModel)
                .where(UserModel.email == dto.email)
                .options(
                    selectinload(UserModel.roles).selectinload(RoleModel.permissions)
                )
            )
            user = result.scalar_one_or_none()

            # 2. Vérifier l'existence et le mot de passe
            if not user or not PasswordService.verifier(dto.password, user.password_hash):
                raise InvalidCredentialsError()

            # 3. Vérifier que le compte est actif
            if not user.is_active:
                raise InvalidCredentialsError("Compte désactivé.")

            # 4. Construire le payload JWT
            payload =JWTService.construire_payload(user)

            # 5. Générer les tokens
            access_token = JWTService.creer_access_token(payload)
            refresh_token = JWTService.creer_refresh_token(payload)

            # 6. Révoquer les anciens tokens
            anciens_tokens = await session.execute(
                select(TokenModel).where(
                    TokenModel.user_id == user.id,
                    TokenModel.revoked == False,
                )
            )
            for ancien in anciens_tokens.scalars().all():
                ancien.revoked = True

            # 7. Sauvegarder le nouveau token
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