"""add is_current flag to project_contexts

Revision ID: 0004_add_project_context_is_current
Revises: 0003_add_git_ops_and_ai_settings
Create Date: 2026-08-21 00:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0004_add_project_context_is_current"
down_revision: Union[str, Sequence[str], None] = "0003_add_git_ops_and_ai_settings"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # This revision id (35 chars) exceeds alembic_version.version_num's default
    # VARCHAR(32), which breaks the upgrade on any fresh database before it even
    # reaches this migration's own changes below. Widen it first so Alembic can
    # record this and all later (also long) revision ids.
    op.alter_column(
        "alembic_version",
        "version_num",
        type_=sa.String(255),
        existing_type=sa.String(32),
    )
    op.add_column(
        "project_contexts",
        sa.Column("is_current", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.create_index(
        op.f("ix_project_contexts_is_current"), "project_contexts", ["is_current"], unique=False
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_project_contexts_is_current"), table_name="project_contexts")
    op.drop_column("project_contexts", "is_current")
