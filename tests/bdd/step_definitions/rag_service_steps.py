"""Step definitions for RAG service validation.

Tests RAG (Retrieval Augmented Generation) service deployment,
health checks, context retrieval, and integration with Weaviate.
"""
from __future__ import annotations

import json
import subprocess
import time
import os
from typing import Dict, Any

import pytest
from pytest_bdd import given, when, then, parsers
import requests

if os.getenv("FAWKES_DEBUG_STEPS") == "1":  # pragma: no cover
    print("[bdd] Loaded rag_service_steps definitions")


def _kubectl_json(args: list[str]) -> Dict:
    """Run kubectl and return parsed JSON."""
    cmd = ["kubectl"] + args
    try:
        raw = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"kubectl failed: {' '.join(cmd)}\n{e.output.decode()}")
    try:
        return json.loads(raw.decode())
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Failed to parse JSON from kubectl output: {e}")


def _kubectl_run(args: list[str]) -> str:
    """Run kubectl and return output as string."""
    cmd = ["kubectl"] + args
    try:
        return subprocess.check_output(cmd, stderr=subprocess.STDOUT).decode().strip()
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"kubectl failed: {' '.join(cmd)}\n{e.output.decode()}")


def _wait_for_pods_ready(namespace: str, label_selector: str, timeout: int = 120) -> bool:
    """Wait for pods to be ready."""
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            pods = _kubectl_json([
                "get", "pods",
                "-n", namespace,
                "-l", label_selector,
                "-o", "json"
            ])
            
            items = pods.get("items", [])
            if not items:
                time.sleep(5)
                continue
            
            all_ready = True
            for pod in items:
                conditions = pod.get("status", {}).get("conditions", [])
                ready_condition = next(
                    (c for c in conditions if c.get("type") == "Ready"),
                    None
                )
                if not ready_condition or ready_condition.get("status") != "True":
                    all_ready = False
                    break
            
            if all_ready:
                return True
            
            time.sleep(5)
        except Exception:
            time.sleep(5)
    
    return False


@given("Weaviate is deployed and running")
def weaviate_deployed():
    """Check that Weaviate is deployed and running."""
    try:
        # Check if Weaviate deployment exists
        deployment = _kubectl_json([
            "get", "deployment", "weaviate",
            "-n", "fawkes",
            "-o", "json"
        ])
        
        # Check if replicas are ready
        status = deployment.get("status", {})
        ready_replicas = status.get("readyReplicas", 0)
        desired_replicas = status.get("replicas", 0)
        
        assert ready_replicas > 0, "Weaviate has no ready replicas"
        assert ready_replicas == desired_replicas, \
            f"Weaviate replicas not ready: {ready_replicas}/{desired_replicas}"
    except Exception as e:
        pytest.skip(f"Weaviate not deployed or not ready: {e}")


@when(parsers.cfparse('I check the RAG service deployment in namespace "{namespace}"'))
def check_rag_deployment(namespace: str, context: Dict):
    """Check RAG service deployment."""
    deployment = _kubectl_json([
        "get", "deployment", "rag-service",
        "-n", namespace,
        "-o", "json"
    ])
    context["rag_deployment"] = deployment


@then(parsers.cfparse('the deployment "{name}" should exist'))
def deployment_exists(name: str, context: Dict):
    """Verify deployment exists."""
    deployment = context.get("rag_deployment")
    assert deployment is not None, f"Deployment {name} not found"
    assert deployment.get("metadata", {}).get("name") == name


@then(parsers.cfparse('the deployment should have {replicas:d} replicas'))
def deployment_has_replicas(replicas: int, context: Dict):
    """Verify deployment has specified replicas."""
    deployment = context.get("rag_deployment")
    assert deployment is not None
    spec_replicas = deployment.get("spec", {}).get("replicas", 0)
    assert spec_replicas == replicas, \
        f"Expected {replicas} replicas, got {spec_replicas}"


@then(parsers.cfparse('all RAG service pods should be in Ready state within {timeout:d} seconds'))
def rag_pods_ready(timeout: int):
    """Wait for RAG service pods to be ready."""
    ready = _wait_for_pods_ready("fawkes", "app=rag-service", timeout)
    assert ready, f"RAG service pods not ready within {timeout} seconds"


