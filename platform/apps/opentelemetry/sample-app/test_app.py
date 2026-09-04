"""Tests for the OpenTelemetry sample application."""

import os

# Disable OTel SDK so test runs don't attempt span export to the collector
os.environ["OTEL_SDK_DISABLED"] = "true"

import app

client = app.app.test_client()


def test_error_endpoint_does_not_leak_exception():
    """The /error response body must not contain the raw exception message."""
    response = client.get("/error")
    assert response.status_code == 500
    assert "This is an intentional error" not in response.get_data(as_text=True)
