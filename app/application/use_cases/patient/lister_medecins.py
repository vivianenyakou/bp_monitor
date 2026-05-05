from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.domain.enums.role_enum import RoleUtilisateur
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.auth.role import RoleModel
from app.infrastructure.models.auth.user import UserModel


@dataclass
class MedecinDTO:
    id: int
    nom_complet: str
    email: str
    telephone: str | None
    specialite: str | None


class ListerMedecinsUseCase:
    async def executer(
        self, organisation_id: int | None = None
    ) -> list[MedecinDTO]:
        async with AsyncSessionFactory() as session:

            query = (
                select(UserModel)
                .join(UserModel.roles)
                .where(RoleModel.name == RoleUtilisateur.MEDECIN)
                .where(UserModel.is_active == True)
                .options(
                    selectinload(UserModel.roles)
                    .selectinload(RoleModel.permissions)
                )
            )

            # Filtrer par organisation si fourni
            if organisation_id:
                query = query.where(
                    UserModel.organisation_id == organisation_id
                )

            result = await session.execute(query)
            medecins = result.scalars().unique().all()

            return [
                MedecinDTO(
                    id=m.id,
                    nom_complet=f"Dr {m.first_name} {m.last_name}",
                    email=m.email,
                    telephone=m.phone_number,
                    specialite=None,
                )
                for m in medecins
            ]