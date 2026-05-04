from abc import abstractmethod
from uuid import UUID

from app.core.interfaces.repository import IRepository
from app.domain.entities.mesure import Mesure
from app.domain.enums.bp_category import PeriodeMesure


class IMesureRepository(IRepository[Mesure]):
    """Interface du repository des mesures — implémentée dans Infrastructure."""

    @abstractmethod
    async def lister_par_patient(self, patient_id: UUID) -> list[Mesure]: ...

    @abstractmethod
    async def lister_session(
        self, patient_id: UUID, session_id: str
    ) -> list[Mesure]: ...

    @abstractmethod
    async def compter_session(
        self, patient_id: UUID, session_id: str
    ) -> int: ...

    @abstractmethod
    async def lister_par_periode(
        self, patient_id: UUID, periode: PeriodeMesure
    ) -> list[Mesure]: ...