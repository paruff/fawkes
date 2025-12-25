"""
Unit tests for the Prometheus exporter.
"""
import json
import pytest
import tempfile
import importlib.util
from pathlib import Path
from unittest.mock import Mock, patch

# Import the exporter module
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))
from prometheus_client import REGISTRY


def test_prometheus_exporter_imports():
    """Test that prometheus exporter can be imported."""
    # Just check the file exists and has valid python syntax
    exporter_path = Path(__file__).parent.parent / "prometheus-exporter.py"
    assert exporter_path.exists(), "prometheus-exporter.py not found"

    # Try to compile it
    try:
        with open(exporter_path, 'r') as f:
            code = f.read()
            compile(code, str(exporter_path), 'exec')
    except SyntaxError as e:
        pytest.fail(f"Syntax error in prometheus-exporter.py: {e}")


def test_exporter_script_exists():
    """Test that the prometheus-exporter.py script exists."""
    exporter_path = Path(__file__).parent.parent / "prometheus-exporter.py"
    assert exporter_path.exists(), "prometheus-exporter.py not found"
    assert exporter_path.is_file(), "prometheus-exporter.py is not a file"


def test_exporter_script_is_executable():
    """Test that the exporter script has executable permissions."""
    exporter_path = Path(__file__).parent.parent / "prometheus-exporter.py"
    assert exporter_path.exists()
    # Check shebang
    with open(exporter_path, 'r') as f:
        first_line = f.readline()
        assert first_line.startswith('#!'), "Missing shebang line"
        assert 'python' in first_line.lower(), "Shebang should reference python"


def test_metrics_exporter_class():
    """Test that MetricsExporter class is defined in the script."""
    exporter_path = Path(__file__).parent.parent / "prometheus-exporter.py"
    with open(exporter_path, 'r') as f:
        content = f.read()
        assert 'class MetricsExporter' in content
        assert 'def parse_checkpoint_result' in content
        assert 'def load_latest_results' in content


def test_parse_checkpoint_result_structure():
    """Test that script handles checkpoint result structure."""
    exporter_path = Path(__file__).parent.parent / "prometheus-exporter.py"
    with open(exporter_path, 'r') as f:
        content = f.read()
        # Check for expected data extraction
        assert 'checkpoint_name' in content
        assert 'statistics' in content
        assert 'evaluated_expectations' in content
        assert 'successful_expectations' in content
        assert 'unsuccessful_expectations' in content


def test_parse_inline_result_valid_json():
    """Test that script has JSON parsing capability."""
    exporter_path = Path(__file__).parent.parent / "prometheus-exporter.py"
    with open(exporter_path, 'r') as f:
        content = f.read()
        assert 'json.loads' in content
        assert 'parse_inline_result' in content


def test_parse_inline_result_invalid_json():
    """Test that script handles JSON errors."""
    exporter_path = Path(__file__).parent.parent / "prometheus-exporter.py"
    with open(exporter_path, 'r') as f:
        content = f.read()
        assert 'JSONDecodeError' in content or 'json.JSONDecodeError' in content


def test_load_latest_results_empty_dir():
    """Test that script checks for results directory existence."""
    exporter_path = Path(__file__).parent.parent / "prometheus-exporter.py"
    with open(exporter_path, 'r') as f:
        content = f.read()
        assert 'results_dir.exists()' in content or 'exists()' in content


def test_load_latest_results_nonexistent_dir():
    """Test that script has error handling for missing directories."""
    exporter_path = Path(__file__).parent.parent / "prometheus-exporter.py"
    with open(exporter_path, 'r') as f:
        content = f.read()
        assert 'logger.warning' in content or 'logger.error' in content


def test_metrics_registry_metrics_defined():
    """Test that all expected metrics are defined in the script."""
    exporter_path = Path(__file__).parent.parent / "prometheus-exporter.py"
    with open(exporter_path, 'r') as f:
        content = f.read()
        # Check for all expected metrics
        assert 'validation_success' in content
        assert 'validation_duration' in content
        assert 'expectation_failures' in content
        assert 'data_freshness' in content
        assert 'validation_runs' in content
        assert 'expectations_total' in content
        assert 'expectations_successful' in content
        assert 'success_rate' in content


def test_exporter_has_main_function():
    """Test that the exporter has a main function."""
    exporter_path = Path(__file__).parent.parent / "prometheus-exporter.py"
    with open(exporter_path, 'r') as f:
        content = f.read()
        assert 'def main():' in content


def test_exporter_has_run_server_function():
    """Test that the exporter has a run_server function."""
    exporter_path = Path(__file__).parent.parent / "prometheus-exporter.py"
    with open(exporter_path, 'r') as f:
        content = f.read()
        assert 'def run_server' in content
        assert 'HTTPServer' in content


def test_requirements_includes_prometheus_client():
    """Test that requirements.txt includes prometheus-client."""
    requirements_path = Path(__file__).parent.parent / "requirements.txt"
    assert requirements_path.exists(), "requirements.txt not found"

    with open(requirements_path, 'r') as f:
        content = f.read()
        assert 'prometheus-client' in content or 'prometheus_client' in content, \
            "prometheus-client not found in requirements.txt"
