"""Make user email nullable

Revision ID: c1f9d8a2b7e3
Revises: 9dbefd7ed35c
Create Date: 2026-05-28 00:00:00.000000
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


revision: str = "c1f9d8a2b7e3"
down_revision: Union[str, Sequence[str], None] = "9dbefd7ed35c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.alter_column(
            "email",
            existing_type=sa.String(length=120),
            nullable=True,
        )


def downgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.alter_column(
            "email",
            existing_type=sa.String(length=120),
            nullable=False,
        )
