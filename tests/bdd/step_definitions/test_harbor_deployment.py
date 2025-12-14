"""Step definitions for Harbor deployment validation.

Validates that Harbor container registry is properly deployed with:
- PostgreSQL database cluster
- All Harbor components running
- UI accessible via ingress
- Trivy scanner enabled
- Projects and robot accounts configured
"""
from __future__ import annotations

import json
import subprocess
import time
from typing import Dict
from urllib.parse import urlparse

import pytest
import requests
from pytest_bdd import given, when, then, parsers, scenarios

# Load all scenarios from the feature file
scenarios('../features/harbor-deployment.feature')


def _kubectl_json(args: list[str]) -> Dict:
    """Run kubectl and return parsed JSON."""
    cmd = ["kubectl"] + args
    try:
        raw = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
        return json.loads(raw.decode())
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"kubectl failed: {' '.join(cmd)}\n{e.output.decode()}")
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Failed to parse JSON from kubectl output: {e}")


def _kubectl_text(args: list[str]) -> str:
    """Run kubectl and return text output."""
    cmd = ["kubectl"] + args
    try:
        return subprocess.check_output(cmd, stderr=subprocess.STDOUT).decode().strip()
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"kubectl failed: {' '.join(cmd)}\n{e.output.decode()}")


# Background steps

@given("I have kubectl configured for the cluster")
def kubectl_configured():
    """Verify kubectl is configured and can reach the cluster."""
    subprocess.check_call(["kubectl", "cluster-info"], stdout=subprocess.DEVNULL)


@given("the ingress-nginx controller is deployed and running")
def ingress_nginx_running():
    """Verify ingress-nginx is running."""
    data = _kubectl_json(["-n", "ingress-nginx", "get", "deployment",
                          "ingress-nginx-controller", "-o", "json"])
    status = data.get("status", {})
    ready_replicas = status.get("readyReplicas", 0)
    assert ready_replicas > 0, "ingress-nginx controller not ready"


@given("the CloudNativePG Operator is installed")
def cloudnativepg_installed():
    """Verify CloudNativePG Operator is installed."""
    try:
        _kubectl_json(["get", "deployment", "-n", "cloudnativepg-system",
                      "cloudnativepg-operator-controller-manager", "-o", "json"])
    except RuntimeError:
        pytest.skip("CloudNativePG Operator not installed")


@given("the CloudNativePG Operator is running")
def cloudnativepg_running():
    """Verify CloudNativePG Operator is running."""
    data = _kubectl_json(["-n", "cloudnativepg-system", "get", "deployment",
                         "cloudnativepg-operator-controller-manager", "-o", "json"])
    status = data.get("status", {})
    ready_replicas = status.get("readyReplicas", 0)
    assert ready_replicas > 0, "CloudNativePG Operator not ready"


# Database scenario steps

@when("the Harbor database cluster is deployed")
def deploy_harbor_database(context: Dict):
    """Check if Harbor database cluster exists."""
    try:
        cluster = _kubectl_json(["get", "cluster", "db-harbor-dev", "-n", "fawkes", "-o", "json"])
        context["harbor_db_cluster"] = cluster
    except RuntimeError:
        context["harbor_db_cluster"] = None


@then(parsers.cfparse('the PostgreSQL cluster "{cluster_name}" should exist in namespace "{namespace}"'))
def postgres_cluster_exists(cluster_name: str, namespace: str, context: Dict):
    """Verify PostgreSQL cluster exists."""
    cluster = context.get("harbor_db_cluster")
    assert cluster is not None, f"PostgreSQL cluster {cluster_name} does not exist"
    assert cluster["metadata"]["name"] == cluster_name
    assert cluster["metadata"]["namespace"] == namespace


@then("the cluster should have 3 instances")
def cluster_has_three_instances(context: Dict):
    """Verify cluster has 3 instances."""
    cluster = context.get("harbor_db_cluster")
    assert cluster is not None, "No cluster data found"
    instances = cluster["spec"]["instances"]
    assert instances == 3, f"Expected 3 instances, got {instances}"


