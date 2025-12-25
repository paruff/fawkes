"""Tests for offline queue management."""

import json
import tempfile
from pathlib import Path

import pytest
from feedback_cli.queue import OfflineQueue, QueuedFeedback


@pytest.fixture
def temp_queue_dir():
    """Create temporary queue directory."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


@pytest.fixture
def queue(temp_queue_dir):
    """Create test queue."""
    queue_path = temp_queue_dir / "queue.json"
    return OfflineQueue(str(queue_path))


def test_queue_initialization(temp_queue_dir):
    """Test queue initialization."""
    queue_path = temp_queue_dir / "queue.json"
    queue = OfflineQueue(str(queue_path))
    
    assert queue.queue_path == queue_path
    assert queue.size() == 0


def test_add_to_queue(queue):
    """Test adding items to queue."""
    feedback_data = {
        "rating": 5,
        "category": "Test",
        "comment": "Test comment",
    }
    
    queue.add(feedback_data)
    
    assert queue.size() == 1
    items = queue.get_all()
    assert len(items) == 1
    assert items[0]["rating"] == 5
    assert items[0]["category"] == "Test"
    assert "queued_at" in items[0]
    assert items[0]["attempts"] == 0


def test_add_multiple_items(queue):
    """Test adding multiple items to queue."""
    for i in range(3):
        queue.add({
            "rating": i + 1,
            "category": f"Category{i}",
            "comment": f"Comment{i}",
        })
    
    assert queue.size() == 3


def test_get_all_empty_queue(queue):
    """Test getting all items from empty queue."""
    items = queue.get_all()
    assert items == []


def test_remove_from_queue(queue):
    """Test removing items from queue."""
    # Add 3 items
    for i in range(3):
        queue.add({
            "rating": i + 1,
            "category": f"Category{i}",
            "comment": f"Comment{i}",
        })
    
    # Remove middle item
    queue.remove(1)
    
    assert queue.size() == 2
    items = queue.get_all()
    assert items[0]["category"] == "Category0"
    assert items[1]["category"] == "Category2"


def test_remove_invalid_index(queue):
    """Test removing with invalid index."""
    queue.add({"rating": 5, "category": "Test", "comment": "Test"})
    
    # Should not raise error, just do nothing
    queue.remove(10)
    assert queue.size() == 1
    
    queue.remove(-1)
    assert queue.size() == 1


def test_increment_attempts(queue):
    """Test incrementing attempt counter."""
    queue.add({
        "rating": 5,
        "category": "Test",
        "comment": "Test",
    })
    
    items = queue.get_all()
    assert items[0]["attempts"] == 0
    
    queue.increment_attempts(0)
    items = queue.get_all()
    assert items[0]["attempts"] == 1
    
    queue.increment_attempts(0)
    items = queue.get_all()
    assert items[0]["attempts"] == 2


def test_clear_queue(queue):
    """Test clearing all items from queue."""
    for i in range(5):
        queue.add({
            "rating": i + 1,
            "category": f"Category{i}",
            "comment": f"Comment{i}",
        })
    
    assert queue.size() == 5
    
    queue.clear()
    
    assert queue.size() == 0
    assert queue.get_all() == []


def test_queue_persistence(temp_queue_dir):
    """Test queue persistence across instances."""
    queue_path = temp_queue_dir / "queue.json"
    
    # Create first queue and add items
    queue1 = OfflineQueue(str(queue_path))
    queue1.add({
        "rating": 5,
        "category": "Persistent",
        "comment": "This should persist",
    })
    
    # Create new queue instance
    queue2 = OfflineQueue(str(queue_path))
    
    # Should have the same item
    assert queue2.size() == 1
    items = queue2.get_all()
    assert items[0]["category"] == "Persistent"


def test_queue_corrupted_file(temp_queue_dir):
    """Test handling corrupted queue file."""
    queue_path = temp_queue_dir / "queue.json"
    
    # Write invalid JSON
    with open(queue_path, "w") as f:
        f.write("invalid json{{{")
    
    # Should handle gracefully and return empty list
    queue = OfflineQueue(str(queue_path))
    items = queue.get_all()
    assert items == []


def test_queued_feedback_model():
    """Test QueuedFeedback model."""
    feedback = QueuedFeedback(
        rating=5,
        category="Test",
        comment="Test comment",
        queued_at="2024-01-01T00:00:00",
        attempts=0,
    )
    
    assert feedback.rating == 5
    assert feedback.category == "Test"
    assert feedback.attempts == 0


def test_queue_with_optional_fields(queue):
    """Test queue with feedback containing optional fields."""
    feedback_data = {
        "rating": 4,
        "category": "Test",
        "comment": "Test comment",
        "email": "test@example.com",
        "page_url": "https://example.com",
        "feedback_type": "bug_report",
    }
    
    queue.add(feedback_data)
    
    items = queue.get_all()
    assert items[0]["email"] == "test@example.com"
    assert items[0]["page_url"] == "https://example.com"
    assert items[0]["feedback_type"] == "bug_report"


def test_queue_json_format(temp_queue_dir):
    """Test queue file JSON format."""
    queue_path = temp_queue_dir / "queue.json"
    queue = OfflineQueue(str(queue_path))
    
    queue.add({
        "rating": 5,
        "category": "Test",
        "comment": "Test",
    })
    
    # Read and verify JSON format
    with open(queue_path, "r") as f:
        data = json.load(f)
    
    assert isinstance(data, list)
    assert len(data) == 1
    assert "rating" in data[0]
    assert "queued_at" in data[0]
