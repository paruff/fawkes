"""Unit tests for CLI commands."""

import pytest
from click.testing import CliRunner
from unittest.mock import Mock, patch, MagicMock

from friction_cli.cli import main
from friction_cli.config import FrictionConfig


@pytest.fixture
def runner():
    """Create CLI test runner."""
    return CliRunner()


@pytest.fixture
def mock_config():
    """Create mock configuration."""
    return FrictionConfig(
        api_url="http://test-api:8000",
        author="Test User",
    )


@pytest.fixture
def mock_client():
    """Create mock API client."""
    client = Mock()
    client.health_check.return_value = True
    client.create_insight.return_value = {
        "id": 123,
        "title": "Test friction",
        "category": {"name": "Test"},
        "priority": "medium",
    }
    client.list_insights.return_value = [
        {
            "id": 1,
            "title": "Test friction 1",
            "category": {"name": "CI/CD"},
            "priority": "high",
            "status": "open",
        },
        {
            "id": 2,
            "title": "Test friction 2",
            "category": {"name": "Documentation"},
            "priority": "medium",
            "status": "new",
        },
    ]
    client.get_insight.return_value = {
        "id": 123,
        "title": "Test friction",
        "description": "Test description",
        "category": {"name": "Test"},
        "priority": "medium",
        "status": "new",
        "author": "Test User",
        "created_at": "2024-01-01T00:00:00Z",
        "tags": [{"name": "test"}, {"name": "friction"}],
    }
    client.list_categories.return_value = [
        {"id": 1, "name": "CI/CD", "description": "CI/CD issues"},
        {"id": 2, "name": "Documentation", "description": "Documentation issues"},
    ]
    return client


def test_version(runner):
    """Test version command."""
    result = runner.invoke(main, ["--version"])
    assert result.exit_code == 0
    assert "version" in result.output.lower()


def test_help(runner):
    """Test help command."""
    result = runner.invoke(main, ["--help"])
    assert result.exit_code == 0
    assert "Fawkes Friction Logger" in result.output


@patch("friction_cli.cli.InsightsClient")
@patch("friction_cli.cli.ConfigManager")
def test_log_quick_mode(mock_config_manager, mock_client_class, runner, mock_config, mock_client):
    """Test logging friction in quick mode."""
    mock_config_manager.return_value.config = mock_config
    mock_client_class.return_value = mock_client

    result = runner.invoke(main, [
        "log",
        "-t", "Test friction",
        "-d", "Test description",
        "-c", "CI/CD",
        "-p", "high",
    ])

    assert result.exit_code == 0
    assert "logged successfully" in result.output
    mock_client.create_insight.assert_called_once()


@patch("friction_cli.cli.InsightsClient")
@patch("friction_cli.cli.ConfigManager")
def test_log_with_tags(mock_config_manager, mock_client_class, runner, mock_config, mock_client):
    """Test logging friction with tags."""
    mock_config_manager.return_value.config = mock_config
    mock_client_class.return_value = mock_client

    result = runner.invoke(main, [
        "log",
        "-t", "Test friction",
        "-d", "Test description",
        "-T", "tag1",
        "-T", "tag2",
    ])

    assert result.exit_code == 0
    mock_client.create_insight.assert_called_once()
    call_args = mock_client.create_insight.call_args[0][0]
    assert "tag1" in call_args.tags
    assert "tag2" in call_args.tags
    assert "friction" in call_args.tags  # Auto-added


@patch("friction_cli.cli.InsightsClient")
@patch("friction_cli.cli.ConfigManager")
def test_log_api_unreachable(mock_config_manager, mock_client_class, runner, mock_config, mock_client):
    """Test logging when API is unreachable."""
    mock_config_manager.return_value.config = mock_config
    mock_client.health_check.return_value = False
    mock_client_class.return_value = mock_client

    result = runner.invoke(main, [
        "log",
        "-t", "Test friction",
        "-d", "Test description",
    ])

    assert result.exit_code == 1
    assert "Cannot connect" in result.output


