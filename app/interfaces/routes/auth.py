from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.application.dtos.auth_dto import LoginDTO, RegisterDTO
from app.application.use_cases.auth.login import LoginUseCase
from app.application.use_cases.auth.register import RegisterUseCase
from app.core.exceptions import BPMonitorException
from app.infrastructure.auth.jwt_service import JWTService
from app.infrastructure.models.auth.user import UserModel
from app.interfaces.dependencies.authorization import get_current_user
from app.interfaces.schemas.auth import (
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
        dto = LoginDTO(email=body.email, password=body.password)
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
    }