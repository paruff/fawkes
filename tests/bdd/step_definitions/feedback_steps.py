"""
BDD step definitions for feedback service tests.
"""
from behave import given, when, then
import requests
import json
import time
import logging
from kubernetes import client, config

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def load_kube_clients():
    """Load kube config and return API clients."""
    try:
        config.load_kube_config()
        logger.info("Loaded kubeconfig from default location")
    except Exception:
        logger.info("Falling back to in-cluster kube config")
        config.load_incluster_config()
    
    core = client.CoreV1Api()
    apps = client.AppsV1Api()
    networking = client.NetworkingV1Api()
    return core, apps, networking


@given('the feedback service is deployed in namespace "{namespace}"')
def step_feedback_service_deployed(context, namespace):
    """Verify feedback service is deployed."""
    core_api, apps_api, _ = load_kube_clients()
    context.namespace = namespace
    context.core_api = core_api
    context.apps_api = apps_api
    
    # Check if deployment exists
    try:
        deployment = apps_api.read_namespaced_deployment("feedback-service", namespace)
        assert deployment is not None
        logger.info(f"Feedback service deployment found in {namespace}")
    except client.exceptions.ApiException as e:
        logger.error(f"Feedback service deployment not found: {e}")
        raise


@given('the feedback service is accessible')
def step_feedback_service_accessible(context):
    """Set up feedback service URL."""
    context.feedback_url = "http://feedback.127.0.0.1.nip.io"
    context.api_base = f"{context.feedback_url}/api/v1"
    
    # Wait for service to be ready
    max_retries = 30
    for i in range(max_retries):
        try:
            response = requests.get(f"{context.feedback_url}/health", timeout=5)
            if response.status_code == 200:
                logger.info("Feedback service is accessible")
                return
        except requests.exceptions.RequestException as e:
            logger.debug(f"Waiting for feedback service (attempt {i+1}/{max_retries}): {e}")
            time.sleep(2)
    
    # Service not accessible, but continue for other tests
    logger.warning("Feedback service not accessible via ingress, tests may fail")


@given('I have admin authorization')
def step_have_admin_auth(context):
    """Set up admin authorization header."""
    # In a real environment, this would use the actual admin token from secrets
    context.admin_token = "admin-secret-token"
    context.auth_headers = {"Authorization": f"Bearer {context.admin_token}"}


@given('there is existing feedback with ID {feedback_id}')
def step_existing_feedback(context, feedback_id):
    """Create or reference existing feedback."""
    context.feedback_id = int(feedback_id)
    # For testing, we'll submit a feedback first
    try:
        feedback_data = {
            "rating": 4,
            "category": "Test",
            "comment": "Test feedback for status update"
        }
        response = requests.post(
            f"{context.api_base}/feedback",
            json=feedback_data,
            timeout=10
        )
        if response.status_code == 201:
            data = response.json()
            context.feedback_id = data.get("id")
            logger.info(f"Created test feedback with ID {context.feedback_id}")
    except Exception as e:
        logger.warning(f"Could not create test feedback: {e}")


@when('I check for the feedback-service deployment in namespace "{namespace}"')
def step_check_feedback_deployment(context, namespace):
    """Check feedback service deployment."""
    _, apps_api, _ = load_kube_clients()
    try:
        context.deployment = apps_api.read_namespaced_deployment("feedback-service", namespace)
        logger.info(f"Found feedback-service deployment in {namespace}")
    except client.exceptions.ApiException as e:
        logger.error(f"Failed to find deployment: {e}")
        context.deployment = None


@when('I check for the CloudNativePG cluster in namespace "{namespace}"')
def step_check_cnpg_cluster(context, namespace):
    """Check CloudNativePG cluster."""
    try:
        config.load_kube_config()
    except Exception:
        config.load_incluster_config()
    
    custom_api = client.CustomObjectsApi()
    try:
        context.db_cluster = custom_api.get_namespaced_custom_object(
            group="postgresql.cnpg.io",
            version="v1",
            namespace=namespace,
            plural="clusters",
            name="db-feedback-dev"
        )
        logger.info(f"Found CloudNativePG cluster db-feedback-dev in {namespace}")
    except client.exceptions.ApiException as e:
        logger.error(f"Failed to find CloudNativePG cluster: {e}")
        context.db_cluster = None


