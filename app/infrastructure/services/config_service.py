from sqlalchemy import select

from app.domain.value_objects.seuil import SeuilTA
from app.infrastructure.db.seed import CONFIGS_DEFAUT
from app.infrastructure.db.session import AsyncSessionFactory
from app.infrastructure.models.multi_tenant.system_config import SystemConfigModel

class ConfigService:
    """
    Service de configuration dynamique par organisation.
    Lit les configs depuis la base de données.
    """

    @staticmethod
    async def get(
        organisation_id: int,
        cle: str,
        defaut: str = "",
    ) -> str:
        """Récupère une valeur de config pour une organisation."""
        async with AsyncSessionFactory() as session:
            result = await session.execute(
                select(SystemConfigModel)
                .where(SystemConfigModel.organisation_id == organisation_id)
                .where(SystemConfigModel.cle == cle)
                .where(SystemConfigModel.est_actif == True)
            )
            config = result.scalar_one_or_none()

            if config and config.valeur:
                return config.valeur

            # Valeur par défaut depuis CONFIGS_DEFAUT
            if cle in CONFIGS_DEFAUT:
                return CONFIGS_DEFAUT[cle]["valeur"]

            return defaut

    @staticmethod
    async def get_int(
        organisation_id: int,
        cle: str,
        defaut: int = 0,
    ) -> int:
        """Récupère une valeur entière."""
        valeur = await ConfigService.get(organisation_id, cle, str(defaut))
        try:
            return int(valeur) if valeur else defaut
        except ValueError:
            return defaut

    @staticmethod
    async def set(
        organisation_id: int,
        cle: str,
        valeur: str,
    ) -> None:
        """Met à jour ou crée une config."""
        async with AsyncSessionFactory() as session:
            result = await session.execute(
                select(SystemConfigModel)
                .where(SystemConfigModel.organisation_id == organisation_id)
                .where(SystemConfigModel.cle == cle)
            )
            config = result.scalar_one_or_none()

            if config:
                config.valeur = valeur
            else:
                description = CONFIGS_DEFAUT.get(cle, {}).get("description", "")
                config = SystemConfigModel(
                    organisation_id= organisation_id,
                    cle=             cle,
                    valeur=          valeur,
                    description=     description,
                )
                session.add(config)

            await session.commit()

    @staticmethod
    async def initialiser_organisation(organisation_id: int) -> None:
        """Initialise les configs par défaut pour une nouvelle organisation."""
        async with AsyncSessionFactory() as session:
            for cle, data in CONFIGS_DEFAUT.items():
                result = await session.execute(
                    select(SystemConfigModel)
                    .where(SystemConfigModel.organisation_id == organisation_id)
                    .where(SystemConfigModel.cle == cle)
                )
                if not result.scalar_one_or_none():
                    config = SystemConfigModel(
                        organisation_id= organisation_id,
                        cle=             cle,
                        valeur=          data["valeur"],
                        description=     data["description"],
                    )
                    session.add(config)

            await session.commit()
                
                
    @staticmethod
    async def get_seuils(organisation_id: int, est_hypertendu: bool) -> SeuilTA:
        sfx = "_hta" if est_hypertendu else ""
        return SeuilTA(
            systolique_eleve=         await ConfigService.get_int(organisation_id, f"seuil_sys_eleve{sfx}", 120),
            diastolique_eleve=        await ConfigService.get_int(organisation_id, f"seuil_dia_eleve{sfx}", 70),
            systolique_hypertension=  await ConfigService.get_int(organisation_id, f"seuil_sys_hypertension{sfx}", 135),
            diastolique_hypertension= await ConfigService.get_int(organisation_id, f"seuil_dia_hypertension{sfx}", 85),
            systolique_critique=      await ConfigService.get_int(organisation_id, f"seuil_sys_critique{sfx}", 180),
            diastolique_critique=     await ConfigService.get_int(organisation_id, f"seuil_dia_critique{sfx}", 110),
        )