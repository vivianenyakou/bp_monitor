import secrets
from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.qrcode_dto import GenererQRCodeDTO, QRCodeDTO
from app.core.config import get_settings
from app.core.exceptions import NotFoundError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth import token
from app.infrastructure.models.multi_tenant.organisations import OrganisationModel
from app.infrastructure.models.multi_tenant.qrcode import QRCodeModel
from app.infrastructure.models.auth.user import UserModel

settings = get_settings()


class GenererQRCodeUseCase:
    """
    Génère un QR code unique pour une organisation.
    Optionnellement lié à un médecin spécifique.
    """

    async def executer(self, dto: GenererQRCodeDTO) -> QRCodeDTO:
        async with AsyncSessionFactory() as session:

            # 1. Vérifier l'organisation
            organisation = await session.get(
                OrganisationModel, dto.organisation_id
            )
            if not organisation:
                raise NotFoundError("Organisation introuvable.")

            # 2. Vérifier le médecin si fourni
            medecin = None
            if dto.medecin_id:
                medecin = await session.get(UserModel, dto.medecin_id)
                if not medecin:
                    raise NotFoundError("Médecin introuvable.")

            # 3. Générer un token unique et sécurisé
            token = secrets.token_urlsafe(32)

            # 4. Calculer l'expiration
            expire_le = None
            if dto.expire_dans_jours:
                expire_le = datetime.utcnow() + timedelta(
                    days=dto.expire_dans_jours
                )

            # 5. Créer le QR code
            qrcode = QRCodeModel(
                token=           token,
                organisation_id= dto.organisation_id,
                medecin_id=      dto.medecin_id,
                est_actif=       True,
                expire_le=       expire_le,
                nombre_scans=    0,
                description=     dto.description,
            )
            session.add(qrcode)
            await session.commit()
            await session.refresh(qrcode)

            # 6. Construire l'URL
            url = f"{settings.base_url}/join?token={token}"

            return QRCodeDTO(
                id=               qrcode.id,
                token=            token,
                organisation_id=  dto.organisation_id,
                organisation_nom= organisation.nom,
                medecin_id=       dto.medecin_id,
                medecin_nom=      f"Dr {medecin.first_name} {medecin.last_name}"
                                  if medecin else None,
                est_actif=        True,
                expire_le=        expire_le,
                nombre_scans=     0,
                description=      dto.description,
                url=              url,
            )