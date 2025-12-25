"""
Unit tests for Backstage TechDocs indexer.
"""
import pytest
import sys
import os
from unittest.mock import Mock, patch

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../.."))

from indexers.techdocs import BackstageIndexer


class TestBackstageIndexer:
    """Test Backstage TechDocs indexer functionality."""

    @patch('indexers.techdocs.weaviate.Client')
    def test_indexer_initialization(self, mock_weaviate):
        """Test indexer initializes correctly."""
        mock_client = Mock()
        mock_client.is_ready.return_value = True
        mock_weaviate.return_value = mock_client

        indexer = BackstageIndexer(
            backstage_url="http://backstage.example.com",
            weaviate_url="http://test:8080",
            dry_run=False
        )

        assert indexer.backstage_url == "http://backstage.example.com"
        assert indexer.weaviate_url == "http://test:8080"
        assert indexer.dry_run is False
        assert indexer.weaviate_client is not None

    def test_indexer_dry_run_mode(self):
        """Test indexer in dry-run mode doesn't connect to Weaviate."""
        indexer = BackstageIndexer(
            backstage_url="http://backstage.example.com",
            dry_run=True
        )

        assert indexer.dry_run is True
        assert indexer.weaviate_client is None

    def test_indexer_with_auth_token(self):
        """Test indexer with authentication token."""
        indexer = BackstageIndexer(
            backstage_url="http://backstage.example.com",
            auth_token="test_token",
            dry_run=True
        )

        assert indexer.auth_token == "test_token"
        assert "Authorization" in indexer.session.headers

    def test_extract_text_from_html(self):
        """Test HTML text extraction using BeautifulSoup."""
        indexer = BackstageIndexer(
            backstage_url="http://test",
            dry_run=True
        )

        html = """
        <html>
        <head><title>Test</title></head>
        <body>
            <h1>Main Title</h1>
            <p>This is a paragraph.</p>
            <script>console.log('hidden');</script>
            <style>.hidden { display: none; }</style>
        </body>
        </html>
        """

        text = indexer._extract_text_from_html(html)

        # BeautifulSoup properly extracts text
        assert "Main Title" in text
        assert "This is a paragraph" in text
        # Script and style content should be removed
        assert "console.log" not in text
        assert ".hidden" not in text
        assert "display: none" not in text

    def test_extract_sections_with_headings(self):
        """Test section extraction from content with headings."""
        indexer = BackstageIndexer(
            backstage_url="http://test",
            dry_run=True
        )

        content = """# Introduction
This is the introduction.

## Overview
This is the overview section.

## Details
This section has more details.
"""

        sections = indexer.extract_sections(content)

        assert len(sections) >= 2
        headings = [s["heading"] for s in sections]
        assert "Introduction" in headings or "Overview" in headings

    def test_extract_sections_no_headings(self):
        """Test section extraction from content without headings."""
        indexer = BackstageIndexer(
            backstage_url="http://test",
            dry_run=True
        )

        content = "Just plain content without any headings."
        sections = indexer.extract_sections(content)

        assert len(sections) == 1
        assert sections[0]["content"].strip() == content

    def test_chunk_content_short(self):
        """Test chunking short content returns single chunk."""
        indexer = BackstageIndexer(
            backstage_url="http://test",
            dry_run=True
        )

        content = "Short content"
        chunks = indexer.chunk_content(content)

        assert len(chunks) == 1
        assert chunks[0] == content

    def test_chunk_content_long(self):
        """Test chunking long content returns multiple chunks."""
        indexer = BackstageIndexer(
            backstage_url="http://test",
            dry_run=True
        )

        # Create content longer than MAX_CHUNK_CHARS
        content = "Paragraph.\n\n" * 500
        chunks = indexer.chunk_content(content)

        assert len(chunks) > 1
        # Each chunk should be within size limits (with some tolerance)
        max_chunk_chars = 512 * 4  # MAX_CHUNK_SIZE * 4
        for chunk in chunks:
            assert len(chunk) <= max_chunk_chars * 1.1  # Allow 10% overflow

    def test_get_content_hash(self):
        """Test content hash calculation."""
        indexer = BackstageIndexer(
            backstage_url="http://test",
            dry_run=True
        )

        content = "Test content"
        hash1 = indexer.get_content_hash(content)
        hash2 = indexer.get_content_hash(content)

        assert hash1 == hash2  # Same content should produce same hash
        assert len(hash1) == 32  # MD5 hash is 32 hex characters

    @patch('indexers.techdocs.requests.Session')
    def test_backstage_request_success(self, mock_session):
        """Test successful Backstage API request."""
        indexer = BackstageIndexer(
            backstage_url="http://test",
            dry_run=True
        )

        # Mock response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": "test"}
        indexer.session.get = Mock(return_value=mock_response)

        result = indexer._backstage_request("/api/test")

        assert result == {"data": "test"}

    @patch('indexers.techdocs.requests.Session')
    def test_backstage_request_404(self, mock_session):
        """Test Backstage API request with 404 error."""
        indexer = BackstageIndexer(
            backstage_url="http://test",
            dry_run=True
        )

        # Mock response
        mock_response = Mock()
        mock_response.status_code = 404
        indexer.session.get = Mock(return_value=mock_response)

        result = indexer._backstage_request("/api/test")

        assert result is None

    def test_fetch_catalog_entities_list_response(self):
        """Test fetching catalog entities with list response."""
        indexer = BackstageIndexer(
            backstage_url="http://test",
            dry_run=True
        )

        mock_entities = [
            {"kind": "Component", "metadata": {"name": "test1"}},
            {"kind": "API", "metadata": {"name": "test2"}}
        ]

        indexer._backstage_request = Mock(return_value=mock_entities)

        entities = indexer.fetch_catalog_entities()

        assert len(entities) == 2
        assert entities[0]["kind"] == "Component"

    def test_fetch_catalog_entities_dict_response(self):
        """Test fetching catalog entities with dict response."""
        indexer = BackstageIndexer(
            backstage_url="http://test",
            dry_run=True
        )

        mock_response = {
            "items": [
                {"kind": "Component", "metadata": {"name": "test1"}},
                {"kind": "API", "metadata": {"name": "test2"}}
            ]
        }

        indexer._backstage_request = Mock(return_value=mock_response)

        entities = indexer.fetch_catalog_entities()

        assert len(entities) == 2
        assert entities[0]["kind"] == "Component"

    def test_fetch_techdocs_metadata(self):
        """Test fetching TechDocs metadata for an entity."""
        indexer = BackstageIndexer(
            backstage_url="http://test",
            dry_run=True
        )

        entity = {
            "kind": "Component",
            "metadata": {
                "namespace": "default",
                "name": "my-service"
            }
        }

        mock_metadata = {
            "site_name": "My Service",
            "site_description": "Service documentation"
        }

        indexer._backstage_request = Mock(return_value=mock_metadata)

        result = indexer.fetch_techdocs_metadata(entity)

        assert result is not None
        assert result["entity_ref"] == "component:default/my-service"
        assert "docs_path" in result
        assert "metadata" in result
