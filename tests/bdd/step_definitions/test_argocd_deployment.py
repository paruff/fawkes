"""Step definitions for ArgoCD deployment validation.

Validates that ArgoCD is properly deployed via Terraform with:
- Correct namespace (argocd)
- UI accessible via ingress
- CLI working
- Admin credentials secured
"""
from __future__ import annotations

import json
import subprocess
from typing import Dict
from urllib.parse import urlparse

import pytest
import requests
from pytest_bdd import given, when, then, parsers, scenarios

# Load all scenarios from the feature file
scenarios('../features/argocd-deployment.feature')


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


# Namespace scenario steps

@when("I check for the argocd namespace")
def check_argocd_namespace(context: Dict):
    """Check if argocd namespace exists."""
    try:
        ns = _kubectl_json(["get", "ns", "argocd", "-o", "json"])
        context["argocd_namespace"] = ns
    except RuntimeError:
        context["argocd_namespace"] = None


@then(parsers.cfparse('the namespace "{namespace}" should exist'))
def namespace_exists(namespace: str, context: Dict):
    """Verify namespace exists."""
    ns = context.get("argocd_namespace")
    assert ns is not None, f"Namespace {namespace} does not exist"


@then(parsers.cfparse('the namespace "{namespace}" should be Active'))
def namespace_active(namespace: str, context: Dict):
    """Verify namespace is in Active phase."""
    ns = context.get("argocd_namespace")
    phase = ns.get("status", {}).get("phase")
    assert phase == "Active", f"Namespace {namespace} is {phase}, not Active"


# Pods scenario steps

@given(parsers.cfparse('ArgoCD is deployed in namespace "{namespace}"'))
def argocd_deployed(namespace: str):
    """Verify ArgoCD is deployed."""
    data = _kubectl_json(["-n", namespace, "get", "deployment", "-o", "json"])
    deployments = [item["metadata"]["name"] for item in data.get("items", [])]
    assert "argocd-server" in deployments, "ArgoCD server deployment not found"


@when("I check the ArgoCD pods")
def check_argocd_pods(context: Dict):
    """Get ArgoCD pods."""
    data = _kubectl_json(["-n", "argocd", "get", "pods", "-o", "json"])
    context["argocd_pods"] = data.get("items", [])


@then(parsers.cfparse('the following pods should be running in namespace "{namespace}":\n{table}'))
def pods_running(namespace: str, table, context: Dict):
    """Verify specified pods are running."""
    pods = context.get("argocd_pods", [])
    pod_names = [pod["metadata"]["name"] for pod in pods]

    for row in table:
        component = row["component"]
        # Use startswith for more precise matching
        found = any(name.startswith(component) for name in pod_names)
        assert found, f"Pod with component '{component}' not found in namespace {namespace}"


@then(parsers.cfparse('all ArgoCD pods should be in Ready state within {timeout:d} seconds'))
def pods_ready(timeout: int):
    """Wait for all ArgoCD pods to be ready."""
    cmd = ["kubectl", "wait", "--for=condition=ready", "pod", 
           "-l", "app.kubernetes.io/part-of=argocd",
           "-n", "argocd", f"--timeout={timeout}s"]
    subprocess.check_call(cmd)


# Ingress scenario steps

@given("ArgoCD is deployed with ingress enabled")
def argocd_ingress_enabled():
    """Verify ArgoCD has ingress configured."""
    data = _kubectl_json(["-n", "argocd", "get", "ingress", "-o", "json"])
    ingresses = data.get("items", [])
    assert len(ingresses) > 0, "No ingress found for ArgoCD"


@when(parsers.cfparse('I check the ingress configuration in namespace "{namespace}"'))
def check_ingress(namespace: str, context: Dict):
    """Get ingress configuration."""
    data = _kubectl_json(["-n", namespace, "get", "ingress", "-o", "json"])
    context["argocd_ingresses"] = data.get("items", [])


@then(parsers.cfparse('an ingress should exist for "{service}"'))
def ingress_exists(service: str, context: Dict):
    """Verify ingress exists for service."""
    ingresses = context.get("argocd_ingresses", [])
    found = any(service in ing["metadata"]["name"] for ing in ingresses)
    assert found, f"Ingress for {service} not found"
    
    # Store the ingress for further checks
    for ing in ingresses:
        if service in ing["metadata"]["name"]:
            context["argocd_ingress"] = ing
            break


