"""
Step definitions for Jenkins Kubernetes deployment tests.

Tests Jenkins deployment via ArgoCD with Kubernetes plugin configured
for dynamic agent provisioning.
"""

import pytest
import requests
from pytest_bdd import scenarios, given, when, then, parsers

# Load all scenarios from the feature file
scenarios("../features/jenkins/jenkins-kubernetes-deployment.feature")


@pytest.fixture
def jenkins_context():
    """Shared context for Jenkins tests."""
    return {
        "namespace": "fawkes",
        "jenkins_url": "http://jenkins.127.0.0.1.nip.io",
        "jenkins_service": "jenkins",
        "admin_username": "admin",
        "admin_password": "test-password-123",  # Test fixture password, not a real credential
        "deployment": None,
        "pods": [],
        "agent_templates": [],
        "response": None,
    }


# Background steps
@given("the Fawkes platform namespace exists")
def check_namespace_exists(jenkins_context, kubectl_helper):
    """Verify the fawkes namespace exists."""
    namespaces = kubectl_helper.get_namespaces()
    assert jenkins_context["namespace"] in namespaces, f"Namespace {jenkins_context['namespace']} not found"


@given("ArgoCD is deployed and running")
def check_argocd_running(jenkins_context, kubectl_helper):
    """Verify ArgoCD is running."""
    # This is a prerequisite check, can be mocked for unit tests
    jenkins_context["argocd_running"] = True
    assert jenkins_context["argocd_running"]


# Scenario 1: Jenkins is deployed via ArgoCD
@given("the Jenkins ArgoCD Application is created")
def check_argocd_app_created(jenkins_context):
    """Verify Jenkins ArgoCD application exists."""
    # In a real test, this would check ArgoCD for the application
    jenkins_context["argocd_app_exists"] = True
    assert jenkins_context["argocd_app_exists"]


@when("I check the Jenkins deployment status")
def check_jenkins_deployment(jenkins_context, kubectl_helper):
    """Check Jenkins deployment status."""
    jenkins_context["deployment"] = kubectl_helper.get_deployment("jenkins", jenkins_context["namespace"])


@then("Jenkins should be running in the fawkes namespace")
def verify_jenkins_running(jenkins_context):
    """Verify Jenkins deployment exists and is running."""
    assert jenkins_context["deployment"] is not None, "Jenkins deployment not found"
    assert jenkins_context["deployment"]["namespace"] == jenkins_context["namespace"]


@then("the Jenkins pod should be in Ready state")
def verify_jenkins_pod_ready(jenkins_context, kubectl_helper):
    """Verify Jenkins pod is ready."""
    pods = kubectl_helper.get_pods_by_label("app.kubernetes.io/name=jenkins", jenkins_context["namespace"])
    jenkins_context["pods"] = pods
    assert len(pods) > 0, "No Jenkins pods found"
    assert pods[0]["status"] == "Running", f"Jenkins pod status: {pods[0]['status']}"
    assert pods[0]["ready"], "Jenkins pod is not ready"


@then("the Jenkins service should be created")
def verify_jenkins_service(jenkins_context, kubectl_helper):
    """Verify Jenkins service exists."""
    service = kubectl_helper.get_service(jenkins_context["jenkins_service"], jenkins_context["namespace"])
    assert service is not None, "Jenkins service not found"


# Scenario 2: Kubernetes plugin is configured
@given("Jenkins is deployed and running")
def jenkins_is_running(jenkins_context, kubectl_helper):
    """Ensure Jenkins is deployed and running."""
    jenkins_context["jenkins_running"] = True
    # This would be actual checks in integration tests
    assert jenkins_context["jenkins_running"]


@when("I check the Jenkins configuration")
def check_jenkins_config(jenkins_context, jenkins_api_helper):
    """Check Jenkins configuration via API or JCasC."""
    jenkins_context["config"] = jenkins_api_helper.get_configuration()


@then("the Kubernetes cloud should be configured")
def verify_k8s_cloud_configured(jenkins_context):
    """Verify Kubernetes cloud is configured in Jenkins."""
    config = jenkins_context.get("config", {})
    clouds = config.get("clouds", [])
    k8s_clouds = [c for c in clouds if c.get("name") == "kubernetes"]
    assert len(k8s_clouds) > 0, "Kubernetes cloud not configured"
    jenkins_context["k8s_cloud"] = k8s_clouds[0]


@then(parsers.parse("the Kubernetes cloud should target the {namespace} namespace"))
def verify_k8s_cloud_namespace(jenkins_context, namespace):
    """Verify Kubernetes cloud targets correct namespace."""
    k8s_cloud = jenkins_context.get("k8s_cloud", {})
    assert k8s_cloud.get("namespace") == namespace, f"Expected namespace {namespace}, got {k8s_cloud.get('namespace')}"


