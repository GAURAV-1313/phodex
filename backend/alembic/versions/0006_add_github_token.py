"""add github token to user_ai_settings (cloud runtime)

Revision ID: 0006_add_github_token
Revises: 0005_add_push_subscriptions
Create Date: 2026-09-11 00:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0006_add_github_token"
down_revision: Union[str, Sequence[str], None] = "0005_add_push_subscriptions"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_ai_settings",
        sa.Column("github_token_encrypted", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("user_ai_settings", "github_token_encrypted")