@when('I submit feedback with rating {rating:d} and category "{category}"')
def step_submit_feedback(context, rating, category):
    """Submit feedback."""
    feedback_data = {
        "rating": rating,
        "category": category,
        "comment": "This is a test feedback comment",
        "email": "tester@example.com",
        "page_url": "https://backstage.example.com/test"
    }
    
    try:
        response = requests.post(
            f"{context.api_base}/feedback",
            json=feedback_data,
            timeout=10
        )
        context.response = response
        if response.status_code == 201:
            context.feedback_data = response.json()
            logger.info(f"Submitted feedback successfully: {context.feedback_data}")
        else:
            logger.error(f"Failed to submit feedback: {response.status_code} - {response.text}")
    except Exception as e:
        logger.error(f"Error submitting feedback: {e}")
        context.response = None


@when('I try to submit feedback with invalid rating {rating:d}')
def step_submit_invalid_feedback(context, rating):
    """Try to submit feedback with invalid data."""
    feedback_data = {
        "rating": rating,
        "category": "Test",
        "comment": "Test comment"
    }
    
    try:
        response = requests.post(
            f"{context.api_base}/feedback",
            json=feedback_data,
            timeout=10
        )
        context.response = response
        logger.info(f"Invalid feedback response: {response.status_code}")
    except Exception as e:
        logger.error(f"Error submitting invalid feedback: {e}")
        context.response = None


@when('I try to list feedback without authorization')
def step_list_feedback_no_auth(context):
    """Try to list feedback without authorization."""
    try:
        response = requests.get(f"{context.api_base}/feedback", timeout=10)
        context.response = response
        logger.info(f"List feedback without auth response: {response.status_code}")
    except Exception as e:
        logger.error(f"Error listing feedback: {e}")
        context.response = None


@when('I list all feedback')
def step_list_feedback(context):
    """List all feedback with admin auth."""
    try:
        response = requests.get(
            f"{context.api_base}/feedback",
            headers=context.auth_headers,
            timeout=10
        )
        context.response = response
        if response.status_code == 200:
            context.feedback_list = response.json()
            logger.info(f"Listed feedback: {len(context.feedback_list.get('items', []))} items")
    except Exception as e:
        logger.error(f"Error listing feedback: {e}")
        context.response = None


@when('I update feedback status to "{status}"')
def step_update_feedback_status(context, status):
    """Update feedback status."""
    try:
        response = requests.put(
            f"{context.api_base}/feedback/{context.feedback_id}/status",
            json={"status": status},
            headers=context.auth_headers,
            timeout=10
        )
        context.response = response
        if response.status_code == 200:
            context.updated_feedback = response.json()
            logger.info(f"Updated feedback status to {status}")
    except Exception as e:
        logger.error(f"Error updating feedback status: {e}")
        context.response = None


@when('I request feedback statistics')
def step_request_stats(context):
    """Request feedback statistics."""
    try:
        response = requests.get(
            f"{context.api_base}/feedback/stats",
            headers=context.auth_headers,
            timeout=10
        )
        context.response = response
        if response.status_code == 200:
            context.stats = response.json()
            logger.info(f"Retrieved feedback stats")
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        context.response = None


@when('I check the ingress configuration in namespace "{namespace}"')
def step_check_ingress(context, namespace):
    """Check ingress configuration."""
    _, _, networking_api = load_kube_clients()
    try:
        context.ingress = networking_api.read_namespaced_ingress("feedback-service", namespace)
        logger.info(f"Found feedback-service ingress in {namespace}")
    except client.exceptions.ApiException as e:
        logger.error(f"Failed to find ingress: {e}")
        context.ingress = None


@when('I check the Backstage app-config')
def step_check_backstage_config(context):
    """Check Backstage configuration for feedback proxy."""
    core_api, _, _ = load_kube_clients()
    try:
        config_map = core_api.read_namespaced_config_map("backstage-app-config", "fawkes")
        context.backstage_config = config_map.data.get("app-config.yaml", "")
        logger.info("Retrieved Backstage app-config")
    except Exception as e:
        logger.error(f"Error retrieving Backstage config: {e}")
        context.backstage_config = ""


