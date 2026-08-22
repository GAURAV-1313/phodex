"""add push_subscriptions table

Revision ID: 0005_add_push_subscriptions
Revises: 0004_add_project_context_is_current
Create Date: 2026-08-21 00:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0005_add_push_subscriptions"
down_revision: Union[str, Sequence[str], None] = "0004_add_project_context_is_current"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "push_subscriptions",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("fcm_token", sa.String(length=4096), nullable=False),
        sa.Column("platform", sa.String(length=32), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name=op.f("fk_push_subscriptions_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_push_subscriptions")),
        sa.UniqueConstraint("fcm_token", name=op.f("uq_push_subscriptions_fcm_token")),
    )
    op.create_index(
        op.f("ix_push_subscriptions_user_id"), "push_subscriptions", ["user_id"], unique=False
    )
    op.create_index(
        op.f("ix_push_subscriptions_fcm_token"), "push_subscriptions", ["fcm_token"], unique=False
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_push_subscriptions_fcm_token"), table_name="push_subscriptions")
    op.drop_index(op.f("ix_push_subscriptions_user_id"), table_name="push_subscriptions")
    op.drop_table("push_subscriptions")
