from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.params import Depends

from app.application.dtos.invitation_dto import AccepterInvitationDTO, ChoisirMedecinDTO, GenererInvitationDTO
from app.application.use_cases.patient.accepter_invitation import AccepterInvitationUseCase
from app.application.use_cases.patient.choisir_medecin import ChoisirMedecinUseCase
from app.application.use_cases.patient.generer_invitation import GenererInvitationUseCase
from app.application.use_cases.patient.lister_medecins import ListerMedecinsUseCase
from app.core.exceptions import BPMonitorException, PatientNotFoundError
from app.domain.enums.role_enum import RoleUtilisateur
from app.infrastructure.db.session import AsyncSessionFactory, get_db_session
from app.infrastructure.models.auth.user import UserModel
from app.infrastructure.models.bp.patient import PatientModel
from app.interfaces.dependencies.authorization import get_current_user, require_any_role
from app.interfaces.schemas.invitation import AccepterInvitationSchema, ChoisirMedecinSchema, InvitationSchema, MedecinSchema
from app.interfaces.schemas.patient import MettreAJourPatientSchema, PatientSchema
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/patients", tags=["Patients"])

@router.get(
    "/medecins",
    response_model=list[MedecinSchema],
    summary="Lister les médecins disponibles",
)
async def lister_medecins(
    organisation_id: int | None = None,
    current_user: UserModel = Depends(get_current_user),
):
    """Liste les médecins — filtre par organisation si fourni."""
    try:
        use_case = ListerMedecinsUseCase()
        return await use_case.executer(
            organisation_id=organisation_id or current_user.organisation_id
        )
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post(
    "/{patient_id}/choisir-medecin",
    summary="Choisir son médecin référent",
)
async def choisir_medecin(
    patient_id: int,
    body: ChoisirMedecinSchema,
    current_user: UserModel = Depends(require_any_role("patient", "admin")),
):
    """Le patient choisit son médecin référent."""
    try:
        use_case = ChoisirMedecinUseCase()
        dto = ChoisirMedecinDTO(
            patient_id=patient_id,
            medecin_id=body.medecin_id,
        )
        return await use_case.executer(dto)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post(
    "/invitation/generer",
    response_model=InvitationSchema,
    summary="Générer un code d'invitation",
)
async def generer_invitation(
    current_user: UserModel = Depends(require_any_role("medecin", "admin")),
):
    """Le médecin génère un code d'invitation valable 48h."""
    try:
        use_case = GenererInvitationUseCase()
        dto = GenererInvitationDTO(
            medecin_id=current_user.id,
            organisation_id=current_user.organisation_id,
        )
        return await use_case.executer(dto)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post(
    "/{patient_id}/invitation/accepter",
    summary="Accepter une invitation médecin",
)
async def accepter_invitation(
    patient_id: int,
    body: AccepterInvitationSchema,
    current_user: UserModel = Depends(require_any_role("patient", "admin")),
):
    """Le patient entre le code d'invitation pour se lier à un médecin."""
    try:
        use_case = AccepterInvitationUseCase()
        dto = AccepterInvitationDTO(
            code=body.code,
            patient_id=patient_id,
        )
        return await use_case.executer(dto)
    except BPMonitorException as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


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