#!/usr/bin/env python3
"""
Sample Python application with OpenTelemetry instrumentation.
Demonstrates traces flowing to OpenTelemetry Collector.
"""

import os
import time
import logging
from flask import Flask, request, jsonify
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# Configure logging with JSON structure
# Note: For production, consider using python-json-logger or structlog
import json

class JSONFormatter(logging.Formatter):
    """Format logs as JSON for structured logging."""
    def format(self, record):
        log_data = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "message": record.getMessage(),
            "traceId": getattr(record, 'otelTraceID', ''),
            "spanId": getattr(record, 'otelSpanID', ''),
        }
        return json.dumps(log_data)

handler = logging.StreamHandler()
handler.setFormatter(JSONFormatter())
logger = logging.getLogger(__name__)
logger.addHandler(handler)
logger.setLevel(logging.INFO)

# OpenTelemetry Collector endpoint
OTEL_EXPORTER_OTLP_ENDPOINT = os.getenv(
    'OTEL_EXPORTER_OTLP_ENDPOINT',
    'otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317'
)

# Service configuration
SERVICE_NAME = os.getenv('SERVICE_NAME', 'otel-sample-app')
SERVICE_VERSION = os.getenv('SERVICE_VERSION', '1.0.0')
DEPLOYMENT_ENVIRONMENT = os.getenv('DEPLOYMENT_ENVIRONMENT', 'development')

# Configure OpenTelemetry
resource = Resource.create({
    "service.name": SERVICE_NAME,
    "service.version": SERVICE_VERSION,
    "deployment.environment": DEPLOYMENT_ENVIRONMENT,
})

# Create tracer provider
tracer_provider = TracerProvider(resource=resource)

# Configure OTLP exporter
otlp_exporter = OTLPSpanExporter(
    endpoint=OTEL_EXPORTER_OTLP_ENDPOINT,
    insecure=True
)

# Add span processor
span_processor = BatchSpanProcessor(otlp_exporter)
tracer_provider.add_span_processor(span_processor)

# Set global tracer provider
trace.set_tracer_provider(tracer_provider)

# Get tracer
tracer = trace.get_tracer(__name__)

# Create Flask app
app = Flask(__name__)

# Instrument Flask
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()


def simulate_work(duration: float, operation: str):
    """Simulate some work with a child span."""
    with tracer.start_as_current_span(f"simulate_{operation}") as span:
        span.set_attribute("operation.duration", duration)
        span.set_attribute("operation.name", operation)
        logger.info(f"Starting {operation} operation")
        time.sleep(duration)
        logger.info(f"Completed {operation} operation")
        return f"Operation '{operation}' completed in {duration}s"


@app.route('/')
def index():
    """Root endpoint with basic information."""
    return jsonify({
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "environment": DEPLOYMENT_ENVIRONMENT,
        "message": "OpenTelemetry Sample Application",
        "endpoints": {
            "/": "This help message",
            "/health": "Health check endpoint",
            "/hello/<name>": "Greeting endpoint with tracing",
            "/work": "Simulate work with nested spans",
            "/error": "Trigger an error to see error traces"
        }
    })


@app.route('/health')
def health():
    """Health check endpoint."""
    return jsonify({"status": "healthy", "service": SERVICE_NAME}), 200


@app.route('/hello/<name>')
def hello(name):
    """Greeting endpoint that demonstrates tracing."""
    with tracer.start_as_current_span("greet_user") as span:
        span.set_attribute("user.name", name)
        logger.info(f"Greeting user: {name}")
        
        # Simulate some processing
        result = simulate_work(0.1, "generate_greeting")
        
        greeting = f"Hello, {name}! Welcome to the OpenTelemetry sample application."
        span.set_attribute("greeting.message", greeting)
        
        return jsonify({
            "greeting": greeting,
            "trace_id": format(span.get_span_context().trace_id, '032x'),
            "span_id": format(span.get_span_context().span_id, '016x')
        })


@app.route('/work')
def work():
    """Endpoint that simulates complex work with nested spans."""
    with tracer.start_as_current_span("complex_work") as span:
        logger.info("Starting complex work operation")
        
        results = []
        
        # Simulate multiple operations
        with tracer.start_as_current_span("database_query"):
            simulate_work(0.15, "query_database")
            results.append("Database query completed")
        
        with tracer.start_as_current_span("external_api_call"):
            simulate_work(0.2, "call_external_api")
            results.append("External API call completed")
        
        with tracer.start_as_current_span("data_processing"):
            simulate_work(0.1, "process_data")
            results.append("Data processing completed")
        
        span.set_attribute("operations.count", len(results))
        logger.info("Complex work operation completed")
        
        return jsonify({
            "status": "success",
            "results": results,
            "trace_id": format(span.get_span_context().trace_id, '032x')
        })


@app.route('/error')
def trigger_error():
    """Endpoint that triggers an error to demonstrate error tracing."""
    with tracer.start_as_current_span("error_operation") as span:
        logger.error("Intentional error triggered for testing")
        span.set_attribute("error", True)
        span.set_attribute("error.type", "IntentionalError")
        
        # Record exception
        try:
            raise ValueError("This is an intentional error for testing traces")
        except ValueError as e:
            span.record_exception(e)
            span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
            logger.exception("Error occurred during operation")
            
            return jsonify({
                "error": "IntentionalError",
                "message": str(e),
                "trace_id": format(span.get_span_context().trace_id, '032x')
            }), 500


if __name__ == '__main__':
    logger.info(f"Starting {SERVICE_NAME} v{SERVICE_VERSION}")
    logger.info(f"OTLP Endpoint: {OTEL_EXPORTER_OTLP_ENDPOINT}")
    logger.info(f"Environment: {DEPLOYMENT_ENVIRONMENT}")
    
    # Run the Flask app
    app.run(host='0.0.0.0', port=8080, debug=False)
