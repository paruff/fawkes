"""
Example unit tests to verify testing infrastructure works.

These tests validate that:
1. Pytest is configured correctly
2. Fixtures are available
3. Markers work as expected
"""

import pytest
from datetime import datetime


@pytest.mark.unit
def test_basic_assertion():
    """Basic test to verify pytest works."""
    assert 1 + 1 == 2


@pytest.mark.unit
@pytest.mark.smoke
def test_string_operations():
    """Test string operations (smoke test)."""
    text = "fawkes platform"
    assert text.upper() == "FAWKES PLATFORM"
    assert "platform" in text


@pytest.mark.unit
@pytest.mark.dora_deployment_frequency
def test_with_dora_marker():
    """Test with DORA metric marker."""
    # This test is tagged as relating to deployment frequency
    deployment_count = 5
    assert deployment_count > 0


@pytest.mark.unit
def test_datetime_operations():
    """Test datetime handling."""
    now = datetime.utcnow()
    assert now.year >= 2025


class TestCalculations:
    """Group of related tests using a class."""

    @pytest.mark.unit
    def test_addition(self):
        """Test addition."""
        assert 2 + 2 == 4

    @pytest.mark.unit
    def test_subtraction(self):
        """Test subtraction."""
        assert 5 - 3 == 2


@pytest.mark.unit
def test_list_operations():
    """Test list operations."""
    items = [1, 2, 3, 4, 5]
    assert len(items) == 5
    assert sum(items) == 15
    assert max(items) == 5


@pytest.mark.unit
@pytest.mark.parametrize(
    "input,expected",
    [
        ("hello", "HELLO"),
        ("world", "WORLD"),
        ("fawkes", "FAWKES"),
    ],
)
def test_uppercase_parametrized(input, expected):
    """Parametrized test for uppercase conversion."""
    assert input.upper() == expected
