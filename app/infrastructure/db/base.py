from sqlalchemy import Column, DateTime, Integer, String, func
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass

class AuditableEntity(Base):
    __abstract__ = True

    id = Column(Integer, primary_key=True, index=True)
    created_by = Column(String, nullable=True)
    last_modified_by = Column(String, nullable=True)
    created_on = Column(DateTime(timezone=True), server_default=func.now())
    last_modified_on = Column(DateTime(timezone=True), onupdate=func.now())