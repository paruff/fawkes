import json
import subprocess
import pytest


@pytest.mark.smoke
def test_cluster_has_nodes():
    """Smoke check: the kind cluster has at least one Ready node."""
    out = subprocess.check_output(["kubectl", "get", "nodes", "-o", "json"])
    data = json.loads(out)
    assert data.get("items"), "No nodes returned from kubectl"
    # Optionally assert Ready condition
    for node in data["items"]:
        conditions = {c["type"]: c["status"] for c in node["status"].get("conditions", [])}
        assert conditions.get("Ready") == "True", f"Node {node['metadata']['name']} not Ready"



@pytest.mark.smoke
def test_fawkes_namespace_exists():
    out = subprocess.check_output(["kubectl", "get", "ns", "fawkes", "-o", "json"])
    data = json.loads(out)
    assert data["metadata"]["name"] == "fawkes"

@pytest.mark.smoke
def test_inspector_deployment_applied():
    # Deployment might be scaled to 0; still verify presence
    out = subprocess.check_output(["kubectl", "get", "deploy", "mcp-k8s-server", "-n", "fawkes", "-o", "json"])
    data = json.loads(out)
    assert data["metadata"]["name"] == "mcp-k8s-server"
    replicas = data["spec"].get("replicas", 0)
    assert replicas >= 0

@pytest.mark.smoke
def test_limitrange_applied():
    out = subprocess.check_output(["kubectl", "get", "limitrange", "-n", "fawkes", "-o", "json"])
    data = json.loads(out)
    assert any(item["metadata"]["name"].startswith("fawkes-") for item in data.get("items", [])), "LimitRange missing"

@pytest.mark.smoke
def test_resourcequota_applied():
    out = subprocess.check_output(["kubectl", "get", "resourcequota", "-n", "fawkes", "-o", "json"])
    data = json.loads(out)
    assert any(item["metadata"]["name"].startswith("fawkes-") for item in data.get("items", [])), "ResourceQuota missing"

@pytest.mark.smoke
def test_ephemeral_pod_lifecycle():
    # Create ephemeral busybox pod and wait for completion
    pod_name = "smoke-echo"
    subprocess.run([
        "kubectl", "run", pod_name, "--image=busybox", "-n", "fawkes", "--restart=Never", "--", "sh", "-c", "echo smoke-test && sleep 1"
    ], check=True)
    # Wait until completed or timeout
    for _ in range(30):
        out = subprocess.check_output(["kubectl", "get", "pod", pod_name, "-n", "fawkes", "-o", "json"])
        phase = json.loads(out)["status"].get("phase")
        if phase in {"Succeeded", "Failed"}:
            break
        import time; time.sleep(1)
    assert phase == "Succeeded", f"Ephemeral pod did not succeed (phase={phase})"
    subprocess.check_output(["kubectl", "delete", "pod", pod_name, "-n", "fawkes", "--ignore-not-found=true"])

@pytest.mark.smoke
def test_smoke_passes():
    assert True
