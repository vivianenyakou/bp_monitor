from app.application.dtos.qrcode_dto import ValiderQRCodeDTO
from app.core.exceptions import NotFoundError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.multi_tenant.organisations import OrganisationModel
from app.infrastructure.models.multi_tenant.qrcode import QRCodeModel
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.pdf.qrcode_pdf import generer_pdf_qrcode
from app.core.config import get_settings

settings = get_settings()


class GenererPDFQRCodeUseCase:
    """Génère un PDF avec le QR code d'une organisation."""

    async def executer(self, qrcode_id: int) -> tuple[bytes, str]:
        """
        Retourne les bytes du PDF et le nom du fichier.
        """
        async with AsyncSessionFactory() as session:

            # 1. Trouver le QR code
            qrcode = await session.get(QRCodeModel, qrcode_id)
            if not qrcode:
                raise NotFoundError("QR code introuvable.")

            # 2. Charger l'organisation
            organisation = await session.get(
                OrganisationModel, qrcode.organisation_id
            )

            # 3. Charger le médecin
            medecin = None
            if qrcode.medecin_id:
                medecin = await session.get(UserModel, qrcode.medecin_id)

            # 4. Formater la date d'expiration
            expire_le = None
            if qrcode.expire_le:
                expire_le = qrcode.expire_le.strftime("%d/%m/%Y")

            # 5. Construire l'URL
            url = f"{settings.base_url}/join?token={qrcode.token}"

            # 6. Générer le PDF
            pdf_bytes = generer_pdf_qrcode(
                url=              url,
                organisation_nom= organisation.nom if organisation else "Organisation",
                medecin_nom=      f"Dr {medecin.first_name} {medecin.last_name}"
                                  if medecin else None,
                description=      qrcode.description,
                expire_le=        expire_le,
                nombre_scans=     qrcode.nombre_scans,
            )

            # 7. Nom du fichier
            nom_fichier = f"qrcode_{organisation.code if organisation else qrcode_id}.pdf"

            return pdf_bytes, nom_fichier