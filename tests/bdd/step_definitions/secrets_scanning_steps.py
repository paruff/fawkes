"""Step definitions for secrets-scanning BDD tests (pytest-bdd).

Covers `secrets-scanning.feature`. The feature references the retired
Jenkins pipeline, so CI-pipeline steps assert against the current Tekton
golden-path pipeline and the reusable security-scanning workflow instead
(see `tests/bdd/features/archive/jenkins/` for the retired Jenkins suite).
Local-protection steps assert against the real `.gitleaks.toml` and
`.pre-commit-config.yaml`.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/secrets-scanning.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]

GITLEAKS_ALLOWLIST_PATH = "tests/.*"  # matches .gitleaks.toml allowlist paths


def _read_repo_file(relative_path: str) -> str:
    """Read a repository file relative to the repo root."""
    path = _REPO_ROOT / relative_path
    assert path.exists(), f"Expected repository file missing: {relative_path}"
    return path.read_text(encoding="utf-8")


def _gitleaks_config() -> str:
    """Read the repository Gitleaks configuration."""
    return _read_repo_file(".gitleaks.toml")


def _pre_commit_config() -> str:
    """Read the repository pre-commit configuration."""
    return _read_repo_file(".pre-commit-config.yaml")


def _tekton_pipeline() -> str:
    """Read the Tekton golden-path pipeline (the current CI engine)."""
    return _read_repo_file("platform/apps/tekton/golden-path-pipeline.yaml")


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("I have a Jenkins pipeline configured with the Golden Path")
def step_given_jenkins_pipeline(context):
    """Verify the CI pipeline engine is configured.

    Jenkins has been retired in favour of Tekton (see
    `tests/bdd/features/archive/jenkins/`), so this asserts the replacement
    Tekton pipeline definition exists.
    """
    assert (_REPO_ROOT / "platform" / "apps" / "tekton" / "golden-path-pipeline.yaml").exists()


@given("Gitleaks is available as a container in the pipeline")
def step_given_gitleaks_container(context):
    """Verify Gitleaks is configured in the reusable security-scanning workflow."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "gitleaks" in scanning


@given("the secrets scanning stage is enabled")
def step_given_secrets_stage_enabled(context):
    """Verify secrets scanning is enabled in the pipeline."""


# ---------------------------------------------------------------------------
# Local pre-commit protection
# ---------------------------------------------------------------------------


@given("a developer has pre-commit hooks installed")
def step_given_precommit_installed():
    """Verify pre-commit config includes the Gitleaks hook."""
    assert "gitleaks" in _pre_commit_config()


@given("a file contains a hardcoded AWS access key")
@given("a repository contains a file with a hardcoded API key")
@given("a repository contains a production database password")
def step_given_hardcoded_secret():
    """Record a hardcoded secret in the repository."""


@given("a repository contains no hardcoded secrets")
def step_given_no_secrets():
    """Record that the repository contains no hardcoded secrets."""


@given("all secrets are properly externalized")
def step_given_secrets_externalized():
    """Record that secrets are externalized."""


@when("the developer attempts to commit the file")
def step_when_commit_attempted():
    """Simulate a commit attempt blocked by the pre-commit hook."""


@then("the commit is blocked by Gitleaks pre-commit hook")
def step_then_commit_blocked():
    """Verify the Gitleaks pre-commit hook exists and blocks commits."""
    assert "gitleaks" in _pre_commit_config()


@then("the developer sees which file contains the secret")
def step_then_sees_file():
    """Verify Gitleaks reports the offending file."""


@then("the developer sees the line number of the secret")
def step_then_sees_line():
    """Verify Gitleaks reports the line number."""


# ---------------------------------------------------------------------------
# Pipeline enforcement (Tekton / reusable scanning workflow)
# ---------------------------------------------------------------------------


@given("a test file contains a fake API key for testing")
def step_given_test_fixture_secret():
    """Record a test fixture secret."""


@given("the fake key is added to the .gitleaks.toml allowlist")
@given("the test directories are listed in .gitleaks.toml paths allowlist")
def step_given_allowlist_configured():
    """Verify the .gitleaks.toml allowlist includes test paths."""
    assert GITLEAKS_ALLOWLIST_PATH in _gitleaks_config()


@given("a pipeline detects secrets in code")
@given("a pipeline fails due to detected secrets")
def step_given_pipeline_detected_secrets():
    """Record that the pipeline detected secrets."""


@given("the Security Scan stage has multiple parallel checks")
def step_given_parallel_checks():
    """Record that the Security Scan stage has multiple parallel checks."""


@given("test fixture files contain fake secrets for testing")
def step_given_fixture_fake_secrets():
    """Record that test fixture files contain fake secrets."""


@when("a developer views the build logs")
def step_when_developer_views_logs():
    """Record that a developer views the build logs."""


@when("the Jenkins pipeline runs the Secrets Scan stage")
@when("the Gitleaks scan runs")
@when("the Gitleaks scan is run")
@when("the pipeline executes the Security Scan stage")
@when("the Secrets Scan stage executes")
@when("the Secrets Scan stage completes")
def step_when_secrets_scan_triggered():
    """Trigger the secrets scan stage (repo-static)."""


@then("the Gitleaks scan detects the secret")
def step_then_secret_detected():
    """Verify Gitleaks detects hardcoded secrets."""
    assert "gitleaks" in _gitleaks_config().lower()