@given(parsers.cfparse('RAG service is deployed in namespace "{namespace}"'))
def rag_service_deployed(namespace: str, context: Dict):
    """Check RAG service is deployed."""
    try:
        deployment = _kubectl_json([
            "get", "deployment", "rag-service",
            "-n", namespace,
            "-o", "json"
        ])
        context["rag_deployment"] = deployment
    except Exception as e:
        pytest.skip(f"RAG service not deployed: {e}")


@when(parsers.cfparse('I check the RAG service'))
def check_rag_service(context: Dict):
    """Check RAG service."""
    service = _kubectl_json([
        "get", "service", "rag-service",
        "-n", "fawkes",
        "-o", "json"
    ])
    context["rag_service"] = service


@then(parsers.cfparse('a service "{name}" should exist in namespace "{namespace}"'))
def service_exists(name: str, namespace: str, context: Dict):
    """Verify service exists."""
    service = context.get("rag_service")
    assert service is not None, f"Service {name} not found"
    assert service.get("metadata", {}).get("name") == name
    assert service.get("metadata", {}).get("namespace") == namespace


@then(parsers.cfparse('the service should be type "{service_type}"'))
def service_type_matches(service_type: str, context: Dict):
    """Verify service type."""
    service = context.get("rag_service")
    assert service is not None
    actual_type = service.get("spec", {}).get("type")
    assert actual_type == service_type, \
        f"Expected service type {service_type}, got {actual_type}"


@then(parsers.cfparse('the service should expose port {port:d}'))
def service_exposes_port(port: int, context: Dict):
    """Verify service exposes specified port."""
    service = context.get("rag_service")
    assert service is not None
    ports = service.get("spec", {}).get("ports", [])
    port_numbers = [p.get("port") for p in ports]
    assert port in port_numbers, \
        f"Port {port} not in service ports {port_numbers}"


@given("RAG service is deployed with ingress enabled")
def rag_service_with_ingress():
    """Check RAG service has ingress."""
    try:
        _kubectl_json([
            "get", "ingress", "rag-service",
            "-n", "fawkes",
            "-o", "json"
        ])
    except Exception as e:
        pytest.skip(f"RAG service ingress not found: {e}")


@when(parsers.cfparse('I check the ingress configuration in namespace "{namespace}"'))
def check_ingress(namespace: str, context: Dict):
    """Check ingress configuration."""
    ingress = _kubectl_json([
        "get", "ingress", "rag-service",
        "-n", namespace,
        "-o", "json"
    ])
    context["rag_ingress"] = ingress


@then(parsers.cfparse('an ingress should exist for "{name}"'))
def ingress_exists(name: str, context: Dict):
    """Verify ingress exists."""
    ingress = context.get("rag_ingress")
    assert ingress is not None, f"Ingress for {name} not found"


@then(parsers.cfparse('the ingress should have host "{host}"'))
def ingress_has_host(host: str, context: Dict):
    """Verify ingress has specified host."""
    ingress = context.get("rag_ingress")
    assert ingress is not None
    rules = ingress.get("spec", {}).get("rules", [])
    hosts = [r.get("host") for r in rules]
    assert host in hosts, f"Host {host} not in ingress hosts {hosts}"


@then(parsers.cfparse('the ingress should use ingressClassName "{class_name}"'))
def ingress_class_matches(class_name: str, context: Dict):
    """Verify ingress class."""
    ingress = context.get("rag_ingress")
    assert ingress is not None
    actual_class = ingress.get("spec", {}).get("ingressClassName")
    assert actual_class == class_name, \
        f"Expected ingressClassName {class_name}, got {actual_class}"


@given(parsers.cfparse('RAG service is running in namespace "{namespace}"'))
def rag_service_running(namespace: str):
    """Check RAG service is running."""
    try:
        pods = _kubectl_json([
            "get", "pods",
            "-n", namespace,
            "-l", "app=rag-service",
            "-o", "json"
        ])
        items = pods.get("items", [])
        assert len(items) > 0, "No RAG service pods found"
        
        # Check at least one pod is running
        running = any(
            pod.get("status", {}).get("phase") == "Running"
            for pod in items
        )
        assert running, "No RAG service pods in Running state"
    except Exception as e:
        pytest.skip(f"RAG service not running: {e}")


@when(parsers.cfparse('I query the health endpoint at "{path}"'))
def query_health_endpoint(path: str, context: Dict):
    """Query health endpoint."""
    # Port forward to service
    url = f"http://rag-service.127.0.0.1.nip.io{path}"
    try:
        response = requests.get(url, timeout=10)
        context["health_response"] = response
    except Exception as e:
        pytest.skip(f"Failed to query health endpoint: {e}")


