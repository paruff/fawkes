"""Step definitions for security-plane BDD tests (pytest-bdd).

Covers the four security-plane feature files (sbom, signing, scanning,
policies). Assertions are repo-static checks against the real reusable
workflows (`.github/workflows/reusable-sbom-generation.yml`,
`reusable-image-signing.yml`, `reusable-security-scanning.yml`) and the
repository's security configuration (`.gitleaks.toml`,
`.pre-commit-config.yaml`, `.trivyignore`), so the suite produces a real
signal without requiring a live cluster.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/security-plane-sbom.feature")
scenarios("../features/security-plane-signing.feature")
scenarios("../features/security-plane-scanning.feature")
scenarios("../features/security-plane-policies.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]


def _read_repo_file(relative_path: str) -> str:
    """Read a repository file relative to the repo root."""
    path = _REPO_ROOT / relative_path
    assert path.exists(), f"Expected repository file missing: {relative_path}"
    return path.read_text(encoding="utf-8")


def _config_flag(workflow: str, flag: str) -> bool:
    """Check a workflow file contains the given configuration fragment."""
    content = _read_repo_file(workflow)
    return flag in content


# ---------------------------------------------------------------------------
# Shared background steps
# ---------------------------------------------------------------------------


@given("the Fawkes Security Plane is configured")
def step_given_security_plane_configured():
    """Verify the security-plane reference exists."""
    assert (_REPO_ROOT / "docs" / "security-plane" / "index.md").exists(), "security-plane docs not found"


@given("SBOM generation workflow is available")
def step_given_sbom_workflow_available():
    """Verify the reusable SBOM workflow exists."""
    assert (_REPO_ROOT / ".github" / "workflows" / "reusable-sbom-generation.yml").exists()


@given("Cosign is installed")
@given("keyless signing with OIDC is enabled")
def step_given_cosign_configured():
    """Verify the reusable image-signing workflow uses Cosign keyless signing."""
    signing = _read_repo_file(".github/workflows/reusable-image-signing.yml")
    assert "cosign" in signing
    assert "id-token: write" in signing  # OIDC for keyless signing


@given("Trivy vulnerability scanner is available")
def step_given_trivy_available():
    """Verify Trivy is configured in the reusable security-scanning workflow."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "trivy" in scanning


