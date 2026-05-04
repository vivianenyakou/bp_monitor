from abc import ABC, abstractmethod
from typing import Generic, TypeVar
from uuid import UUID

from app.core.entity import BaseEntity

T = TypeVar("T", bound=BaseEntity)


class IRepository(ABC, Generic[T]):
    """Interface générique — implémentée dans Infrastructure."""

    @abstractmethod
    async def get_by_id(self, id: UUID) -> T | None: ...

    @abstractmethod
    async def save(self, entity: T) -> T: ...

    @abstractmethod
    async def delete(self, id: UUID) -> None: ...

    @abstractmethod
    async def exists(self, id: UUID) -> bool: ...