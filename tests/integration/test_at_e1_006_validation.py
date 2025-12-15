"""
Integration test for AT-E1-006 acceptance criteria validation.

This test runs the AT-E1-006 validation script and verifies that all
acceptance criteria are met for the Observability Stack (Prometheus/Grafana).

Usage:
    pytest tests/integration/test_at_e1_006_validation.py -v
    pytest tests/integration/test_at_e1_006_validation.py -v --namespace monitoring
"""

import json
import os
import subprocess
import pytest
from pathlib import Path


class TestATE1006Validation:
    """Test suite for AT-E1-006 acceptance criteria."""

    @pytest.fixture(scope="class")
    def repo_root(self):
        """Get repository root directory."""
        # Assuming this file is in tests/integration/
        return Path(__file__).parent.parent.parent

    @pytest.fixture(scope="class")
    def validation_script(self, repo_root):
        """Get path to validation script."""
        script_path = repo_root / "scripts" / "validate-at-e1-006.sh"
        assert script_path.exists(), f"Validation script not found: {script_path}"
        assert os.access(script_path, os.X_OK), f"Validation script not executable: {script_path}"
        return script_path

    @pytest.fixture(scope="class")
    def namespace(self, request):
        """Get monitoring namespace from CLI or environment."""
        return (
            request.config.getoption("--namespace", None) or
            os.getenv("NAMESPACE", "monitoring")
        )

    @pytest.fixture(scope="class")
    def argocd_namespace(self, request):
        """Get ArgoCD namespace from CLI or environment."""
        return (
            request.config.getoption("--argocd-namespace", None) or
            os.getenv("ARGOCD_NAMESPACE", "fawkes")
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
    def validation_result(self, validation_script, namespace, argocd_namespace, validation_timeout, repo_root):
        """Run validation script and return results."""
        # Change to repo root for consistent paths
        original_dir = os.getcwd()
        os.chdir(repo_root)

        try:
            # Run validation script
            result = subprocess.run(
                [
                    str(validation_script),
                    "--namespace", namespace,
                    "--argocd-namespace", argocd_namespace,
                ],
                capture_output=True,
                text=True,
                timeout=validation_timeout
            )

            # Find and parse the JSON report
            reports_dir = repo_root / "reports"
            if reports_dir.exists():
                # Get the most recent AT-E1-006 report
                report_files = sorted(
                    reports_dir.glob("at-e1-006-validation-*.json"),
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
    @pytest.mark.observability
    @pytest.mark.smoke
    def test_validation_script_runs(self, validation_result):
        """Test that validation script runs successfully."""
        assert validation_result["exit_code"] in [0, 1], \
            f"Validation script crashed: {validation_result['stderr']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_validation_report_generated(self, validation_result):
        """Test that validation report is generated."""
        assert validation_result["report"] is not None, \
            "Validation report was not generated"
        
        # Check report structure
        assert "test_suite" in validation_result["report"]
        assert "AT-E1-006" in validation_result["report"]["test_suite"]
        assert "summary" in validation_result["report"]
        assert "results" in validation_result["report"]

    @pytest.mark.integration
    @pytest.mark.observability
    @pytest.mark.smoke
    def test_all_acceptance_criteria_pass(self, validation_result):
        """Test that all AT-E1-006 acceptance criteria pass."""
        assert validation_result["exit_code"] == 0, \
            f"Validation failed. Check output:\n{validation_result['stdout']}\n{validation_result['stderr']}"
        
        if validation_result["report"]:
            summary = validation_result["report"]["summary"]
            assert summary["failed"] == 0, \
                f"{summary['failed']} tests failed. Pass rate: {summary['pass_percentage']}%"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_namespace_exists(self, validation_result):
        """Test that monitoring namespace exists."""
        if validation_result["report"]:
            namespace_test = next(
                (t for t in validation_result["report"]["results"] if "namespace_exists" in t["test"]),
                None
            )
            assert namespace_test is not None, "Namespace existence test not found"
            assert namespace_test["status"] == "PASS", \
                f"Namespace check failed: {namespace_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_argocd_application_healthy(self, validation_result):
        """Test that ArgoCD Application for prometheus-stack is Healthy and Synced."""
        if validation_result["report"]:
            argocd_test = next(
                (t for t in validation_result["report"]["results"] if "argocd_application" in t["test"]),
                None
            )
            assert argocd_test is not None, "ArgoCD Application test not found"
            assert argocd_test["status"] == "PASS", \
                f"ArgoCD Application check failed: {argocd_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_prometheus_operator_running(self, validation_result):
        """Test that Prometheus Operator is deployed and running."""
        if validation_result["report"]:
            operator_test = next(
                (t for t in validation_result["report"]["results"] if "prometheus_operator" in t["test"]),
                None
            )
            assert operator_test is not None, "Prometheus Operator test not found"
            assert operator_test["status"] == "PASS", \
                f"Prometheus Operator check failed: {operator_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_prometheus_server_running(self, validation_result):
        """Test that Prometheus Server is deployed and running."""
        if validation_result["report"]:
            server_test = next(
                (t for t in validation_result["report"]["results"] if "prometheus_server" in t["test"]),
                None
            )
            assert server_test is not None, "Prometheus Server test not found"
            assert server_test["status"] == "PASS", \
                f"Prometheus Server check failed: {server_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_grafana_deployed(self, validation_result):
        """Test that Grafana is deployed and running."""
        if validation_result["report"]:
            grafana_test = next(
                (t for t in validation_result["report"]["results"] if "grafana" in t["test"]),
                None
            )
            assert grafana_test is not None, "Grafana test not found"
            assert grafana_test["status"] == "PASS", \
                f"Grafana check failed: {grafana_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_alertmanager_running(self, validation_result):
        """Test that Alertmanager is deployed and running."""
        if validation_result["report"]:
            alertmanager_test = next(
                (t for t in validation_result["report"]["results"] if "alertmanager" in t["test"]),
                None
            )
            assert alertmanager_test is not None, "Alertmanager test not found"
            assert alertmanager_test["status"] == "PASS", \
                f"Alertmanager check failed: {alertmanager_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_node_exporter_running(self, validation_result):
        """Test that Node Exporter is running on all nodes."""
        if validation_result["report"]:
            node_exporter_test = next(
                (t for t in validation_result["report"]["results"] if "node_exporter" in t["test"]),
                None
            )
            assert node_exporter_test is not None, "Node Exporter test not found"
            assert node_exporter_test["status"] == "PASS", \
                f"Node Exporter check failed: {node_exporter_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_kube_state_metrics_running(self, validation_result):
        """Test that kube-state-metrics is running."""
        if validation_result["report"]:
            ksm_test = next(
                (t for t in validation_result["report"]["results"] if "kube_state_metrics" in t["test"]),
                None
            )
            assert ksm_test is not None, "kube-state-metrics test not found"
            assert ksm_test["status"] == "PASS", \
                f"kube-state-metrics check failed: {ksm_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_servicemonitors_configured(self, validation_result):
        """Test that ServiceMonitors are configured for platform components."""
        if validation_result["report"]:
            sm_test = next(
                (t for t in validation_result["report"]["results"] if "servicemonitors" in t["test"]),
                None
            )
            assert sm_test is not None, "ServiceMonitors test not found"
            assert sm_test["status"] == "PASS", \
                f"ServiceMonitors check failed: {sm_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_prometheus_storage_configured(self, validation_result):
        """Test that persistent storage is configured for Prometheus."""
        if validation_result["report"]:
            storage_test = next(
                (t for t in validation_result["report"]["results"] if "prometheus_storage" in t["test"]),
                None
            )
            assert storage_test is not None, "Prometheus storage test not found"
            assert storage_test["status"] == "PASS", \
                f"Prometheus storage check failed: {storage_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_grafana_ingress_configured(self, validation_result):
        """Test that Grafana ingress is configured."""
        if validation_result["report"]:
            ingress_test = next(
                (t for t in validation_result["report"]["results"] if "grafana_ingress" in t["test"]),
                None
            )
            assert ingress_test is not None, "Grafana ingress test not found"
            assert ingress_test["status"] == "PASS", \
                f"Grafana ingress check failed: {ingress_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_prometheus_ingress_configured(self, validation_result):
        """Test that Prometheus ingress is configured."""
        if validation_result["report"]:
            ingress_test = next(
                (t for t in validation_result["report"]["results"] if "prometheus_ingress" in t["test"]),
                None
            )
            assert ingress_test is not None, "Prometheus ingress test not found"
            assert ingress_test["status"] == "PASS", \
                f"Prometheus ingress check failed: {ingress_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_resource_limits_configured(self, validation_result):
        """Test that resource limits are configured for all components."""
        if validation_result["report"]:
            limits_test = next(
                (t for t in validation_result["report"]["results"] if "resource_limits" in t["test"]),
                None
            )
            assert limits_test is not None, "Resource limits test not found"
            assert limits_test["status"] == "PASS", \
                f"Resource limits check failed: {limits_test['message']}"

    @pytest.mark.integration
    @pytest.mark.observability
    def test_pods_health(self, validation_result):
        """Test that all pods in monitoring namespace are healthy."""
        if validation_result["report"]:
            health_test = next(
                (t for t in validation_result["report"]["results"] if "pods_health" in t["test"]),
                None
            )
            assert health_test is not None, "Pods health test not found"
            assert health_test["status"] == "PASS", \
                f"Pods health check failed: {health_test['message']}"


def pytest_addoption(parser):
    """Add custom command line options."""
    parser.addoption(
        "--namespace",
        action="store",
        default=None,
        help="Monitoring namespace (default: monitoring)"
    )
    parser.addoption(
        "--argocd-namespace",
        action="store",
        default=None,
        help="ArgoCD namespace (default: fawkes)"
    )
    parser.addoption(
        "--validation-timeout",
        action="store",
        type=int,
        default=None,
        help="Timeout in seconds for validation script (default: 600)"
    )
