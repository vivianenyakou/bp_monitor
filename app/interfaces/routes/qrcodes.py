from fastapi import APIRouter, HTTPException, status, Depends

from app.application.dtos.qrcode_dto import (
    GenererQRCodeDTO,
    ValiderQRCodeDTO,
)
from app.application.use_cases.qrcode.generer_qrcode import GenererQRCodeUseCase
from app.application.use_cases.qrcode.valider_qrcode import ValiderQRCodeUseCase
from app.application.use_cases.qrcode.lister_qrcodes import ListerQRCodesUseCase
from app.core.exceptions import BPMonitorException
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.multi_tenant.qrcode import QRCodeModel
from app.infrastructure.models.multi_tenant.qrcode import QRCodeModel
from app.infrastructure.models.auth.user import UserModel
from app.interfaces.dependencies.authorization import require_any_role
from app.interfaces.schemas.qrcode import (
    GenererQRCodeSchema,
    QRCodeSchema,
    QRCodeInfoSchema,
)

from fastapi.responses import Response
from app.application.use_cases.qrcode.generer_pdf import GenererPDFQRCodeUseCase

from app.infrastructure.pdf.qrcode_pdf import  generer_pdf_qrcode
from reportlab.lib.pagesizes import A4


router = APIRouter(prefix="/qrcodes", tags=["QR Codes"])


@router.post(
    "/generer",
    response_model=QRCodeSchema,
    status_code=status.HTTP_201_CREATED,
    summary="Générer un QR code pour une organisation",
)
async def generer_qrcode(
    body: GenererQRCodeSchema,
    current_user: UserModel = Depends(require_any_role("admin", "super_admin")),
):
    """
    Génère un QR code unique pour une organisation.
    Optionnellement lié à un médecin spécifique.
    Réservé aux admins.
    """
    try:
        use_case = GenererQRCodeUseCase()
        dto = GenererQRCodeDTO(
            organisation_id=   body.organisation_id,
            medecin_id=        body.medecin_id,
            description=       body.description,
            expire_dans_jours= body.expire_dans_jours,
        )
        return await use_case.executer(dto)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get(
    "/valider/{token}",
    response_model=QRCodeInfoSchema,
    summary="Valider un token QR code",
)
async def valider_qrcode(token: str):
    """
    Valide un token QR et retourne les infos
    de l'organisation et du médecin.
    Accessible sans authentification.
    """
    try:
        use_case = ValiderQRCodeUseCase()
        return await use_case.executer(ValiderQRCodeDTO(token=token))
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get(
    "/organisation/{organisation_id}",
    response_model=list[QRCodeSchema],
    summary="Lister les QR codes d'une organisation",
)
async def lister_qrcodes(
    organisation_id: int,
    current_user: UserModel = Depends(require_any_role("admin", "super_admin")),
):
    """Liste tous les QR codes d'une organisation."""
    try:
        use_case = ListerQRCodesUseCase()
        return await use_case.executer(organisation_id)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.patch(
    "/{qrcode_id}/desactiver",
    summary="Désactiver un QR code",
)
async def desactiver_qrcode(
    qrcode_id: int,
    current_user: UserModel = Depends(require_any_role("admin", "super_admin")),
):
    """Désactive un QR code — il ne sera plus scannable."""
    try:
        async with AsyncSessionFactory() as session:
            qrcode = await session.get(QRCodeModel, qrcode_id)
            if not qrcode:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="QR code introuvable.",
                )
            qrcode.est_actif = False
            await session.commit()
            return {"message": "QR code désactivé avec succès."}
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)

@router.get(
    "/{qrcode_id}/pdf",
    summary="Télécharger le PDF du QR code",
)
async def telecharger_pdf(
    qrcode_id: int,
    current_user: UserModel = Depends(require_any_role("admin", "super_admin")),
):
    """
    Génère et retourne un PDF avec le QR code.
    Prêt à imprimer et afficher en clinique.
    """
    try:
        use_case  = GenererPDFQRCodeUseCase()
        pdf_bytes, nom_fichier = await use_case.executer(qrcode_id)

        return Response(
            content=     pdf_bytes,
            media_type=  "application/pdf",
            headers={
                "Content-Disposition": f"attachment; filename={nom_fichier}",
                "Content-Length":      str(len(pdf_bytes)),
            },
        )
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)