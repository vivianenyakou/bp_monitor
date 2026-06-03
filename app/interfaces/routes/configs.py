
from select import select
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select

from fastapi import APIRouter, Depends, HTTPException
from app.core.exceptions import BPMonitorException
from app.domain.enums.role_enum import RoleUtilisateur

from app.infrastructure.db.seed import CONFIGS_DEFAUT
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.multi_tenant.system_config import SystemConfigModel
from app.infrastructure.models.multi_tenant.system_config import SystemConfigModel
from app.infrastructure.services.config_service import ConfigService
from app.interfaces.dependencies.authorization import require_any_role
from app.interfaces.schemas.config import (
    BulkConfigSchema,
    ConfigSchema,
    MettreAJourConfigSchema,
)

router = APIRouter(prefix="/configs", tags=["Configuration"])


@router.get(
    "/organisation/{organisation_id}",
    summary="Lister toutes les configs d'une organisation",
)
async def lister_configs(
    organisation_id: int,
    current_user: UserModel = Depends(
        require_any_role(RoleUtilisateur.ADMIN, RoleUtilisateur.SUPER_ADMIN)
    ),
):
    """
    Retourne toutes les configurations de l'organisation.
    Inclut les valeurs actuelles et les descriptions.
    """
    try:
        async with AsyncSessionFactory() as session:
            result = await session.execute(
                select(SystemConfigModel)
                .where(SystemConfigModel.organisation_id == organisation_id)
                .order_by(SystemConfigModel.cle)
            )
            configs = result.scalars().all()

            # Fusionner avec les défauts
            configs_map = {c.cle: c.valeur for c in configs}
            resultats   = []

            for cle, data in CONFIGS_DEFAUT.items():
                resultats.append({
                    "cle":         cle,
                    "valeur":      configs_map.get(cle, data["valeur"]),
                    "valeur_defaut": data["valeur"],
                    "description": data["description"],
                })

            return resultats
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.patch(
    "/organisation/{organisation_id}/{cle}",
    summary="Mettre à jour une config",
)
async def mettre_a_jour_config(
    organisation_id: int,
    cle:             str,
    body:            MettreAJourConfigSchema,
    current_user:    UserModel = Depends(
        require_any_role(RoleUtilisateur.ADMIN, RoleUtilisateur.SUPER_ADMIN)
    ),
):
    """Met à jour une configuration spécifique."""
    try:
        if cle not in CONFIGS_DEFAUT:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Clé de configuration inconnue : '{cle}'",
            )

        await ConfigService.set(organisation_id, cle, body.valeur)
        return {
            "message":    f"Configuration '{cle}' mise à jour.",
            "cle":        cle,
            "valeur":     body.valeur,
            "organisation_id": organisation_id,
        }
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post(
    "/organisation/{organisation_id}/bulk",
    summary="Mettre à jour plusieurs configs en une fois",
    status_code=status.HTTP_201_CREATED,
)
async def bulk_update_configs(
    organisation_id: int,
    body:            BulkConfigSchema,
    current_user:    UserModel = Depends(
        require_any_role(RoleUtilisateur.ADMIN, RoleUtilisateur.SUPER_ADMIN)
    ),
):
    """Met à jour plusieurs configurations en une seule requête."""
    try:
        erreurs  = []
        updated  = []

        for cle, valeur in body.configs.items():
            if cle not in CONFIGS_DEFAUT:
                erreurs.append(f"Clé inconnue : '{cle}'")
                continue
            await ConfigService.set(organisation_id, cle, valeur)
            updated.append(cle)

        return {
            "message":  f"{len(updated)} configuration(s) mise(s) à jour.",
            "updated":  updated,
            "erreurs":  erreurs,
        }
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post(
    "/organisation/{organisation_id}/initialiser",
    summary="Initialiser les configs par défaut",
    status_code=status.HTTP_201_CREATED,
)
async def initialiser_configs(
    organisation_id: int,
    current_user:    UserModel = Depends(
        require_any_role(RoleUtilisateur.ADMIN, RoleUtilisateur.SUPER_ADMIN)
    ),
):
    """Initialise toutes les configs par défaut pour une organisation."""
    try:
        await ConfigService.initialiser_organisation(organisation_id)
        return {
            "message": f"Configurations initialisées pour l'organisation {organisation_id}.",
            "nombre":  len(CONFIGS_DEFAUT),
        }
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get(
    "/cles",
    summary="Lister toutes les clés disponibles",
)
async def lister_cles(
    current_user: UserModel = Depends(
        require_any_role("admin", "super_admin")
    ),
):
    """Retourne toutes les clés de configuration disponibles."""
    return [
        {
            "cle":         cle,
            "valeur_defaut": data["valeur"],
            "description": data["description"],
        }
        for cle, data in CONFIGS_DEFAUT.items()
    ]