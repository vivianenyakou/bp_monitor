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

    # Seuils BP personnalisés (optionnel — remplace les seuils par défaut)
    seuil_systolique_eleve       = Column(Integer, nullable=True)
    seuil_diastolique_eleve      = Column(Integer, nullable=True)
    seuil_systolique_hypertension = Column(Integer, nullable=True)
    seuil_diastolique_hypertension = Column(Integer, nullable=True)
    seuil_systolique_critique    = Column(Integer, nullable=True)
    seuil_diastolique_critique   = Column(Integer, nullable=True)

    # Relations
    user    = relationship("UserModel", back_populates="patient_profile")
    mesures = relationship("MesureModel", back_populates="patient")
    alertes = relationship("AlerteModel", back_populates="patient")