"""
Unit tests for RAG indexing script functionality.

These tests validate the test-indexing.py script's core functions
without requiring a live Weaviate instance.
"""

import pytest
from pathlib import Path
import sys

# Add services directory to path
services_path = Path(__file__).parent.parent.parent / "services" / "rag" / "scripts"
sys.path.insert(0, str(services_path))


@pytest.mark.unit
def test_sample_documents_structure():
    """Test that sample documents have the required structure."""
    # Import the function (will fail gracefully if weaviate-client not installed)
    try:
        from test_indexing import get_sample_documents
    except ImportError:
        pytest.skip("weaviate-client not installed")
    
    documents = get_sample_documents()
    
    # Verify we have documents
    assert len(documents) > 0, "Should have at least one sample document"
    
    # Verify each document has required fields
    required_fields = ["title", "content", "filepath", "category"]
    for doc in documents:
        for field in required_fields:
            assert field in doc, f"Document missing required field: {field}"
            assert doc[field], f"Field {field} should not be empty"
    
    # Verify categories are valid
    valid_categories = ["adr", "readme", "doc", "code"]
    for doc in documents:
        assert doc["category"] in valid_categories, \
            f"Invalid category: {doc['category']}"


@pytest.mark.unit
def test_sample_documents_content():
    """Test that sample documents contain meaningful content."""
    try:
        from test_indexing import get_sample_documents
    except ImportError:
        pytest.skip("weaviate-client not installed")
    
    documents = get_sample_documents()
    
    for doc in documents:
        # Title should be reasonably long
        assert len(doc["title"]) > 5, \
            f"Title too short: {doc['title']}"
        
        # Content should be substantial
        assert len(doc["content"]) > 50, \
            f"Content too short for document: {doc['title']}"
        
        # Filepath should look like a path
        assert "/" in doc["filepath"], \
            f"Filepath doesn't look like a path: {doc['filepath']}"


@pytest.mark.unit
def test_schema_constants():
    """Test that constants are properly defined."""
    try:
        from test_indexing import (
            DEFAULT_WEAVIATE_URL,
            SCHEMA_NAME,
            MIN_RELEVANCE_SCORE
        )
    except ImportError:
        pytest.skip("weaviate-client not installed")
    
    # Verify constants
    assert DEFAULT_WEAVIATE_URL.startswith("http"), \
        "Default URL should start with http"
    assert SCHEMA_NAME, "Schema name should not be empty"
    assert 0 <= MIN_RELEVANCE_SCORE <= 1, \
        "Relevance score should be between 0 and 1"


@pytest.mark.unit
@pytest.mark.parametrize("category,expected_count", [
    ("adr", 2),  # Expect 2 ADR documents
    ("readme", 1),  # Expect 1 README
    ("doc", 2),  # Expect 2 doc files
])
def test_document_categories(category, expected_count):
    """Test that we have the expected number of documents per category."""
    try:
        from test_indexing import get_sample_documents
    except ImportError:
        pytest.skip("weaviate-client not installed")
    
    documents = get_sample_documents()
    category_docs = [doc for doc in documents if doc["category"] == category]
    
    assert len(category_docs) >= expected_count, \
        f"Expected at least {expected_count} {category} documents, got {len(category_docs)}"


@pytest.mark.unit
def test_adr_documents_format():
    """Test that ADR documents follow the ADR format."""
    try:
        from test_indexing import get_sample_documents
    except ImportError:
        pytest.skip("weaviate-client not installed")
    
    documents = get_sample_documents()
    adr_docs = [doc for doc in documents if doc["category"] == "adr"]
    
    for doc in adr_docs:
        # ADR title should include "ADR-"
        assert "ADR-" in doc["title"], \
            f"ADR title should contain 'ADR-': {doc['title']}"
        
        # ADR content should have sections
        content = doc["content"]
        assert "Status" in content or "## Status" in content, \
            "ADR should have a Status section"
        assert "Decision" in content or "## Decision" in content, \
            "ADR should have a Decision section"


@pytest.mark.unit
def test_script_has_main_guard():
    """Test that the script can be imported without executing."""
    # This test passes if we can import without errors
    # and without the script executing
    try:
        import test_indexing
        assert hasattr(test_indexing, "main"), \
            "Script should have a main function"
    except ImportError:
        pytest.skip("weaviate-client not installed")


@pytest.mark.unit
def test_relevance_threshold():
    """Test that the relevance threshold is appropriate."""
    try:
        from test_indexing import MIN_RELEVANCE_SCORE
    except ImportError:
        pytest.skip("weaviate-client not installed")
    
    # 0.7 is a good threshold for semantic search
    assert MIN_RELEVANCE_SCORE == 0.7, \
        "Relevance threshold should be 0.7 as per requirements"
