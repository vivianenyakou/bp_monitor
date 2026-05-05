from sqlalchemy import select

from app.application.dtos.organisation_dto import CreerOrganisationDTO, OrganisationDTO
from app.core.exceptions import ConflictError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.multi_tenant.organisations import OrganisationModel


class CreerOrganisationUseCase:
    """Crée une nouvelle clinique/hôpital — réservé au super admin."""

    async def executer(self, dto: CreerOrganisationDTO) -> OrganisationDTO:
        async with AsyncSessionFactory() as session:

            # Vérifier que le code est unique
            result = await session.execute(
                select(OrganisationModel).where(OrganisationModel.code == dto.code)
            )
            if result.scalar_one_or_none():
                raise ConflictError(
                    f"Une organisation avec le code '{dto.code}' existe déjà."
                )

            organisation = OrganisationModel(
                nom=dto.nom,
                code=dto.code.upper(),
                adresse=dto.adresse,
                telephone=dto.telephone,
                email=dto.email,
                est_actif=True,
                nif_structure=dto.nif_structure,
                raison_sociale=dto.raison_sociale,
            )
            session.add(organisation)
            await session.commit()
            await session.refresh(organisation)

            return OrganisationDTO(
                id=organisation.id,
                nom=organisation.nom,
                code=organisation.code,
                adresse=organisation.adresse,
                telephone=organisation.telephone,
                email=organisation.email,
                est_actif=organisation.est_actif,
                nif_structure=organisation.nif_structure,
                raison_sociale=organisation.raison_sociale,
            )