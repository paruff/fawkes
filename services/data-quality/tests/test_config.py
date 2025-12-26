#!/usr/bin/env python3
"""
Unit tests for Great Expectations configuration.
"""
import os
import json
import yaml
import pytest
from pathlib import Path


# Define base paths
BASE_DIR = Path(__file__).parent.parent
GX_DIR = BASE_DIR / "gx"
EXPECTATIONS_DIR = BASE_DIR / "expectations"
CHECKPOINTS_DIR = BASE_DIR / "checkpoints"


class TestGreatExpectationsConfig:
    """Test Great Expectations configuration."""

    def test_gx_config_exists(self):
        """Test that Great Expectations config file exists."""
        config_file = GX_DIR / "great_expectations.yml"
        assert config_file.exists(), "great_expectations.yml not found"

    def test_gx_config_valid_yaml(self):
        """Test that Great Expectations config is valid YAML."""
        config_file = GX_DIR / "great_expectations.yml"
        with open(config_file, "r") as f:
            config = yaml.safe_load(f)

        assert config is not None
        assert "config_version" in config
        assert config["config_version"] == 3.0

    def test_datasources_config_exists(self):
        """Test that datasources config exists."""
        datasources_file = GX_DIR / "datasources.yml"
        assert datasources_file.exists(), "datasources.yml not found"

    def test_datasources_config_valid(self):
        """Test that datasources config is valid."""
        datasources_file = GX_DIR / "datasources.yml"
        with open(datasources_file, "r") as f:
            config = yaml.safe_load(f)

        assert "datasources" in config
        datasources = config["datasources"]

        # Check required datasources
        assert "backstage_db" in datasources
        assert "harbor_db" in datasources
        assert "datahub_db" in datasources
        assert "dora_metrics_db" in datasources
        assert "sonarqube_db" in datasources


class TestExpectationSuites:
    """Test expectation suites."""

    def test_expectation_suites_exist(self):
        """Test that all expectation suites exist."""
        suites = [
            "backstage_db_suite.json",
            "harbor_db_suite.json",
            "datahub_db_suite.json",
            "dora_metrics_suite.json",
            "sonarqube_db_suite.json",
        ]

        for suite_file in suites:
            suite_path = EXPECTATIONS_DIR / suite_file
            assert suite_path.exists(), f"Expectation suite {suite_file} not found"

    def test_expectation_suites_valid_json(self):
        """Test that expectation suites are valid JSON."""
        for suite_file in EXPECTATIONS_DIR.glob("*.json"):
            with open(suite_file, "r") as f:
                suite = json.load(f)

            assert "expectation_suite_name" in suite
            assert "expectations" in suite
            assert isinstance(suite["expectations"], list)
            assert len(suite["expectations"]) > 0

    def test_backstage_suite_expectations(self):
        """Test Backstage suite has required expectations."""
        suite_file = EXPECTATIONS_DIR / "backstage_db_suite.json"
        with open(suite_file, "r") as f:
            suite = json.load(f)

        expectation_types = [exp["expectation_type"] for exp in suite["expectations"]]

        # Check for key expectation types
        assert "expect_table_row_count_to_be_between" in expectation_types
        assert "expect_column_values_to_not_be_null" in expectation_types
        assert "expect_column_values_to_be_unique" in expectation_types


class TestCheckpoints:
    """Test checkpoint configurations."""

    def test_checkpoints_exist(self):
        """Test that checkpoint files exist."""
        checkpoints = [
            "backstage_db_checkpoint.yml",
            "harbor_db_checkpoint.yml",
            "datahub_db_checkpoint.yml",
            "dora_metrics_checkpoint.yml",
            "sonarqube_db_checkpoint.yml",
            "all_databases_checkpoint.yml",
        ]

        for checkpoint_file in checkpoints:
            checkpoint_path = CHECKPOINTS_DIR / checkpoint_file
            assert checkpoint_path.exists(), f"Checkpoint {checkpoint_file} not found"

    def test_checkpoints_valid_yaml(self):
        """Test that checkpoints are valid YAML."""
        for checkpoint_file in CHECKPOINTS_DIR.glob("*.yml"):
            with open(checkpoint_file, "r") as f:
                checkpoint = yaml.safe_load(f)

            assert "name" in checkpoint
            assert "config_version" in checkpoint
            assert "validations" in checkpoint
            assert isinstance(checkpoint["validations"], list)

    def test_all_databases_checkpoint_complete(self):
        """Test that all databases checkpoint includes all validations."""
        checkpoint_file = CHECKPOINTS_DIR / "all_databases_checkpoint.yml"
        with open(checkpoint_file, "r") as f:
            checkpoint = yaml.safe_load(f)

        validations = checkpoint["validations"]
        datasources = [v["batch_request"]["datasource_name"] for v in validations]

        # Should have all 5 datasources (backstage, harbor, datahub, dora, sonarqube)
        assert len(datasources) >= 5
        assert "backstage_db" in datasources
        assert "harbor_db" in datasources
        assert "datahub_db" in datasources
        assert "dora_metrics_db" in datasources
        assert "sonarqube_db" in datasources


class TestAlertConfiguration:
    """Test alert configuration."""

    def test_alerting_config_exists(self):
        """Test that alerting config exists."""
        alerting_file = BASE_DIR / "alerting.yaml"
        assert alerting_file.exists(), "alerting.yaml not found"

    def test_alerting_config_valid(self):
        """Test that alerting config is valid YAML."""
        alerting_file = BASE_DIR / "alerting.yaml"
        with open(alerting_file, "r") as f:
            config = yaml.safe_load(f)

        assert "rules" in config
        assert "daily_summary" in config
        assert "channels" in config
        assert isinstance(config["rules"], list)
        assert len(config["rules"]) > 0


class TestRequirements:
    """Test requirements and dependencies."""

    def test_requirements_file_exists(self):
        """Test that requirements.txt exists."""
        requirements_file = BASE_DIR / "requirements.txt"
        assert requirements_file.exists(), "requirements.txt not found"

    def test_requirements_has_gx(self):
        """Test that requirements.txt includes Great Expectations."""
        requirements_file = BASE_DIR / "requirements.txt"
        with open(requirements_file, "r") as f:
            content = f.read()

        assert "great-expectations" in content
        assert "sqlalchemy" in content
        assert "psycopg2-binary" in content


if __name__ == "__main__":
    # Run tests
    pytest.main([__file__, "-v"])