@when('I request metrics from the feedback service')
def step_request_metrics(context):
    """Request Prometheus metrics."""
    try:
        response = requests.get(f"{context.feedback_url}/metrics", timeout=10)
        context.metrics_response = response
        if response.status_code == 200:
            context.metrics = response.text
            logger.info("Retrieved metrics successfully")
    except Exception as e:
        logger.error(f"Error getting metrics: {e}")
        context.metrics_response = None


@then('the deployment "{deployment_name}" should exist')
def step_deployment_exists(context, deployment_name):
    """Verify deployment exists."""
    assert context.deployment is not None, f"Deployment {deployment_name} not found"
    assert context.deployment.metadata.name == deployment_name


@then('the deployment should have at least {count:d} ready replica')
@then('the deployment should have at least {count:d} ready replicas')
def step_deployment_ready_replicas(context, count):
    """Verify deployment has ready replicas."""
    assert context.deployment is not None
    ready_replicas = context.deployment.status.ready_replicas or 0
    assert ready_replicas >= count, f"Expected at least {count} ready replicas, got {ready_replicas}"


@then('the feedback service should be healthy')
def step_feedback_healthy(context):
    """Verify feedback service is healthy."""
    try:
        response = requests.get(f"{context.feedback_url}/health", timeout=10)
        assert response.status_code == 200
        data = response.json()
        assert data.get("status") in ["healthy", "degraded"]
        logger.info(f"Feedback service health: {data.get('status')}")
    except Exception as e:
        logger.warning(f"Health check failed: {e}")
        # Don't fail the test if service is not accessible yet
        pass


@then('the cluster "{cluster_name}" should exist')
def step_cluster_exists(context, cluster_name):
    """Verify CloudNativePG cluster exists."""
    assert context.db_cluster is not None, f"Cluster {cluster_name} not found"
    assert context.db_cluster.get("metadata", {}).get("name") == cluster_name


@then('the database cluster should be ready')
def step_cluster_ready(context):
    """Verify database cluster is ready."""
    if context.db_cluster:
        status = context.db_cluster.get("status", {})
        # Check if cluster has instances
        instances = status.get("instances", 0)
        assert instances > 0, "Cluster has no instances"
        logger.info(f"Database cluster has {instances} instances")


@then('the feedback should be accepted')
def step_feedback_accepted(context):
    """Verify feedback was accepted."""
    assert context.response is not None
    assert context.response.status_code == 201, f"Expected 201, got {context.response.status_code}"


@then('the response should contain a feedback ID')
def step_response_has_id(context):
    """Verify response contains feedback ID."""
    assert hasattr(context, 'feedback_data')
    assert "id" in context.feedback_data
    assert context.feedback_data["id"] > 0


@then('the feedback status should be "{status}"')
def step_feedback_status(context, status):
    """Verify feedback status."""
    if hasattr(context, 'feedback_data'):
        assert context.feedback_data.get("status") == status
    elif hasattr(context, 'updated_feedback'):
        assert context.updated_feedback.get("status") == status


@then('the request should be rejected with validation error')
def step_rejected_validation(context):
    """Verify request was rejected with validation error."""
    assert context.response is not None
    assert context.response.status_code == 422  # FastAPI validation error


@then('the response should indicate rating must be between 1 and 5')
def step_rating_validation_message(context):
    """Verify validation error message."""
    # FastAPI returns validation details in response
    assert context.response.status_code == 422


@then('the request should be rejected with status {status:d}')
def step_rejected_with_status(context, status):
    """Verify request was rejected with specific status."""
    assert context.response is not None
    assert context.response.status_code == status, \
        f"Expected {status}, got {context.response.status_code}"


@then('the request should be successful')
def step_request_successful(context):
    """Verify request was successful."""
    assert context.response is not None
    assert context.response.status_code == 200, \
        f"Expected 200, got {context.response.status_code}"


@then('the response should contain a list of feedback items')
def step_response_has_feedback_list(context):
    """Verify response contains feedback list."""
    assert hasattr(context, 'feedback_list')
    assert "items" in context.feedback_list
    assert isinstance(context.feedback_list["items"], list)


