"""
BDD step definitions for health checks
"""
from behave import given, when, then
from fastapi.testclient import TestClient
from app.main import app


client = TestClient(app)


@when('I request the health endpoint')
def step_request_health(context):
    context.response = client.get("/health")


@when('I request the ready endpoint')
def step_request_ready(context):
    context.response = client.get("/ready")


@when('I request the info endpoint')
def step_request_info(context):
    context.response = client.get("/info")


@then('the response status should be {status_code:d}')
def step_check_status(context, status_code):
    assert context.response.status_code == status_code, \
        f"Expected {status_code}, got {context.response.status_code}"


@then('the response should contain status "{status}"')
def step_check_status_field(context, status):
    data = context.response.json()
    assert data.get("status") == status, \
        f"Expected status '{status}', got '{data.get('status')}'"


@then('the response should contain service "{service}"')
def step_check_service(context, service):
    data = context.response.json()
    assert data.get("service") == service, \
        f"Expected service '{service}', got '{data.get('service')}'"


@then('the response should contain name "{name}"')
def step_check_name(context, name):
    data = context.response.json()
    assert data.get("name") == name, \
        f"Expected name '{name}', got '{data.get('name')}'"


@then('the response should contain version "{version}"')
def step_check_version(context, version):
    data = context.response.json()
    assert data.get("version") == version, \
        f"Expected version '{version}', got '{data.get('version')}'"
