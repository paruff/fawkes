"""
Unit tests for AI triage module.
"""
import pytest
from unittest.mock import Mock, AsyncMock, patch

from app.ai_triage import (
    calculate_priority_score,
    suggest_labels,
    detect_duplicates,
    _calculate_similarity,
    determine_milestone,
    triage_feedback,
)


class TestCalculatePriorityScore:
    """Tests for priority score calculation."""

    def test_p0_critical_bug(self):
        """Test P0 priority for critical bug."""
        priority, score, details = calculate_priority_score(
            feedback_type="bug_report",
            category="Security",
            comment="Critical security vulnerability causing data loss",
            rating=1,
            sentiment_compound=-0.8,
        )

        assert priority == "P0"
        assert score >= 0.65
        assert "critical" in details["matched_keywords"]
        assert "security" in details["matched_keywords"]

    def test_p1_major_bug(self):
        """Test P1 priority for major bug."""
        priority, score, details = calculate_priority_score(
            feedback_type="bug_report",
            category="Performance",
            comment="Major error causing application failure",
            rating=2,
            sentiment_compound=-0.3,
        )

        assert priority in ["P0", "P1"]
        assert score >= 0.45
        assert "major" in details["matched_keywords"]

    def test_p2_feature_request(self):
        """Test P2 priority for feature request."""
        priority, score, details = calculate_priority_score(
            feedback_type="feature_request",
            category="Features",
            comment="Would be nice to have feature X for better workflow",
            rating=4,
            sentiment_compound=0.1,
        )

        assert priority in ["P2", "P3"]
        assert score < 0.65
        assert details["type_score"] > 0

    def test_p3_minor_feedback(self):
        """Test P3 priority for minor feedback."""
        priority, score, details = calculate_priority_score(
            feedback_type="feedback",
            category="UI/UX",
            comment="Minor suggestion to polish the interface",
            rating=5,
            sentiment_compound=0.5,
        )

        assert priority == "P3"
        assert score < 0.45
        assert "minor" in details["matched_keywords"]

    def test_without_sentiment(self):
        """Test priority calculation without sentiment."""
        priority, score, details = calculate_priority_score(
            feedback_type="bug_report", category="Bug Report", comment="Bug found", rating=2, sentiment_compound=None
        )

        assert priority in ["P0", "P1", "P2", "P3"]
        assert details["sentiment_score"] == 0.0

    def test_keyword_matching(self):
        """Test that keywords are properly matched."""
        priority, score, details = calculate_priority_score(
            feedback_type="bug_report",
            category="General",
            comment="This is a critical blocker causing outage",
            rating=1,
            sentiment_compound=-0.5,
        )

        assert "critical" in details["matched_keywords"]
        assert "blocker" in details["matched_keywords"]
        assert "outage" in details["matched_keywords"]
        assert details["keyword_score"] > 0


class TestSuggestLabels:
    """Tests for label suggestion."""

    def test_bug_report_labels(self):
        """Test labels for bug report."""
        labels = suggest_labels(
            feedback_type="bug_report", category="UI/UX", priority="P0", comment="Security issue in UI"
        )

        assert "feedback" in labels
        assert "automated" in labels
        assert "bug" in labels
        assert "P0" in labels
        assert "category:ui-ux" in labels
        assert "security" in labels

    def test_feature_request_labels(self):
        """Test labels for feature request."""
        labels = suggest_labels(
            feedback_type="feature_request",
            category="Features",
            priority="P2",
            comment="Add new feature for better performance",
        )

        assert "enhancement" in labels
        assert "P2" in labels
        assert "performance" in labels

    def test_documentation_labels(self):
        """Test documentation-related labels."""
        labels = suggest_labels(
            feedback_type="feedback",
            category="Documentation",
            priority="P3",
            comment="The documentation needs improvement",
        )

        assert "documentation" in labels
        assert "category:documentation" in labels

    def test_accessibility_labels(self):
        """Test accessibility-related labels."""
        labels = suggest_labels(
            feedback_type="feedback",
            category="UI/UX",
            priority="P2",
            comment="Screen reader support is needed for accessibility",
        )

        assert "accessibility" in labels

    def test_multiple_keyword_labels(self):
        """Test multiple keyword-based labels."""
        labels = suggest_labels(
            feedback_type="bug_report",
            category="Performance",
            priority="P1",
            comment="Security vulnerability causing performance issues in the UI",
        )

        assert "security" in labels
        assert "performance" in labels
        assert "ux" in labels


class TestCalculateSimilarity:
    """Tests for text similarity calculation."""

    def test_identical_strings(self):
        """Test similarity of identical strings."""
        similarity = _calculate_similarity("hello world", "hello world")
        assert similarity == 1.0

    def test_completely_different_strings(self):
        """Test similarity of completely different strings."""
        similarity = _calculate_similarity("hello world", "goodbye universe")
        assert similarity < 0.5

    def test_similar_strings(self):
        """Test similarity of similar strings."""
        similarity = _calculate_similarity("the application is very slow", "the app is extremely slow")
        assert similarity > 0.5

    def test_empty_strings(self):
        """Test handling of empty strings."""
        assert _calculate_similarity("", "hello") == 0.0
        assert _calculate_similarity("hello", "") == 0.0
        assert _calculate_similarity("", "") == 0.0

    def test_partial_match(self):
        """Test partial string match."""
        similarity = _calculate_similarity("bug in login page", "issue with login")
        assert 0.3 < similarity < 0.8


