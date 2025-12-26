# tests/unit/test_terraform_utils.py

import pytest
from hypothesis import given, strategies as st


def test_validate_environment_name():
    """Valid environment names should pass validation"""
    valid_names = ["dev", "staging", "production"]
    for name in valid_names:
        assert validate_environment_name(name) == True


def test_invalid_environment_name():
    """Invalid environment names should fail validation"""
    invalid_names = ["Dev", "PROD", "test123", ""]
    for name in invalid_names:
        assert validate_environment_name(name) == False


@given(st.integers(min_value=1, max_value=100))
def test_node_count_validation(node_count):
    """Property test: any valid node count should work"""
    config = create_cluster_config(node_count=node_count)
    assert config["node_count"] == node_count
    assert config["node_count"] > 0
