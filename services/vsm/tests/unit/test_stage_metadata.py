"""Unit tests for stage metadata API."""
import pytest
from unittest.mock import MagicMock, patch
from app.models import Stage, StageType, StageCategory


def test_stage_category_enum_values():
    """Test that StageCategory enum has correct values."""
    assert StageCategory.WAIT.value == 'wait'
    assert StageCategory.ACTIVE.value == 'active'
    assert StageCategory.DONE.value == 'done'


def test_stage_model_has_new_fields():
    """Test that Stage model includes new fields."""
    from datetime import datetime, timezone

    # Create a stage instance with new fields
    stage = Stage(
        name='Test Stage',
        order=1,
        type=StageType.DEVELOPMENT,
        category=StageCategory.ACTIVE,
        wip_limit=5,
        description='Test description'
    )

    assert stage.name == 'Test Stage'
    assert stage.order == 1
    assert stage.type == StageType.DEVELOPMENT
    assert stage.category == StageCategory.ACTIVE
    assert stage.wip_limit == 5
    assert stage.description == 'Test description'


def test_stage_response_schema():
    """Test StageResponse schema includes new fields."""
    from app.schemas import StageResponse

    # Create a response with new fields
    stage_data = {
        'id': 1,
        'name': 'Development',
        'order': 3,
        'type': StageType.DEVELOPMENT,
        'category': StageCategory.ACTIVE,
        'wip_limit': 10,
        'description': 'Active implementation phase'
    }

    response = StageResponse(**stage_data)

    assert response.id == 1
    assert response.name == 'Development'
    assert response.order == 3
    assert response.type == StageType.DEVELOPMENT
    assert response.category == StageCategory.ACTIVE
    assert response.wip_limit == 10
    assert response.description == 'Active implementation phase'


def test_stage_response_schema_with_null_fields():
    """Test StageResponse schema allows null for optional fields."""
    from app.schemas import StageResponse

    # Create a response with null optional fields
    stage_data = {
        'id': 1,
        'name': 'Backlog',
        'order': 1,
        'type': StageType.BACKLOG,
        'category': None,
        'wip_limit': None,
        'description': None
    }

    response = StageResponse(**stage_data)

    assert response.id == 1
    assert response.name == 'Backlog'
    assert response.category is None
    assert response.wip_limit is None
    assert response.description is None


def test_stage_response_with_all_categories():
    """Test StageResponse with all category types."""
    from app.schemas import StageResponse

    # Wait stage
    wait_stage = StageResponse(
        id=1, name='Backlog', order=1,
        type=StageType.BACKLOG, category=StageCategory.WAIT,
        wip_limit=None, description='Waiting'
    )
    assert wait_stage.category == StageCategory.WAIT

    # Active stage
    active_stage = StageResponse(
        id=2, name='Development', order=2,
        type=StageType.DEVELOPMENT, category=StageCategory.ACTIVE,
        wip_limit=10, description='Active work'
    )
    assert active_stage.category == StageCategory.ACTIVE
    assert active_stage.wip_limit == 10

    # Done stage
    done_stage = StageResponse(
        id=3, name='Production', order=3,
        type=StageType.PRODUCTION, category=StageCategory.DONE,
        wip_limit=None, description='Completed'
    )
    assert done_stage.category == StageCategory.DONE

