from app.core.exceptions import NotFoundError
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.multi_tenant.organisations import OrganisationModel


class ChangerStatutOrganisationUseCase:
    async def executer(self, organisation_id: int, est_actif: bool) -> dict:
        async with AsyncSessionFactory() as session:
            organisation = await session.get(OrganisationModel, organisation_id)
            if not organisation:
                raise NotFoundError("Organisation introuvable.")

            organisation.est_actif = est_actif
            await session.commit()
            await session.refresh(organisation)

            return {
                "id": organisation.id,
                "est_actif": organisation.est_actif,
                "message": "Organisation activée." if est_actif else "Organisation désactivée.",
            }