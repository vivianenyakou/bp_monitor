from abc import ABC, abstractmethod

# un objet immuable (ex: une tension 128/82 ne se modifie pas, on en crée un nouveau)
class ValueObject(ABC):
    """
    Objet valeur — immuable, égalité par valeur (pas par identité).
    Toujours valider dans __init__ via _validate().
    """

    @abstractmethod
    def _validate(self) -> None:
        """Lever une DomainException si les valeurs sont invalides."""
        ...

    def __eq__(self, other: object) -> bool:
        if type(self) is not type(other):
            return False
        return self.__dict__ == other.__dict__

    def __hash__(self) -> int:
        return hash(tuple(sorted(self.__dict__.items())))

    def __repr__(self) -> str:
        attrs = ", ".join(f"{k}={v!r}" for k, v in self.__dict__.items())
        return f"{self.__class__.__name__}({attrs})"