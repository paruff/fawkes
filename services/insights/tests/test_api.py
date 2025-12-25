"""Tests for API endpoints."""
import pytest
from fastapi import status


def test_health_check(client):
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "insights"
    assert "version" in data


def test_create_tag(client):
    """Test creating a tag."""
    tag_data = {
        "name": "Test Tag",
        "slug": "test-tag",
        "description": "Test description",
        "color": "#10B981"
    }
    response = client.post("/tags", json=tag_data)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["name"] == tag_data["name"]
    assert data["slug"] == tag_data["slug"]
    assert "id" in data


def test_list_tags(client, sample_tag):
    """Test listing tags."""
    response = client.get("/tags")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0


def test_get_tag(client, sample_tag):
    """Test getting a specific tag."""
    response = client.get(f"/tags/{sample_tag.id}")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["id"] == sample_tag.id
    assert data["name"] == sample_tag.name


def test_update_tag(client, sample_tag):
    """Test updating a tag."""
    update_data = {"description": "Updated description"}
    response = client.put(f"/tags/{sample_tag.id}", json=update_data)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["description"] == "Updated description"


def test_delete_tag(client, sample_tag):
    """Test deleting a tag."""
    response = client.delete(f"/tags/{sample_tag.id}")
    assert response.status_code == status.HTTP_204_NO_CONTENT

    # Verify tag is deleted
    response = client.get(f"/tags/{sample_tag.id}")
    assert response.status_code == status.HTTP_404_NOT_FOUND


def test_create_category(client):
    """Test creating a category."""
    category_data = {
        "name": "Test Category",
        "slug": "test-category",
        "description": "Test description",
        "color": "#3B82F6",
        "icon": "test"
    }
    response = client.post("/categories", json=category_data)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["name"] == category_data["name"]
    assert data["slug"] == category_data["slug"]


def test_list_categories(client, sample_category):
    """Test listing categories."""
    response = client.get("/categories")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0


def test_get_category(client, sample_category):
    """Test getting a specific category."""
    response = client.get(f"/categories/{sample_category.id}")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["id"] == sample_category.id
    assert data["name"] == sample_category.name


def test_create_insight(client, sample_category, sample_tag):
    """Test creating an insight."""
    insight_data = {
        "title": "Test Insight",
        "description": "Test description",
        "content": "Test content",
        "source": "Test source",
        "author": "test-author",
        "category_id": sample_category.id,
        "priority": "high",
        "status": "published",
        "tag_ids": [sample_tag.id]
    }
    response = client.post("/insights", json=insight_data)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["title"] == insight_data["title"]
    assert data["category_id"] == sample_category.id
    assert len(data["tags"]) == 1


def test_list_insights(client, sample_insight):
    """Test listing insights."""
    response = client.get("/insights")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert "total" in data
    assert "insights" in data
    assert data["total"] > 0


