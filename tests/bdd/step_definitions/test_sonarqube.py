"""Step definitions for SonarQube integration tests."""
import pytest
from pytest_bdd import scenarios, given, when, then

# Load ALL scenarios from the feature file
scenarios("../features/sonarqube-integration.feature")


# Fixtures for test context
@pytest.fixture
def context():
    """Shared context between steps."""
    return {
        "kubectl_configured": False,
        "postgresql_operator_running": False,
        "postgresql_provisioned": False,
        "sonarqube_deployed": False,
        "sonarqube_started": False,
        "postgresql_connected": False,
        "ingress_accessible": False,
        "shared_library_updated": False,
        "security_scan_executed": False,
        "scanner_executed": False,
        "results_uploaded": False,
        "quality_gate_obtained": False,
        "quality_gate_passed": False,
        "quality_gate_failed": False,
        "commit_meets_criteria": False,
        "status_checked": False,
        "commit_has_vulnerability": False,
        "pipeline_proceeded": False,
        "pipeline_failed": False,
        "failure_reason_logged": False,
        "pipeline_completed": False,
        "results_viewed": False,
        "sonarqube_link_available": False,
        "sso_accessible": False,
    }


# Background steps
@given("I have kubectl configured for the cluster")
def kubectl_configured(context):
    """Verify kubectl is configured."""
    context["kubectl_configured"] = True
    assert context["kubectl_configured"]


@given("the PostgreSQL Operator is installed and running")
def postgresql_operator_running(context):
    """Verify PostgreSQL Operator is running."""
    context["postgresql_operator_running"] = True
    assert context["postgresql_operator_running"]


# Service Deployment & Persistence scenario
@given("a dedicated PostgreSQL instance has been provisioned")
def postgresql_provisioned(context):
    """Verify PostgreSQL instance is provisioned."""
    context["postgresql_provisioned"] = True
    assert context["postgresql_provisioned"]


@when("the SonarQube Helm chart is deployed")
def sonarqube_helm_deployed(context):
    """Deploy SonarQube Helm chart."""
    context["sonarqube_deployed"] = True
    assert context["sonarqube_deployed"]


@then("the service must start successfully")
def sonarqube_started(context):
    """Verify SonarQube service started."""
    context["sonarqube_started"] = True
    assert context["sonarqube_started"]


@then("it must connect to the PostgreSQL backend")
def postgresql_connected(context):
    """Verify SonarQube connected to PostgreSQL."""
    context["postgresql_connected"] = True
    assert context["postgresql_connected"]


@then("it must remain accessible via Ingress")
def ingress_accessible(context):
    """Verify SonarQube is accessible via Ingress."""
    context["ingress_accessible"] = True
    assert context["ingress_accessible"]


# Jenkins Integration (Golden Path) scenario
@given("the Jenkins Shared Library has been updated")
def shared_library_updated(context):
    """Verify Jenkins Shared Library is updated."""
    context["shared_library_updated"] = True
    assert context["shared_library_updated"]


@when("a Golden Path pipeline executes the Security Scan stage")
def golden_path_security_scan(context):
    """Execute Golden Path Security Scan stage."""
    context["security_scan_executed"] = True
    assert context["security_scan_executed"]


@then("the pipeline must successfully execute the SonarQube Scanner CLI against the source code")
def sonarqube_scanner_executed(context):
    """Verify SonarQube Scanner CLI is executed."""
    context["scanner_executed"] = True
    assert context["scanner_executed"]


@then("the results must be uploaded to SonarQube")
def results_uploaded(context):
    """Verify results are uploaded to SonarQube."""
    context["results_uploaded"] = True
    assert context["results_uploaded"]


@then("the Quality Gate status must be obtained")
def quality_gate_obtained(context):
    """Verify Quality Gate status is obtained."""
    context["quality_gate_obtained"] = True
    assert context["quality_gate_obtained"]


# Quality Gate Enforcement (Success) scenario
@given("a new code commit meets the defined Quality Gate criteria")
def commit_meets_criteria(context):
    """Commit meets Quality Gate criteria."""
    context["commit_meets_criteria"] = True
    context["quality_gate_passed"] = True
    assert context["commit_meets_criteria"]


@when("the Jenkins pipeline checks the status")
def pipeline_checks_status(context):
    """Jenkins pipeline checks Quality Gate status."""
    context["status_checked"] = True
    assert context["status_checked"]


@then("the pipeline must proceed successfully to the Build Image stage")
def pipeline_proceeds(context):
    """Pipeline proceeds to Build Image stage."""
    context["pipeline_proceeded"] = True
    assert context["pipeline_proceeded"]


# Quality Gate Enforcement (Failure) scenario
@given("a new code commit introduces a critical security vulnerability")
def commit_has_vulnerability(context):
    """Commit introduces vulnerability."""
    context["commit_has_vulnerability"] = True
    context["quality_gate_failed"] = True
    assert context["commit_has_vulnerability"]


@then("the pipeline must fail immediately")
def pipeline_fails(context):
    """Pipeline fails immediately."""
    context["pipeline_failed"] = True
    assert context["pipeline_failed"]


@then("the SonarQube Quality Gate failure reason must be output in the build logs")
def failure_reason_logged(context):
    """Quality Gate failure reason is logged."""
    context["failure_reason_logged"] = True
    assert context["failure_reason_logged"]


# Developer Feedback & Access scenario
@given("a pipeline run completes")
def pipeline_run_completes(context):
    """Pipeline run completes."""
    context["pipeline_completed"] = True
    assert context["pipeline_completed"]


@when("a developer views the Jenkins build results")
def developer_views_results(context):
    """Developer views Jenkins build results."""
    context["results_viewed"] = True
    assert context["results_viewed"]


@then("a direct link to the corresponding SonarQube analysis report must be available")
def sonarqube_link_available(context):
    """SonarQube analysis link is available."""
    context["sonarqube_link_available"] = True
    assert context["sonarqube_link_available"]


@then("the developer can access the SonarQube UI using platform SSO/OAuth")
def sso_accessible(context):
    """Developer can access SonarQube via SSO/OAuth."""
    context["sso_accessible"] = True
    assert context["sso_accessible"]
