from fastapi import APIRouter, Depends, HTTPException, status

from app.application.dtos.session_dto import CreerMesureAvecSessionDTO
from app.application.use_cases.session.creer_mesure_session import (
    CreerMesureSessionUseCase,
)
from app.application.use_cases.session.obtenir_session import ObtenirSessionUseCase
from app.core.exceptions import BPMonitorException
from app.infrastructure.models.auth.user import UserModel
from app.interfaces.dependencies.authorization import get_current_user, require_any_role
from app.interfaces.schemas.session import (
    CreerMesureSessionSchema,
    SessionSchema,
)

router = APIRouter(prefix="/sessions", tags=["Sessions BP"])


@router.get(
    "/patient/{patient_id}",
    response_model=SessionSchema,
    summary="Obtenir la session active du patient",
)
async def obtenir_session(
    patient_id: int,
    current_user: UserModel = Depends(
        require_any_role("patient", "medecin", "admin")
    ),
):
    """
    Retourne la session active du patient.
    Indique le créneau actuel, le jour et les mesures restantes.
    """
    try:
        use_case = ObtenirSessionUseCase()
        return await use_case.executer(patient_id)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post(
    "/mesure",
    status_code=status.HTTP_201_CREATED,
    summary="Enregistrer une mesure dans le protocole",
)
async def creer_mesure_session(
    body: CreerMesureSessionSchema,
    current_user: UserModel = Depends(
        require_any_role("patient", "medecin", "admin")
    ),
):
    """
    Enregistre une mesure dans le cadre du protocole 3 jours.
    Gère automatiquement le créneau, le jour et les alertes.
    """
    try:
        use_case = CreerMesureSessionUseCase()
        dto      = CreerMesureAvecSessionDTO(
            patient_id=      body.patient_id,
            systolique=      body.systolique,
            diastolique=     body.diastolique,
            pouls=           body.pouls,
            notes=           body.notes,
            medicament_pris= body.medicament_pris,
        )
        return await use_case.executer(dto)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get(
    "/creneau",
    summary="Vérifier le créneau actuel",
)
async def verifier_creneau(
    current_user: UserModel = Depends(get_current_user),
):
    """Retourne le créneau actuel et le message si hors créneau."""
    from app.domain.services.creneau_service import CreneauService
    from datetime import datetime, timezone

    creneau = CreneauService.creneau_actuel()
    return {
        "creneau":          creneau.value,
        "est_disponible":   CreneauService.est_disponible(),
        "heure_utc":        datetime.now(timezone.utc).strftime("%H:%M UTC"),
        "message":          CreneauService.prochain_creneau()
                            if not CreneauService.est_disponible()
                            else None,
    }