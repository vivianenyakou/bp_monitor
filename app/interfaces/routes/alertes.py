from fastapi import APIRouter, Depends, HTTPException, status

from app.application.dtos.alerte_dto import AcquitterAlerteDTO
from app.application.use_cases.alerte.acquitter_alerte import AcquitterAlerteUseCase
from app.application.use_cases.alerte.declencher_alerte import DeclencherAlerteUseCase
from app.application.use_cases.alerte.lister_alertes import ListerAlertesUseCase
from app.core.exceptions import BPMonitorException
from app.domain.enums.role_enum import RoleUtilisateur
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.notifications.notification_service import NotificationService
from app.interfaces.dependencies.authorization import get_current_user, require_any_role
from app.interfaces.schemas.alerte import AlerteSchema, AcquitterAlerteSchema

router = APIRouter(prefix="/alertes", tags=["Alertes"])

@router.get(
    "/",
    response_model=list[AlerteSchema],
    summary="Lister les alertes",
)
async def lister_alertes(
    patient_id: int | None = None,
    medecin_id: int | None = None,
    current_user: UserModel = Depends(get_current_user),
):
    try:
        use_case = ListerAlertesUseCase()

        # Patient — forcer le filtre sur son propre profil
        if RoleUtilisateur.PATIENT in current_user.role_names and RoleUtilisateur.ADMIN not in current_user.role_names:
            from sqlalchemy import select
            from app.infrastructure.db.session import AsyncSessionFactory
            from app.infrastructure.models.bp.patient import PatientModel

            async with AsyncSessionFactory() as session:
                result = await session.execute(
                    select(PatientModel).where(
                        PatientModel.user_id == current_user.id
                    )
                )
                patient = result.scalar_one_or_none()
                if patient:
                    patient_id = patient.id

        # Médecin — forcer le filtre sur ses patients
        elif RoleUtilisateur.MEDECIN in current_user.role_names and RoleUtilisateur.ADMIN not in current_user.role_names:
            medecin_id = current_user.id

        return await use_case.executer(
            patient_id=patient_id,
            medecin_id=medecin_id,
        )
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)

@router.post(
    "/{alerte_id}/declencher",
    response_model=AlerteSchema,
    summary="Déclencher une alerte",
)
async def declencher_alerte(alerte_id: int):
    """Envoie les notifications d'une alerte en attente au médecin."""
    try:
        use_case = DeclencherAlerteUseCase(notification_service=None)
        return await use_case.executer(alerte_id)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.patch(
    "/{alerte_id}/acquitter",
    response_model=AlerteSchema,
    summary="Acquitter une alerte",
)
async def acquitter_alerte(alerte_id: int, body: AcquitterAlerteSchema):
    """Le médecin acquitte une alerte — elle ne sera plus remontée."""
    try:
        use_case = AcquitterAlerteUseCase()
        dto = AcquitterAlerteDTO(
            alerte_id=alerte_id,
            acquittee_par=body.acquittee_par,
        )
        return await use_case.executer(dto)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post("/{alerte_id}/declencher", response_model=AlerteSchema)
async def declencher_alerte(
    alerte_id: int,
    current_user: UserModel = Depends(require_any_role(RoleUtilisateur.MEDECIN, RoleUtilisateur.ADMIN)),
):
    try:
        use_case = DeclencherAlerteUseCase(
            notification_service=NotificationService()
        )
        return await use_case.executer(alerte_id)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)