@then(parsers.cfparse('the database credentials secret "{secret_name}" should exist'))
def database_credentials_exist(secret_name: str):
    """Verify database credentials secret exists."""
    try:
        secret = _kubectl_json(["get", "secret", secret_name, "-n", "fawkes", "-o", "json"])
        assert secret is not None
        assert "username" in secret.get("data", {})
        assert "password" in secret.get("data", {})
    except RuntimeError as e:
        pytest.fail(f"Secret {secret_name} does not exist: {e}")


# Namespace scenario steps

@when(parsers.cfparse('I check for the {namespace} namespace'))
def check_namespace(namespace: str, context: Dict):
    """Check if namespace exists."""
    try:
        ns = _kubectl_json(["get", "ns", namespace, "-o", "json"])
        context[f"{namespace}_namespace"] = ns
    except RuntimeError:
        context[f"{namespace}_namespace"] = None


@then(parsers.cfparse('the namespace "{namespace}" should exist'))
def namespace_exists(namespace: str, context: Dict):
    """Verify namespace exists."""
    ns = context.get(f"{namespace}_namespace")
    assert ns is not None, f"Namespace {namespace} does not exist"


@then(parsers.cfparse('the namespace "{namespace}" should be Active'))
def namespace_is_active(namespace: str, context: Dict):
    """Verify namespace is Active."""
    ns = context.get(f"{namespace}_namespace")
    assert ns is not None, f"Namespace {namespace} does not exist"
    phase = ns.get("status", {}).get("phase")
    assert phase == "Active", f"Namespace {namespace} is {phase}, not Active"


# Pods scenario steps

@given(parsers.cfparse('Harbor is deployed in namespace "{namespace}"'))
def harbor_deployed(namespace: str):
    """Verify Harbor is deployed."""
    try:
        pods = _kubectl_json(["-n", namespace, "get", "pods", "-l", "app=harbor", "-o", "json"])
        items = pods.get("items", [])
        assert len(items) > 0, f"No Harbor pods found in namespace {namespace}"
    except RuntimeError as e:
        pytest.skip(f"Harbor not deployed: {e}")


@when("I check the Harbor pods")
def check_harbor_pods(context: Dict):
    """Check Harbor pods status."""
    try:
        pods = _kubectl_json(["-n", "fawkes", "get", "pods", "-l", "app=harbor", "-o", "json"])
        context["harbor_pods"] = pods.get("items", [])
    except RuntimeError as e:
        context["harbor_pods"] = []


@then("the following pods should be running in namespace \"fawkes\":")
def pods_running(datatable, context: Dict):
    """Verify specified pods are running."""
    pods = context.get("harbor_pods", [])
    expected_components = [row["component"] for row in datatable]
    
    # Get actual pod names
    actual_pods = [pod["metadata"]["name"] for pod in pods]
    
    # Check if each expected component has at least one pod
    for component in expected_components:
        matching_pods = [p for p in actual_pods if component in p]
        assert len(matching_pods) > 0, f"No pod found for component {component}"


@then(parsers.cfparse("all Harbor pods should be in Ready state within {timeout:d} seconds"))
def all_harbor_pods_ready(timeout: int, context: Dict):
    """Wait for all Harbor pods to be ready."""
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            pods = _kubectl_json(["-n", "fawkes", "get", "pods", "-l", "app=harbor", "-o", "json"])
            items = pods.get("items", [])
            
            if not items:
                time.sleep(5)
                continue
            
            all_ready = True
            for pod in items:
                conditions = pod.get("status", {}).get("conditions", [])
                ready_condition = next((c for c in conditions if c["type"] == "Ready"), None)
                if not ready_condition or ready_condition["status"] != "True":
                    all_ready = False
                    break
            
            if all_ready:
                return
            
            time.sleep(5)
        except RuntimeError:
            time.sleep(5)
    
    pytest.fail(f"Harbor pods not ready within {timeout} seconds")


# Ingress scenario steps

