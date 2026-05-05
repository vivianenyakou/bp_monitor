from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.infrastructure.db.base import AuditableEntity


class TokenModel(AuditableEntity):
    __tablename__ = "tokens"

    user_id       = Column(Integer, ForeignKey("users.id"), nullable=False)
    token         = Column(Text, nullable=False)
    refresh_token = Column(Text, nullable=True)
    expires_at    = Column(DateTime, nullable=False)
    revoked       = Column(Boolean, default=False)

    user = relationship("UserModel", back_populates="tokens")