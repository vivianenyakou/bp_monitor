from dataclasses import dataclass, field
from uuid import UUID

from app.core.entity import AggregateRoot
from app.domain.enums.role_enum import RoleUtilisateur


@dataclass
class Medecin(AggregateRoot):
    """
    Agrégat Médecin — consulte les tableaux de bord
    et reçoit les alertes critiques de ses patients.
    """
    nom: str
    prenom: str
    email: str
    telephone: str | None = None
    specialite: str | None = None
    role: RoleUtilisateur = RoleUtilisateur.MEDECIN
    patients_ids: list[UUID] = field(default_factory=list)
    est_actif: bool = True

    def __post_init__(self) -> None:
        super().__init__()

    def ajouter_patient(self, patient_id: UUID) -> None:
        """Ajoute un patient à la liste du médecin."""
        if patient_id not in self.patients_ids:
            self.patients_ids.append(patient_id)
            self._touch()

    def retirer_patient(self, patient_id: UUID) -> None:
        """Retire un patient de la liste du médecin."""
        if patient_id in self.patients_ids:
            self.patients_ids.remove(patient_id)
            self._touch()

    @property
    def nom_complet(self) -> str:
        return f"Dr {self.prenom} {self.nom}"