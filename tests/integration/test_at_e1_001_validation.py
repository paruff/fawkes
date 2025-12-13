"""
Integration test for AT-E1-001 acceptance criteria validation.

This test runs the AT-E1-001 validation script and verifies that all
acceptance criteria are met for the AKS cluster infrastructure.

Usage:
    pytest tests/integration/test_at_e1_001_validation.py -v
    pytest tests/integration/test_at_e1_001_validation.py -v --resource-group my-rg --cluster-name my-aks
"""

import json
import os
import subprocess
import pytest
from pathlib import Path


class TestATE1001Validation:
    """Test suite for AT-E1-001 acceptance criteria."""

    @pytest.fixture(scope="class")
    def repo_root(self):
        """Get repository root directory."""
        # Assuming this file is in tests/integration/
        return Path(__file__).parent.parent.parent

    @pytest.fixture(scope="class")
    def validation_script(self, repo_root):
        """Get path to validation script."""
        script_path = repo_root / "scripts" / "validate-at-e1-001.sh"
        assert script_path.exists(), f"Validation script not found: {script_path}"
        assert os.access(script_path, os.X_OK), f"Validation script not executable: {script_path}"
        return script_path

    @pytest.fixture(scope="class")
    def resource_group(self, request):
        """Get resource group from CLI or environment."""
        return (
            request.config.getoption("--resource-group", None) or
            os.getenv("AZURE_RESOURCE_GROUP", "fawkes-rg")
        )

    @pytest.fixture(scope="class")
    def cluster_name(self, request):
        """Get cluster name from CLI or environment."""
        return (
            request.config.getoption("--cluster-name", None) or
            os.getenv("AZURE_CLUSTER_NAME", "fawkes-aks")
        )

    @pytest.fixture(scope="class")
    def validation_timeout(self, request):
        """Get timeout for validation script from CLI or default."""
        timeout = request.config.getoption("--validation-timeout", None)
        if timeout is not None:
            return timeout  # Already converted to int by pytest type=int
        env_timeout = os.getenv("VALIDATION_TIMEOUT")
        if env_timeout:
            try:
                return int(env_timeout)
            except (ValueError, TypeError):
                pass
        return 600  # Default 10 minutes

    @pytest.fixture(scope="class")
    def validation_result(self, validation_script, resource_group, cluster_name, validation_timeout, repo_root):
        """Run validation script and return results."""
        # Change to repo root for consistent paths
        original_dir = os.getcwd()
        os.chdir(repo_root)

        try:
            # Run validation script
            result = subprocess.run(
                [
                    str(validation_script),
                    "--resource-group", resource_group,
                    "--cluster-name", cluster_name,
                ],
                capture_output=True,
                text=True,
                timeout=validation_timeout
            )

            # Find and parse the JSON report
            reports_dir = repo_root / "reports"
            if reports_dir.exists():
                # Get the most recent AT-E1-001 report
                report_files = sorted(
                    reports_dir.glob("at-e1-001-validation-*.json"),
                    key=lambda p: p.stat().st_mtime,
                    reverse=True
                )
                if report_files:
                    with open(report_files[0], 'r') as f:
                        report = json.load(f)
                else:
                    report = None
            else:
                report = None

            return {
                "exit_code": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "report": report
            }
        finally:
            os.chdir(original_dir)

    @pytest.mark.integration
    @pytest.mark.azure
    @pytest.mark.smoke
    def test_validation_script_runs(self, validation_result):
        """Test that validation script runs successfully."""
        assert validation_result["exit_code"] in [0, 1], \
            f"Validation script crashed: {validation_result['stderr']}"

    @pytest.mark.integration
    @pytest.mark.azure
    def test_validation_report_generated(self, validation_result):
        """Test that validation report is generated."""
        assert validation_result["report"] is not None, \
            "Validation report was not generated"
        
        # Check report structure
        assert "test_suite" in validation_result["report"]
        assert validation_result["report"]["test_suite"] == "AT-E1-001"
        assert "summary" in validation_result["report"]
        assert "tests" in validation_result["report"]

    @pytest.mark.integration
    @pytest.mark.azure
    @pytest.mark.smoke
    def test_all_acceptance_criteria_pass(self, validation_result):
        """Test that all AT-E1-001 acceptance criteria pass."""
        assert validation_result["exit_code"] == 0, \
            f"Validation failed. Check output:\n{validation_result['stdout']}\n{validation_result['stderr']}"
        
        if validation_result["report"]:
            summary = validation_result["report"]["summary"]
            assert summary["failed"] == 0, \
                f"{summary['failed']} tests failed. Success rate: {summary['success_rate']}%"

    @pytest.mark.integration
    @pytest.mark.azure
    def test_cluster_exists(self, validation_result):
        """Test that AKS cluster exists and is running."""
        if validation_result["report"]:
            cluster_test = next(
                (t for t in validation_result["report"]["tests"] if "Cluster Exists" in t["test"]),
                None
            )
            assert cluster_test is not None, "Cluster existence test not found"
            assert cluster_test["status"] == "PASS", \
                f"Cluster check failed: {cluster_test['message']}"

    @pytest.mark.integration
    @pytest.mark.azure
    def test_minimum_nodes_present(self, validation_result):
        """Test that cluster has minimum required nodes (4)."""
        if validation_result["report"]:
            node_test = next(
                (t for t in validation_result["report"]["tests"] if "Node Count" in t["test"]),
                None
            )
            assert node_test is not None, "Node count test not found"
            assert node_test["status"] == "PASS", \
                f"Node count check failed: {node_test['message']}"

    @pytest.mark.integration
    @pytest.mark.azure
    def test_all_nodes_ready(self, validation_result):
        """Test that all nodes are in Ready state."""
        if validation_result["report"]:
            ready_test = next(
                (t for t in validation_result["report"]["tests"] if "Nodes Ready" in t["test"]),
                None
            )
            assert ready_test is not None, "Nodes ready test not found"
            assert ready_test["status"] == "PASS", \
                f"Nodes ready check failed: {ready_test['message']}"

    @pytest.mark.integration
    @pytest.mark.azure
    def test_nodes_schedulable(self, validation_result):
        """Test that all nodes are schedulable."""
        if validation_result["report"]:
            sched_test = next(
                (t for t in validation_result["report"]["tests"] if "Nodes Schedulable" in t["test"]),
                None
            )
            assert sched_test is not None, "Nodes schedulable test not found"
            assert sched_test["status"] == "PASS", \
                f"Nodes schedulable check failed: {sched_test['message']}"

    @pytest.mark.integration
    @pytest.mark.azure
    def test_system_pods_running(self, validation_result):
        """Test that all system pods are running."""
        if validation_result["report"]:
            pods_test = next(
                (t for t in validation_result["report"]["tests"] if "System Pods" in t["test"]),
                None
            )
            assert pods_test is not None, "System pods test not found"
            assert pods_test["status"] == "PASS", \
                f"System pods check failed: {pods_test['message']}"

    @pytest.mark.integration
    @pytest.mark.azure
    def test_metrics_available(self, validation_result):
        """Test that cluster metrics are available (kubelet, cAdvisor)."""
        if validation_result["report"]:
            metrics_test = next(
                (t for t in validation_result["report"]["tests"] if "Cluster Metrics" in t["test"]),
                None
            )
            assert metrics_test is not None, "Cluster metrics test not found"
            assert metrics_test["status"] == "PASS", \
                f"Cluster metrics check failed: {metrics_test['message']}"

    @pytest.mark.integration
    @pytest.mark.azure
    def test_storage_class_configured(self, validation_result):
        """Test that StorageClass is configured for persistent volumes."""
        if validation_result["report"]:
            storage_test = next(
                (t for t in validation_result["report"]["tests"] if "StorageClass" in t["test"]),
                None
            )
            assert storage_test is not None, "StorageClass test not found"
            assert storage_test["status"] == "PASS", \
                f"StorageClass check failed: {storage_test['message']}"

    @pytest.mark.integration
    @pytest.mark.azure
    def test_ingress_controller_deployed(self, validation_result):
        """Test that ingress controller is deployed (nginx/traefik)."""
        if validation_result["report"]:
            ingress_test = next(
                (t for t in validation_result["report"]["tests"] if "Ingress Controller" in t["test"]),
                None
            )
            assert ingress_test is not None, "Ingress controller test not found"
            assert ingress_test["status"] == "PASS", \
                f"Ingress controller check failed: {ingress_test['message']}"

    @pytest.mark.integration
    @pytest.mark.azure
    def test_resource_limits_within_threshold(self, validation_result):
        """Test that cluster resource limits are within acceptable range."""
        if validation_result["report"]:
            limits_test = next(
                (t for t in validation_result["report"]["tests"] if "Resource Limits" in t["test"]),
                None
            )
            assert limits_test is not None, "Resource limits test not found"
            assert limits_test["status"] == "PASS", \
                f"Resource limits check failed: {limits_test['message']}"

    @pytest.mark.integration
    @pytest.mark.azure
    def test_kubectl_configured(self, validation_result):
        """Test that kubectl is configured and working."""
        if validation_result["report"]:
            kubectl_test = next(
                (t for t in validation_result["report"]["tests"] if "kubectl Configuration" in t["test"]),
                None
            )
            assert kubectl_test is not None, "kubectl configuration test not found"
            assert kubectl_test["status"] == "PASS", \
                f"kubectl configuration check failed: {kubectl_test['message']}"


def pytest_addoption(parser):
    """Add custom command line options."""
    parser.addoption(
        "--resource-group",
        action="store",
        default=None,
        help="Azure resource group name"
    )
    parser.addoption(
        "--cluster-name",
        action="store",
        default=None,
        help="AKS cluster name"
    )
    parser.addoption(
        "--validation-timeout",
        action="store",
        type=int,
        default=None,
        help="Timeout in seconds for validation script (default: 600)"
    )
