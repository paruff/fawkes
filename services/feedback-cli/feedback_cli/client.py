"""API client for Feedback service."""

from typing import Any, Dict, List, Optional

import requests
from pydantic import BaseModel, Field


class FeedbackSubmission(BaseModel):
    """Model for submitting feedback."""

    rating: int = Field(..., description="Rating from 1-5", ge=1, le=5)
    category: str = Field(..., description="Feedback category")
    comment: str = Field(..., description="Feedback comment", min_length=1)
    email: Optional[str] = Field(None, description="Optional email for follow-up")
    page_url: Optional[str] = Field(None, description="Page URL where feedback was submitted")
    feedback_type: str = Field("feedback", description="Type of feedback (feedback, bug_report, feature_request)")


class FeedbackClient:
    """Client for interacting with Feedback API."""

    def __init__(self, base_url: str, api_key: Optional[str] = None):
        """Initialize Feedback API client.

        Args:
            base_url: Base URL of the Feedback API
            api_key: Optional API key for authentication
        """
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.session = requests.Session()
        if api_key:
            self.session.headers["Authorization"] = f"Bearer {api_key}"

    def submit_feedback(self, feedback: FeedbackSubmission) -> Dict[str, Any]:
        """Submit new feedback.

        Args:
            feedback: Feedback data to submit

        Returns:
            Created feedback data

        Raises:
            requests.HTTPError: If the API request fails
        """
        response = self.session.post(
            f"{self.base_url}/api/v1/feedback",
            json=feedback.model_dump(exclude_none=True),
            timeout=10,
        )
        response.raise_for_status()
        return response.json()

    def list_feedback(
        self,
        category: Optional[str] = None,
        status: Optional[str] = None,
        limit: int = 10,
        page: int = 1,
    ) -> Dict[str, Any]:
        """List feedback with optional filters.

        Args:
            category: Filter by category
            status: Filter by status
            limit: Maximum number of results per page
            page: Page number

        Returns:
            Dict with feedback items and pagination info

        Raises:
            requests.HTTPError: If the API request fails
        """
        params = {"limit": limit, "page": page}
        if category:
            params["category"] = category
        if status:
            params["status"] = status

        response = self.session.get(
            f"{self.base_url}/api/v1/feedback",
            params=params,
            timeout=10,
        )
        response.raise_for_status()
        return response.json()

    def get_feedback(self, feedback_id: int) -> Dict[str, Any]:
        """Get a specific feedback by ID.

        Args:
            feedback_id: ID of the feedback to retrieve

        Returns:
            Feedback data

        Raises:
            requests.HTTPError: If the API request fails
        """
        response = self.session.get(
            f"{self.base_url}/api/v1/feedback/{feedback_id}",
            timeout=10,
        )
        response.raise_for_status()
        return response.json()

    def get_stats(self) -> Dict[str, Any]:
        """Get feedback statistics.

        Returns:
            Statistics data

        Raises:
            requests.HTTPError: If the API request fails
        """
        response = self.session.get(
            f"{self.base_url}/api/v1/feedback/stats",
            timeout=10,
        )
        response.raise_for_status()
        return response.json()

    def health_check(self) -> bool:
        """Check if the Feedback API is healthy.

        Returns:
            True if healthy, False otherwise
        """
        try:
            response = self.session.get(f"{self.base_url}/health", timeout=5)
            return response.status_code == 200
        except Exception:
            return False