@patch("friction_cli.cli.InsightsClient")
@patch("friction_cli.cli.ConfigManager")
def test_list_command(mock_config_manager, mock_client_class, runner, mock_config, mock_client):
    """Test list command."""
    mock_config_manager.return_value.config = mock_config
    mock_client_class.return_value = mock_client

    result = runner.invoke(main, ["list"])

    assert result.exit_code == 0
    assert "Test friction 1" in result.output
    assert "Test friction 2" in result.output
    mock_client.list_insights.assert_called_once()


@patch("friction_cli.cli.InsightsClient")
@patch("friction_cli.cli.ConfigManager")
def test_list_with_filters(mock_config_manager, mock_client_class, runner, mock_config, mock_client):
    """Test list command with filters."""
    mock_config_manager.return_value.config = mock_config
    mock_client_class.return_value = mock_client

    result = runner.invoke(main, [
        "list",
        "-c", "CI/CD",
        "-p", "high",
        "-l", "20",
    ])

    assert result.exit_code == 0
    mock_client.list_insights.assert_called_once_with(
        category="CI/CD",
        priority="high",
        limit=20,
    )


@patch("friction_cli.cli.InsightsClient")
@patch("friction_cli.cli.ConfigManager")
def test_list_empty(mock_config_manager, mock_client_class, runner, mock_config, mock_client):
    """Test list command with no results."""
    mock_config_manager.return_value.config = mock_config
    mock_client.list_insights.return_value = []
    mock_client_class.return_value = mock_client

    result = runner.invoke(main, ["list"])

    assert result.exit_code == 0
    assert "No friction points found" in result.output


@patch("friction_cli.cli.InsightsClient")
@patch("friction_cli.cli.ConfigManager")
def test_show_command(mock_config_manager, mock_client_class, runner, mock_config, mock_client):
    """Test show command."""
    mock_config_manager.return_value.config = mock_config
    mock_client_class.return_value = mock_client

    result = runner.invoke(main, ["show", "123"])

    assert result.exit_code == 0
    assert "Test friction" in result.output
    assert "Test description" in result.output
    mock_client.get_insight.assert_called_once_with(123)


@patch("friction_cli.cli.InsightsClient")
@patch("friction_cli.cli.ConfigManager")
def test_categories_list(mock_config_manager, mock_client_class, runner, mock_config, mock_client):
    """Test categories list command."""
    mock_config_manager.return_value.config = mock_config
    mock_client_class.return_value = mock_client

    result = runner.invoke(main, ["categories", "list"])

    assert result.exit_code == 0
    assert "CI/CD" in result.output
    assert "Documentation" in result.output
    mock_client.list_categories.assert_called_once()


@patch("friction_cli.cli.ConfigManager")
def test_config_show(mock_config_manager, runner, mock_config):
    """Test config show command."""
    mock_config_manager.return_value.config = mock_config
    mock_config_manager.return_value.config_path = "/test/.friction/config.yaml"

    result = runner.invoke(main, ["config", "show"])

    assert result.exit_code == 0
    assert "http://test-api:8000" in result.output
    assert "Test User" in result.output


@patch("friction_cli.cli.InsightsClient")
@patch("friction_cli.cli.ConfigManager")
def test_config_init(mock_config_manager, mock_client_class, runner):
    """Test config init command."""
    mock_client = Mock()
    mock_client.health_check.return_value = True
    mock_client_class.return_value = mock_client

    mock_manager = Mock()
    mock_config_manager.return_value = mock_manager

    result = runner.invoke(main, [
        "config", "init",
        "--api-url", "http://test-api:8000",
        "--author", "Test User",
    ])

    assert result.exit_code == 0
    assert "Configuration saved" in result.output
    mock_manager.save.assert_called_once()


def test_cli_without_config(runner):
    """Test CLI without configuration (should use defaults)."""
    with patch("friction_cli.cli.ConfigManager") as mock_config_manager:
        mock_config = FrictionConfig()
        mock_config_manager.return_value.config = mock_config

        result = runner.invoke(main, ["config", "show"])

        assert result.exit_code == 0
