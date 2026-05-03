from sqlalchemy import Column, DateTime, Integer, String
from sqlalchemy.sql import func

from app.infrastructure.db.base import Base


class AuditableEntity(Base):
    __abstract__ = True

    id = Column(Integer, primary_key=True, index=True)
    created_by = Column(String, nullable=True)
    last_modified_by = Column(String, nullable=True)
    created_on = Column(DateTime(timezone=True), server_default=func.now())
    last_modified_on = Column(DateTime(timezone=True), onupdate=func.now())