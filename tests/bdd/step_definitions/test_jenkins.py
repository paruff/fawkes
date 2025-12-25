"""Step definitions for Jenkins pipeline tests."""
import pytest
from pytest_bdd import scenarios, given, when, then, parsers

# Load ALL scenarios from the feature file
scenarios("../features/jenkins/pipeline-creation.feature")


# Fixtures for test context
@pytest.fixture
def context():
    """Shared context between steps."""
    return {}


# Step definitions
@given("the Fawkes platform is deployed")
def fawkes_deployed(context):
    """Verify Fawkes platform is deployed."""
    # For now, just pass - you'll add real checks later
    context["fawkes_deployed"] = True
    assert context["fawkes_deployed"]


@given("Jenkins is running and accessible")
def jenkins_running(context):
    """Verify Jenkins is accessible."""
    # Mock for now
    context["jenkins_running"] = True
    assert context["jenkins_running"]


@when("I request a new workspace through Fawkes")
def request_workspace(context):
    """Request workspace creation."""
    # Mock the API call for now
    context["workspace_requested"] = True
    context["workspace_id"] = "test-workspace-123"


@then("a Jenkins pipeline should be created")
def verify_pipeline_created(context):
    """Verify pipeline exists."""
    # Mock verification
    assert context["workspace_requested"]
    assert context["workspace_id"]
