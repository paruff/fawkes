"""API client for Insights service."""

from typing import Any, Dict, List, Optional

import requests
from pydantic import BaseModel, Field


class InsightCreate(BaseModel):
    """Model for creating an insight (friction log)."""

    title: str = Field(..., description="Brief title of the friction point")
    description: str = Field(..., description="Detailed description of the friction")
    content: str = Field(..., description="Full content including context and impact")
    category_id: Optional[int] = Field(None, description="Category ID")
    category_name: Optional[str] = Field(None, description="Category name (if ID not provided)")
    tags: List[str] = Field(default_factory=list, description="Tags for the friction point")
    priority: str = Field(default="medium", description="Priority: low, medium, high, critical")
    source: str = Field(default="CLI", description="Source of the insight")
    author: Optional[str] = Field(None, description="Author of the friction log")
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Additional metadata")


class InsightsClient:
    """Client for interacting with Insights API."""

    def __init__(self, base_url: str, api_key: Optional[str] = None):
        """Initialize Insights API client.

        Args:
            base_url: Base URL of the Insights API
            api_key: Optional API key for authentication
        """
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.session = requests.Session()
        if api_key:
            self.session.headers["Authorization"] = f"Bearer {api_key}"

    def create_insight(self, insight: InsightCreate) -> Dict[str, Any]:
        """Create a new insight (friction log).

        Args:
            insight: Insight data to create

        Returns:
            Created insight data

        Raises:
            requests.HTTPError: If the API request fails
        """
        response = self.session.post(
            f"{self.base_url}/insights",
            json=insight.model_dump(exclude_none=True),
        )
        response.raise_for_status()
        return response.json()

    def list_insights(
        self,
        category: Optional[str] = None,
        priority: Optional[str] = None,
        status: Optional[str] = None,
        limit: int = 10,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """List insights with optional filters.

        Args:
            category: Filter by category name
            priority: Filter by priority
            status: Filter by status
            limit: Maximum number of results
            offset: Offset for pagination

        Returns:
            List of insights

        Raises:
            requests.HTTPError: If the API request fails
        """
        params = {"limit": limit, "offset": offset}
        if category:
            params["category"] = category
        if priority:
            params["priority"] = priority
        if status:
            params["status"] = status

        response = self.session.get(f"{self.base_url}/insights", params=params)
        response.raise_for_status()
        return response.json()

    def get_insight(self, insight_id: int) -> Dict[str, Any]:
        """Get a specific insight by ID.

        Args:
            insight_id: ID of the insight to retrieve

        Returns:
            Insight data

        Raises:
            requests.HTTPError: If the API request fails
        """
        response = self.session.get(f"{self.base_url}/insights/{insight_id}")
        response.raise_for_status()
        return response.json()

    def list_categories(self) -> List[Dict[str, Any]]:
        """List all available categories.

        Returns:
            List of categories

        Raises:
            requests.HTTPError: If the API request fails
        """
        response = self.session.get(f"{self.base_url}/categories")
        response.raise_for_status()
        return response.json()

    def list_tags(self) -> List[Dict[str, Any]]:
        """List all available tags.

        Returns:
            List of tags

        Raises:
            requests.HTTPError: If the API request fails
        """
        response = self.session.get(f"{self.base_url}/tags")
        response.raise_for_status()
        return response.json()

    def health_check(self) -> bool:
        """Check if the Insights API is healthy.

        Returns:
            True if healthy, False otherwise
        """
        try:
            response = self.session.get(f"{self.base_url}/health", timeout=5)
            return response.status_code == 200
        except Exception:
            return False
