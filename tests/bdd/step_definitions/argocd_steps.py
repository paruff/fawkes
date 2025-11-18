"""Step definitions for Argo CD bootstrap validation.

Business-focused checks that the ignite bootstrap produced a healthy
GitOps baseline: Argo CD namespace exists and root Applications are
Synced & Healthy.
"""
from __future__ import annotations

import json
import subprocess
from typing import Dict

import pytest
from pytest_bdd import given, when, then, parsers


def _kubectl_json(args: list[str]) -> Dict:
    """Run kubectl and return parsed JSON.

    Args:
        args: kubectl arguments after the initial 'kubectl'. Must include
              output format json (-o json or jsonpath not supported here).
    Returns:
        Parsed JSON as Python dict.
    Raises:
        RuntimeError: if kubectl fails or returns non-JSON.
    """
    cmd = ["kubectl"] + args
    try:
        raw = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:  # pragma: no cover
        raise RuntimeError(f"kubectl failed: {' '.join(cmd)}\n{e.output.decode()}" )
    try:
        return json.loads(raw.decode())
    except json.JSONDecodeError as e:  # pragma: no cover
        raise RuntimeError(f"Failed to parse JSON from kubectl output: {e}")


@given(parsers.cfparse('the Argo CD namespace "{namespace}" exists'))
def argo_cd_namespace_exists(namespace: str):
    ns = _kubectl_json(["get", "ns", namespace, "-o", "json"])
    phase = ns.get("status", {}).get("phase")
    assert phase == "Active", f"Namespace {namespace} not Active (phase={phase})"


@given("the Kubernetes API is reachable")
def k8s_api_reachable():
    # Simple cluster-info command; rely on exit status
    subprocess.check_call(["kubectl", "cluster-info"], stdout=subprocess.DEVNULL)


@when(parsers.cfparse('I list Argo CD Applications in namespace "{namespace}"'))
def list_argocd_applications(namespace: str, context: Dict):
    data = _kubectl_json(["-n", namespace, "get", "applications.argoproj.io", "-o", "json"])
    apps = {item["metadata"]["name"]: item for item in data.get("items", [])}
    context["apps"] = apps
    assert apps, f"No Applications found in namespace {namespace}"


def _assert_app_synced_healthy(app: Dict, name: str):
    status = app.get("status", {})
    sync_status = status.get("sync", {}).get("status")
    health_status = status.get("health", {}).get("status")
    assert sync_status == "Synced", f"Application {name} sync status={sync_status}" \
        + f" (expected Synced)"
    assert health_status == "Healthy", f"Application {name} health status={health_status}" \
        + f" (expected Healthy)"


@then(parsers.cfparse('Application "{app_name}" is Synced and Healthy'))
def application_synced_healthy(app_name: str, context: Dict):
    apps: Dict[str, Dict] = context.get("apps", {})
    assert app_name in apps, f"Application {app_name} not found in listed apps ({list(apps)})"
    _assert_app_synced_healthy(apps[app_name], app_name)


# Alias to support Scenario Outline step text
@then(parsers.cfparse('Application "{appName}" is Synced and Healthy'))
def application_synced_healthy_outline(appName: str, context: Dict):
    apps: Dict[str, Dict] = context.get("apps", {})
    assert appName in apps, f"Application {appName} not found in listed apps ({list(apps)})"
    _assert_app_synced_healthy(apps[appName], appName)
