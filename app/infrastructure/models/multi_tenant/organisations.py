from sqlalchemy import Boolean, Column, String
from sqlalchemy.orm import relationship

from app.infrastructure.db.base import AuditableEntity


class OrganisationModel(AuditableEntity):
    __tablename__ = "organisations"

    nom       = Column(String(100), nullable=False)
    code      = Column(String(20), unique=True, nullable=False)
    adresse   = Column(String(255), nullable=True)
    telephone = Column(String(20), nullable=True)
    nif_structure = Column(String(50), nullable=True)
    raison_sociale = Column(String(255), nullable=True)
    email     = Column(String(120), nullable=True)
    logo_url  = Column(String(255), nullable=True)
    est_actif = Column(Boolean, default=True)

    # Relations
    utilisateurs = relationship("UserModel", back_populates="organisation")
    patients     = relationship("PatientModel", back_populates="organisation")