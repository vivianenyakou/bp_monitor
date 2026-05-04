from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.infrastructure.db.base import AuditableEntity


class TokenModel(AuditableEntity):
    __tablename__ = "tokens"

    user_id       = Column(Integer, ForeignKey("users.id"), nullable=False)
    token         = Column(String(500), nullable=False)
    refresh_token = Column(String(500), nullable=True)
    expires_at    = Column(DateTime, nullable=False)
    revoked       = Column(Boolean, default=False)

    user = relationship("UserModel", back_populates="tokens")