from datetime import date, datetime

from sqlalchemy import Boolean, Column, Date, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.infrastructure.db.base import AuditableEntity


class SessionModel(AuditableEntity):
    __tablename__ = "sessions"

    patient_id      = Column(Integer, ForeignKey("patients.id"), nullable=False)
    session_id      = Column(String(50), unique=True, nullable=False, index=True)

    # Jours calendaires
    date_jour1      = Column(Date, nullable=False)   # date démarrage
    date_jour2      = Column(Date, nullable=True)    # date_jour1 + 1
    date_jour3      = Column(Date, nullable=True)    # date_jour1 + 2

    # Progression
    mesures_j1_matin = Column(Integer, default=0)   # 0 à 3
    mesures_j1_soir  = Column(Integer, default=0)
    mesures_j2_matin = Column(Integer, default=0)
    mesures_j2_soir  = Column(Integer, default=0)
    mesures_j3_matin = Column(Integer, default=0)
    mesures_j3_soir  = Column(Integer, default=0)

    # Statuts
    jour1_complete   = Column(Boolean, default=False)
    jour2_complete   = Column(Boolean, default=False)
    jour3_complete   = Column(Boolean, default=False)
    protocole_termine = Column(Boolean, default=False)

    # Médicament
    medicament_pris  = Column(Boolean, nullable=True)  # None = pas encore demandé

    # Dates
    demarre_le       = Column(DateTime, nullable=False)
    termine_le       = Column(DateTime, nullable=True)

    # Relations
    patient = relationship("PatientModel", back_populates="sessions")