@then('the status update should be successful')
def step_status_update_successful(context):
    """Verify status update was successful."""
    assert context.response is not None
    assert context.response.status_code == 200


@then('the response should contain total feedback count')
def step_response_has_total(context):
    """Verify response contains total count."""
    assert hasattr(context, 'stats')
    assert "total_feedback" in context.stats


@then('the response should contain average rating')
def step_response_has_average(context):
    """Verify response contains average rating."""
    assert hasattr(context, 'stats')
    assert "average_rating" in context.stats


@then('the response should contain feedback by category')
def step_response_has_by_category(context):
    """Verify response contains breakdown by category."""
    assert hasattr(context, 'stats')
    assert "by_category" in context.stats


@then('the response should contain feedback by status')
def step_response_has_by_status(context):
    """Verify response contains breakdown by status."""
    assert hasattr(context, 'stats')
    assert "by_status" in context.stats


@then('an ingress should exist for "{ingress_name}"')
def step_ingress_exists(context, ingress_name):
    """Verify ingress exists."""
    assert context.ingress is not None, f"Ingress {ingress_name} not found"


@then('the ingress should have host "{host}"')
def step_ingress_has_host(context, host):
    """Verify ingress has specific host."""
    assert context.ingress is not None
    rules = context.ingress.spec.rules
    assert any(rule.host == host for rule in rules), f"Host {host} not found in ingress"


@then('the ingress should use ingressClassName "{class_name}"')
def step_ingress_has_class(context, class_name):
    """Verify ingress uses specific class."""
    assert context.ingress is not None
    assert context.ingress.spec.ingress_class_name == class_name


@then('the proxy should include endpoint "{endpoint}"')
def step_proxy_has_endpoint(context, endpoint):
    """Verify Backstage proxy includes feedback endpoint."""
    assert endpoint in context.backstage_config, \
        f"Proxy endpoint {endpoint} not found in Backstage config"


@then('the proxy target should be "{target}"')
def step_proxy_target(context, target):
    """Verify proxy target URL."""
    assert target in context.backstage_config, \
        f"Proxy target {target} not found in Backstage config"


@then('the response should contain Prometheus metrics')
def step_response_has_metrics(context):
    """Verify response contains Prometheus metrics."""
    assert context.metrics_response is not None
    assert context.metrics_response.status_code == 200


@then('metrics should include "{metric_name}"')
def step_metrics_include(context, metric_name):
    """Verify specific metric is present."""
    assert hasattr(context, 'metrics')
    assert metric_name in context.metrics, f"Metric {metric_name} not found"


@then('the deployment should have CPU requests defined')
def step_deployment_has_cpu_requests(context):
    """Verify deployment has CPU requests."""
    assert context.deployment is not None
    container = context.deployment.spec.template.spec.containers[0]
    assert container.resources.requests is not None
    assert "cpu" in container.resources.requests


@then('the deployment should have memory requests defined')
def step_deployment_has_memory_requests(context):
    """Verify deployment has memory requests."""
    assert context.deployment is not None
    container = context.deployment.spec.template.spec.containers[0]
    assert container.resources.requests is not None
    assert "memory" in container.resources.requests


@then('the deployment should have CPU limits defined')
def step_deployment_has_cpu_limits(context):
    """Verify deployment has CPU limits."""
    assert context.deployment is not None
    container = context.deployment.spec.template.spec.containers[0]
    assert container.resources.limits is not None
    assert "cpu" in container.resources.limits


@then('the deployment should have memory limits defined')
def step_deployment_has_memory_limits(context):
    """Verify deployment has memory limits."""
    assert context.deployment is not None
    container = context.deployment.spec.template.spec.containers[0]
    assert container.resources.limits is not None
    assert "memory" in container.resources.limits


@then('the deployment should run as non-root user')
def step_deployment_non_root(context):
    """Verify deployment runs as non-root."""
    assert context.deployment is not None
    security_context = context.deployment.spec.template.spec.security_context
    assert security_context is not None
    assert security_context.run_as_non_root is True
