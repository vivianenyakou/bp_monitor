from fastapi import APIRouter, Depends, HTTPException, status

from app.application.dtos.organisation_dto import CreerOrganisationDTO
from app.application.use_cases.multi_tenant.creer_organisation import CreerOrganisationUseCase
from app.application.use_cases.multi_tenant.desactiver_organisation import ChangerStatutOrganisationUseCase
from app.application.use_cases.multi_tenant.desactiver_organisation import ChangerStatutOrganisationUseCase
from app.application.use_cases.multi_tenant.lister_organisantions import ListerOrganisationsUseCase
from app.core.exceptions import BPMonitorException
from app.domain.enums.role_enum import RoleUtilisateur
from app.domain.enums.role_enum import RoleUtilisateur
from app.infrastructure.models.auth.user import UserModel
from app.interfaces.dependencies.authorization import require_any_role, require_super_admin
from app.interfaces.schemas.organisation import CreerOrganisationSchema, OrganisationSchema


router = APIRouter(prefix="/organisations", tags=["Organisations"])


@router.get(
    "/publiques",
    response_model=list[OrganisationSchema],
    summary="Lister les organisations (public)",
)
async def lister_organisations_publiques():
    """Retourne les organisations actives — accessible sans authentification (inscription)."""
    try:
        use_case = ListerOrganisationsUseCase()
        return await use_case.executer()
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post(
    "/",
    response_model=OrganisationSchema,
    status_code=status.HTTP_201_CREATED,
    summary="Créer une organisation (clinique/hôpital)",
)
async def creer_organisation(
    body: CreerOrganisationSchema,
    _=Depends(require_any_role(RoleUtilisateur.SUPER_ADMIN, RoleUtilisateur.ADMIN)),
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
    _=Depends(require_any_role(RoleUtilisateur.SUPER_ADMIN, RoleUtilisateur.ADMIN)),
):
    try:
        use_case = ListerOrganisationsUseCase()
        return await use_case.executer()
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    

@router.patch(
    "/organisation/{id}/statut",
    summary="Activer ou désactiver une organisation",
)
async def changer_statut_organisation(
    organisation_id: int,
    est_actif: bool,
    current_user: UserModel = Depends(require_any_role(RoleUtilisateur.ADMIN, RoleUtilisateur.SUPER_ADMIN)),
):
    try:
        use_case = ChangerStatutOrganisationUseCase()
        return await use_case.executer(organisation_id, est_actif)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)