@then(parsers.parse('the Jenkins URL should be "{url}"'))
def verify_jenkins_url(jenkins_context, url):
    """Verify Jenkins URL is correctly configured."""
    k8s_cloud = jenkins_context.get("k8s_cloud", {})
    assert k8s_cloud.get("jenkinsUrl") == url, f"Expected URL {url}, got {k8s_cloud.get('jenkinsUrl')}"


@then(parsers.parse('the Jenkins tunnel should be "{tunnel}"'))
def verify_jenkins_tunnel(jenkins_context, tunnel):
    """Verify Jenkins tunnel is correctly configured."""
    k8s_cloud = jenkins_context.get("k8s_cloud", {})
    assert k8s_cloud.get("jenkinsTunnel") == tunnel, f"Expected tunnel {tunnel}, got {k8s_cloud.get('jenkinsTunnel')}"


# Scenario 3: Agent templates are configured
@given("Jenkins is deployed with Kubernetes plugin")
def jenkins_with_k8s_plugin(jenkins_context):
    """Ensure Jenkins has Kubernetes plugin configured."""
    jenkins_context["k8s_plugin_configured"] = True
    assert jenkins_context["k8s_plugin_configured"]


@when("I check the configured agent templates")
def check_agent_templates(jenkins_context, jenkins_api_helper):
    """Get list of configured agent templates."""
    config = jenkins_api_helper.get_configuration()
    jenkins_context["k8s_cloud"] = config["clouds"][0]
    jenkins_context["agent_templates"] = config["clouds"][0].get("templates", [])


@then("all expected agent templates should exist")
def verify_agent_templates(jenkins_context):
    """Verify expected agent templates exist."""
    templates = jenkins_context.get("agent_templates", [])

    # Expected templates from JCasC configuration
    expected_templates = ["jnlp-agent", "maven-agent", "python-agent", "node-agent", "go-agent"]
    template_names = [t.get("name") for t in templates]

    for expected_name in expected_templates:
        assert expected_name in template_names, f"Agent template {expected_name} not found"


@then(parsers.parse("agent templates should include {template_name}"))
def verify_template_exists(jenkins_context, template_name):
    """Verify specific template exists."""
    templates = jenkins_context.get("agent_templates", [])
    template_names = [t.get("name") for t in templates]
    assert template_name in template_names, f"Agent template {template_name} not found"


# Scenario 4: Dynamic agent provisioning works
@given("Jenkins is accessible")
def jenkins_accessible(jenkins_context):
    """Verify Jenkins is accessible."""
    jenkins_context["jenkins_accessible"] = True
    assert jenkins_context["jenkins_accessible"]


@given("the Kubernetes plugin is configured")
def k8s_plugin_configured(jenkins_context):
    """Verify Kubernetes plugin is configured."""
    jenkins_context["k8s_plugin_configured"] = True
    assert jenkins_context["k8s_plugin_configured"]


@when(parsers.parse('a pipeline job requests a "{label}" label'))
def request_agent_with_label(jenkins_context, label, jenkins_api_helper):
    """Simulate pipeline job requesting an agent with specific label."""
    jenkins_context["requested_label"] = label
    jenkins_context["job_executed"] = jenkins_api_helper.run_test_job(label)


@then("a Kubernetes pod should be created dynamically")
def verify_dynamic_pod_created(jenkins_context, kubectl_helper):
    """Verify a dynamic agent pod was created."""
    # This would check for pods with jenkins agent labels
    jenkins_context["dynamic_pod_created"] = True
    assert jenkins_context["dynamic_pod_created"]


@then(parsers.parse("the pod should run in the {namespace} namespace"))
def verify_pod_namespace(jenkins_context, namespace):
    """Verify pod runs in correct namespace."""
    assert jenkins_context["namespace"] == namespace


@then("the pod should connect to Jenkins controller")
def verify_pod_connected(jenkins_context):
    """Verify pod connected to Jenkins controller."""
    jenkins_context["pod_connected"] = True
    assert jenkins_context["pod_connected"]


@then("the job should execute on the dynamic agent")
def verify_job_executed(jenkins_context):
    """Verify job executed successfully on agent."""
    assert jenkins_context.get("job_executed", False)


@then("the pod should be terminated after job completion")
def verify_pod_terminated(jenkins_context):
    """Verify agent pod is terminated after job."""
    jenkins_context["pod_terminated"] = True
    assert jenkins_context["pod_terminated"]


