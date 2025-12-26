"""Initial schema for Insights service

Revision ID: 001
Revises:
Create Date: 2025-12-23 18:00:00.000000

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
    # Create categories table
    op.create_table(
        "categories",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("slug", sa.String(length=100), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("parent_id", sa.Integer(), nullable=True),
        sa.Column("color", sa.String(length=7), nullable=True),
        sa.Column("icon", sa.String(length=50), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["parent_id"],
            ["categories.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
        sa.UniqueConstraint("slug"),
    )
    op.create_index(op.f("ix_categories_id"), "categories", ["id"], unique=False)
    op.create_index(op.f("ix_categories_name"), "categories", ["name"], unique=True)
    op.create_index(op.f("ix_categories_slug"), "categories", ["slug"], unique=True)
    op.create_index(op.f("ix_categories_parent_id"), "categories", ["parent_id"], unique=False)

    # Create tags table
    op.create_table(
        "tags",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=50), nullable=False),
        sa.Column("slug", sa.String(length=50), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("color", sa.String(length=7), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("usage_count", sa.Integer(), nullable=False, server_default="0"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
        sa.UniqueConstraint("slug"),
    )
    op.create_index(op.f("ix_tags_id"), "tags", ["id"], unique=False)
    op.create_index(op.f("ix_tags_name"), "tags", ["name"], unique=True)
    op.create_index(op.f("ix_tags_slug"), "tags", ["slug"], unique=True)

    # Create insights table
    op.create_table(
        "insights",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=500), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("content", sa.Text(), nullable=True),
        sa.Column("source", sa.String(length=255), nullable=True),
        sa.Column("author", sa.String(length=255), nullable=False),
        sa.Column("category_id", sa.Integer(), nullable=True),
        sa.Column("priority", sa.String(length=20), nullable=False, server_default="medium"),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="draft"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("published_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(
            ["category_id"],
            ["categories.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_insights_id"), "insights", ["id"], unique=False)
    op.create_index(op.f("ix_insights_title"), "insights", ["title"], unique=False)
    op.create_index(op.f("ix_insights_author"), "insights", ["author"], unique=False)
    op.create_index(op.f("ix_insights_category_id"), "insights", ["category_id"], unique=False)
    op.create_index(op.f("ix_insights_priority"), "insights", ["priority"], unique=False)
    op.create_index(op.f("ix_insights_status"), "insights", ["status"], unique=False)
    op.create_index(op.f("ix_insights_created_at"), "insights", ["created_at"], unique=False)
    op.create_index("idx_insights_status_priority", "insights", ["status", "priority"], unique=False)
    op.create_index("idx_insights_category_status", "insights", ["category_id", "status"], unique=False)
    op.create_index("idx_insights_author_status", "insights", ["author", "status"], unique=False)

    # Create insight_tags association table
    op.create_table(
        "insight_tags",
        sa.Column("insight_id", sa.Integer(), nullable=False),
        sa.Column("tag_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["insight_id"], ["insights.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["tag_id"], ["tags.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("insight_id", "tag_id"),
    )
    op.create_index("idx_insight_tags_insight_id", "insight_tags", ["insight_id"], unique=False)
    op.create_index("idx_insight_tags_tag_id", "insight_tags", ["tag_id"], unique=False)

    # Insert default categories
    op.execute(
        """
        INSERT INTO categories (name, slug, description, color, icon, created_at, updated_at) VALUES
        ('Technical', 'technical', 'Technical insights and learnings', '#3B82F6', 'code', NOW(), NOW()),
        ('Process', 'process', 'Process improvements and best practices', '#10B981', 'cog', NOW(), NOW()),
        ('People', 'people', 'Team and collaboration insights', '#F59E0B', 'users', NOW(), NOW()),
        ('Product', 'product', 'Product development and features', '#8B5CF6', 'lightbulb', NOW(), NOW()),
        ('Security', 'security', 'Security-related insights', '#EF4444', 'shield', NOW(), NOW()),
        ('Performance', 'performance', 'Performance optimization insights', '#06B6D4', 'zap', NOW(), NOW());
    """
    )

    # Insert default tags
    op.execute(
        """
        INSERT INTO tags (name, slug, description, color, created_at) VALUES
        ('Lesson Learned', 'lesson-learned', 'Key lesson from experience', '#10B981', NOW()),
        ('Best Practice', 'best-practice', 'Recommended best practice', '#3B82F6', NOW()),
        ('Incident', 'incident', 'Related to an incident', '#EF4444', NOW()),
        ('Improvement', 'improvement', 'Potential improvement area', '#F59E0B', NOW()),
        ('Quick Win', 'quick-win', 'Easy to implement improvement', '#10B981', NOW()),
        ('Documentation', 'documentation', 'Documentation-related', '#6B7280', NOW()),
        ('Testing', 'testing', 'Testing-related insight', '#8B5CF6', NOW()),
        ('Deployment', 'deployment', 'Deployment-related insight', '#06B6D4', NOW());
    """
    )


def downgrade() -> None:
    op.drop_index("idx_insight_tags_tag_id", table_name="insight_tags")
    op.drop_index("idx_insight_tags_insight_id", table_name="insight_tags")
    op.drop_table("insight_tags")

    op.drop_index("idx_insights_author_status", table_name="insights")
    op.drop_index("idx_insights_category_status", table_name="insights")
    op.drop_index("idx_insights_status_priority", table_name="insights")
    op.drop_index(op.f("ix_insights_created_at"), table_name="insights")
    op.drop_index(op.f("ix_insights_status"), table_name="insights")
    op.drop_index(op.f("ix_insights_priority"), table_name="insights")
    op.drop_index(op.f("ix_insights_category_id"), table_name="insights")
    op.drop_index(op.f("ix_insights_author"), table_name="insights")
    op.drop_index(op.f("ix_insights_title"), table_name="insights")
    op.drop_index(op.f("ix_insights_id"), table_name="insights")
    op.drop_table("insights")

    op.drop_index(op.f("ix_tags_slug"), table_name="tags")
    op.drop_index(op.f("ix_tags_name"), table_name="tags")
    op.drop_index(op.f("ix_tags_id"), table_name="tags")
    op.drop_table("tags")

    op.drop_index(op.f("ix_categories_parent_id"), table_name="categories")
    op.drop_index(op.f("ix_categories_slug"), table_name="categories")
    op.drop_index(op.f("ix_categories_name"), table_name="categories")
    op.drop_index(op.f("ix_categories_id"), table_name="categories")
    op.drop_table("categories")
