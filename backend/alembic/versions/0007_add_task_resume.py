"""add runtime session id and resume count to tasks

Revision ID: 0007_add_task_resume
Revises: 0006_add_github_token
Create Date: 2026-10-09 00:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0007_add_task_resume"
down_revision: Union[str, Sequence[str], None] = "0006_add_github_token"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("tasks", sa.Column("runtime_session_id", sa.String(255), nullable=True))
    op.add_column(
        "tasks",
        sa.Column("resume_count", sa.Integer(), nullable=False, server_default="0"),
    )


def downgrade() -> None:
    op.drop_column("tasks", "resume_count")
    op.drop_column("tasks", "runtime_session_id")
