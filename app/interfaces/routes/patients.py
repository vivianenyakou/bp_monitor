from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.params import Depends

from app.core.exceptions import BPMonitorException, PatientNotFoundError
from app.domain.enums.role_enum import RoleUtilisateur
from app.infrastructure.db.session import AsyncSessionFactory, get_db_session
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.bp.patient import PatientModel
from app.interfaces.dependencies.authorization import require_any_role
from app.interfaces.schemas.patient import MettreAJourPatientSchema, PatientSchema
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/patients", tags=["Patients"])


@router.get(
    "/{patient_id}",
    response_model=PatientSchema,
    summary="Obtenir le profil d'un patient",
)
async def obtenir_patient(
      patient_id: int,
      current_user: UserModel = Depends(require_any_role(RoleUtilisateur.MEDECIN, RoleUtilisateur.ADMIN, RoleUtilisateur.PATIENT, RoleUtilisateur.SECRETAIRE)),
      session: AsyncSession = Depends(get_db_session),
):
    """Retourne le profil médical d'un patient."""
    try:
        async with AsyncSessionFactory() as session:
            patient = await session.get(PatientModel, patient_id)
            if not patient:
                raise PatientNotFoundError()
            return patient
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.patch(
    "/{patient_id}",
    response_model=PatientSchema,
    summary="Mettre à jour le profil d'un patient",
)
async def mettre_a_jour_patient(
    patient_id: int, body: MettreAJourPatientSchema,
    current_user: UserModel = Depends(require_any_role(RoleUtilisateur.MEDECIN, RoleUtilisateur.ADMIN, RoleUtilisateur.PATIENT, RoleUtilisateur.SECRETAIRE)),
    session: AsyncSession = Depends(get_db_session),):
    """Met à jour le profil médical d'un patient."""
    try:
        async with AsyncSessionFactory() as session:
            patient = await session.get(PatientModel, patient_id)
            if not patient:
                raise PatientNotFoundError()

            # Mettre à jour uniquement les champs fournis
            for champ, valeur in body.model_dump(exclude_none=True).items():
                setattr(patient, champ, valeur)

            await session.commit()
            await session.refresh(patient)
            return patient
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)