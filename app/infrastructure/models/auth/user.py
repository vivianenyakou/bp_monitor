from sqlalchemy import Boolean, Column, Integer, String
from sqlalchemy.orm import relationship

from app.infrastructure.db.base import AuditableEntity
from app.infrastructure.models.auth.associations import user_roles


class UserModel(AuditableEntity):
    __tablename__ = "users"

    username       = Column(String(50), nullable=True)
    last_name      = Column(String(50), nullable=True)
    first_name     = Column(String(50), nullable=True)
    email          = Column(String(120), unique=True, nullable=False)
    password_hash  = Column(String(255), nullable=False)
    phone_number   = Column(String(20), nullable=False)

    # Statut du compte
    is_active            = Column(Boolean, default=True)
    email_confirmed      = Column(Boolean, default=False)
    phone_confirmed      = Column(Boolean, default=False)
    lockout_enabled      = Column(Boolean, default=False)
    access_failed_count  = Column(Integer, default=0)

    # Relations
    roles = relationship(
        "RoleModel",
        secondary=user_roles,
        back_populates="users",
    )
    tokens          = relationship("TokenModel",      back_populates="user")
    audits          = relationship("AuditTrailModel", back_populates="user")
    patient_profile = relationship(
        "PatientModel",
        foreign_keys="[PatientModel.user_id]",
        back_populates="user",
        uselist=False,
    )
    organisation = relationship("OrganisationModel", back_populates="utilisateurs")
    roles = relationship(
        "RoleModel",
        secondary=user_roles,
        back_populates="users",
    )

    @property
    def role_names(self) -> list[str]:
        return [role.name for role in self.roles]

    @property
    def permission_names(self) -> list[str]:
        return [
            perm.name
            for role in self.roles
            for perm in role.permissions
        ]

    def has_permission(self, permission: str) -> bool:
        return permission in self.permission_names

    def has_role(self, role: str) -> bool:
        return role in self.role_names