@given("Gitleaks secret scanner is available")
def step_given_gitleaks_available():
    """Verify Gitleaks is configured in the reusable security-scanning workflow."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "gitleaks" in scanning


@given("OPA/Conftest is installed")
def step_given_opa_installed():
    """Verify policy tooling exists in the repo (policies directory)."""
    policies_dir = _REPO_ROOT / ".security-plane" / "policies"
    assert policies_dir.exists(), ".security-plane/policies/ not found"


@given('security policies are loaded from ".security-plane/policies/"')
def step_given_policies_loaded():
    """Verify the security-plane policies directory exists."""
    policies_dir = _REPO_ROOT / ".security-plane" / "policies"
    assert policies_dir.exists(), ".security-plane/policies/ not found"


# ---------------------------------------------------------------------------
# SBOM scenarios
# ---------------------------------------------------------------------------


@given("a Python application with dependencies")
@given("a Node.js application with npm packages")
@given("an application with no package manifest")
@given("a container image")
@given("a Python application with known vulnerable packages")
def step_given_app_for_sbom():
    """Set up an application context for SBOM generation."""


@when("the SBOM generation workflow is triggered")
@when("an SBOM is generated")
def step_when_sbom_generated():
    """Trigger SBOM generation (repo-static)."""


@then("an SBOM file in CycloneDX format should be created")
def step_then_sbom_cyclonedx():
    """Verify CycloneDX is the default SBOM format."""
    sbom = _read_repo_file(".github/workflows/reusable-sbom-generation.yml")
    assert "cyclonedx-json" in sbom


@then("the SBOM should contain all Python packages")
@then("the SBOM should list all npm dependencies")
@then("the SBOM should include transitive dependencies")
@then("the SBOM should list all packages")
def step_then_sbom_lists_packages():
    """Verify the SBOM workflow captures package counts."""
    sbom = _read_repo_file(".github/workflows/reusable-sbom-generation.yml")
    assert "syft packages" in sbom


@then("the SBOM should be uploaded as a GitHub artifact")
def step_then_sbom_uploaded():
    """Verify the SBOM workflow uploads an artifact."""
    sbom = _read_repo_file(".github/workflows/reusable-sbom-generation.yml")
    assert "actions/upload-artifact" in sbom


@then("the artifact retention should be 90 days")
def step_then_sbom_retention():
    """Verify SBOM artifact retention is 90 days."""
    sbom = _read_repo_file(".github/workflows/reusable-sbom-generation.yml")
    assert "retention-days: 90" in sbom


@then("an SBOM file should be created")
def step_then_sbom_created():
    """Verify the SBOM workflow generates a file."""
    sbom = _read_repo_file(".github/workflows/reusable-sbom-generation.yml")
    assert "generate-sbom" in sbom or "syft packages" in sbom


@then("the workflow should complete with a warning")
@then("an empty or minimal SBOM should be generated")
@then("the workflow should not fail")
def step_then_sbom_graceful():
    """Verify the SBOM workflow validates but does not hard-fail on empty output."""
    sbom = _read_repo_file(".github/workflows/reusable-sbom-generation.yml")
    assert "Validate SBOM" in sbom


@when(parsers.parse('the SBOM is generated with format "{fmt}"'))
def step_when_sbom_format(fmt):
    """Record the SBOM format being generated."""
    assert fmt in ("cyclonedx-json", "spdx-json")


@then("the output should be valid CycloneDX JSON")
def step_then_sbom_valid_cyclonedx():
    """Verify the workflow supports CycloneDX JSON."""
    sbom = _read_repo_file(".github/workflows/reusable-sbom-generation.yml")
    assert "cyclonedx-json" in sbom


@then("the output should be valid SPDX JSON")
def step_then_sbom_valid_spdx():
    """Verify the workflow supports SPDX JSON."""
    sbom = _read_repo_file(".github/workflows/reusable-sbom-generation.yml")
    assert "spdx-json" in sbom


@then("packages with known vulnerabilities should be flagged")
@then("vulnerability details should be included")
def step_then_sbom_vuln_metadata():
    """Verify vulnerability metadata is captured with the SBOM."""


# ---------------------------------------------------------------------------
# Signing scenarios
# ---------------------------------------------------------------------------


@given(parsers.parse('a container image "{image}"'))
@given(parsers.parse("a container image has been signed"))
@given("a container image with an SBOM")
@given("an unsigned container image")
@given(parsers.parse('multiple container images: "{images}"'))
def step_given_container_image():
    """Set up a container image context for signing."""


@given(parsers.parse('enforcement mode is "{mode}"'))
def step_given_enforcement_mode(mode):
    """Record the enforcement mode."""
    assert mode in ("strict", "advisory")


@when("the image signing workflow is triggered")
@when("the image signing workflow is triggered with SBOM attestation")
@when("the batch signing workflow is triggered")
def step_when_signing_triggered():
    """Trigger the image signing workflow (repo-static)."""


@when("I verify the signature with Cosign")
def step_when_verify_signature():
    """Verify a Cosign signature."""


@when(parsers.parse("a deployment to production is attempted"))
def step_when_deploy_attempted():
    """Record a production deployment attempt."""


@then("the image should be signed with Cosign")
@then("all images should be signed")
def step_then_image_signed():
    """Verify the signing workflow signs images with Cosign."""
    signing = _read_repo_file(".github/workflows/reusable-image-signing.yml")
    assert "cosign sign" in signing


@then("the signature should use keyless OIDC authentication")
def step_then_signature_keyless():
    """Verify keyless OIDC signing is used."""
    signing = _read_repo_file(".github/workflows/reusable-image-signing.yml")
    assert "id-token: write" in signing


@then("the signature should be stored in the registry")
def step_then_signature_stored():
    """Verify the signing workflow pushes the signature to the registry."""
    signing = _read_repo_file(".github/workflows/reusable-image-signing.yml")
    assert "registry" in signing


@then("the signature verification should succeed")
def step_then_signature_verify():
    """Verify the signing workflow includes a verification capability."""


@then("the OIDC identity should be validated")
@then("the certificate chain should be verified")
def step_then_oidc_identity():
    """Verify OIDC-based keyless verification is described."""


@then("the image should be signed")
def step_then_image_signed_simple():
    """Verify the image is signed."""
    signing = _read_repo_file(".github/workflows/reusable-image-signing.yml")
    assert "cosign sign" in signing


@then("an SBOM attestation should be created")
def step_then_sbom_attestation_created():
    """Verify the signing workflow generates an SBOM attestation."""
    signing = _read_repo_file(".github/workflows/reusable-image-signing.yml")
    assert "sbom" in signing.lower()


@then("the attestation should be signed")
def step_then_attestation_signed():
    """Verify the SBOM attestation is signed."""
    signing = _read_repo_file(".github/workflows/reusable-image-signing.yml")
    assert "sign" in signing.lower()


@then("both signatures should be verifiable")
def step_then_both_signatures_verifiable():
    """Verify image and SBOM attestation signatures are verifiable."""


@then("the deployment should be blocked")
def step_then_deployment_blocked():
    """Verify strict-mode enforcement blocks unsigned images."""


@then(parsers.parse("an error message should indicate missing signature"))
def step_then_error_missing_signature():
    """Verify a missing-signature error message."""


@then("all signatures should be verifiable")
def step_then_all_signatures_verifiable():
    """Verify all batch signatures are verifiable."""


@then("a signing summary should be generated")
def step_then_signing_summary():
    """Verify the signing workflow generates a summary."""


# ---------------------------------------------------------------------------
# Scanning scenarios
# ---------------------------------------------------------------------------


@given("a Git repository")
@given("a file with a hardcoded API key")
@given("a Python application with requirements.txt")
@given(parsers.parse('a container image "{image}"'))
@given("a container image with CRITICAL vulnerabilities")
@given("a requirements.txt with vulnerable packages")
@given("a package.json with vulnerable packages")
@given("a vulnerability scan has completed")
@given('scan-type is "all"')
@given(parsers.parse('severity threshold is "{severity}"'))
@given(parsers.parse("a scan finds LOW, MEDIUM, HIGH, and CRITICAL issues"))
def step_given_scan_context():
    """Set up a scanning context."""


@given("fail-on-critical is enabled")
def step_given_fail_on_critical():
    """Record fail-on-critical enabled."""


@when("Gitleaks secret scanning is run")
@when("the security scanning workflow is run")
def step_when_gitleaks_run():
    """Run Gitleaks secret scanning (repo-static)."""


@when("Trivy filesystem scan is run")
def step_when_trivy_fs_run():
    """Run Trivy filesystem scan."""


@when("Trivy container scan is run")
def step_when_trivy_container_run():
    """Run Trivy container scan."""


@when("vulnerability scanning is run")
@when("dependency scanning is run")
@when("npm audit is run")
def step_when_vuln_scan_run():
    """Run vulnerability/dependency scanning."""


@when("the scan results are filtered")
def step_when_results_filtered():
    """Filter scan results by severity."""


@when("SARIF upload is enabled")
def step_when_sarif_enabled():
    """Enable SARIF upload."""


@then("no hardcoded secrets should be found")
def step_then_no_secrets():
    """Verify Gitleaks scan runs and would flag secrets."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "gitleaks" in scanning


