"""Offline queue management for feedback submissions."""

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Dict, Any, Optional

from pydantic import BaseModel, Field


class QueuedFeedback(BaseModel):
    """Model for queued feedback item."""

    rating: int = Field(..., description="Rating from 1-5")
    category: str = Field(..., description="Feedback category")
    comment: str = Field(..., description="Feedback comment")
    email: Optional[str] = Field(None, description="User email")
    page_url: Optional[str] = Field(None, description="Page URL")
    feedback_type: str = Field("feedback", description="Feedback type")
    queued_at: str = Field(..., description="Timestamp when queued")
    attempts: int = Field(0, description="Number of sync attempts")


class OfflineQueue:
    """Manages offline queue for feedback submissions."""

    def __init__(self, queue_path: str):
        """Initialize offline queue.

        Args:
            queue_path: Path to queue file
        """
        self.queue_path = Path(queue_path)
        self.queue_path.parent.mkdir(parents=True, exist_ok=True)

    def add(self, feedback_data: Dict[str, Any]) -> None:
        """Add feedback to offline queue.

        Args:
            feedback_data: Feedback data to queue
        """
        queue = self._load_queue()

        queued_feedback = QueuedFeedback(**feedback_data, queued_at=datetime.now(timezone.utc).isoformat(), attempts=0)

        queue.append(queued_feedback.model_dump())
        self._save_queue(queue)

    def get_all(self) -> List[Dict[str, Any]]:
        """Get all queued feedback items.

        Returns:
            List of queued feedback items
        """
        return self._load_queue()

    def remove(self, index: int) -> None:
        """Remove feedback from queue by index.

        Args:
            index: Index of item to remove
        """
        queue = self._load_queue()
        if 0 <= index < len(queue):
            queue.pop(index)
            self._save_queue(queue)

    def increment_attempts(self, index: int) -> None:
        """Increment sync attempt counter for a queued item.

        Args:
            index: Index of item to update
        """
        queue = self._load_queue()
        if 0 <= index < len(queue):
            queue[index]["attempts"] = queue[index].get("attempts", 0) + 1
            self._save_queue(queue)

    def clear(self) -> None:
        """Clear all items from queue."""
        self._save_queue([])

    def size(self) -> int:
        """Get number of items in queue.

        Returns:
            Number of queued items
        """
        return len(self._load_queue())

    def _load_queue(self) -> List[Dict[str, Any]]:
        """Load queue from file.

        Returns:
            List of queued items
        """
        if not self.queue_path.exists():
            return []

        try:
            with open(self.queue_path, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return []

    def _save_queue(self, queue: List[Dict[str, Any]]) -> None:
        """Save queue to file.

        Args:
            queue: List of queued items to save
        """
        with open(self.queue_path, "w") as f:
            json.dump(queue, f, indent=2)
