"""
Unit tests for GitHub indexer.
"""
import pytest
import sys
import os
from unittest.mock import Mock, patch, MagicMock

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../.."))

from indexers.github import GitHubIndexer, RateLimiter


class TestRateLimiter:
    """Test rate limiter functionality."""

    def test_rate_limiter_initialization(self):
        """Test that rate limiter initializes correctly."""
        limiter = RateLimiter()
        assert limiter.remaining is None
        assert limiter.reset_time is None
        assert limiter.last_check is None

    def test_rate_limiter_update(self):
        """Test updating rate limit from headers."""
        limiter = RateLimiter()
        headers = {
            "X-RateLimit-Remaining": "100",
            "X-RateLimit-Reset": "1234567890"
        }
        limiter.update(headers)
        assert limiter.remaining == 100
        assert limiter.reset_time == 1234567890
        assert limiter.last_check is not None

    def test_should_wait_when_low_remaining(self):
        """Test that we should wait when remaining requests are low."""
        limiter = RateLimiter()
        limiter.remaining = 5
        limiter.reset_time = 9999999999  # Far future
        should_wait, wait_time = limiter.should_wait()
        assert should_wait
        assert wait_time > 0


class TestGitHubIndexer:
    """Test GitHub indexer functionality."""

    @patch('indexers.github.weaviate.Client')
    def test_indexer_initialization(self, mock_weaviate):
        """Test indexer initializes correctly."""
        mock_client = Mock()
        mock_client.is_ready.return_value = True
        mock_weaviate.return_value = mock_client

        indexer = GitHubIndexer(
            github_token="test_token",
            weaviate_url="http://test:8080",
            dry_run=False
        )

        assert indexer.github_token == "test_token"
        assert indexer.weaviate_url == "http://test:8080"
        assert indexer.dry_run is False
        assert indexer.weaviate_client is not None

    def test_indexer_dry_run_mode(self):
        """Test indexer in dry-run mode doesn't connect to Weaviate."""
        indexer = GitHubIndexer(
            github_token="test_token",
            dry_run=True
        )

        assert indexer.dry_run is True
        assert indexer.weaviate_client is None

    def test_chunk_content_short(self):
        """Test chunking short content returns single chunk."""
        indexer = GitHubIndexer(github_token="test", dry_run=True)
        content = "Short content"
        chunks = indexer.chunk_content(content)

        assert len(chunks) == 1
        assert chunks[0] == content

    def test_chunk_content_long(self):
        """Test chunking long content returns multiple chunks."""
        indexer = GitHubIndexer(github_token="test", dry_run=True)
        # Create content longer than MAX_CHUNK_CHARS
        content = "Paragraph.\n\n" * 500
        chunks = indexer.chunk_content(content)

        assert len(chunks) > 1
        max_chunk_chars = 512 * 4  # MAX_CHUNK_SIZE * 4
        for chunk in chunks:
            assert len(chunk) <= max_chunk_chars * 1.1  # Allow 10% overflow

    def test_get_file_hash(self):
        """Test file hash calculation."""
        indexer = GitHubIndexer(github_token="test", dry_run=True)
        content = "Test content"
        hash1 = indexer.get_file_hash(content)
        hash2 = indexer.get_file_hash(content)

        assert hash1 == hash2  # Same content should produce same hash
        assert len(hash1) == 32  # MD5 hash is 32 hex characters

    @patch('indexers.github.requests.Session')
    def test_github_request_success(self, mock_session):
        """Test successful GitHub API request."""
        indexer = GitHubIndexer(github_token="test", dry_run=True)

        # Mock response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": "test"}
        mock_response.headers = {}
        indexer.session.get = Mock(return_value=mock_response)

        result = indexer._github_request("https://api.github.com/test")

        assert result == {"data": "test"}

    @patch('indexers.github.requests.Session')
    def test_github_request_404(self, mock_session):
        """Test GitHub API request with 404 error."""
        indexer = GitHubIndexer(github_token="test", dry_run=True)

        # Mock response
        mock_response = Mock()
        mock_response.status_code = 404
        mock_response.headers = {}
        indexer.session.get = Mock(return_value=mock_response)

        result = indexer._github_request("https://api.github.com/test")

        assert result is None

    def test_fetch_file_content_with_content(self):
        """Test fetching file content from GitHub API response."""
        indexer = GitHubIndexer(github_token="test", dry_run=True)

        # Mock file info with base64 encoded content
        import base64
        content = "Test file content"
        encoded = base64.b64encode(content.encode()).decode()

        file_info = {
            "type": "file",
            "size": len(content),
            "content": encoded
        }

        result = indexer.fetch_file_content(file_info)

        assert result == content

    def test_fetch_file_content_too_large(self):
        """Test that large files are skipped."""
        indexer = GitHubIndexer(github_token="test", dry_run=True)

        file_info = {
            "type": "file",
            "size": 2 * 1024 * 1024,  # 2MB
            "path": "large_file.md"
        }

        result = indexer.fetch_file_content(file_info)

        assert result is None

    def test_fetch_file_content_not_file(self):
        """Test that non-file types are skipped."""
        indexer = GitHubIndexer(github_token="test", dry_run=True)

        file_info = {
            "type": "dir",
            "name": "directory"
        }

        result = indexer.fetch_file_content(file_info)

        assert result is None