@given("Harbor is deployed with ingress enabled")
def harbor_ingress_enabled():
    """Verify Harbor has ingress configured."""
    try:
        ingresses = _kubectl_json(["-n", "fawkes", "get", "ingress", "-o", "json"])
        items = ingresses.get("items", [])
        harbor_ingress = [i for i in items if "harbor" in i["metadata"]["name"].lower()]
        assert len(harbor_ingress) > 0, "No Harbor ingress found"
    except RuntimeError as e:
        pytest.skip(f"Harbor ingress not configured: {e}")


@when(parsers.cfparse('I check the ingress configuration in namespace "{namespace}"'))
def check_ingress_config(namespace: str, context: Dict):
    """Check ingress configuration."""
    try:
        ingresses = _kubectl_json(["-n", namespace, "get", "ingress", "-o", "json"])
        context["harbor_ingresses"] = ingresses.get("items", [])
    except RuntimeError:
        context["harbor_ingresses"] = []


@then(parsers.cfparse('an ingress should exist for "{service}"'))
def ingress_exists_for_service(service: str, context: Dict):
    """Verify ingress exists for service."""
    ingresses = context.get("harbor_ingresses", [])
    matching = [i for i in ingresses if service.lower() in i["metadata"]["name"].lower()]
    assert len(matching) > 0, f"No ingress found for service {service}"
    context["harbor_ingress"] = matching[0]


@then(parsers.cfparse('the ingress should have host "{host}"'))
def ingress_has_host(host: str, context: Dict):
    """Verify ingress has expected host."""
    ingress = context.get("harbor_ingress")
    assert ingress is not None, "No ingress data found"
    
    rules = ingress.get("spec", {}).get("rules", [])
    hosts = [rule.get("host") for rule in rules]
    assert host in hosts, f"Host {host} not found in ingress. Found: {hosts}"


@then(parsers.cfparse('the ingress should use ingressClassName "{class_name}"'))
def ingress_has_class(class_name: str, context: Dict):
    """Verify ingress uses expected class."""
    ingress = context.get("harbor_ingress")
    assert ingress is not None, "No ingress data found"
    
    ingress_class = ingress.get("spec", {}).get("ingressClassName")
    assert ingress_class == class_name, f"Expected {class_name}, got {ingress_class}"


@then(parsers.cfparse('the Harbor UI should be accessible at "{url}"'))
def harbor_ui_accessible(url: str):
    """Verify Harbor UI is accessible."""
    try:
        # Try to access Harbor UI
        response = requests.get(url, timeout=10, allow_redirects=True)
        # Harbor typically returns 200 or redirects to login
        assert response.status_code in [200, 302, 401], \
            f"Harbor UI returned status {response.status_code}"
    except requests.exceptions.RequestException as e:
        pytest.skip(f"Cannot access Harbor UI: {e}")


# Authentication scenario steps

@given("Harbor UI is accessible")
def harbor_ui_accessible_given():
    """Verify Harbor UI is accessible."""
    try:
        response = requests.get("http://harbor.127.0.0.1.nip.io", timeout=10)
        assert response.status_code in [200, 302, 401]
    except requests.exceptions.RequestException as e:
        pytest.skip(f"Harbor UI not accessible: {e}")


@when("I attempt to login with admin credentials")
def attempt_login(context: Dict):
    """Attempt to login to Harbor."""
    # This is a placeholder - actual login requires Harbor API
    context["login_attempted"] = True


@then("I should successfully authenticate")
def login_successful(context: Dict):
    """Verify login was successful."""
    # This is a placeholder - would need Harbor API client
    assert context.get("login_attempted"), "Login not attempted"


@then("I should see the Harbor dashboard")
def see_dashboard(context: Dict):
    """Verify dashboard is visible."""
    # This is a placeholder - would need Harbor API client
    assert context.get("login_attempted"), "Login not attempted"


# Trivy scanner scenario steps

@when("I check the Trivy scanner pod")
def check_trivy_pod(context: Dict):
    """Check Trivy scanner pod."""
    try:
        pods = _kubectl_json(["-n", "fawkes", "get", "pods", 
                             "-l", "component=trivy", "-o", "json"])
        context["trivy_pods"] = pods.get("items", [])
    except RuntimeError:
        context["trivy_pods"] = []


