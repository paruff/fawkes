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
        assert conditions.get("Ready") == "True", f"Node {node['metadata']['name']} not Ready"import pytest


@pytest.mark.smoke
def test_smoke_passes():
    assert True
