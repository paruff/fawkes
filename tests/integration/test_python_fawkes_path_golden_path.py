"""Integration test suite for python-fawkes-path golden path.

Wraps the 8 golden path validation scripts into a pytest suite that can
be run in CI or locally against a live cluster.

Usage:
    pytest tests/integration/test_python_fawkes_path_golden_path.py -v
    pytest tests/integration/test_python_fawkes_path_golden_path.py -v -k observability
"""

import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
SCRIPTS_DIR = REPO_ROOT / "scripts"

GOLDEN_PATH_SCRIPTS = [
    "validate-golden-path-devex.sh",
    "validate-golden-path-dora.sh",
    "validate-golden-path-gitops.sh",
    "validate-golden-path-observability.sh",
    "validate-golden-path-pipeline.sh",
    "validate-golden-path-progressive-delivery.sh",
    "validate-golden-path-resources.sh",
    "validate-golden-path-security.sh",
]


def _run_script(script_name: str, timeout: int = 120) -> subprocess.CompletedProcess:
    """Run a golden path validation script and return the result."""
    script_path = SCRIPTS_DIR / script_name
    assert script_path.exists(), f"Script not found: {script_path}"
    return subprocess.run(
        ["bash", str(script_path)],
        capture_output=True,
        text=True,
        timeout=timeout,
        cwd=str(REPO_ROOT),
        check=False,
    )


class TestGoldenPathDevEx:
    """Validate the DevEx plane: catalog-info, Backstage discovery."""

    def test_devex_script_passes(self):
        result = _run_script("validate-golden-path-devex.sh")
        assert result.returncode == 0, f"DevEx validation failed:\nstdout: {result.stdout}\nstderr: {result.stderr}"


class TestGoldenPathDORA:
    """Validate DORA metrics are emitted and queryable."""

    def test_dora_script_passes(self):
        result = _run_script("validate-golden-path-dora.sh")
        assert result.returncode == 0, f"DORA validation failed:\nstdout: {result.stdout}\nstderr: {result.stderr}"


class TestGoldenPathGitOps:
    """Validate GitOps: ArgoCD Application synced and healthy."""

    def test_gitops_script_passes(self):
        result = _run_script("validate-golden-path-gitops.sh")
        assert result.returncode == 0, f"GitOps validation failed:\nstdout: {result.stdout}\nstderr: {result.stderr}"


class TestGoldenPathObservability:
    """Validate OTEL traces reach Tempo and Prometheus has metrics."""

    def test_observability_script_passes(self):
        result = _run_script("validate-golden-path-observability.sh")
        assert result.returncode == 0, (
            f"Observability validation failed:\nstdout: {result.stdout}\nstderr: {result.stderr}"
        )


class TestGoldenPathPipeline:
    """Validate Tekton pipeline ran and produced signed artifacts."""

    def test_pipeline_script_passes(self):
        result = _run_script("validate-golden-path-pipeline.sh")
        assert result.returncode == 0, f"Pipeline validation failed:\nstdout: {result.stdout}\nstderr: {result.stderr}"


class TestGoldenPathProgressiveDelivery:
    """Validate Argo Rollouts canary configuration."""

    def test_progressive_delivery_script_passes(self):
        result = _run_script("validate-golden-path-progressive-delivery.sh")
        assert result.returncode == 0, (
            f"Progressive delivery validation failed:\nstdout: {result.stdout}\nstderr: {result.stderr}"
        )


class TestGoldenPathResources:
    """Validate resource requests/limits and PVC health."""

    def test_resources_script_passes(self):
        result = _run_script("validate-golden-path-resources.sh")
        assert result.returncode == 0, f"Resources validation failed:\nstdout: {result.stdout}\nstderr: {result.stderr}"


class TestGoldenPathSecurity:
    """Validate image signatures, RBAC, and security contexts."""

    def test_security_script_passes(self):
        result = _run_script("validate-golden-path-security.sh")
        assert result.returncode == 0, f"Security validation failed:\nstdout: {result.stdout}\nstderr: {result.stderr}"


class TestAllScriptsExist:
    """Verify all expected golden path scripts are present."""

    @pytest.mark.parametrize("script_name", GOLDEN_PATH_SCRIPTS)
    def test_script_exists(self, script_name):
        script = SCRIPTS_DIR / script_name
        assert script.exists(), f"Missing golden path script: {script}"

    @pytest.mark.parametrize("script_name", GOLDEN_PATH_SCRIPTS)
    def test_script_is_executable(self, script_name):
        script = SCRIPTS_DIR / script_name
        assert script.stat().st_mode & 0o111, f"Script not executable: {script}"
