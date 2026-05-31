from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.auth_dto import RegisterDTO, TokenDTO
from app.application.services.phone_number_formatter import normaliser_telephone_togo
from app.core.exceptions import ConflictError, NotFoundError
from app.infrastructure.auth.jwt_service import JWTService
from app.infrastructure.auth.password_service import PasswordService
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.role import RoleModel
from app.infrastructure.models.auth.token import TokenModel
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.bp.patient import PatientModel
from app.infrastructure.models.multi_tenant.organisations import OrganisationModel



class RegisterUseCase:
    """
    Crée un nouveau compte utilisateur avec le rôle patient par défaut.
    Si un organisation_code est fourni, rattache le patient à l'organisation.
    """

    async def executer(self, dto: RegisterDTO) -> TokenDTO:
        async with AsyncSessionFactory() as session:

            # 1. Vérifier que l'email n'existe pas déjà
            result = await session.execute(
                select(UserModel).where(UserModel.email == dto.email)
            )
            if result.scalar_one_or_none():
                raise ConflictError("Un compte avec cet email existe déjà.")

            # 2. Trouver l'organisation si un code est fourni
            organisation = None
            if dto.organisation_code:
                result = await session.execute(
                    select(OrganisationModel)
                    .where(OrganisationModel.code == dto.organisation_code.upper())
                    .where(OrganisationModel.est_actif == True)
                )
                organisation = result.scalar_one_or_none()
                if not organisation:
                    raise NotFoundError(
                        f"Organisation '{dto.organisation_code}' introuvable ou inactive."
                    )

            # 3. Récupérer le rôle patient par défaut
            result = await session.execute(
                select(RoleModel)
                .where(RoleModel.name == "patient")
                .options(selectinload(RoleModel.permissions))
            )
            role_patient = result.scalar_one_or_none()

            # 4. Créer l'utilisateur
            phone = normaliser_telephone_togo(dto.phone_number)
            user = UserModel(
                username=dto.username,
                email=dto.email,
                password_hash=PasswordService.hasher(dto.password),
                first_name=dto.first_name,
                last_name=dto.last_name,
                phone_number=phone,
                is_active=True,
                organisation_id=organisation.id if organisation else None,
            )
            if role_patient:
                user.roles = [role_patient]

            session.add(user)
            await session.flush()

            # 5. Créer automatiquement le profil patient
            patient = PatientModel(
                user_id=user.id,
                organisation_id=organisation.id if organisation else None,
            )
            session.add(patient)
            await session.flush()

            # 6. Générer les tokens
            payload = JWTService.construire_payload(user)
            access_token = JWTService.creer_access_token(payload)
            refresh_token = JWTService.creer_refresh_token(payload)

            # 7. Sauvegarder le token
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
