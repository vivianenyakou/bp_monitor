from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer

from app.application.dtos.auth_dto import CreerUtilisateurDTO, LoginDTO, RegisterDTO
from app.application.use_cases.auth.app.application.use_cases.auth.changer_statut_utilisateur import ChangerStatutUtilisateurUseCase
from app.application.use_cases.auth.app.application.use_cases.auth.creer_utilisateur import CreerUtilisateurUseCase
from app.application.use_cases.auth.login import LoginUseCase
from app.application.use_cases.auth.register import RegisterUseCase
from app.domain.enums.role_enum import RoleUtilisateur
from app.domain.enums.role_enum import RoleUtilisateur
from app.core.exceptions import BPMonitorException
from app.infrastructure.models.auth.user import UserModel
from app.interfaces.dependencies.authorization import get_current_user, require_any_role
from app.interfaces.schemas.auth import (
    CreerUtilisateurSchema,
    LoginSchema,
    RegisterSchema,
    TokenSchema,
)

router = APIRouter(prefix="/auth", tags=["Authentification"])
security = HTTPBearer()


@router.post(
    "/register",
    response_model=TokenSchema,
    status_code=status.HTTP_201_CREATED,
    summary="Créer un compte",
)
async def register(body: RegisterSchema):
    """Crée un nouveau compte patient et retourne les tokens JWT."""
    try:
        use_case = RegisterUseCase()
        dto = RegisterDTO(
            username=body.username,
            email=body.email,
            password=body.password,
            first_name=body.first_name,
            last_name=body.last_name,
            phone_number=body.phone_number,
            birth_date=body.birth_date,
            organisation_code=body.organisation_code,
            qrcode_token=body.qr_code_token,
        )
        return await use_case.executer(dto)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post(
    "/login",
    response_model=TokenSchema,
    summary="Se connecter",
)
async def login(body: LoginSchema):
    """Authentifie un utilisateur et retourne les tokens JWT."""
    try:
        use_case = LoginUseCase()
        dto = LoginDTO(identifiant=body.identifiant,password=body.password)
        return await use_case.executer(dto)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get(
    "/me",
    summary="Utilisateur connecté",
)
async def me(
    current_user: UserModel = Depends(get_current_user),
):
    """Retourne les informations de l'utilisateur connecté."""
    return {
        "id": current_user.id,
        "email": current_user.email,
        "username": current_user.username,
        "roles": current_user.role_names,
        "permissions": current_user.permission_names,
        "first_name": current_user.first_name,
        "last_name": current_user.last_name,
        "phone_number": current_user.phone_number,
        "organisation_code": current_user.organisation_id,
    }

@router.post(
    "/utilisateurs",
    status_code=status.HTTP_201_CREATED,
    summary="Créer un utilisateur avec un rôle",
)
async def creer_utilisateur(
    body: CreerUtilisateurSchema,
    current_user: UserModel = Depends(require_any_role(RoleUtilisateur.ADMIN, RoleUtilisateur.SUPER_ADMIN)),
):
    try:
        use_case = CreerUtilisateurUseCase()
        dto = CreerUtilisateurDTO(
            username=body.username,
            email=body.email,
            password=body.password,
            role=body.role,
            first_name=body.first_name,
            last_name=body.last_name,
            phone_number=body.phone_number,
            organisation_id=body.organisation_id,
            specialite=body.specialite,
        )
        return await use_case.executer(dto)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    
@router.patch(
    "/utilisateurs/{user_id}/statut",
    summary="Activer ou désactiver un utilisateur",
)
async def changer_statut_utilisateur(
    user_id: int,
    is_active: bool,
    current_user: UserModel = Depends(require_any_role(RoleUtilisateur.ADMIN, RoleUtilisateur.SUPER_ADMIN)),
):
    try:
        use_case = ChangerStatutUtilisateurUseCase()
        return await use_case.executer(user_id, is_active)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)