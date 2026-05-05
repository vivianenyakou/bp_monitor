from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.infrastructure.db.base import AuditableEntity


class InvitationModel(AuditableEntity):
    __tablename__ = "invitations"

    code          = Column(String(10), unique=True, nullable=False)
    medecin_id    = Column(Integer, ForeignKey("users.id"), nullable=False)
    patient_id    = Column(Integer, ForeignKey("patients.id"), nullable=True)
    organisation_id = Column(Integer, ForeignKey("organisations.id"), nullable=True)
    est_utilise   = Column(Boolean, default=False)
    expire_le     = Column(DateTime, nullable=False)
    utilise_le    = Column(DateTime, nullable=True)

    # Relations
    medecin = relationship("UserModel", foreign_keys=[medecin_id])
    patient = relationship("PatientModel", foreign_keys=[patient_id])