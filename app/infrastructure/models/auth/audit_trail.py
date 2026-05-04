from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.infrastructure.db.base import AuditableEntity


class AuditTrailModel(AuditableEntity):
    __tablename__ = "audit_trails"

    user_id      = Column(Integer, ForeignKey("users.id"), nullable=True)
    table_name   = Column(String(100), nullable=False)
    old_values   = Column(Text, nullable=True)
    new_values   = Column(Text, nullable=True)
    type         = Column(String(50), nullable=False)
    timestamp    = Column(DateTime, default=datetime.utcnow)
    ip_address   = Column(String(50), nullable=True)
    browser_info = Column(String(255), nullable=True)

    user = relationship("UserModel", back_populates="audits")