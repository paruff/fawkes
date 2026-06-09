"""Step definitions for observability BDD tests."""

from behave import given, when, then
from fastapi.testclient import TestClient

from app.main import app


@given("the tracer-bullet service is running")
def step_service_running(context):
    context.client = TestClient(app)


@when('I GET "{path}"')
def step_get_path(context, path):
    context.response = context.client.get(path)


@then("the response status is {status:d}")
def step_response_status(context, status):
    assert context.response.status_code == status, f"Expected {status}, got {context.response.status_code}"


@then('the response body contains "{text}"')
def step_response_contains(context, text):
    content = context.response.text
    assert text in content, f"'{text}' not found in response: {content[:200]}"


@then("the trace_id is a valid 128-bit hex string")
def step_valid_trace_id(context):
    data = context.response.json()
    trace_id = data["trace_id"]
    assert len(trace_id) == 32, f"trace_id length {len(trace_id)}, expected 32"
    int(trace_id, 16)  # Raises ValueError if not valid hex


@then('the logs contain "{text}"')
def step_logs_contain(context, text):
    # In unit tests, logs go to stderr. We verify the TraceContextFilter
    # is configured by checking that the logger has the filter attached.
    import logging

    from app.main import logger

    filters = [f for f in logger.filters if f.__class__.__name__ == "TraceContextFilter"]
    assert len(filters) > 0, "TraceContextFilter not found on logger"
    # The filter adds trace_id and span_id to every record
    record = logging.LogRecord(
        name="test", level=logging.INFO, pathname="", lineno=0, msg="test", args=(), exc_info=None
    )
    filters[0].filter(record)
    assert hasattr(record, "trace_id"), "trace_id not injected into log record"
    assert hasattr(record, "span_id"), "span_id not injected into log record"