class TestDetectDuplicates:
    """Tests for duplicate detection."""

    @pytest.mark.asyncio
    async def test_no_duplicates_found(self):
        """Test when no duplicates are found."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"items": []}

        with patch("app.ai_triage.GITHUB_TOKEN", "test-token"), patch("httpx.AsyncClient") as mock_client:
            mock_client_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_client_instance
            mock_client_instance.get = AsyncMock(return_value=mock_response)

            duplicates = await detect_duplicates(
                comment="This is a unique issue", category="UI/UX", feedback_type="bug_report"
            )

            assert duplicates == []

    @pytest.mark.asyncio
    async def test_duplicates_found(self):
        """Test when duplicates are found."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "items": [
                {
                    "number": 123,
                    "html_url": "https://github.com/test/repo/issues/123",
                    "title": "Bug: Login page is broken",
                    "body": "The login page is not working properly",
                    "state": "open",
                }
            ]
        }

        with patch("app.ai_triage.GITHUB_TOKEN", "test-token"), patch("httpx.AsyncClient") as mock_client:
            mock_client_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_client_instance
            mock_client_instance.get = AsyncMock(return_value=mock_response)

            duplicates = await detect_duplicates(
                comment="The login page is not working properly",
                category="Bug Report",
                feedback_type="bug_report",
                similarity_threshold=0.7,
            )

            assert len(duplicates) > 0
            assert duplicates[0]["issue_number"] == 123
            assert duplicates[0]["similarity"] >= 0.7

    @pytest.mark.asyncio
    async def test_without_github_token(self):
        """Test duplicate detection without GitHub token."""
        with patch("app.ai_triage.GITHUB_TOKEN", None):
            duplicates = await detect_duplicates(comment="Test issue", category="General", feedback_type="feedback")

            assert duplicates == []

    @pytest.mark.asyncio
    async def test_api_error(self):
        """Test handling of API errors."""
        mock_response = Mock()
        mock_response.status_code = 500

        with patch("app.ai_triage.GITHUB_TOKEN", "test-token"), patch("httpx.AsyncClient") as mock_client:
            mock_client_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_client_instance
            mock_client_instance.get = AsyncMock(return_value=mock_response)

            duplicates = await detect_duplicates(comment="Test issue", category="General", feedback_type="feedback")

            assert duplicates == []


class TestDetermineMilestone:
    """Tests for milestone determination."""

    def test_p0_milestone(self):
        """Test milestone for P0 priority."""
        milestone = determine_milestone("P0", "bug_report")
        assert milestone == "Hotfix"

    def test_p1_milestone(self):
        """Test milestone for P1 priority."""
        milestone = determine_milestone("P1", "bug_report")
        assert milestone == "Next Sprint"

    def test_p2_milestone(self):
        """Test milestone for P2 priority."""
        milestone = determine_milestone("P2", "feature_request")
        assert milestone == "Backlog"

    def test_p3_milestone(self):
        """Test milestone for P3 priority."""
        milestone = determine_milestone("P3", "feedback")
        assert milestone == "Future"


class TestTriageFeedback:
    """Tests for complete triage process."""

    @pytest.mark.asyncio
    async def test_triage_with_no_duplicates(self):
        """Test triage when no duplicates are found."""
        with patch("app.ai_triage.detect_duplicates", return_value=[]):
            result = await triage_feedback(
                feedback_id=1,
                feedback_type="bug_report",
                category="Security",
                comment="Critical security issue",
                rating=1,
                sentiment_compound=-0.8,
            )

            assert result["feedback_id"] == 1
            assert result["priority"] == "P0"
            assert result["should_create_issue"] is True
            assert "security" in result["suggested_labels"]
            assert result["suggested_milestone"] == "Hotfix"
            assert len(result["potential_duplicates"]) == 0

    @pytest.mark.asyncio
    async def test_triage_with_duplicates(self):
        """Test triage when duplicates are found."""
        mock_duplicates = [
            {
                "issue_number": 123,
                "issue_url": "https://github.com/test/repo/issues/123",
                "title": "Similar issue",
                "similarity": 0.85,
                "state": "open",
            }
        ]

        with patch("app.ai_triage.detect_duplicates", return_value=mock_duplicates):
            result = await triage_feedback(
                feedback_id=2,
                feedback_type="bug_report",
                category="Performance",
                comment="Performance issue",
                rating=2,
                sentiment_compound=-0.3,
            )

            assert result["should_create_issue"] is False
            assert len(result["potential_duplicates"]) == 1
            assert "Duplicate issues found" in result["triage_reason"]

    @pytest.mark.asyncio
    async def test_triage_feature_request(self):
        """Test triage for feature request."""
        with patch("app.ai_triage.detect_duplicates", return_value=[]):
            result = await triage_feedback(
                feedback_id=3,
                feedback_type="feature_request",
                category="Features",
                comment="Add new feature for better workflow",
                rating=4,
                sentiment_compound=0.2,
            )

            assert result["priority"] in ["P2", "P3"]
            assert "enhancement" in result["suggested_labels"]
            assert result["should_create_issue"] is True