@then(parsers.cfparse('the response status should be {status:d}'))
def response_status(status: int, context: Dict):
    """Verify response status code."""
    response = context.get("health_response") or context.get("query_response")
    assert response is not None, "No response in context"
    assert response.status_code == status, \
        f"Expected status {status}, got {response.status_code}"


@then(parsers.cfparse('the response should contain status "{status1}" or "{status2}"'))
def response_contains_status(status1: str, status2: str, context: Dict):
    """Verify response contains one of the specified statuses."""
    response = context.get("health_response")
    assert response is not None
    data = response.json()
    actual_status = data.get("status")
    assert actual_status in [status1, status2], \
        f"Status {actual_status} not in [{status1}, {status2}]"


@then("the response should indicate weaviate_connected status")
def response_has_weaviate_status(context: Dict):
    """Verify response has weaviate_connected field."""
    response = context.get("health_response")
    assert response is not None
    data = response.json()
    assert "weaviate_connected" in data, "Missing weaviate_connected field"


@given("RAG service is running and healthy")
def rag_service_healthy():
    """Check RAG service is healthy."""
    try:
        url = "http://rag-service.127.0.0.1.nip.io/api/v1/health"
        response = requests.get(url, timeout=10)
        assert response.status_code == 200
        data = response.json()
        assert data.get("status") in ["UP", "DEGRADED"]
    except Exception as e:
        pytest.skip(f"RAG service not healthy: {e}")


@given("internal documentation is indexed in Weaviate")
def documentation_indexed():
    """Check that documentation is indexed."""
    # This is a prerequisite that should be met by running index-docs.py
    # We'll skip if not met
    try:
        url = "http://rag-service.127.0.0.1.nip.io/api/v1/query"
        response = requests.post(
            url,
            json={"query": "test", "top_k": 1},
            timeout=10
        )
        assert response.status_code == 200
        data = response.json()
        # If we get any results, docs are indexed
        if data.get("count", 0) == 0:
            pytest.skip("No documents indexed in Weaviate")
    except Exception as e:
        pytest.skip(f"Cannot verify indexed documents: {e}")


@when(parsers.cfparse('I send a query "{query}"'))
def send_query(query: str, context: Dict):
    """Send query to RAG service."""
    url = "http://rag-service.127.0.0.1.nip.io/api/v1/query"
    start_time = time.time()
    try:
        response = requests.post(
            url,
            json={"query": query, "top_k": 5, "threshold": 0.7},
            timeout=10
        )
        elapsed_ms = (time.time() - start_time) * 1000
        context["query_response"] = response
        context["query_elapsed_ms"] = elapsed_ms
    except Exception as e:
        pytest.skip(f"Failed to send query: {e}")


@then(parsers.cfparse('the response should return within {max_ms:d} milliseconds'))
def response_within_time(max_ms: int, context: Dict):
    """Verify response time."""
    elapsed_ms = context.get("query_elapsed_ms", float('inf'))
    assert elapsed_ms <= max_ms, \
        f"Response time {elapsed_ms:.2f}ms exceeds {max_ms}ms"


@then(parsers.cfparse('the response should contain at least {min_count:d} result'))
@then(parsers.cfparse('the response should contain at least {min_count:d} results'))
def response_has_results(min_count: int, context: Dict):
    """Verify response has minimum number of results."""
    response = context.get("query_response")
    assert response is not None
    data = response.json()
    count = data.get("count", 0)
    assert count >= min_count, f"Expected at least {min_count} results, got {count}"


@then("the response should include retrieval_time_ms field")
def response_has_retrieval_time(context: Dict):
    """Verify response has retrieval_time_ms field."""
    response = context.get("query_response")
    assert response is not None
    data = response.json()
    assert "retrieval_time_ms" in data, "Missing retrieval_time_ms field"


@then("the response should contain results")
def response_contains_results(context: Dict):
    """Verify response contains results."""
    response = context.get("query_response")
    assert response is not None
    data = response.json()
    results = data.get("results", [])
    assert len(results) > 0, "No results in response"


@then(parsers.cfparse('at least one result should have relevance_score greater than {threshold:f}'))
def result_has_high_relevance(threshold: float, context: Dict):
    """Verify at least one result has high relevance score."""
    response = context.get("query_response")
    assert response is not None
    data = response.json()
    results = data.get("results", [])
    
    high_relevance = any(
        r.get("relevance_score", 0) > threshold
        for r in results
    )
    assert high_relevance, \
        f"No result with relevance_score > {threshold}"


