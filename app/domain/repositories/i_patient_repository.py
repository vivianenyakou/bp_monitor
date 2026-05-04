from abc import abstractmethod

from app.core.interfaces.repository import IRepository
from app.domain.entities.patient import Patient


class IPatientRepository(IRepository[Patient]):
    """Interface du repository des patients — implémentée dans Infrastructure."""

    @abstractmethod
    async def trouver_par_email(self, email: str) -> Patient | None: ...

    @abstractmethod
    async def lister_par_medecin(self, medecin_id: str) -> list[Patient]: ...

    @abstractmethod
    async def lister_actifs(self) -> list[Patient]: ...