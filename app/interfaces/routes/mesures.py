from fastapi import APIRouter, HTTPException, status

from app.application.dtos.mesure_dto import CreerMesureDTO
from app.application.use_cases.mesure.creer_mesure import CreerMesureUseCase
from app.application.use_cases.mesure.lister_mesures import ListerMesuresUseCase
from app.application.use_cases.mesure.obtenir_resume import ObtenirResumeUseCase
from app.core.exceptions import BPMonitorException
from app.interfaces.schemas.mesure import (
    CreerMesureSchema,
    MesureSchema,
    ResumeSessionSchema,
)

router = APIRouter(prefix="/mesures", tags=["Mesures"])


@router.post(
    "/",
    response_model=MesureSchema,
    status_code=status.HTTP_201_CREATED,
    summary="Enregistrer une mesure de tension",
)
async def creer_mesure(body: CreerMesureSchema):
    """
    Enregistre une mesure de tension artérielle.
    Déclenche automatiquement une alerte si les seuils sont dépassés.
    """
    try:
        use_case = CreerMesureUseCase(notification_service=None)
        dto = CreerMesureDTO(
            patient_id=body.patient_id,
            systolique=body.systolique,
            diastolique=body.diastolique,
            pouls=body.pouls,
            periode=body.periode,
            jour=body.jour,
            numero_mesure=body.numero_mesure,
            notes=body.notes,
            session_id=body.session_id,
        )
        resultat = await use_case.executer(dto)
        return resultat
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get(
    "/patient/{patient_id}",
    response_model=list[MesureSchema],
    summary="Lister les mesures d'un patient",
)
async def lister_mesures(patient_id: int):
    """Retourne toutes les mesures d'un patient, triées par date décroissante."""
    try:
        use_case = ListerMesuresUseCase()
        return await use_case.executer(patient_id)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get(
    "/resume/{patient_id}/{session_id}",
    response_model=ResumeSessionSchema,
    summary="Obtenir le résumé d'une session",
)
async def obtenir_resume(patient_id: int, session_id: str):
    """
    Retourne les moyennes d'une session (partielle ou complète).
    Inclut les moyennes globale, matin, soir et par jour.
    """
    try:
        use_case = ObtenirResumeUseCase()
        return await use_case.executer(patient_id, session_id)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)