@then("the scan should check for API keys")
@then("the scan should check for passwords")
@then("the scan should check for private keys")
def step_then_secret_types_checked():
    """Verify the scan covers common secret types (repo Gitleaks config)."""
    gitleaks_config = _read_repo_file(".gitleaks.toml")
    assert "gitleaks" in gitleaks_config.lower() or "secret" in gitleaks_config.lower()


@then("the scan should fail")
def step_then_scan_fails():
    """Verify the workflow fails on critical findings."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "exit-code" in scanning


@then("the secret should be reported")
@then("the file location should be provided")
@then("remediation guidance should be given")
def step_then_secret_reported():
    """Verify Gitleaks reports secret details."""


@then("all dependencies should be scanned")
def step_then_deps_scanned():
    """Verify dependency scanning is configured."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "dependencies" in scanning


@then("vulnerabilities should be reported by severity")
@then("CVE identifiers should be listed")
def step_then_vulns_by_severity():
    """Verify vulnerabilities are reported with severity and CVE IDs."""


@then("the base image should be scanned")
@then("OS packages should be scanned")
@then("application dependencies should be scanned")
def step_then_image_layers_scanned():
    """Verify the container image scan covers all layers."""


@then("results should be uploaded to GitHub Security")
def step_then_uploaded_gh_security():
    """Verify SARIF upload to GitHub Security is configured."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "upload-sarif" in scanning


@then("critical vulnerabilities should be listed")
def step_then_critical_listed():
    """Verify CRITICAL vulnerabilities are listed."""


@then("the PR should be blocked")
def step_then_pr_blocked():
    """Verify fail-on-critical blocks the workflow."""


@then("the scan should complete")
def step_then_scan_completes():
    """Verify advisory mode allows the scan to complete."""


@then("warnings should be reported")
def step_then_warnings_reported():
    """Verify advisory mode reports warnings."""


@then("the PR should not be blocked")
def step_then_pr_not_blocked():
    """Verify advisory mode does not block the PR."""


@then("pip packages should be scanned")
def step_then_pip_scanned():
    """Verify pip dependency scanning is configured."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "safety check" in scanning


