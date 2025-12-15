# OpenTelemetry Sample Application

A simple Python Flask application instrumented with OpenTelemetry to demonstrate distributed tracing.

## Features

- **Automatic Instrumentation**: Flask and Requests libraries are automatically instrumented
- **Distributed Tracing**: Sends traces to OpenTelemetry Collector via OTLP gRPC
- **Structured Logging**: Logs include trace and span IDs for correlation
- **Multiple Endpoints**: Demonstrates different tracing scenarios

## Endpoints

- `GET /` - Service information
- `GET /health` - Health check
- `GET /hello/<name>` - Simple greeting with tracing
- `GET /work` - Complex operation with nested spans
- `GET /error` - Intentional error to demonstrate error tracing

## Configuration

Environment variables:

- `OTEL_EXPORTER_OTLP_ENDPOINT` - OpenTelemetry Collector endpoint (default: `otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317`)
- `SERVICE_NAME` - Service name for traces (default: `otel-sample-app`)
- `SERVICE_VERSION` - Service version (default: `1.0.0`)
- `DEPLOYMENT_ENVIRONMENT` - Deployment environment (default: `development`)

## Building

```bash
docker build -t otel-sample-app:latest .
```

## Running Locally

```bash
pip install -r requirements.txt
export OTEL_EXPORTER_OTLP_ENDPOINT=localhost:4317
python app.py
```

## Deploying to Kubernetes

```bash
kubectl apply -f deployment.yaml
```

## Testing

Generate some traces:

```bash
# Simple greeting
curl http://otel-sample-app:8080/hello/World

# Complex work with nested spans
curl http://otel-sample-app:8080/work

# Error trace
curl http://otel-sample-app:8080/error
```

## Viewing Traces

Traces can be viewed in:
- Grafana Tempo (via Grafana UI)
- Directly via Tempo API

Example Grafana query:
```
{service.name="otel-sample-app"}
```
