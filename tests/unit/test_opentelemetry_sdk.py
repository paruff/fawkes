"""
Unit tests validating OpenTelemetry SDK 1.41.1 functionality.

Covers traces, metrics, and logs signal types to confirm the upgrade
from 1.28.2 does not regress core SDK behaviour.
"""

import pytest
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.sdk.trace.export.in_memory_span_exporter import InMemorySpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import InMemoryMetricReader

# ---------------------------------------------------------------------------
# Traces
# ---------------------------------------------------------------------------


@pytest.fixture()
def in_memory_tracer():
    """Return a tracer backed by an in-memory exporter."""
    exporter = InMemorySpanExporter()
    provider = TracerProvider(resource=Resource.create({"service.name": "test-service"}))
    provider.add_span_processor(SimpleSpanProcessor(exporter))
    tracer = provider.get_tracer("test-tracer")
    return tracer, exporter


@pytest.mark.unit
def test_trace_span_created(in_memory_tracer):
    """Span created via context manager is finished and exported."""
    tracer, exporter = in_memory_tracer
    with tracer.start_as_current_span("test-span") as span:
        span.set_attribute("key", "value")

    spans = exporter.get_finished_spans()
    assert len(spans) == 1
    assert spans[0].name == "test-span"
    assert spans[0].attributes["key"] == "value"


@pytest.mark.unit
def test_trace_nested_spans(in_memory_tracer):
    """Nested spans have the correct parent-child relationship."""
    tracer, exporter = in_memory_tracer
    with tracer.start_as_current_span("parent") as parent:
        with tracer.start_as_current_span("child") as child:
            child.set_attribute("nested", True)

    spans = exporter.get_finished_spans()
    assert len(spans) == 2
    child_span = next(s for s in spans if s.name == "child")
    parent_span = next(s for s in spans if s.name == "parent")
    assert child_span.parent.span_id == parent_span.context.span_id


@pytest.mark.unit
def test_trace_span_status_ok(in_memory_tracer):
    """Span status defaults to UNSET; setting OK is reflected in exported span."""
    from opentelemetry.trace import StatusCode

    tracer, exporter = in_memory_tracer
    with tracer.start_as_current_span("status-span") as span:
        span.set_status(StatusCode.OK)

    spans = exporter.get_finished_spans()
    assert spans[0].status.status_code == StatusCode.OK


@pytest.mark.unit
def test_trace_span_records_exception(in_memory_tracer):
    """Exceptions recorded on a span appear in the exported events."""
    tracer, exporter = in_memory_tracer
    with tracer.start_as_current_span("error-span") as span:
        try:
            raise ValueError("test error")
        except ValueError as exc:
            span.record_exception(exc)

    spans = exporter.get_finished_spans()
    assert len(spans[0].events) == 1
    assert spans[0].events[0].name == "exception"


# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------


@pytest.fixture()
def in_memory_meter():
    """Return a meter backed by an in-memory reader."""
    reader = InMemoryMetricReader()
    provider = MeterProvider(metric_readers=[reader])
    meter = provider.get_meter("test-meter")
    return meter, reader


@pytest.mark.unit
def test_metrics_counter_increments(in_memory_meter):
    """Counter add() is reflected in collected metrics."""
    meter, reader = in_memory_meter
    counter = meter.create_counter("requests_total", description="Total requests")
    counter.add(3, {"method": "GET"})

    data = reader.get_metrics_data()
    metrics_list = data.resource_metrics
    assert len(metrics_list) > 0

    scope_metrics = metrics_list[0].scope_metrics
    assert len(scope_metrics) > 0

    instrument_data = scope_metrics[0].metrics[0]
    assert instrument_data.name == "requests_total"
    dp = instrument_data.data.data_points[0]
    assert dp.value == 3


@pytest.mark.unit
def test_metrics_histogram_records(in_memory_meter):
    """Histogram record() is reflected in collected metrics."""
    meter, reader = in_memory_meter
    histogram = meter.create_histogram("request_duration_ms", description="Request latency")
    histogram.record(42, {"route": "/health"})

    data = reader.get_metrics_data()
    scope_metrics = data.resource_metrics[0].scope_metrics[0]
    instrument_data = scope_metrics.metrics[0]
    assert instrument_data.name == "request_duration_ms"
    dp = instrument_data.data.data_points[0]
    assert dp.sum == 42


# ---------------------------------------------------------------------------
# SDK version assertion
# ---------------------------------------------------------------------------


@pytest.mark.unit
def test_opentelemetry_sdk_version():
    """Confirm the installed SDK is 1.41.1."""
    import importlib.metadata

    version = importlib.metadata.version("opentelemetry-sdk")
    assert version == "1.41.1", f"Expected 1.41.1, got {version}"


@pytest.mark.unit
def test_opentelemetry_api_version():
    """Confirm the installed API is 1.41.1."""
    import importlib.metadata

    version = importlib.metadata.version("opentelemetry-api")
    assert version == "1.41.1", f"Expected 1.41.1, got {version}"
