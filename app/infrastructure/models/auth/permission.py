from sqlalchemy import Column, String
from sqlalchemy.orm import relationship

from app.infrastructure.db.base import AuditableEntity
from app.infrastructure.models.auth.associations import role_permissions


class PermissionModel(AuditableEntity):
    __tablename__ = "permissions"

    name = Column(String(100), unique=True, nullable=False)
    description = Column(String(255), nullable=True)

    roles = relationship(
        "RoleModel",
        secondary=role_permissions,
        back_populates="permissions",
    )