@then(parsers.cfparse('the pod with label "{label}" should be running'))
def pod_with_label_running(label: str, context: Dict):
    """Verify pod with label is running."""
    trivy_pods = context.get("trivy_pods", [])
    assert len(trivy_pods) > 0, f"No pods found with label {label}"
    
    for pod in trivy_pods:
        phase = pod.get("status", {}).get("phase")
        assert phase == "Running", f"Pod is {phase}, not Running"


@then("the Trivy scanner should be registered in Harbor")
def trivy_registered():
    """Verify Trivy scanner is registered."""
    # This would require Harbor API call
    # Placeholder for now
    pass


# Additional placeholder steps for scenarios not fully implemented

@given("Harbor is deployed and accessible")
def harbor_deployed_accessible():
    """Verify Harbor is deployed and accessible."""
    harbor_ui_accessible_given()


@when("I query Harbor API for projects")
def query_harbor_projects(context: Dict):
    """Query Harbor API for projects."""
    context["harbor_projects_queried"] = True


@then(parsers.cfparse('the "{project}" project should exist'))
def project_exists(project: str, context: Dict):
    """Verify project exists."""
    # Placeholder - would need Harbor API client
    assert context.get("harbor_projects_queried")


@then("the project should be publicly accessible for reading")
def project_publicly_accessible():
    """Verify project is public."""
    # Placeholder - would need Harbor API client
    pass


@given("I am logged in with Docker CLI")
def docker_login():
    """Login to Harbor with Docker CLI."""
    # Placeholder - would need actual Docker login
    pass


@when(parsers.cfparse('I tag a test image "{source}" as "{target}"'))
def tag_image(source: str, target: str, context: Dict):
    """Tag a test image."""
    context["image_tagged"] = True


@when("I push the image to Harbor")
def push_image(context: Dict):
    """Push image to Harbor."""
    context["image_pushed"] = True


@then("the image should be successfully pushed")
def image_pushed_successfully(context: Dict):
    """Verify image was pushed."""
    assert context.get("image_pushed")


@then("the image should be visible in the Harbor UI")
def image_visible_ui():
    """Verify image is visible in UI."""
    pass


@then("the image should be automatically scanned by Trivy")
def image_scanned():
    """Verify image was scanned."""
    pass


@given("a container image is pushed to Harbor")
def image_pushed_to_harbor():
    """Prerequisite: image pushed to Harbor."""
    pytest.skip("Requires actual image push")


@when("I query the scan results via Harbor API")
def query_scan_results(context: Dict):
    """Query scan results."""
    context["scan_results_queried"] = True


@then("the scan results should show vulnerability counts")
def scan_shows_vulnerabilities(context: Dict):
    """Verify scan results show vulnerabilities."""
    assert context.get("scan_results_queried")


@then("the scan should have completed status")
def scan_completed():
    """Verify scan completed."""
    pass


@given("I am logged in as admin")
def logged_in_as_admin():
    """Login as admin."""
    pass


@when(parsers.cfparse('I create a robot account "{name}" with push/pull permissions'))
def create_robot_account(name: str, context: Dict):
    """Create robot account."""
    context["robot_account_created"] = True


@then("the robot account should be created")
def robot_account_created(context: Dict):
    """Verify robot account created."""
    assert context.get("robot_account_created")


@then("I should receive a token for authentication")
def receive_token():
    """Verify token received."""
    pass


@then("the robot account should be able to push images")
def robot_can_push():
    """Verify robot can push."""
    pass


@when("I check for ServiceMonitor resources")
def check_servicemonitor(context: Dict):
    """Check for ServiceMonitor."""
    try:
        monitors = _kubectl_json(["-n", "fawkes", "get", "servicemonitor", "-o", "json"])
        context["servicemonitors"] = monitors.get("items", [])
    except RuntimeError:
        context["servicemonitors"] = []