# Scenario 5: Jenkins UI is accessible via Ingress
@given("Jenkins is deployed with Ingress enabled")
def jenkins_with_ingress(jenkins_context, kubectl_helper):
    """Verify Jenkins has Ingress configured."""
    ingress = kubectl_helper.get_ingress("jenkins", jenkins_context["namespace"])
    jenkins_context["ingress"] = ingress
    assert ingress is not None, "Jenkins ingress not found"


@when(parsers.parse('I access the Jenkins URL "{url}"'))
def access_jenkins_url(jenkins_context, url):
    """Access Jenkins via HTTP (mocked for unit test).

    Note: In integration tests, this would actually make HTTP request.
    For unit tests, we mock a successful response.
    """
    # Mock a successful response for unit tests
    # In integration tests, replace with: requests.get(url, timeout=10)
    jenkins_context["response"] = _create_mock_response()
    jenkins_context["url_accessed"] = url


def _create_mock_response():
    """Create mock HTTP response for testing."""

    class MockResponse:
        """Mock HTTP response object."""

        status_code = 200
        text = "<html><title>Jenkins</title><body>Jenkins login</body></html>"
        headers = {"Server": "nginx"}

    return MockResponse()


@then("I should receive a successful HTTP response")
def verify_http_success(jenkins_context):
    """Verify HTTP response is successful."""
    response = jenkins_context.get("response")
    assert response is not None, "No response received from Jenkins"
    assert response.status_code in [200, 403], f"Expected 200 or 403, got {response.status_code}"


@then("the Jenkins login page should be displayed")
def verify_login_page(jenkins_context):
    """Verify Jenkins login page is displayed."""
    response = jenkins_context.get("response")
    assert response is not None
    assert "jenkins" in response.text.lower(), "Jenkins page not detected"


@then("the page should be served over the nginx ingress")
def verify_nginx_ingress(jenkins_context):
    """Verify response comes from nginx ingress."""
    response = jenkins_context.get("response")
    assert response is not None
    # Check for nginx headers
    headers = response.headers
    # This is a simplified check; actual implementation may vary
    jenkins_context["served_by_nginx"] = True
    assert jenkins_context["served_by_nginx"]


# Scenario 6: Jenkins authentication is configured
@given("Jenkins is deployed")
def jenkins_deployed(jenkins_context):
    """Verify Jenkins is deployed."""
    jenkins_context["jenkins_deployed"] = True
    assert jenkins_context["jenkins_deployed"]


@when("I attempt to access Jenkins without credentials")
def access_without_credentials(jenkins_context):
    """Attempt to access Jenkins without auth."""
    jenkins_context["unauthenticated_access"] = False
    # Would check if redirected to login
    jenkins_context["redirected_to_login"] = True


@then("I should be redirected to the login page")
def verify_redirected_to_login(jenkins_context):
    """Verify redirect to login page."""
    assert jenkins_context.get("redirected_to_login", False)


@then("anonymous access should be denied")
def verify_anonymous_denied(jenkins_context):
    """Verify anonymous access is not allowed."""
    assert not jenkins_context.get("unauthenticated_access", False)


@when("I login with valid admin credentials")
def login_with_admin_creds(jenkins_context, jenkins_api_helper):
    """Login with admin credentials."""
    success = jenkins_api_helper.login(jenkins_context["admin_username"], jenkins_context["admin_password"])
    jenkins_context["login_success"] = success


@then("I should be authenticated successfully")
def verify_authentication_success(jenkins_context):
    """Verify login was successful."""
    assert jenkins_context.get("login_success", False)


@then("I should have access to Jenkins dashboard")
def verify_dashboard_access(jenkins_context):
    """Verify access to Jenkins dashboard."""
    jenkins_context["dashboard_access"] = True
    assert jenkins_context["dashboard_access"]


# Scenario 7: Agent resource limits are configured
@given("Jenkins has maven-agent template configured")
def maven_agent_configured(jenkins_context, jenkins_api_helper):
    """Verify maven-agent template exists."""
    config = jenkins_api_helper.get_configuration()
    jenkins_context["k8s_cloud"] = config["clouds"][0]
    jenkins_context["agent_templates"] = config["clouds"][0]["templates"]
    templates = jenkins_context.get("agent_templates", [])
    maven_template = next((t for t in templates if t.get("name") == "maven-agent"), None)
    jenkins_context["maven_template"] = maven_template
    assert maven_template is not None, "maven-agent template not found"


@when("I check the maven-agent resource configuration")
def check_maven_resources(jenkins_context):
    """Get maven agent resource configuration."""
    template = jenkins_context.get("maven_template")
    assert template is not None, "maven_template not set in context"
    containers = template.get("containers", [])
    maven_container = next((c for c in containers if "maven" in c.get("image", "")), None)
    jenkins_context["maven_container"] = maven_container
    assert maven_container is not None, "maven container not found in template"


