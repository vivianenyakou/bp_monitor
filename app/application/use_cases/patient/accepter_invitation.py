from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.application.dtos.invitation_dto import AccepterInvitationDTO
from app.core.exceptions import ApplicationException, PatientNotFoundError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.multi_tenant.invitation import InvitationModel
from app.infrastructure.models.bp.patient import PatientModel
from app.infrastructure.models.auth.user import UserModel


class AccepterInvitationUseCase:

    async def executer(self, dto: AccepterInvitationDTO) -> dict:
        async with AsyncSessionFactory() as session:

            # 1. Trouver l'invitation
            result = await session.execute(
                select(InvitationModel)
                .where(InvitationModel.code == dto.code.upper())
            )
            invitation = result.scalar_one_or_none()

            # 2. Vérifier la validité
            if not invitation:
                raise ApplicationException("Code d'invitation invalide.")

            if invitation.est_utilise:
                raise ApplicationException("Ce code a déjà été utilisé.")

            if datetime.utcnow() > invitation.expire_le:
                raise ApplicationException("Ce code d'invitation a expiré.")

            # 3. Vérifier le patient
            patient = await session.get(PatientModel, dto.patient_id)
            if not patient:
                raise PatientNotFoundError()

            # 4. Charger le médecin
            medecin = await session.get(UserModel, invitation.medecin_id)

            # 5. Lier patient ↔ médecin
            patient.medecin_id = invitation.medecin_id
            if invitation.organisation_id:
                patient.organisation_id = invitation.organisation_id

            # 6. Marquer l'invitation comme utilisée
            invitation.est_utilise = True
            invitation.patient_id  = patient.id
            invitation.utilise_le  = datetime.utcnow()

            await session.commit()

            return {
                "message": f"Vous êtes maintenant suivi par le Médecin "
                           f"{medecin.first_name} {medecin.last_name}.",
                "medecin_id": medecin.id,
                "patient_id": patient.id,
            }