"""Tests for configuration management."""

import os
import tempfile
from pathlib import Path

import pytest
import yaml
from feedback_cli.config import ConfigManager, FeedbackConfig


@pytest.fixture
def temp_config_dir():
    """Create temporary config directory."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


def test_config_defaults():
    """Test default configuration values."""
    config = FeedbackConfig()
    
    assert config.api_url == "http://feedback-service.fawkes.svc.cluster.local:8000"
    assert config.api_key is None
    assert config.default_category == "General"
    assert config.offline_mode is True


def test_config_custom_values():
    """Test configuration with custom values."""
    config = FeedbackConfig(
        api_url="http://custom-api.com",
        api_key="test-key",
        default_category="Custom",
        author="Test User",
        offline_mode=False,
    )
    
    assert config.api_url == "http://custom-api.com"
    assert config.api_key == "test-key"
    assert config.default_category == "Custom"
    assert config.author == "Test User"
    assert config.offline_mode is False


def test_config_manager_load_from_file(temp_config_dir):
    """Test loading configuration from file."""
    config_path = temp_config_dir / "config.yaml"
    config_data = {
        "api_url": "http://file-api.com",
        "default_category": "File Category",
    }
    
    with open(config_path, "w") as f:
        yaml.safe_dump(config_data, f)
    
    manager = ConfigManager(config_path)
    config = manager.load()
    
    assert config.api_url == "http://file-api.com"
    assert config.default_category == "File Category"


def test_config_manager_save(temp_config_dir):
    """Test saving configuration to file."""
    config_path = temp_config_dir / "config.yaml"
    manager = ConfigManager(config_path)
    
    config = FeedbackConfig(
        api_url="http://saved-api.com",
        author="Saved User",
    )
    
    manager.save(config)
    
    assert config_path.exists()
    
    with open(config_path, "r") as f:
        saved_data = yaml.safe_load(f)
    
    assert saved_data["api_url"] == "http://saved-api.com"
    assert saved_data["author"] == "Saved User"


def test_config_manager_env_override(temp_config_dir, monkeypatch):
    """Test environment variable override."""
    config_path = temp_config_dir / "config.yaml"
    config_data = {"api_url": "http://file-api.com"}
    
    with open(config_path, "w") as f:
        yaml.safe_dump(config_data, f)
    
    # Set environment variable
    monkeypatch.setenv("FEEDBACK_API_URL", "http://env-api.com")
    monkeypatch.setenv("FEEDBACK_AUTHOR", "Env User")
    
    manager = ConfigManager(config_path)
    config = manager.load()
    
    # Environment should override file
    assert config.api_url == "http://env-api.com"
    assert config.author == "Env User"


def test_config_manager_default_path():
    """Test default config path."""
    manager = ConfigManager()
    
    expected_path = Path.home() / ".fawkes-feedback" / "config.yaml"
    assert manager.config_path == expected_path


def test_config_manager_property(temp_config_dir):
    """Test config property lazy loading."""
    config_path = temp_config_dir / "config.yaml"
    manager = ConfigManager(config_path)
    
    # Config should be None initially
    assert manager._config is None
    
    # Accessing property should load config
    config = manager.config
    assert config is not None
    assert manager._config is not None
    
    # Second access should return cached config
    config2 = manager.config
    assert config2 is config


def test_config_offline_mode_env(temp_config_dir, monkeypatch):
    """Test offline mode from environment."""
    config_path = temp_config_dir / "config.yaml"
    
    # Test various true values
    for value in ["true", "1", "yes"]:
        monkeypatch.setenv("FEEDBACK_OFFLINE_MODE", value)
        manager = ConfigManager(config_path)
        config = manager.load()
        assert config.offline_mode is True
        manager._config = None  # Reset for next iteration
    
    # Test false value
    monkeypatch.setenv("FEEDBACK_OFFLINE_MODE", "false")
    manager = ConfigManager(config_path)
    config = manager.load()
    assert config.offline_mode is False


def test_config_queue_path_default(temp_config_dir):
    """Test default queue path."""
    config_path = temp_config_dir / "config.yaml"
    manager = ConfigManager(config_path)
    config = manager.load()
    
    expected_queue_path = str(Path.home() / ".fawkes-feedback" / "queue.json")
    assert config.queue_path == expected_queue_path
