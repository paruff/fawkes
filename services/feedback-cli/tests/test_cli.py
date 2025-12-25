"""Tests for CLI commands."""

import pytest
import responses
from click.testing import CliRunner
from feedback_cli.cli import main


@pytest.fixture
def runner():
    """Create CLI test runner."""
    return CliRunner()


def test_cli_version(runner):
    """Test version command."""
    result = runner.invoke(main, ["--version"])
    assert result.exit_code == 0
    assert "0.1.0" in result.output


def test_cli_help(runner):
    """Test help command."""
    result = runner.invoke(main, ["--help"])
    assert result.exit_code == 0
    assert "Fawkes Feedback CLI" in result.output
    assert "submit" in result.output
    assert "list" in result.output
    assert "config" in result.output


@responses.activate
def test_submit_with_flags(runner):
    """Test submit command with flags."""
    responses.add(
        responses.GET,
        "http://feedback-service.fawkes.svc.cluster.local:8000/health",
        json={"status": "healthy"},
        status=200,
    )
    responses.add(
        responses.POST,
        "http://feedback-service.fawkes.svc.cluster.local:8000/api/v1/feedback",
        json={
            "id": 123,
            "rating": 5,
            "category": "Test",
            "comment": "Great!",
            "status": "open",
            "created_at": "2024-01-01T00:00:00",
            "updated_at": "2024-01-01T00:00:00",
        },
        status=201,
    )

    result = runner.invoke(
        main,
        [
            "submit",
            "-r",
            "5",
            "-c",
            "Test",
            "-m",
            "Great!",
        ],
    )

    assert result.exit_code == 0
    assert "successfully" in result.output.lower()


def test_submit_missing_required_fields(runner):
    """Test submit command with missing required fields enters interactive mode."""
    # When missing fields, it goes into interactive mode and waits for input
    # Since we're not providing input, it should abort
    result = runner.invoke(
        main,
        [
            "submit",
            "-r",
            "5",
            # Missing category and comment triggers interactive mode
        ],
    )

    # Should show interactive mode or abort
    assert result.exit_code != 0
    assert "Interactive Mode" in result.output or "Aborted" in result.output


@responses.activate
def test_list_command(runner):
    """Test list command."""
    responses.add(
        responses.GET,
        "http://feedback-service.fawkes.svc.cluster.local:8000/health",
        json={"status": "healthy"},
        status=200,
    )
    responses.add(
        responses.GET,
        "http://feedback-service.fawkes.svc.cluster.local:8000/api/v1/feedback",
        json={
            "items": [
                {
                    "id": 1,
                    "rating": 5,
                    "category": "Test",
                    "feedback_type": "feedback",
                    "status": "open",
                    "created_at": "2024-01-01T00:00:00",
                },
            ],
            "total": 1,
            "page": 1,
            "page_size": 10,
        },
        status=200,
    )

    result = runner.invoke(main, ["list"])

    assert result.exit_code == 0
    assert "Recent Feedback" in result.output


def test_config_show(runner):
    """Test config show command."""
    result = runner.invoke(main, ["config", "show"])

    assert result.exit_code == 0
    assert "Configuration" in result.output
    assert "API URL" in result.output


def test_queue_empty(runner):
    """Test queue command with empty queue."""
    with runner.isolated_filesystem():
        result = runner.invoke(main, ["queue"])

        assert result.exit_code == 0
        assert "empty" in result.output.lower()


def test_config_set_offline(runner):
    """Test setting offline mode."""
    with runner.isolated_filesystem():
        result = runner.invoke(main, ["config", "set-offline", "true"])

        assert result.exit_code == 0
        assert "enabled" in result.output.lower()
