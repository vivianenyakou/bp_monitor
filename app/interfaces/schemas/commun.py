from pydantic import BaseModel


class ReponseSucces(BaseModel):
    """Réponse générique pour les opérations réussies."""
    message: str
    succes: bool = True


class ReponseErreur(BaseModel):
    """Réponse générique pour les erreurs."""
    message: str
    succes: bool = False
    code: int