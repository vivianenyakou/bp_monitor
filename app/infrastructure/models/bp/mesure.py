from sqlalchemy import Column, Enum as SqlEnum, ForeignKey, Integer, String, Text
from sqlalchemy import DateTime
from sqlalchemy.orm import relationship
from datetime import datetime

from app.domain.enums.bp_category import CategorieTA, PeriodeMesure
from app.infrastructure.db.base import AuditableEntity


class MesureModel(AuditableEntity):
    __tablename__ = "mesures"

    patient_id     = Column(Integer, ForeignKey("patients.id"), nullable=False)
    systolique     = Column(Integer, nullable=False)
    diastolique    = Column(Integer, nullable=False)
    pouls          = Column(Integer, nullable=True)
    periode        = Column(SqlEnum(PeriodeMesure), nullable=False)
    jour           = Column(Integer, nullable=False)   # 1, 2 ou 3
    numero_mesure  = Column(Integer, nullable=False)   # 1, 2 ou 3
    categorie      = Column(SqlEnum(CategorieTA), nullable=True)
    session_id     = Column(String(50), nullable=False)  # regroupe les 18 mesures
    prise_le       = Column(DateTime, default=datetime.utcnow)
    notes          = Column(Text, nullable=True)

    # Relations
    patient = relationship("PatientModel", back_populates="mesures")