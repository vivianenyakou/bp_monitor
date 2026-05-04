from datetime import datetime

from sqlalchemy import Column, DateTime, Enum as SqlEnum, ForeignKey
from sqlalchemy import Integer, String, Text
from sqlalchemy.orm import relationship

from app.domain.enums.bp_category import NiveauAlerte, StatutAlerte
from app.infrastructure.db.base import AuditableEntity


class AlerteModel(AuditableEntity):
    __tablename__ = "alertes"

    patient_id    = Column(Integer, ForeignKey("patients.id"), nullable=False)
    medecin_id    = Column(Integer, ForeignKey("users.id"), nullable=True)
    systolique    = Column(Integer, nullable=False)
    diastolique   = Column(Integer, nullable=False)
    niveau        = Column(SqlEnum(NiveauAlerte), nullable=False)
    statut        = Column(SqlEnum(StatutAlerte), default=StatutAlerte.EN_ATTENTE)
    message       = Column(Text, nullable=False)
    declenchee_le = Column(DateTime, default=datetime.utcnow)
    acquittee_le  = Column(DateTime, nullable=True)
    acquittee_par = Column(String(100), nullable=True)

    # Relations
    patient = relationship("PatientModel", back_populates="alertes")