@then("each result should have content, source, and relevance_score fields")
def results_have_required_fields(context: Dict):
    """Verify results have required fields."""
    response = context.get("query_response")
    assert response is not None
    data = response.json()
    results = data.get("results", [])
    
    for i, result in enumerate(results):
        assert "content" in result, f"Result {i} missing 'content' field"
        assert "source" in result, f"Result {i} missing 'source' field"
        assert "relevance_score" in result, f"Result {i} missing 'relevance_score' field"


@when(parsers.cfparse('I check the RAG service configuration'))
def check_rag_config(context: Dict):
    """Check RAG service configuration."""
    configmap = _kubectl_json([
        "get", "configmap", "rag-service-config",
        "-n", "fawkes",
        "-o", "json"
    ])
    context["rag_configmap"] = configmap


@then(parsers.cfparse('the ConfigMap "{name}" should exist'))
def configmap_exists(name: str, context: Dict):
    """Verify ConfigMap exists."""
    configmap = context.get("rag_configmap")
    assert configmap is not None, f"ConfigMap {name} not found"


@then("it should contain weaviate_url pointing to Weaviate service")
def configmap_has_weaviate_url(context: Dict):
    """Verify ConfigMap has weaviate_url."""
    configmap = context.get("rag_configmap")
    assert configmap is not None
    data = configmap.get("data", {})
    weaviate_url = data.get("weaviate_url")
    assert weaviate_url is not None, "Missing weaviate_url in ConfigMap"
    assert "weaviate" in weaviate_url.lower(), \
        f"weaviate_url doesn't reference Weaviate: {weaviate_url}"


@then("the RAG service should successfully connect to Weaviate")
def rag_connects_to_weaviate():
    """Verify RAG service connects to Weaviate."""
    try:
        url = "http://rag-service.127.0.0.1.nip.io/api/v1/health"
        response = requests.get(url, timeout=10)
        assert response.status_code == 200
        data = response.json()
        assert data.get("weaviate_connected") is True, \
            "RAG service not connected to Weaviate"
    except Exception as e:
        pytest.fail(f"Failed to verify Weaviate connection: {e}")


@when(parsers.cfparse('I check the resource specifications for RAG service deployment'))
def check_rag_resources(context: Dict):
    """Check RAG service resource specifications."""
    deployment = _kubectl_json([
        "get", "deployment", "rag-service",
        "-n", "fawkes",
        "-o", "json"
    ])
    context["rag_deployment"] = deployment


@then(parsers.cfparse('the deployment should have CPU requests of "{cpu}"'))
def deployment_has_cpu_request(cpu: str, context: Dict):
    """Verify deployment has CPU request."""
    deployment = context.get("rag_deployment")
    assert deployment is not None
    containers = deployment.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
    assert len(containers) > 0
    resources = containers[0].get("resources", {})
    requests = resources.get("requests", {})
    assert requests.get("cpu") == cpu, \
        f"Expected CPU request {cpu}, got {requests.get('cpu')}"


@then(parsers.cfparse('the deployment should have memory requests of "{memory}"'))
def deployment_has_memory_request(memory: str, context: Dict):
    """Verify deployment has memory request."""
    deployment = context.get("rag_deployment")
    assert deployment is not None
    containers = deployment.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
    assert len(containers) > 0
    resources = containers[0].get("resources", {})
    requests = resources.get("requests", {})
    assert requests.get("memory") == memory, \
        f"Expected memory request {memory}, got {requests.get('memory')}"


@then(parsers.cfparse('the deployment should have CPU limits of "{cpu}"'))
def deployment_has_cpu_limit(cpu: str, context: Dict):
    """Verify deployment has CPU limit."""
    deployment = context.get("rag_deployment")
    assert deployment is not None
    containers = deployment.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
    assert len(containers) > 0
    resources = containers[0].get("resources", {})
    limits = resources.get("limits", {})
    assert limits.get("cpu") == cpu, \
        f"Expected CPU limit {cpu}, got {limits.get('cpu')}"


@then(parsers.cfparse('the deployment should have memory limits of "{memory}"'))
def deployment_has_memory_limit(memory: str, context: Dict):
    """Verify deployment has memory limit."""
    deployment = context.get("rag_deployment")
    assert deployment is not None
    containers = deployment.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
    assert len(containers) > 0
    resources = containers[0].get("resources", {})
    limits = resources.get("limits", {})
    assert limits.get("memory") == memory, \
        f"Expected memory limit {memory}, got {limits.get('memory')}"


