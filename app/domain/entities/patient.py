from dataclasses import dataclass, field
from uuid import UUID

from app.core.entity import AggregateRoot
from app.domain.enums.role_enum import RoleUtilisateur
from app.domain.value_objects.seuil import SeuilTA


@dataclass
class Patient(AggregateRoot):
    """
    Agrégat Patient — point d'entrée pour toutes les opérations
    liées au patient (mesures, seuils personnalisés).
    """
    nom: str
    prenom: str
    email: str
    telephone: str | None = None
    medecin_id: UUID | None = None
    seuils: SeuilTA = field(default_factory=SeuilTA)
    role: RoleUtilisateur = RoleUtilisateur.PATIENT
    est_actif: bool = True

    def __post_init__(self) -> None:
        super().__init__()

    def assigner_medecin(self, medecin_id: UUID) -> None:
        """Assigne un médecin référent au patient."""
        self.medecin_id = medecin_id
        self._touch()

    def personnaliser_seuils(self, seuils: SeuilTA) -> None:
        """Personnalise les seuils d'alerte du patient."""
        self.seuils = seuils
        self._touch()

    def desactiver(self) -> None:
        """Désactive le compte patient."""
        self.est_actif = False
        self._touch()

    @property
    def nom_complet(self) -> str:
        return f"{self.prenom} {self.nom}"