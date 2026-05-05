import random
import string
from datetime import datetime, timedelta

from sqlalchemy import select

from app.application.dtos.invitation_dto import GenererInvitationDTO, InvitationDTO
from app.core.exceptions import DoctorNotFoundError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.multi_tenant.invitation import InvitationModel
from app.infrastructure.models.auth.user import UserModel


class GenererInvitationUseCase:
    async def executer(self, dto: GenererInvitationDTO) -> InvitationDTO:
        async with AsyncSessionFactory() as session:

            # 1. Vérifier le médecin
            medecin = await session.get(UserModel, dto.medecin_id)
            if not medecin:
                raise DoctorNotFoundError()

            # 2. Générer un code unique
            code = self._generer_code()

            # Vérifier que le code n'existe pas déjà
            while True:
                result = await session.execute(
                    select(InvitationModel).where(InvitationModel.code == code)
                )
                if not result.scalar_one_or_none():
                    break
                code = self._generer_code()

            # 3. Créer l'invitation
            invitation = InvitationModel(
                code=code,
                medecin_id=dto.medecin_id,
                organisation_id=dto.organisation_id,
                est_utilise=False,
                expire_le=datetime.utcnow() + timedelta(hours=48),
            )
            session.add(invitation)
            await session.commit()
            await session.refresh(invitation)

            return InvitationDTO(
                id=invitation.id,
                code=invitation.code,
                medecin_id=invitation.medecin_id,
                medecin_nom=f"Médécin {medecin.first_name} {medecin.last_name}",
                est_utilise=invitation.est_utilise,
                expire_le=invitation.expire_le,
            )

    @staticmethod
    def _generer_code() -> str:
        """Génère un code alphanumérique de 8 caractères en majuscules."""
        return "".join(
            random.choices(string.ascii_uppercase + string.digits, k=8)
        )