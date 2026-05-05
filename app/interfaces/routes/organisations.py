from fastapi import APIRouter, Depends, HTTPException, status

from app.application.dtos.organisation_dto import CreerOrganisationDTO
from app.application.use_cases.multi_tenant.creer_organisation import CreerOrganisationUseCase
from app.application.use_cases.multi_tenant.lister_organisantions import ListerOrganisationsUseCase
from app.core.exceptions import BPMonitorException
from app.domain.enums.role_enum import RoleUtilisateur
from app.interfaces.dependencies.authorization import require_any_role, require_super_admin
from app.interfaces.schemas.organisation import CreerOrganisationSchema, OrganisationSchema


router = APIRouter(prefix="/organisations", tags=["Organisations"])


@router.post(
    "/",
    response_model=OrganisationSchema,
    status_code=status.HTTP_201_CREATED,
    summary="Créer une organisation (clinique/hôpital)",
)
async def creer_organisation(
    body: CreerOrganisationSchema,
    _=Depends(require_super_admin(), require_any_role(RoleUtilisateur.SUPER_ADMIN)),
):
    """Crée une nouvelle clinique ou hôpital. Réservé au super admin."""
    try:
        use_case = CreerOrganisationUseCase()
        dto = CreerOrganisationDTO(
            nom=body.nom,
            code=body.code,
            adresse=body.adresse,
            telephone=body.telephone,
            email=body.email,
            nif_structure=body.nif_structure,
            raison_sociale=body.raison_sociale,
        )
        return await use_case.executer(dto)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get(
    "/",
    response_model=list[OrganisationSchema],
    summary="Lister les organisations",
)
async def lister_organisations(
    _=Depends(require_super_admin(), require_any_role(RoleUtilisateur.SUPER_ADMIN)),
):
    try:
        use_case = ListerOrganisationsUseCase()
        return await use_case.executer()
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)