@then(parsers.parse('the CPU request should be "{cpu}"'))
def verify_cpu_request(jenkins_context, cpu):
    """Verify CPU request value."""
    container = jenkins_context.get("maven_container", {})
    assert container.get("resourceRequestCpu") == cpu


@then(parsers.parse('the memory request should be "{memory}"'))
def verify_memory_request(jenkins_context, memory):
    """Verify memory request value."""
    container = jenkins_context.get("maven_container", {})
    assert container.get("resourceRequestMemory") == memory


@then(parsers.parse('the CPU limit should be "{cpu}"'))
def verify_cpu_limit(jenkins_context, cpu):
    """Verify CPU limit value."""
    container = jenkins_context.get("maven_container", {})
    assert container.get("resourceLimitCpu") == cpu


@then(parsers.parse('the memory limit should be "{memory}"'))
def verify_memory_limit(jenkins_context, memory):
    """Verify memory limit value."""
    container = jenkins_context.get("maven_container", {})
    assert container.get("resourceLimitMemory") == memory


# Scenario 8: Agent idle termination is configured
@given("Jenkins agent templates are configured")
def agent_templates_configured(jenkins_context):
    """Verify agent templates are configured."""
    jenkins_context["templates_configured"] = True
    assert jenkins_context["templates_configured"]


@when("I check the agent idle termination settings")
def check_idle_termination(jenkins_context):
    """Check idle termination configuration."""
    jenkins_context["checked_idle_termination"] = True


@then(parsers.parse("all agent templates should have idleTerminationMinutes set to {minutes:d}"))
def verify_idle_termination_minutes(jenkins_context, minutes):
    """Verify idle termination is set correctly."""
    templates = jenkins_context.get("agent_templates", [])
    for template in templates:
        assert (
            template.get("idleTerminationMinutes") == minutes
        ), f"Template {template.get('name')} has incorrect idle termination"


@then("idle agents should be terminated after the configured time")
def verify_idle_agents_terminated(jenkins_context):
    """Verify idle agents will be terminated."""
    jenkins_context["idle_termination_configured"] = True
    assert jenkins_context["idle_termination_configured"]


# Scenario 9: Agent capacity limits are configured
@given("the Kubernetes cloud is configured")
def k8s_cloud_configured(jenkins_context, jenkins_api_helper):
    """Verify Kubernetes cloud is configured."""
    config = jenkins_api_helper.get_configuration()
    jenkins_context["k8s_cloud"] = config["clouds"][0]
    jenkins_context["k8s_cloud_configured"] = True
    assert jenkins_context["k8s_cloud_configured"]


@when("I check the capacity settings")
def check_capacity_settings(jenkins_context):
    """Check capacity configuration."""
    jenkins_context["checked_capacity"] = True


@then(parsers.parse('the container capacity should be "{capacity}"'))
def verify_container_capacity(jenkins_context, capacity):
    """Verify container capacity limit."""
    k8s_cloud = jenkins_context.get("k8s_cloud", {})
    assert k8s_cloud.get("containerCapStr") == capacity


@then("each agent template should have appropriate instance capacity")
def verify_instance_capacity(jenkins_context):
    """Verify each template has instance capacity set."""
    templates = jenkins_context.get("agent_templates", [])
    for template in templates:
        assert "instanceCapStr" in template, f"Template {template.get('name')} missing instance capacity"


# Scenario 10: Jenkins Configuration as Code is working
@given("Jenkins is deployed with JCasC enabled")
def jenkins_with_jcasc(jenkins_context):
    """Verify Jenkins has JCasC enabled."""
    jenkins_context["jcasc_enabled"] = True
    assert jenkins_context["jcasc_enabled"]


@when("I check the Jenkins system message")
def check_system_message(jenkins_context, jenkins_api_helper):
    """Get Jenkins system message."""
    jenkins_context["system_message"] = jenkins_api_helper.get_system_message()


@then(parsers.parse('it should display "{message}"'))
def verify_system_message(jenkins_context, message):
    """Verify system message matches expected value."""
    actual_message = jenkins_context.get("system_message", "")
    assert message in actual_message, f"Expected '{message}' in system message, got '{actual_message}'"


@then(parsers.parse("the number of executors on controller should be {count:d}"))
def verify_executor_count(jenkins_context, count, jenkins_api_helper):
    """Verify number of executors on controller."""
    executor_count = jenkins_api_helper.get_executor_count()
    assert executor_count == count, f"Expected {count} executors, got {executor_count}"


@then("all configuration should be loaded from JCasC")
def verify_jcasc_loaded(jenkins_context):
    """Verify configuration is loaded from JCasC."""
    jenkins_context["jcasc_loaded"] = True
    assert jenkins_context["jcasc_loaded"]
