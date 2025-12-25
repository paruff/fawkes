"""Initial schema for VSM service

Revision ID: 001
Revises:
Create Date: 2025-12-21 21:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create work_items table
    op.create_table(
        "work_items",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=500), nullable=False),
        sa.Column("type", sa.Enum("feature", "bug", "task", "epic", name="workitemtype"), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_work_items_id"), "work_items", ["id"], unique=False)

    # Create stages table
    op.create_table(
        "stages",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("order", sa.Integer(), nullable=False),
        sa.Column(
            "type",
            sa.Enum("backlog", "analysis", "development", "testing", "deployment", "production", name="stagetype"),
            nullable=False,
        ),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
    )
    op.create_index(op.f("ix_stages_id"), "stages", ["id"], unique=False)
    op.create_index(op.f("ix_stages_name"), "stages", ["name"], unique=True)

    # Create stage_transitions table
    op.create_table(
        "stage_transitions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("work_item_id", sa.Integer(), nullable=False),
        sa.Column("from_stage_id", sa.Integer(), nullable=True),
        sa.Column("to_stage_id", sa.Integer(), nullable=False),
        sa.Column("timestamp", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["from_stage_id"],
            ["stages.id"],
        ),
        sa.ForeignKeyConstraint(
            ["to_stage_id"],
            ["stages.id"],
        ),
        sa.ForeignKeyConstraint(
            ["work_item_id"],
            ["work_items.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_stage_transitions_id"), "stage_transitions", ["id"], unique=False)
    op.create_index(op.f("ix_stage_transitions_work_item_id"), "stage_transitions", ["work_item_id"], unique=False)
    op.create_index(op.f("ix_stage_transitions_timestamp"), "stage_transitions", ["timestamp"], unique=False)

    # Create flow_metrics table
    op.create_table(
        "flow_metrics",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("date", sa.DateTime(), nullable=False),
        sa.Column("period_type", sa.String(length=20), nullable=False),
        sa.Column("throughput", sa.Integer(), nullable=True),
        sa.Column("wip", sa.Float(), nullable=True),
        sa.Column("cycle_time_avg", sa.Float(), nullable=True),
        sa.Column("cycle_time_p50", sa.Float(), nullable=True),
        sa.Column("cycle_time_p85", sa.Float(), nullable=True),
        sa.Column("cycle_time_p95", sa.Float(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_flow_metrics_id"), "flow_metrics", ["id"], unique=False)
    op.create_index(op.f("ix_flow_metrics_date"), "flow_metrics", ["date"], unique=False)

    # Insert default stages
    op.execute(
        """
        INSERT INTO stages (name, "order", type, created_at) VALUES
        ('Backlog', 1, 'backlog', NOW()),
        ('Analysis', 2, 'analysis', NOW()),
        ('Development', 3, 'development', NOW()),
        ('Testing', 4, 'testing', NOW()),
        ('Deployment', 5, 'deployment', NOW()),
        ('Production', 6, 'production', NOW());
    """
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_flow_metrics_date"), table_name="flow_metrics")
    op.drop_index(op.f("ix_flow_metrics_id"), table_name="flow_metrics")
    op.drop_table("flow_metrics")

    op.drop_index(op.f("ix_stage_transitions_timestamp"), table_name="stage_transitions")
    op.drop_index(op.f("ix_stage_transitions_work_item_id"), table_name="stage_transitions")
    op.drop_index(op.f("ix_stage_transitions_id"), table_name="stage_transitions")
    op.drop_table("stage_transitions")

    op.drop_index(op.f("ix_stages_name"), table_name="stages")
    op.drop_index(op.f("ix_stages_id"), table_name="stages")
    op.drop_table("stages")

    op.drop_index(op.f("ix_work_items_id"), table_name="work_items")
    op.drop_table("work_items")
