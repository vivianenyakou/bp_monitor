from sqlalchemy import select

from app.application.dtos.organisation_dto import OrganisationDTO
from app.application.dtos.organisation_dto import OrganisationDTO
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.multi_tenant.organisations import OrganisationModel


class ListerOrganisationsUseCase:
    """Liste toutes les organisations — réservé au super admin."""

    async def executer(self) -> list[OrganisationDTO]:
        async with AsyncSessionFactory() as session:
            result = await session.execute(
                select(OrganisationModel)
                .where(OrganisationModel.est_actif == True)
                .order_by(OrganisationModel.nom)
            )
            tenants = result.scalars().all()

            return [
                OrganisationDTO(
                    id=t.id,
                    nom=t.nom,
                    code=t.code,
                    adresse=t.adresse,
                    telephone=t.telephone,
                    email=t.email,
                    est_actif=t.est_actif,
                    nif_structure=t.nif_structure,
                    raison_sociale=t.raison_sociale,
                )
                for t in tenants
            ]