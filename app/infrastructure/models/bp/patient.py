from sqlalchemy import Column, Date, Enum as SqlEnum, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.domain.enums.blood_group import BloodGroup
from app.infrastructure.db.base import AuditableEntity


class PatientModel(AuditableEntity):
    __tablename__ = "patients"

    user_id           = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    gender            = Column(String(10), nullable=True)
    birth_date        = Column(Date, nullable=True)
    address           = Column(String(255), nullable=True)
    emergency_contact = Column(String(255), nullable=True)
    blood_group       = Column(SqlEnum(BloodGroup), nullable=True)
    medecin_id        = Column(Integer, ForeignKey("users.id"), nullable=True)

    # Seuils BP personnalisés (optionnel — remplace les seuils par défaut)
    seuil_systolique_eleve       = Column(Integer, nullable=True)
    seuil_diastolique_eleve      = Column(Integer, nullable=True)
    seuil_systolique_hypertension = Column(Integer, nullable=True)
    seuil_diastolique_hypertension = Column(Integer, nullable=True)
    seuil_systolique_critique    = Column(Integer, nullable=True)
    seuil_diastolique_critique   = Column(Integer, nullable=True)

    # Relations
    user    = relationship("UserModel", back_populates="patient_profile" , foreign_keys=[user_id])
    medecin = relationship("UserModel", foreign_keys=[medecin_id])

    @property
    def medecin_nom_complet(self) -> str | None:
        if self.medecin is None:
            return None
        return f"{self.medecin.first_name or ''} {self.medecin.last_name or ''}".strip() or None
    organisation = relationship("OrganisationModel", back_populates="patients")
    mesures = relationship("MesureModel", back_populates="patient")
    alertes = relationship("AlerteModel", back_populates="patient")
    sessions = relationship("SessionModel", back_populates="patient")