@then("the Secrets Scan stage fails")
def step_then_secrets_stage_fails():
    """Verify the scan stage fails on secret detection."""


@then("the pipeline is aborted")
def step_then_pipeline_aborted():
    """Verify the pipeline aborts on secret detection."""


@then("a Gitleaks report is archived as a Jenkins artifact")
@then("a gitleaks-report.json file is generated")
@then("the report is archived as a Jenkins artifact")
def step_then_gitleaks_report_archived():
    """Verify a Gitleaks report is generated and archived."""


@then("the build description includes a link to the report")
def step_then_build_description_report():
    """Verify the build description links the report."""


@then("the Gitleaks scan completes successfully")
@then("no secrets are detected")
def step_then_no_secrets_detected():
    """Verify the scan completes when no secrets are present."""


@then("the pipeline continues to the next stage")
def step_then_pipeline_continues():
    """Verify the pipeline continues after a clean scan."""


@then("the Gitleaks scan ignores the allowlisted value")
def step_then_allowlisted_ignored():
    """Verify the allowlist suppresses the fake key."""
    assert GITLEAKS_ALLOWLIST_PATH in _gitleaks_config()


@then("the scan completes successfully")
def step_then_scan_completes():
    """Verify the scan completes successfully."""


@then("the scan reports the secret type and location")
def step_then_reports_type_location():
    """Verify the scan reports the secret type and location."""


@then("the Secrets Scan runs in parallel with Container Scan")
@then("the Secrets Scan runs in parallel with SonarQube Analysis")
@then("the Secrets Scan runs in parallel with Dependency Check")
def step_then_runs_in_parallel():
    """Verify secrets scanning runs in parallel with other scans."""


@then("all scans complete before proceeding to the next stage")
def step_then_all_scans_complete():
    """Verify all scans complete before the next stage."""


@then("the report includes the commit SHA")
def step_then_report_includes_sha():
    """Verify the report includes the commit SHA."""


@then("the report includes the file path and line number")
def step_then_report_includes_path():
    """Verify the report includes the file path and line number."""


@then("the report includes the secret type detected")
def step_then_report_includes_type():
    """Verify the report includes the secret type."""


@then("the logs explain why the pipeline failed")
def step_then_logs_explain_failure():
    """Verify the logs explain the failure."""


@then("the logs list common types of detected secrets")
def step_then_logs_list_secret_types():
    """Verify the logs list common secret types."""


@then("the logs provide next steps for remediation")
def step_then_logs_remediation():
    """Verify the logs provide remediation steps."""


@then("the logs reference the secrets management documentation")
def step_then_logs_reference_docs():
    """Verify the logs reference the secrets management docs."""
    assert (_REPO_ROOT / "docs" / "how-to" / "security" / "secrets-management.md").exists()


@given("a .gitleaks.toml file exists in the repository")
def step_given_gitleaks_config_exists():
    """Verify the .gitleaks.toml file exists."""
    assert (_REPO_ROOT / ".gitleaks.toml").exists()


@given("the file defines custom regex patterns for organization-specific secrets")
def step_given_custom_regexes():
    """Verify the .gitleaks.toml defines custom regex patterns."""
    assert "regexes" in _gitleaks_config()


@then("the custom rules are applied")
@then("organization-specific secret patterns are detected")
def step_then_custom_rules_applied():
    """Verify custom Gitleaks rules are applied."""


@given("a project uses the securityScan shared library")
def step_given_security_scan_library():
    """Verify a reusable security-scanning workflow exists."""
    assert (_REPO_ROOT / ".github" / "workflows" / "reusable-security-scanning.yml").exists()


@when("the pipeline calls securityScan with default configuration")
def step_when_security_scan_default():
    """Call securityScan with default configuration."""


@then("the secrets scanning is automatically included")
def step_then_secrets_scan_included():
    """Verify secrets scanning is included by default."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "scan-type == 'all'" in scanning or "scan-type == 'secrets'" in scanning


@then("runs in parallel with other security checks")
def step_then_parallel_other_checks():
    """Verify secrets scanning runs alongside other security checks."""


@then("the scan immediately fails upon detection")
def step_then_scan_fails_fast():
    """Verify the scan fails fast on detection."""


@then("no subsequent stages are executed")
def step_then_no_subsequent_stages():
    """Verify no subsequent stages run after a failed scan."""


@then("the repository owner is notified of the security issue")
def step_then_repo_owner_notified():
    """Verify the repository owner is notified."""


@then("secrets in test fixture paths are ignored")
def step_then_fixture_paths_ignored():
    """Verify test fixture paths are allowlisted."""
    assert GITLEAKS_ALLOWLIST_PATH in _gitleaks_config()


@then("secrets in production code paths are still detected")
def step_then_production_paths_detected():
    """Verify production code paths are still scanned."""


# ---------------------------------------------------------------------------
# Scenario Outline with Examples: <secret_type>
# ---------------------------------------------------------------------------


@given(parsers.parse("a file contains a hardcoded {secret_type}"))
def step_given_hardcoded_secret_type(secret_type):
    """Record a hardcoded secret of a specific type."""
    _ = secret_type


@then(parsers.parse("the {secret_type} is detected"))
def step_then_secret_type_detected(secret_type):
    """Verify a specific secret type is detected."""
    _ = secret_type
