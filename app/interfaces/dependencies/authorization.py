from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import InvalidTokenError
from app.domain.enums.role_enum import RoleUtilisateur
from app.infrastructure.auth.jwt_service import JWTService
from app.infrastructure.db.session import get_db_session
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.auth.role import RoleModel

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    session: AsyncSession = Depends(get_db_session),
) -> UserModel:
    """
    Décode le token JWT et retourne l'utilisateur connecté.
    Utilisé comme dépendance de base pour toutes les routes protégées.
    """
    try:
        payload = JWTService.decoder_token(credentials.credentials)
        user_id = int(payload.get("sub"))
        organisation_id = payload.get("organisation_id")
    except (InvalidTokenError, ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide ou expiré.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Charger l'utilisateur avec ses rôles et permissions
    result = await session.execute(
        select(UserModel)
        .where(UserModel.id == user_id)
        .where(UserModel.is_active == True)
        .options(
            selectinload(UserModel.roles).selectinload(RoleModel.permissions)
        )
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Utilisateur introuvable ou désactivé.",
        )
    if user.organisation_id != organisation_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Organisation invalide.",
        )
    return user


def require_any_role(*allowed_roles: str):

    async def wrapper(
        current_user: UserModel = Depends(get_current_user),
    ) -> UserModel:
        role_names = {r.name for r in current_user.roles}

        if not any(r in role_names for r in allowed_roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Accès refusé. Rôles requis : {', '.join(allowed_roles)}",
            )
        return current_user

    return wrapper

def require_super_admin():
    """Réservé au super admin uniquement."""
    async def wrapper(
        current_user: UserModel = Depends(get_current_user),
    ) -> UserModel:
        if not current_user.has_role(RoleUtilisateur.SUPER_ADMIN):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Accès réservé au super administrateur.",
            )
        return current_user
    return wrapper

def require_permission(permission: str):
    """
    Protège une route — l'utilisateur doit avoir la permission spécifique.

    Usage :
        @router.post("/", dependencies=[Depends(require_permission("creer_mesure"))])
    """
    async def wrapper(
        current_user: UserModel = Depends(get_current_user),
    ) -> UserModel:
        if not current_user.has_permission(permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission refusée : '{permission}' requise.",
            )
        return current_user

    return wrapper