@when(parsers.cfparse('I check the security context for RAG service pods'))
def check_security_context(context: Dict):
    """Check security context for RAG service pods."""
    deployment = _kubectl_json([
        "get", "deployment", "rag-service",
        "-n", "fawkes",
        "-o", "json"
    ])
    context["rag_deployment"] = deployment


@then("the pods should run as non-root user")
def pods_run_as_nonroot(context: Dict):
    """Verify pods run as non-root."""
    deployment = context.get("rag_deployment")
    assert deployment is not None
    pod_spec = deployment.get("spec", {}).get("template", {}).get("spec", {})
    security_context = pod_spec.get("securityContext", {})
    assert security_context.get("runAsNonRoot") is True, \
        "Pod not configured to run as non-root"


@then(parsers.cfparse('the pods should have readOnlyRootFilesystem set to {value}'))
def pods_have_readonly_fs(value: str, context: Dict):
    """Verify readOnlyRootFilesystem setting."""
    deployment = context.get("rag_deployment")
    assert deployment is not None
    containers = deployment.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
    assert len(containers) > 0
    security_context = containers[0].get("securityContext", {})
    expected = value.lower() == "true"
    actual = security_context.get("readOnlyRootFilesystem", False)
    assert actual == expected, \
        f"Expected readOnlyRootFilesystem={expected}, got {actual}"


@then("the pods should drop all capabilities")
def pods_drop_capabilities(context: Dict):
    """Verify pods drop all capabilities."""
    deployment = context.get("rag_deployment")
    assert deployment is not None
    containers = deployment.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
    assert len(containers) > 0
    security_context = containers[0].get("securityContext", {})
    capabilities = security_context.get("capabilities", {})
    drop = capabilities.get("drop", [])
    assert "ALL" in drop, "Pod doesn't drop all capabilities"


@then(parsers.cfparse('a serviceaccount "{name}" should exist'))
def serviceaccount_exists(name: str):
    """Verify ServiceAccount exists."""
    sa = _kubectl_json([
        "get", "serviceaccount", name,
        "-n", "fawkes",
        "-o", "json"
    ])
    assert sa.get("metadata", {}).get("name") == name


@when(parsers.cfparse('I access the OpenAPI documentation at "{path}"'))
def access_openapi_docs(path: str, context: Dict):
    """Access OpenAPI documentation."""
    url = f"http://rag-service.127.0.0.1.nip.io{path}"
    try:
        response = requests.get(url, timeout=10)
        context["docs_response"] = response
    except Exception as e:
        pytest.skip(f"Failed to access OpenAPI docs: {e}")


@then("the documentation should be accessible")
def docs_accessible(context: Dict):
    """Verify documentation is accessible."""
    response = context.get("docs_response")
    assert response is not None
    assert response.status_code == 200, \
        f"Docs not accessible, status: {response.status_code}"


@then(parsers.cfparse('it should document the "{endpoint}" endpoint'))
def docs_contain_endpoint(endpoint: str, context: Dict):
    """Verify documentation contains endpoint."""
    response = context.get("docs_response")
    assert response is not None
    # Check if endpoint is mentioned in the page
    content = response.text.lower()
    assert endpoint.lower() in content, \
        f"Endpoint {endpoint} not found in documentation"


@then(parsers.cfparse('the query endpoint should accept query, top_k, and threshold parameters'))
def query_endpoint_has_parameters(context: Dict):
    """Verify query endpoint accepts required parameters."""
    response = context.get("docs_response")
    assert response is not None
    content = response.text.lower()
    assert "query" in content
    assert "top_k" in content or "topk" in content
    assert "threshold" in content


@when(parsers.cfparse('I query the metrics endpoint at "{path}"'))
def query_metrics_endpoint(path: str, context: Dict):
    """Query metrics endpoint."""
    url = f"http://rag-service.127.0.0.1.nip.io{path}"
    try:
        response = requests.get(url, timeout=10)
        context["metrics_response"] = response
    except Exception as e:
        pytest.skip(f"Failed to query metrics endpoint: {e}")


@then(parsers.cfparse('the response should contain metric "{metric}"'))
def response_contains_metric(metric: str, context: Dict):
    """Verify response contains metric."""
    response = context.get("metrics_response")
    assert response is not None
    content = response.text
    assert metric in content, f"Metric {metric} not found in metrics output"
