from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.infrastructure.db.base import AuditableEntity


class QRCodeModel(AuditableEntity):
    __tablename__ = "qr_codes"

    token           = Column(String(100), unique=True, nullable=False, index=True)
    organisation_id = Column(Integer, ForeignKey("organisations.id"), nullable=False)
    medecin_id      = Column(Integer, ForeignKey("users.id"), nullable=True)
    est_actif       = Column(Boolean, default=True)
    expire_le       = Column(DateTime, nullable=True)
    nombre_scans    = Column(Integer, default=0)
    description     = Column(String(255), nullable=True)

    # Relations
    organisation = relationship("OrganisationModel")
    medecin      = relationship("UserModel", foreign_keys=[medecin_id])