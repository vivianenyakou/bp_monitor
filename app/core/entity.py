from abc import ABC
from datetime import datetime, timezone
from uuid import UUID, uuid4


class BaseEntity(ABC):
    def __init__(self, id: UUID | None = None) -> None:
        self._id: UUID = id or uuid4()
        self._created_at: datetime = datetime.now(timezone.utc)
        self._updated_at: datetime = datetime.now(timezone.utc)

    @property
    def id(self) -> UUID:
        return self._id

    @property
    def created_at(self) -> datetime:
        return self._created_at

    @property
    def updated_at(self) -> datetime:
        return self._updated_at

    def _touch(self) -> None:
        """Mettre à jour updated_at à chaque modification."""
        self._updated_at = datetime.now(timezone.utc)

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, BaseEntity):
            return False
        return self._id == other._id

    def __hash__(self) -> int:
        return hash(self._id)

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__} id={self._id}>"


class AggregateRoot(BaseEntity, ABC):
    """
    Racine d'agrégat.
    Point d'entrée unique pour modifier l'agrégat.
    Collecte les domain events à publier après persistance.
    """
    def __init__(self, id: UUID | None = None) -> None:
        super().__init__(id)
        self._domain_events: list = []

    def add_event(self, event: object) -> None:
        self._domain_events.append(event)

    def pull_events(self) -> list:
        events = self._domain_events.copy()
        self._domain_events.clear()
        return events