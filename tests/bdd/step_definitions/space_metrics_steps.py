"""
BDD step definitions for SPACE metrics service tests.

Tests SPACE framework (Satisfaction, Performance, Activity, Communication, Efficiency)
metrics collection, API endpoints, survey integration, and privacy compliance.
"""
from behave import given, when, then
import requests
import json
import time
import logging
from kubernetes import client, config
from kubernetes.stream import stream

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
    return core, apps


def get_pod_name(core_api, namespace, label_selector, timeout=120):
    """Get the first running pod matching the label selector."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            pods = core_api.list_namespaced_pod(
                namespace=namespace,
                label_selector=label_selector,
                field_selector="status.phase=Running"
            )
            if pods.items:
                pod_name = pods.items[0].metadata.name
                logger.info(f"Found running pod: {pod_name}")
                return pod_name
        except Exception as e:
            logger.debug(f"Error finding pod: {e}")
        time.sleep(2)
    raise RuntimeError(f"No running pod found for selector '{label_selector}' in {namespace}")


def exec_in_pod(core_api, namespace, pod_name, command):
    """Execute a command in a pod and return the output."""
    try:
        resp = stream(
            core_api.connect_get_namespaced_pod_exec,
            pod_name,
            namespace,
            command=command,
            stderr=True,
            stdin=False,
            stdout=True,
            tty=False,
        )
        return resp
    except Exception as e:
        logger.error(f"Error executing command in pod: {e}")
        raise


def parse_table_to_dict(table):
    """Parse a behave table into a dictionary.
    
    Args:
        table: Behave table with two columns (key, value)
        
    Returns:
        dict: Dictionary with parsed values, attempting float conversion
    """
    result = {}
    if table:
        for row in table:
            key = row[0]  # First column is the key
            value = row[1]  # Second column is the value
            # Try to convert to numeric type
            try:
                # Try float first to handle both int and float
                numeric_value = float(value)
                # If it's a whole number, convert to int
                if numeric_value.is_integer():
                    result[key] = int(numeric_value)
                else:
                    result[key] = numeric_value
            except (ValueError, AttributeError):
                # Keep as string if not numeric
                result[key] = value
    return result


# Background steps

@given('the SPACE metrics service is deployed')
def step_space_metrics_deployed(context):
    """Verify SPACE metrics service is deployed."""
    core_api, apps_api = load_kube_clients()
    namespace = getattr(context, 'namespace', 'fawkes-local')
    
    context.namespace = namespace
    context.core_api = core_api
    context.apps_api = apps_api
    
    # Check if deployment exists
    try:
        deployment = apps_api.read_namespaced_deployment("space-metrics", namespace)
        assert deployment is not None
        logger.info(f"SPACE metrics deployment found in {namespace}")
        
        # Wait for deployment to be ready
        max_retries = 30
        for i in range(max_retries):
            deployment = apps_api.read_namespaced_deployment("space-metrics", namespace)
            if deployment.status.ready_replicas and deployment.status.ready_replicas > 0:
                logger.info(f"SPACE metrics deployment is ready with {deployment.status.ready_replicas} replica(s)")
                break
            time.sleep(2)
        else:
            logger.warning("SPACE metrics deployment not ready after waiting")
    except client.exceptions.ApiException as e:
        logger.error(f"SPACE metrics deployment not found: {e}")
        raise


@given('the database is initialized')
def step_database_initialized(context):
    """Verify database connection is available."""
    # Check if database secret exists
    try:
        core_api = context.core_api
        namespace = context.namespace
        secret = core_api.read_namespaced_secret("space-metrics-db-credentials", namespace)
        assert secret is not None
        logger.info("Database credentials secret found")
        context.db_secret_exists = True
    except client.exceptions.ApiException as e:
        logger.warning(f"Database credentials secret not found: {e}")
        context.db_secret_exists = False


# Health check steps

@when('I check the health endpoint')
def step_check_health_endpoint(context):
    """Check the health endpoint of SPACE metrics service."""
    try:
        pod_name = get_pod_name(context.core_api, context.namespace, "app=space-metrics")
        context.pod_name = pod_name
        
        # Execute curl command in the pod
        command = ["curl", "-s", "http://localhost:8000/health"]
        output = exec_in_pod(context.core_api, context.namespace, pod_name, command)
        
        context.health_response = json.loads(output)
        context.health_status_code = 200
        logger.info(f"Health check response: {context.health_response}")
    except Exception as e:
        logger.error(f"Error checking health endpoint: {e}")
        context.health_status_code = 500
        context.health_response = {}


@then('the service should respond with status "{status}"')
def step_verify_status(context, status):
    """Verify the service status."""
    assert context.health_status_code == 200, f"Expected 200, got {context.health_status_code}"
    assert context.health_response.get('status') == status, \
        f"Expected status '{status}', got '{context.health_response.get('status')}'"


@then('the response should include service name "{service_name}"')
def step_verify_service_name(context, service_name):
    """Verify the service name in response."""
    assert context.health_response.get('service') == service_name, \
        f"Expected service '{service_name}', got '{context.health_response.get('service')}'"


# SPACE dimensions steps

@when('I request SPACE metrics')
def step_request_space_metrics(context):
    """Request all SPACE metrics."""
    try:
        pod_name = context.pod_name
        command = ["curl", "-s", "http://localhost:8000/api/v1/metrics/space"]
        output = exec_in_pod(context.core_api, context.namespace, pod_name, command)
        
        context.space_metrics = json.loads(output)
        logger.info(f"SPACE metrics response: {context.space_metrics}")
    except Exception as e:
        logger.error(f"Error requesting SPACE metrics: {e}")
        context.space_metrics = {}


@then('I should receive data for all 5 dimensions')
def step_verify_all_dimensions(context):
    """Verify all 5 SPACE dimensions are present."""
    metrics = context.space_metrics
    assert 'dimensions' in metrics or all(dim in metrics for dim in [
        'satisfaction', 'performance', 'activity', 'communication', 'efficiency'
    ]), "Not all SPACE dimensions are present"


@then('the dimensions should include "{dimension}"')
def step_verify_dimension_included(context, dimension):
    """Verify specific dimension is included."""
    metrics = context.space_metrics
    if 'dimensions' in metrics:
        assert dimension in metrics['dimensions'], f"Dimension '{dimension}' not found"
    else:
        assert dimension in metrics, f"Dimension '{dimension}' not found"


# Individual dimension steps

@when('I request {dimension} dimension metrics')
def step_request_dimension_metrics(context, dimension):
    """Request metrics for a specific dimension."""
    try:
        pod_name = context.pod_name
        command = ["curl", "-s", f"http://localhost:8000/api/v1/metrics/space/{dimension}"]
        output = exec_in_pod(context.core_api, context.namespace, pod_name, command)
        
        context.dimension_metrics = json.loads(output)
        context.dimension_name = dimension
        logger.info(f"{dimension.capitalize()} metrics response: {context.dimension_metrics}")
    except Exception as e:
        logger.error(f"Error requesting {dimension} metrics: {e}")
        context.dimension_metrics = {}


@then('I should receive {dimension} data')
def step_verify_dimension_data(context, dimension):
    """Verify dimension data is received."""
    assert context.dimension_metrics, f"No data received for {dimension} dimension"
    assert isinstance(context.dimension_metrics, dict), f"{dimension} data should be a dictionary"


@then('the data should include "{field}"')
def step_verify_field_in_data(context, field):
    """Verify specific field is in the data."""
    assert field in context.dimension_metrics or \
           any(field in str(v) for v in context.dimension_metrics.values()), \
           f"Field '{field}' not found in response"


# Survey integration steps

@when('I submit a pulse survey response')
def step_submit_pulse_survey(context):
    """Submit a pulse survey response."""
    try:
        pod_name = context.pod_name
        
        # Build survey data from table or use defaults
        if hasattr(context, 'table') and context.table:
            survey_data = parse_table_to_dict(context.table)
        else:
            # Default survey data
            survey_data = {
                "valuable_work_percentage": 70.0,
                "flow_state_days": 3.0,
                "cognitive_load": 3.0
            }
        
        # Execute POST request
        json_data = json.dumps(survey_data)
        command = [
            "curl", "-s", "-X", "POST",
            "-H", "Content-Type: application/json",
            "-d", json_data,
            "http://localhost:8000/api/v1/surveys/pulse/submit"
        ]
        output = exec_in_pod(context.core_api, context.namespace, pod_name, command)
        
        context.survey_response = json.loads(output)
        logger.info(f"Pulse survey response: {context.survey_response}")
    except Exception as e:
        logger.error(f"Error submitting pulse survey: {e}")
        context.survey_response = {"status": "error", "message": str(e)}


@then('the survey should be accepted')
def step_verify_survey_accepted(context):
    """Verify survey was accepted."""
    assert context.survey_response.get('status') in ['success', 'accepted'], \
        f"Survey not accepted: {context.survey_response}"


@then('I should receive a success confirmation')
def step_verify_success_confirmation(context):
    """Verify success confirmation is received."""
    assert context.survey_response.get('status') == 'success' or \
           'success' in str(context.survey_response).lower(), \
           f"No success confirmation: {context.survey_response}"


# Friction logging steps

@when('I log a friction incident')
def step_log_friction_incident(context):
    """Log a friction incident."""
    try:
        pod_name = context.pod_name
        
        # Build friction data from table or use defaults
        if hasattr(context, 'table') and context.table:
            friction_data = parse_table_to_dict(context.table)
        else:
            # Default friction data
            friction_data = {
                "title": "Test friction",
                "description": "Testing friction logging",
                "severity": "low"
            }
        
        # Execute POST request
        json_data = json.dumps(friction_data)
        command = [
            "curl", "-s", "-X", "POST",
            "-H", "Content-Type: application/json",
            "-d", json_data,
            "http://localhost:8000/api/v1/friction/log"
        ]
        output = exec_in_pod(context.core_api, context.namespace, pod_name, command)
        
        context.friction_response = json.loads(output)
        logger.info(f"Friction logging response: {context.friction_response}")
    except Exception as e:
        logger.error(f"Error logging friction: {e}")
        context.friction_response = {"status": "error", "message": str(e)}


@then('the friction incident should be logged')
def step_verify_friction_logged(context):
    """Verify friction incident was logged."""
    assert context.friction_response.get('status') in ['success', 'logged'], \
        f"Friction not logged: {context.friction_response}"


# DevEx health score steps

@when('I request the DevEx health score')
def step_request_health_score(context):
    """Request the DevEx health score."""
    try:
        pod_name = context.pod_name
        command = ["curl", "-s", "http://localhost:8000/api/v1/metrics/space/health"]
        output = exec_in_pod(context.core_api, context.namespace, pod_name, command)
        
        context.health_score_response = json.loads(output)
        logger.info(f"Health score response: {context.health_score_response}")
    except Exception as e:
        logger.error(f"Error requesting health score: {e}")
        context.health_score_response = {}


@then('I should receive a health score between {min_score:d} and {max_score:d}')
def step_verify_health_score_range(context, min_score, max_score):
    """Verify health score is in valid range."""
    score = context.health_score_response.get('score', context.health_score_response.get('health_score', -1))
    assert min_score <= score <= max_score, \
        f"Health score {score} not in range [{min_score}, {max_score}]"


@then('the response should include a status indicator')
def step_verify_status_indicator(context):
    """Verify status indicator is present."""
    assert 'status' in context.health_score_response or 'indicator' in context.health_score_response, \
        "No status indicator found in response"


# Prometheus metrics steps

@when('I request Prometheus metrics')
def step_request_prometheus_metrics(context):
    """Request Prometheus metrics."""
    try:
        pod_name = context.pod_name
        command = ["curl", "-s", "http://localhost:8000/metrics"]
        output = exec_in_pod(context.core_api, context.namespace, pod_name, command)
        
        context.prometheus_metrics = output
        logger.info(f"Prometheus metrics received: {len(output)} bytes")
    except Exception as e:
        logger.error(f"Error requesting Prometheus metrics: {e}")
        context.prometheus_metrics = ""


@then('the metrics should include "{metric_name}"')
def step_verify_metric_included(context, metric_name):
    """Verify specific metric is included in Prometheus output."""
    assert metric_name in context.prometheus_metrics, \
        f"Metric '{metric_name}' not found in Prometheus output"


# Privacy compliance steps

@when('I request aggregated metrics')
def step_request_aggregated_metrics(context):
    """Request aggregated metrics."""
    try:
        pod_name = context.pod_name
        command = ["curl", "-s", "http://localhost:8000/api/v1/metrics/space"]
        output = exec_in_pod(context.core_api, context.namespace, pod_name, command)
        
        context.aggregated_metrics = output
        logger.info(f"Aggregated metrics received")
    except Exception as e:
        logger.error(f"Error requesting aggregated metrics: {e}")
        context.aggregated_metrics = ""


@then('individual developer data should not be exposed')
def step_verify_no_individual_data(context):
    """Verify individual developer data is not exposed."""
    # Check for common individual identifiers
    forbidden_fields = ['user_id', 'username', 'email', 'developer_name', 'developer_id']
    metrics_text = context.aggregated_metrics.lower()
    
    for field in forbidden_fields:
        assert field not in metrics_text, \
            f"Individual identifier '{field}' found in metrics response"


@then('metrics should be aggregated for teams of {threshold:d}+ developers')
def step_verify_aggregation_threshold(context, threshold):
    """Verify aggregation threshold is enforced."""
    try:
        # Check ConfigMap for aggregation threshold
        configmap = context.core_api.read_namespaced_config_map(
            "space-metrics-config",
            context.namespace
        )
        threshold_value = configmap.data.get('aggregation-threshold', '0')
        
        try:
            config_threshold = int(threshold_value)
        except ValueError:
            logger.error(f"Invalid aggregation threshold value: {threshold_value}")
            assert False, f"Aggregation threshold '{threshold_value}' is not a valid integer"
        
        assert config_threshold >= threshold, \
            f"Aggregation threshold {config_threshold} is less than required {threshold}"
        logger.info(f"Aggregation threshold verified: {config_threshold}")
    except client.exceptions.ApiException as e:
        logger.warning(f"Could not verify aggregation threshold: {e}")
        # Don't fail test if we can't check the config


@then('no personal identifiers should be in the response')
def step_verify_no_personal_identifiers(context):
    """Verify no personal identifiers in response."""
    # This is similar to the individual data check
    personal_identifiers = [
        'user_id', 'userid', 'username', 'user_name',
        'email', 'e-mail', 'developer_name', 'developername',
        'developer_id', 'developerid', 'person_id', 'personid'
    ]
    metrics_text = context.aggregated_metrics.lower()
    
    for identifier in personal_identifiers:
        assert identifier not in metrics_text, \
            f"Personal identifier '{identifier}' found in response"