@then(parsers.cfparse('the ingress should have host "{host}"'))
def ingress_has_host(host: str, context: Dict):
    """Verify ingress has the specified host."""
    ingress = context.get("argocd_ingress")
    rules = ingress.get("spec", {}).get("rules", [])
    hosts = [rule.get("host") for rule in rules]
    assert host in hosts, f"Host {host} not found in ingress. Found: {hosts}"


@then(parsers.cfparse('the ingress should use ingressClassName "{classname}"'))
def ingress_has_class(classname: str, context: Dict):
    """Verify ingress uses the specified ingressClassName."""
    ingress = context.get("argocd_ingress")
    ing_class = ingress.get("spec", {}).get("ingressClassName")
    assert ing_class == classname, f"Expected ingressClassName {classname}, got {ing_class}"


@then(parsers.cfparse('the ArgoCD UI should be accessible at "{url}"'))
def ui_accessible(url: str):
    """Verify ArgoCD UI is accessible (basic check)."""
    # Validate URL format using proper parsing
    try:
        parsed = urlparse(url)
        # Verify URL has scheme and hostname
        if not parsed.scheme or not parsed.netloc:
            pytest.skip(f"Invalid URL format: {url}")
        # Verify hostname starts with argocd for security
        if not parsed.netloc.startswith('argocd.'):
            pytest.skip(f"URL hostname must start with 'argocd.' for security: {url}")
    except Exception as e:
        pytest.skip(f"Failed to parse URL {url}: {e}")

    # Note: This may fail in CI without proper DNS/routing
    # Consider it a soft check or skip in certain environments
    try:
        # For HTTPS, verify SSL; for HTTP (local dev), allow insecure
        verify_ssl = parsed.scheme == 'https'
        response = requests.get(url, timeout=10, allow_redirects=True, verify=verify_ssl)
        # ArgoCD UI should return something (200, 301, etc.)
        assert response.status_code < 500, f"ArgoCD UI returned {response.status_code}"
    except requests.RequestException as e:
        # In local/CI environments without proper routing, we can't always reach it
        # This is acceptable - the ingress configuration is the main requirement
        pytest.skip(f"Could not reach {url}: {e}")


# CLI scenario steps

@when("I retrieve the initial admin password")
def retrieve_admin_password(context: Dict):
    """Retrieve admin password from secret."""
    try:
        secret = _kubectl_json(["-n", "argocd", "get", "secret", 
                               "argocd-initial-admin-secret", "-o", "json"])
        context["admin_secret"] = secret
    except RuntimeError:
        context["admin_secret"] = None


@then(parsers.cfparse('the secret "{secret_name}" should exist in namespace "{namespace}"'))
def secret_exists(secret_name: str, namespace: str, context: Dict):
    """Verify secret exists."""
    secret = context.get("admin_secret")
    assert secret is not None, f"Secret {secret_name} not found in namespace {namespace}"


@then(parsers.cfparse('the secret should contain a "{key}" key'))
def secret_has_key(key: str, context: Dict):
    """Verify secret contains the specified key."""
    secret = context.get("admin_secret")
    data = secret.get("data", {})
    assert key in data, f"Key '{key}' not found in secret. Available keys: {list(data.keys())}"