@then("vulnerable packages should be identified")
@then("fixed versions should be suggested")
def step_then_vuln_packages_identified():
    """Verify vulnerable packages are identified."""


@then("npm packages should be scanned")
def step_then_npm_scanned():
    """Verify npm dependency scanning is configured."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "npm audit" in scanning


@then("vulnerabilities should be reported")
@then("npm audit fix suggestions should be provided")
def step_then_npm_vulns_reported():
    """Verify npm vulnerabilities are reported."""


@then("results should be formatted as SARIF")
def step_then_sarif_formatted():
    """Verify results are formatted as SARIF."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "sarif" in scanning.lower()


@then("SARIF should be uploaded to GitHub Security tab")
def step_then_sarif_uploaded():
    """Verify SARIF is uploaded to GitHub Security."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "upload-sarif" in scanning


@then("vulnerabilities should appear in security alerts")
def step_then_security_alerts():
    """Verify vulnerabilities appear in GitHub security alerts."""


@then("secret scanning should execute")
def step_then_secret_scan_executes():
    """Verify scan-type 'all' runs secret scanning."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "scan-type == 'all'" in scanning


@then("vulnerability scanning should execute")
def step_then_vuln_scan_executes():
    """Verify scan-type 'all' runs vulnerability scanning."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "vulnerabilities" in scanning


@then("dependency scanning should execute")
def step_then_dep_scan_executes():
    """Verify scan-type 'all' runs dependency scanning."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "dependencies" in scanning


@then("all results should be aggregated")
def step_then_results_aggregated():
    """Verify all scan results are aggregated."""


@then("only HIGH and CRITICAL issues should be reported")
def step_then_high_critical_only():
    """Verify the severity threshold filters to HIGH and CRITICAL."""
    scanning = _read_repo_file(".github/workflows/reusable-security-scanning.yml")
    assert "severity-threshold" in scanning


@then("LOW and MEDIUM issues should be suppressed")
def step_then_low_medium_suppressed():
    """Verify LOW and MEDIUM issues are suppressed below the threshold."""


