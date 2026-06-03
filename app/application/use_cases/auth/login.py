from datetime import datetime

from sqlalchemy import func, or_, select
from sqlalchemy.orm import selectinload

from app.application.dtos.auth_dto import LoginDTO, TokenDTO
from app.application.services.phone_number_formatter import normaliser_telephone_togo
from app.core.exceptions import InvalidCredentialsError
from app.infrastructure.auth.jwt_service import JWTService
from app.infrastructure.auth.password_service import PasswordService
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.role import RoleModel
from app.infrastructure.models.auth.token import TokenModel
from app.infrastructure.models.auth.user import UserModel

class LoginUseCase:

    async def executer(self, dto: LoginDTO) -> TokenDTO:
        async with AsyncSessionFactory() as session:

            # 1. Normaliser l'identifiant
            identifiant = normaliser_identifiant(dto.identifiant)
            identifiant_sans_plus = identifiant.replace("+", "")
            telephone_togo = normaliser_telephone_togo(identifiant)
            telephone_togo_sans_plus = (
                telephone_togo.replace("+", "") if telephone_togo else None
            )
            conditions = [
                UserModel.email == identifiant,
                UserModel.username == identifiant,
                # Avec +
                UserModel.phone_number == identifiant,
                # Sans + des deux cotes
                func.replace(UserModel.phone_number, "+", "")
                == identifiant_sans_plus,
            ]
            if telephone_togo:
                conditions.extend(
                    [
                        UserModel.phone_number == telephone_togo,
                        func.replace(UserModel.phone_number, "+", "")
                        == telephone_togo_sans_plus,
                    ]
                )

            # 2. Chercher l'utilisateur par email, phone ou username
            result = await session.execute(
                select(UserModel)
                .where(or_(*conditions))
                .options(
                    selectinload(UserModel.roles)
                    .selectinload(RoleModel.permissions)
                )
            )
            user = result.scalars().first()

            # 3. Vérifier existence et mot de passe
            if not user or not PasswordService.verifier(
                dto.password, user.password_hash
            ):
                raise InvalidCredentialsError("Identifiants incorrects.")

            # 4. Vérifier que le compte est actif
            if not user.is_active:
                raise InvalidCredentialsError("Compte désactivé.")

            # 5. Vérifier le lockout
            if user.lockout_enabled:
                raise InvalidCredentialsError(
                    "Compte verrouillé. Contactez l'administrateur."
                )

            # 6. Construire le payload JWT
            payload = JWTService.construire_payload(user)

            # 7. Générer les tokens
            access_token  = JWTService.creer_access_token(payload)
            refresh_token = JWTService.creer_refresh_token(payload)

            # 8. Révoquer les anciens tokens
            anciens = await session.execute(
                select(TokenModel).where(
                    TokenModel.user_id == user.id,
                    TokenModel.revoked == False,
                )
            )
            for ancien in anciens.scalars().all():
                ancien.revoked = True

            # 9. Sauvegarder le nouveau token
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
def normaliser_identifiant(identifiant: str) -> str:
    """Supprime espaces et tirets mais garde le +"""
    return identifiant.strip().replace(" ", "").replace("-", "")
