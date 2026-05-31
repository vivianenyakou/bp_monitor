from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.qrcode_dto import QRCodeInfoDTO, ValiderQRCodeDTO
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.multi_tenant.organisations import OrganisationModel
from app.infrastructure.models.multi_tenant.qrcode import QRCodeModel
from app.infrastructure.models.auth.user import UserModel

class ValiderQRCodeUseCase:
    """
    Valide un token QR code et retourne les informations
    de l'organisation et du médecin associés.
    """

    async def executer(self, dto: ValiderQRCodeDTO) -> QRCodeInfoDTO:
        async with AsyncSessionFactory() as session:

            # 1. Trouver le QR code
            result = await session.execute(
                select(QRCodeModel)
                .where(QRCodeModel.token == dto.token)
            )
            qrcode = result.scalar_one_or_none()

            # 2. Vérifier existence
            if not qrcode:
                return QRCodeInfoDTO(
                    token=             dto.token,
                    organisation_id=   0,
                    organisation_nom=  "",
                    organisation_code= "",
                    medecin_id=        None,
                    medecin_nom=       None,
                    est_valide=        False,
                    message=           "QR code invalide.",
                )

            # 3. Vérifier si actif
            if not qrcode.est_actif:
                return QRCodeInfoDTO(
                    token=             dto.token,
                    organisation_id=   0,
                    organisation_nom=  "",
                    organisation_code= "",
                    medecin_id=        None,
                    medecin_nom=       None,
                    est_valide=        False,
                    message=           "QR code désactivé.",
                )

            # 4. Vérifier expiration
            if qrcode.expire_le and datetime.utcnow() > qrcode.expire_le:
                return QRCodeInfoDTO(
                    token=             dto.token,
                    organisation_id=   0,
                    organisation_nom=  "",
                    organisation_code= "",
                    medecin_id=        None,
                    medecin_nom=       None,
                    est_valide=        False,
                    message=           "QR code expiré.",
                )

            # 5. Charger organisation
            organisation = await session.get(
                OrganisationModel, qrcode.organisation_id
            )

            # 6. Charger médecin
            medecin = None
            if qrcode.medecin_id:
                medecin = await session.get(UserModel, qrcode.medecin_id)

            # 7. Incrémenter le nombre de scans
            qrcode.nombre_scans += 1
            await session.commit()

            return QRCodeInfoDTO(
                token=             dto.token,
                organisation_id=   organisation.id,
                organisation_nom=  organisation.nom,
                organisation_code= organisation.code,
                medecin_id=        qrcode.medecin_id,
                medecin_nom=       f"Dr {medecin.first_name} {medecin.last_name}"
                                   if medecin else None,
                est_valide=        True,
                message=           None,
            )