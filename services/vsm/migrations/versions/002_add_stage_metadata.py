"""Add stage metadata fields

Revision ID: 002
Revises: 001
Create Date: 2025-12-21 22:07:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '002'
down_revision: Union[str, None] = '001'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create StageCategory enum type
    stage_category_enum = sa.Enum('wait', 'active', 'done', name='stagecategory')
    stage_category_enum.create(op.get_bind(), checkfirst=True)
    
    # Add new columns to stages table
    op.add_column('stages', sa.Column('category', stage_category_enum, nullable=True))
    op.add_column('stages', sa.Column('wip_limit', sa.Integer(), nullable=True))
    op.add_column('stages', sa.Column('description', sa.String(length=1000), nullable=True))
    
    # Update existing stages with category and descriptions based on type
    # Note: This maps the old StageType to the new StageCategory
    op.execute("""
        UPDATE stages SET 
            category = CASE 
                WHEN name = 'Backlog' THEN 'wait'
                WHEN name = 'Analysis' THEN 'active'
                WHEN name = 'Development' THEN 'active'
                WHEN name = 'Testing' THEN 'active'
                WHEN name = 'Deployment' THEN 'active'
                WHEN name = 'Production' THEN 'done'
                ELSE 'active'
            END,
            wip_limit = CASE 
                WHEN name = 'Backlog' THEN NULL
                WHEN name = 'Analysis' THEN 5
                WHEN name = 'Development' THEN 10
                WHEN name = 'Testing' THEN 8
                WHEN name = 'Deployment' THEN 3
                WHEN name = 'Production' THEN NULL
                ELSE NULL
            END,
            description = CASE 
                WHEN name = 'Backlog' THEN 'Work items waiting to be analyzed and prioritized'
                WHEN name = 'Analysis' THEN 'Active design and analysis phase'
                WHEN name = 'Development' THEN 'Active implementation phase'
                WHEN name = 'Testing' THEN 'Active testing and quality assurance phase'
                WHEN name = 'Deployment' THEN 'Active deployment to production'
                WHEN name = 'Production' THEN 'Work items deployed and running in production'
                ELSE 'Value stream stage'
            END
        WHERE name IN ('Backlog', 'Analysis', 'Development', 'Testing', 'Deployment', 'Production');
    """)


def downgrade() -> None:
    # Remove columns
    op.drop_column('stages', 'description')
    op.drop_column('stages', 'wip_limit')
    op.drop_column('stages', 'category')
    
    # Drop enum type
    stage_category_enum = sa.Enum('wait', 'active', 'done', name='stagecategory')
    stage_category_enum.drop(op.get_bind(), checkfirst=True)
