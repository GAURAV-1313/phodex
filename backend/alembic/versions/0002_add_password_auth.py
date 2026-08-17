"""add password auth

Revision ID: 0002_add_password_auth
Revises: 0001_initial
Create Date: 2026-08-01 00:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0002_add_password_auth"
down_revision: Union[str, Sequence[str], None] = "0001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("password_hash", sa.String(length=1024), nullable=True))
    op.alter_column("users", "google_sub", existing_type=sa.String(length=255), nullable=True)


def downgrade() -> None:
    op.alter_column("users", "google_sub", existing_type=sa.String(length=255), nullable=False)
    op.drop_column("users", "password_hash")
