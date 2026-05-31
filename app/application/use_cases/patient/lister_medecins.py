from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.domain.enums.role_enum import RoleUtilisateur
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.role import RoleModel
from app.infrastructure.models.auth.user import UserModel

class ListerMedecinsUseCase:
    """
    Liste tous les médecins avec leurs informations complètes.
    Filtre par organisation si fourni.
    """

    async def executer(
        self,
        organisation_id: int | None = None,
    ) -> list[dict]:
        async with AsyncSessionFactory() as session:

            query = (
                select(UserModel)
                .join(UserModel.roles)
                .where(RoleModel.name == "medecin")
                .where(UserModel.is_active == True)
                .options(
                    selectinload(UserModel.roles)
                    .selectinload(RoleModel.permissions)
                )
                .order_by(UserModel.id.desc())
            )

            if organisation_id:
                query = query.where(
                    UserModel.organisation_id == organisation_id
                )

            result   = await session.execute(query)
            medecins = result.scalars().unique().all()

            return [self._to_dict(m) for m in medecins]

    def _to_dict(self, medecin: UserModel) -> dict:
        return {
            "id":               medecin.id,
            "nom_complet":      f"Dr {medecin.first_name or ''} {medecin.last_name or ''}".strip()
                                if (medecin.first_name or medecin.last_name)
                                else medecin.username
                                or medecin.phone_number
                                or "Medecin",
            "username":         medecin.username,
            "email":            medecin.email,
            "telephone":        medecin.phone_number,
            "organisation_id":  medecin.organisation_id,
            "is_active":        medecin.is_active,
            "roles":            medecin.role_names,
            "created_on":       str(medecin.created_on) if medecin.created_on else None,
        }
