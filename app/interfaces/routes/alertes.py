from fastapi import APIRouter, HTTPException, status

from app.application.dtos.alerte_dto import AcquitterAlerteDTO
from app.application.use_cases.alerte.acquitter_alerte import AcquitterAlerteUseCase
from app.application.use_cases.alerte.declencher_alerte import DeclencherAlerteUseCase
from app.core.exceptions import BPMonitorException
from app.interfaces.schemas.alerte import AlerteSchema, AcquitterAlerteSchema

router = APIRouter(prefix="/alertes", tags=["Alertes"])


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