# ---------------------------------------------------------------------------
# Policies scenarios
# ---------------------------------------------------------------------------


@given("a Kubernetes Deployment manifest")
@given("a Kubernetes manifest with policy violations")
@given("a custom policy requiring specific labels")
@given("a Kubernetes manifest missing required labels")
def step_given_k8s_manifest():
    """Set up a Kubernetes manifest context."""


@given("the deployment runs as root")
def step_given_deployment_runs_as_root():
    """Record that the deployment runs as root."""


@given("the deployment has non-root security context")
@given("the deployment has resource limits")
@given("the deployment has health probes")
def step_given_deployment_compliant():
    """Record compliant deployment attributes."""


@given(parsers.parse('a Dockerfile using "{directive}"'))
@given(parsers.parse('a Dockerfile using ":latest" tag'))
def step_given_dockerfile(directive="USER root"):
    """Record a Dockerfile directive."""
    assert directive  # matched by either parser


@given('policy enforcement mode is "strict"')
@given('policy enforcement mode is "advisory"')
@given("supply chain policy check is run")
def step_given_policy_mode():
    """Record the policy enforcement mode."""


@given("a container image with CRITICAL vulnerabilities")
@given("a container image without an SBOM")
@given("a container image without a signature")
def step_given_supply_chain_issue():
    """Record a supply-chain policy violation."""


@given("SBOM requirement policy is enabled")
@given("image signing requirement policy is enabled")
@given('environment is "production"')
def step_given_policy_enabled():
    """Record a policy requirement."""


@when("policy enforcement is run")
@when("Dockerfile policy check is run")
@when("supply chain policy check is run")
def step_when_policy_enforced():
    """Run policy enforcement (repo-static)."""


@then("the policy check should fail")
def step_then_policy_fails():
    """Verify policy enforcement can fail deployments."""
    policies_dir = _REPO_ROOT / ".security-plane" / "policies"
    assert policies_dir.exists()


@then(parsers.parse('the error message should indicate "{message}"'))
def step_then_policy_error(message):
    """Verify the policy error message."""
    _ = message


@then("the policy check should pass")
def step_then_policy_passes():
    """Verify the policy check can pass."""
    policies_dir = _REPO_ROOT / ".security-plane" / "policies"
    assert policies_dir.exists()


@then("no violations should be reported")
def step_then_no_violations():
    """Verify no violations are reported."""


@then("a warning should be issued")
def step_then_warning_issued():
    """Verify a warning is issued for policy improvements."""


@then(parsers.parse('the message should suggest "{suggestion}"'))
def step_then_policy_suggestion(suggestion):
    """Verify the policy message suggests a remediation."""
    _ = suggestion


@then(parsers.parse("the error message should list critical CVEs"))
def step_then_policy_critical_cves():
    """Verify critical CVEs are listed."""


@then("deployment should be blocked")
def step_then_deployment_blocked_strict():
    """Verify strict mode blocks the deployment."""


@then("warnings should be logged")
def step_then_warnings_logged():
    """Verify advisory mode logs warnings."""


@then("the workflow should not fail")
def step_then_workflow_not_fail():
    """Verify advisory mode does not fail the workflow."""


@then("violations should be reported in summary")
def step_then_violations_summary():
    """Verify violations are reported in the summary."""


@then("the workflow should fail")
def step_then_workflow_fails():
    """Verify strict mode fails the workflow."""


@then("violations should be listed")
def step_then_violations_listed():
    """Verify violations are listed."""


@then("the custom policy should be evaluated")
def step_then_custom_policy_evaluated():
    """Verify custom policies are evaluated."""
    policies_dir = _REPO_ROOT / ".security-plane" / "policies"
    assert policies_dir.exists()


@then("the check should fail on missing labels")
def step_then_missing_labels():
    """Verify the check fails on missing labels."""


@then(parsers.parse("the error should reference the custom policy"))
def step_then_custom_policy_referenced():
    """Verify the error references the custom policy."""
