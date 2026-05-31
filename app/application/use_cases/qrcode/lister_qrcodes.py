import secrets

from sqlalchemy import select

from app.application.dtos.qrcode_dto import QRCodeDTO
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.multi_tenant.organisations import OrganisationModel
from app.infrastructure.models.multi_tenant.qrcode import QRCodeModel
from app.core.config import get_settings

settings = get_settings()

class ListerQRCodesUseCase:
    """Liste tous les QR codes d'une organisation."""

    async def executer(self, organisation_id: int) -> list[QRCodeDTO]:
        async with AsyncSessionFactory() as session:

            result = await session.execute(
                select(QRCodeModel)
                .where(QRCodeModel.organisation_id == organisation_id)
                .order_by(QRCodeModel.id.desc())
            )
            qrcodes = result.scalars().all()

            resultats = []
            for qr in qrcodes:
                organisation = await session.get(
                    OrganisationModel, qr.organisation_id
                )
                medecin = None
                if qr.medecin_id:
                    medecin = await session.get(UserModel, qr.medecin_id)
                # 3. Générer un token unique et sécurisé
                token = secrets.token_urlsafe(32)
                url = f"{settings.base_url}/join?token={token}"


                resultats.append(QRCodeDTO(
                    id=               qr.id,
                    token=            token,
                    organisation_id=  qr.organisation_id,
                    organisation_nom= organisation.nom if organisation else "",
                    medecin_id=       qr.medecin_id,
                    medecin_nom=      f"Dr {medecin.first_name} {medecin.last_name}"
                                      if medecin else None,
                    est_actif=        qr.est_actif,
                    expire_le=        qr.expire_le,
                    nombre_scans=     qr.nombre_scans,
                    description=      qr.description,
                    url=              url,
                ))

            return resultats