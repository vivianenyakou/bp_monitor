from sqlalchemy import Column, String
from sqlalchemy.orm import relationship

from app.infrastructure.db.base import AuditableEntity
from app.infrastructure.models.auth.associations import role_permissions, user_roles


class RoleModel(AuditableEntity):
    __tablename__ = "roles"

    name = Column(String(50), unique=True, nullable=False)
    description = Column(String(255), nullable=True)

    users = relationship(
        "UserModel",
        secondary=user_roles,
        back_populates="roles",
    )
    permissions = relationship(
        "PermissionModel",
        secondary=role_permissions,
        back_populates="roles",
    )