"""add git operations and per-user ai settings

Revision ID: 0003_add_git_ops_and_ai_settings
Revises: 0002_add_password_auth
Create Date: 2026-08-17 00:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0003_add_git_ops_and_ai_settings"
down_revision: Union[str, Sequence[str], None] = "0002_add_password_auth"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "git_operations",
        sa.Column("task_id", sa.Uuid(), nullable=False),
        sa.Column("repo_path", sa.String(length=1024), nullable=False),
        sa.Column("commit_message", sa.Text(), nullable=False),
        sa.Column(
            "status",
            sa.Enum(
                "pending_review",
                "approved",
                "running",
                "completed",
                "failed",
                "rejected",
                name="git_operation_status",
                native_enum=False,
            ),
            nullable=False,
        ),
        sa.Column("status_output", sa.Text(), nullable=True),
        sa.Column("diff_stat_output", sa.Text(), nullable=True),
        sa.Column("pushed_branch", sa.String(length=255), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["task_id"], ["tasks.id"], name=op.f("fk_git_operations_task_id_tasks"), ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_git_operations")),
    )
    op.create_index(op.f("ix_git_operations_task_id"), "git_operations", ["task_id"], unique=False)
    op.create_index(op.f("ix_git_operations_status"), "git_operations", ["status"], unique=False)

    op.create_table(
        "user_ai_settings",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("anthropic_api_key_encrypted", sa.Text(), nullable=True),
        sa.Column("openai_api_key_encrypted", sa.Text(), nullable=True),
        sa.Column("preferred_claude_model", sa.String(length=255), nullable=True),
        sa.Column("preferred_codex_model", sa.String(length=255), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"], name=op.f("fk_user_ai_settings_user_id_users"), ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_user_ai_settings")),
        sa.UniqueConstraint("user_id", name=op.f("uq_user_ai_settings_user_id")),
    )
    op.create_index(
        op.f("ix_user_ai_settings_user_id"), "user_ai_settings", ["user_id"], unique=False
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_user_ai_settings_user_id"), table_name="user_ai_settings")
    op.drop_table("user_ai_settings")

    op.drop_index(op.f("ix_git_operations_status"), table_name="git_operations")
    op.drop_index(op.f("ix_git_operations_task_id"), table_name="git_operations")
    op.drop_table("git_operations")
