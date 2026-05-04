from abc import abstractmethod
from uuid import UUID

from app.core.interfaces.repository import IRepository
from app.domain.entities.alerte import Alerte
from app.domain.enums.bp_category import StatutAlerte


class IAlerteRepository(IRepository[Alerte]):
    """Interface du repository des alertes — implémentée dans Infrastructure."""

    @abstractmethod
    async def lister_par_patient(self, patient_id: UUID) -> list[Alerte]: ...

    @abstractmethod
    async def lister_par_medecin(self, medecin_id: UUID) -> list[Alerte]: ...

    @abstractmethod
    async def lister_par_statut(self, statut: StatutAlerte) -> list[Alerte]: ...

    @abstractmethod
    async def lister_non_acquittees(self, medecin_id: UUID) -> list[Alerte]: ...