def test_list_insights_with_filters(client, sample_insight):
    """Test listing insights with filters."""
    response = client.get(
        "/insights",
        params={
            "status": "draft",
            "priority": "medium"
        }
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert "insights" in data
    for insight in data["insights"]:
        assert insight["status"] == "draft"
        assert insight["priority"] == "medium"


def test_get_insight(client, sample_insight):
    """Test getting a specific insight."""
    response = client.get(f"/insights/{sample_insight.id}")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["id"] == sample_insight.id
    assert data["title"] == sample_insight.title


def test_update_insight(client, sample_insight):
    """Test updating an insight."""
    update_data = {
        "title": "Updated Title",
        "priority": "high"
    }
    response = client.put(f"/insights/{sample_insight.id}", json=update_data)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["title"] == "Updated Title"
    assert data["priority"] == "high"


def test_delete_insight(client, sample_insight):
    """Test deleting an insight."""
    response = client.delete(f"/insights/{sample_insight.id}")
    assert response.status_code == status.HTTP_204_NO_CONTENT

    # Verify insight is deleted
    response = client.get(f"/insights/{sample_insight.id}")
    assert response.status_code == status.HTTP_404_NOT_FOUND


def test_search_insights(client, sample_insight):
    """Test searching insights."""
    search_data = {
        "query": "Test",
        "page": 1,
        "page_size": 20
    }
    response = client.post("/insights/search", json=search_data)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert "total" in data
    assert "insights" in data


def test_search_insights_with_filters(client, sample_insight, sample_category):
    """Test searching insights with filters."""
    search_data = {
        "query": "Test",
        "category_id": sample_category.id,
        "status": "draft",
        "page": 1,
        "page_size": 20
    }
    response = client.post("/insights/search", json=search_data)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert "insights" in data


def test_get_statistics(client, sample_insight):
    """Test getting statistics."""
    response = client.get("/statistics")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert "total_insights" in data
    assert "insights_by_status" in data
    assert "insights_by_priority" in data
    assert "insights_by_category" in data
    assert "total_tags" in data
    assert "total_categories" in data
    assert "recent_insights" in data
    assert data["total_insights"] > 0


def test_tag_usage_count_increment(client, sample_category, sample_tag):
    """Test that creating an insight increments tag usage count."""
    # Get initial usage count
    response = client.get(f"/tags/{sample_tag.id}")
    initial_count = response.json()["usage_count"]

    # Create insight with tag
    insight_data = {
        "title": "Test Insight",
        "description": "Test description",
        "author": "test-author",
        "category_id": sample_category.id,
        "priority": "medium",
        "status": "draft",
        "tag_ids": [sample_tag.id]
    }
    client.post("/insights", json=insight_data)

    # Check usage count increased
    response = client.get(f"/tags/{sample_tag.id}")
    new_count = response.json()["usage_count"]
    assert new_count == initial_count + 1


def test_tag_usage_count_decrement(client, sample_insight, sample_tag):
    """Test that deleting an insight decrements tag usage count."""
    # Get initial usage count
    response = client.get(f"/tags/{sample_tag.id}")
    initial_count = response.json()["usage_count"]

    # Delete insight
    client.delete(f"/insights/{sample_insight.id}")

    # Check usage count decreased (but not below 0)
    response = client.get(f"/tags/{sample_tag.id}")
    new_count = response.json()["usage_count"]
    # If initial count was 0, it stays at 0; otherwise it decreases
    if initial_count > 0:
        assert new_count == initial_count - 1
    else:
        assert new_count == 0


def test_cannot_delete_category_with_insights(client, sample_category, sample_insight):
    """Test that categories with insights cannot be deleted."""
    response = client.delete(f"/categories/{sample_category.id}")
    assert response.status_code == status.HTTP_400_BAD_REQUEST


def test_pagination(client, sample_category):
    """Test pagination works correctly."""
    # Create multiple insights
    for i in range(5):
        insight_data = {
            "title": f"Insight {i}",
            "description": f"Description {i}",
            "author": "test-author",
            "category_id": sample_category.id,
            "priority": "medium",
            "status": "draft"
        }
        client.post("/insights", json=insight_data)

    # Test pagination
    response = client.get("/insights", params={"page": 1, "page_size": 2})
    data = response.json()
    assert len(data["insights"]) == 2
    assert data["page"] == 1
    assert data["page_size"] == 2
    assert data["total"] >= 5


def test_invalid_tag_creation(client):
    """Test creating a tag with invalid data."""
    invalid_data = {
        "name": "",  # Empty name
        "slug": "test"
    }
    response = client.post("/tags", json=invalid_data)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


def test_duplicate_tag_creation(client, sample_tag):
    """Test creating a duplicate tag."""
    duplicate_data = {
        "name": sample_tag.name,
        "slug": "different-slug"
    }
    response = client.post("/tags", json=duplicate_data)
    assert response.status_code == status.HTTP_400_BAD_REQUEST


def test_get_nonexistent_insight(client):
    """Test getting a non-existent insight."""
    response = client.get("/insights/99999")
    assert response.status_code == status.HTTP_404_NOT_FOUND
