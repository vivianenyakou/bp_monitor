from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.infrastructure.db.base import AuditableEntity


class SystemConfigModel(AuditableEntity):
    __tablename__ = "system_configs"

    organisation_id = Column(
        Integer, ForeignKey("organisations.id"), nullable=False, index=True
    )
    cle         = Column(String(100), nullable=False)
    valeur      = Column(Text, nullable=True)
    description = Column(String(255), nullable=True)
    est_actif   = Column(Boolean, default=True)

    # Relation
    organisation = relationship("OrganisationModel")

    # Contrainte unique — une clé par organisation
    __table_args__ = (
        __import__("sqlalchemy").UniqueConstraint(
            "organisation_id", "cle", name="uq_config_org_cle"
        ),
    )