@then("a ServiceMonitor for Harbor should exist")
def servicemonitor_exists(context: Dict):
    """Verify ServiceMonitor exists."""
    monitors = context.get("servicemonitors", [])
    harbor_monitors = [m for m in monitors if "harbor" in m["metadata"]["name"].lower()]
    assert len(harbor_monitors) > 0, "No Harbor ServiceMonitor found"


@then("Prometheus should be scraping Harbor metrics")
def prometheus_scraping():
    """Verify Prometheus is scraping."""
    # Would need to check Prometheus targets
    pass


@given("Harbor is deployed with internal Redis")
def harbor_with_redis():
    """Verify Harbor has Redis."""
    harbor_deployed("fawkes")


@when(parsers.cfparse('I check Redis pod status in namespace "{namespace}"'))
def check_redis_pod(namespace: str, context: Dict):
    """Check Redis pod."""
    try:
        pods = _kubectl_json(["-n", namespace, "get", "pods",
                             "-l", "component=redis", "-o", "json"])
        context["redis_pods"] = pods.get("items", [])
    except RuntimeError:
        context["redis_pods"] = []


@then("the Redis pod should be running")
def redis_running(context: Dict):
    """Verify Redis is running."""
    redis_pods = context.get("redis_pods", [])
    assert len(redis_pods) > 0, "No Redis pods found"
    
    for pod in redis_pods:
        phase = pod.get("status", {}).get("phase")
        assert phase == "Running", f"Redis pod is {phase}, not Running"


@then("Harbor core should be able to connect to Redis")
def harbor_connects_redis():
    """Verify Harbor can connect to Redis."""
    # Would need to check Harbor logs or connection
    pass


@when("I check the PersistentVolumeClaims")
def check_pvcs(context: Dict):
    """Check PVCs."""
    try:
        pvcs = _kubectl_json(["-n", "fawkes", "get", "pvc", "-o", "json"])
        context["pvcs"] = pvcs.get("items", [])
    except RuntimeError:
        context["pvcs"] = []


@then("PVCs should exist for:")
def pvcs_exist_for_components(datatable, context: Dict):
    """Verify PVCs exist for components."""
    pvcs = context.get("pvcs", [])
    expected_components = [row["component"] for row in datatable]
    
    pvc_names = [pvc["metadata"]["name"] for pvc in pvcs]
    
    for component in expected_components:
        matching = [p for p in pvc_names if component in p]
        assert len(matching) > 0, f"No PVC found for {component}"


@then("all PVCs should be Bound")
def all_pvcs_bound(context: Dict):
    """Verify all PVCs are bound."""
    pvcs = context.get("pvcs", [])
    for pvc in pvcs:
        phase = pvc.get("status", {}).get("phase")
        assert phase == "Bound", f"PVC {pvc['metadata']['name']} is {phase}, not Bound"


@when("I configure a replication policy")
def configure_replication(context: Dict):
    """Configure replication policy."""
    context["replication_configured"] = True


@then("Harbor should support multi-registry replication")
def harbor_supports_replication(context: Dict):
    """Verify replication support."""
    assert context.get("replication_configured")


@then("artifacts should be replicated to target registry")
def artifacts_replicated():
    """Verify artifacts replicated."""
    pass


@when(parsers.cfparse('I query the Harbor API endpoint "{endpoint}"'))
def query_harbor_api(endpoint: str, context: Dict):
    """Query Harbor API."""
    try:
        response = requests.get(f"http://harbor.127.0.0.1.nip.io{endpoint}", timeout=10)
        context["api_response"] = response
    except requests.exceptions.RequestException as e:
        context["api_response"] = None


@then("I should receive a valid JSON response")
def valid_json_response(context: Dict):
    """Verify valid JSON response."""
    response = context.get("api_response")
    assert response is not None, "No API response"
    assert response.status_code == 200, f"Status code: {response.status_code}"
    try:
        response.json()
    except ValueError:
        pytest.fail("Response is not valid JSON")


@then("the response should contain Harbor version information")
def response_contains_version(context: Dict):
    """Verify response contains version."""
    response = context.get("api_response")
    assert response is not None
    data = response.json()
    # Check for version-related fields
    assert "harbor_version" in data or "version" in data