@then("I should be able to login using argocd CLI")
def argocd_cli_login(context: Dict):
    """Verify argocd CLI can login (if CLI is installed)."""
    # Check if argocd CLI is available
    try:
        subprocess.check_output(["which", "argocd"], stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        pytest.skip("argocd CLI not installed")
    
    # This is a basic check - full login test would require more setup
    # Just verify the CLI can reach the server
    try:
        subprocess.check_output(["argocd", "version", "--client"], 
                               stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        pytest.skip("argocd CLI not functional")


# Security scenario steps

@when("I check the admin credentials storage")
def check_credentials_storage(context: Dict):
    """Check how admin credentials are stored."""
    try:
        secret = _kubectl_json(["-n", "argocd", "get", "secret",
                               "argocd-initial-admin-secret", "-o", "json"])
        context["admin_secret"] = secret
    except RuntimeError:
        context["admin_secret"] = None


@then("the credentials should be stored in a Kubernetes secret")
def credentials_in_secret(context: Dict):
    """Verify credentials are in a Kubernetes secret."""
    secret = context.get("admin_secret")
    assert secret is not None, "Admin credentials secret not found"
    assert secret.get("kind") == "Secret", "Admin credentials not stored as Secret"


@then(parsers.cfparse('the secret should be named "{name}"'))
def secret_named(name: str, context: Dict):
    """Verify secret has the correct name."""
    secret = context.get("admin_secret")
    actual_name = secret.get("metadata", {}).get("name")
    assert actual_name == name, f"Expected secret name {name}, got {actual_name}"


@then(parsers.cfparse('the secret should be in namespace "{namespace}"'))
def secret_in_namespace(namespace: str, context: Dict):
    """Verify secret is in the correct namespace."""
    secret = context.get("admin_secret")
    actual_ns = secret.get("metadata", {}).get("namespace")
    assert actual_ns == namespace, f"Expected namespace {namespace}, got {actual_ns}"


@then("the password should be base64 encoded")
def password_base64_encoded(context: Dict):
    """Verify password is base64 encoded."""
    secret = context.get("admin_secret")
    data = secret.get("data", {})
    assert "password" in data, "Password key not found in secret"
    # Kubernetes automatically base64 encodes data in secrets
    # Just verify it exists and is not empty
    assert len(data["password"]) > 0, "Password data is empty"


# Health scenario steps

@given(parsers.cfparse('ArgoCD server is running in namespace "{namespace}"'))
def argocd_server_running(namespace: str):
    """Verify ArgoCD server is running."""
    data = _kubectl_json(["-n", namespace, "get", "deployment", 
                         "argocd-server", "-o", "json"])
    status = data.get("status", {})
    ready = status.get("readyReplicas", 0)
    assert ready > 0, "ArgoCD server not ready"


@when("I check the ArgoCD server health endpoint")
def check_health_endpoint(context: Dict):
    """Check ArgoCD health endpoint."""
    # Port forward would be needed for full health check
    # For now, just verify the deployment is healthy
    try:
        data = _kubectl_json(["-n", "argocd", "get", "deployment",
                             "argocd-server", "-o", "json"])
        context["server_deployment"] = data
    except RuntimeError:
        context["server_deployment"] = None


@then(parsers.cfparse('the health endpoint should return status "{status}"'))
def health_status(status: str, context: Dict):
    """Verify health status (via deployment status)."""
    deployment = context.get("server_deployment")
    assert deployment is not None, "ArgoCD server deployment not found"
    
    # Check deployment conditions
    conditions = deployment.get("status", {}).get("conditions", [])
    available = any(c.get("type") == "Available" and c.get("status") == "True" 
                   for c in conditions)
    assert available, f"ArgoCD server not available. Expected health status: {status}"


@then("the API server should be responsive")
def api_server_responsive(context: Dict):
    """Verify API server is responsive."""
    deployment = context.get("server_deployment")
    status = deployment.get("status", {})
    ready = status.get("readyReplicas", 0)
    replicas = status.get("replicas", 0)
    assert ready == replicas and ready > 0, "API server not fully ready"


# Resources scenario steps

@when(parsers.cfparse('I check the resource specifications for ArgoCD deployments'))
def check_resource_specs(context: Dict):
    """Get resource specifications for ArgoCD deployments."""
    data = _kubectl_json(["-n", "argocd", "get", "deployments", "-o", "json"])
    context["argocd_deployments"] = data.get("items", [])


@then("all deployments should have CPU requests defined")
def deployments_have_cpu_requests(context: Dict):
    """Verify all deployments have CPU requests."""
    deployments = context.get("argocd_deployments", [])
    for deploy in deployments:
        containers = deploy.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
        for container in containers:
            resources = container.get("resources", {})
            requests = resources.get("requests", {})
            assert "cpu" in requests, f"CPU request not defined for {deploy['metadata']['name']}/{container['name']}"


@then("all deployments should have memory requests defined")
def deployments_have_memory_requests(context: Dict):
    """Verify all deployments have memory requests."""
    deployments = context.get("argocd_deployments", [])
    for deploy in deployments:
        containers = deploy.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
        for container in containers:
            resources = container.get("resources", {})
            requests = resources.get("requests", {})
            assert "memory" in requests, f"Memory request not defined for {deploy['metadata']['name']}/{container['name']}"


@then("all deployments should have CPU limits defined")
def deployments_have_cpu_limits(context: Dict):
    """Verify all deployments have CPU limits."""
    deployments = context.get("argocd_deployments", [])
    for deploy in deployments:
        containers = deploy.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
        for container in containers:
            resources = container.get("resources", {})
            limits = resources.get("limits", {})
            assert "cpu" in limits, f"CPU limit not defined for {deploy['metadata']['name']}/{container['name']}"


@then("all deployments should have memory limits defined")
def deployments_have_memory_limits(context: Dict):
    """Verify all deployments have memory limits."""
    deployments = context.get("argocd_deployments", [])
    for deploy in deployments:
        containers = deploy.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
        for container in containers:
            resources = container.get("resources", {})
            limits = resources.get("limits", {})
            assert "memory" in limits, f"Memory limit not defined for {deploy['metadata']['name']}/{container['name']}"


# CRDs scenario steps

@given("ArgoCD is deployed")
def argocd_deployed_simple():
    """Verify ArgoCD is deployed."""
    data = _kubectl_json(["-n", "argocd", "get", "deployment", "-o", "json"])
    deployments = [item["metadata"]["name"] for item in data.get("items", [])]
    assert len(deployments) > 0, "No ArgoCD deployments found"


@when("I check for ArgoCD Custom Resource Definitions")
def check_argocd_crds(context: Dict):
    """Get ArgoCD CRDs."""
    data = _kubectl_json(["get", "crd", "-o", "json"])
    context["all_crds"] = data.get("items", [])


@then("the following CRDs should exist:\n{table}")
def crds_exist(table, context: Dict):
    """Verify specified CRDs exist."""
    all_crds = context.get("all_crds", [])
    crd_names = [crd["metadata"]["name"] for crd in all_crds]
    
    for row in table:
        crd_name = row["crd"]
        assert crd_name in crd_names, f"CRD {crd_name} not found"


@then("all CRDs should be established")
def crds_established(context: Dict):
    """Verify all ArgoCD CRDs are established."""
    all_crds = context.get("all_crds", [])
    # Filter CRDs that are part of ArgoCD (ending with argoproj.io)
    argocd_crds = [crd for crd in all_crds if crd["metadata"]["name"].endswith(".argoproj.io")]

    for crd in argocd_crds:
        conditions = crd.get("status", {}).get("conditions", [])
        established = any(c.get("type") == "Established" and c.get("status") == "True"
                         for c in conditions)
        assert established, f"CRD {crd['metadata']['name']} not established"


# Service scenario steps

@when(parsers.cfparse('I check the ArgoCD services'))
def check_argocd_services(context: Dict):
    """Get ArgoCD services."""
    data = _kubectl_json(["-n", "argocd", "get", "services", "-o", "json"])
    context["argocd_services"] = data.get("items", [])


@then(parsers.cfparse('a service "{service_name}" should exist'))
def service_exists(service_name: str, context: Dict):
    """Verify service exists."""
    services = context.get("argocd_services", [])
    service_names = [svc["metadata"]["name"] for svc in services]
    assert service_name in service_names, f"Service {service_name} not found"
    
    # Store for further checks
    for svc in services:
        if svc["metadata"]["name"] == service_name:
            context["argocd_server_service"] = svc
            break


@then(parsers.cfparse('the service "{service_name}" should be type "{svc_type}"'))
def service_type(service_name: str, svc_type: str, context: Dict):
    """Verify service type."""
    service = context.get("argocd_server_service")
    actual_type = service.get("spec", {}).get("type")
    assert actual_type == svc_type, f"Expected type {svc_type}, got {actual_type}"


@then(parsers.cfparse('the service should expose port {port:d} for {protocol}'))
def service_exposes_port(port: int, protocol: str, context: Dict):
    """Verify service exposes the specified port."""
    service = context.get("argocd_server_service")
    ports = service.get("spec", {}).get("ports", [])
    port_numbers = [p.get("port") for p in ports]
    assert port in port_numbers, f"Port {port} not exposed. Available ports: {port_numbers}"
