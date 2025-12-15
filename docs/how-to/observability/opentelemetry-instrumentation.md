# OpenTelemetry Instrumentation Guide

This guide shows how to instrument your applications to send traces to the Fawkes OpenTelemetry Collector.

## Overview

The OpenTelemetry Collector is deployed as a DaemonSet and accepts traces via OTLP (OpenTelemetry Protocol) on:
- **gRPC**: `otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317`
- **HTTP**: `otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4318`

## Quick Start by Language

### Python

#### Install Dependencies
```bash
pip install opentelemetry-api \
            opentelemetry-sdk \
            opentelemetry-exporter-otlp-proto-grpc \
            opentelemetry-instrumentation-flask  # or your framework
```

#### Basic Setup
```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configure resource
resource = Resource.create({
    "service.name": "my-service",
    "service.version": "1.0.0",
    "deployment.environment": "production",
})

# Create tracer provider
tracer_provider = TracerProvider(resource=resource)

# Configure OTLP exporter
otlp_exporter = OTLPSpanExporter(
    endpoint="otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317",
    insecure=True
)

# Add span processor
span_processor = BatchSpanProcessor(otlp_exporter)
tracer_provider.add_span_processor(span_processor)

# Set global tracer provider
trace.set_tracer_provider(tracer_provider)

# Get tracer
tracer = trace.get_tracer(__name__)
```

#### Flask Auto-Instrumentation
```python
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from flask import Flask

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
```

### Go

#### Install Dependencies
```bash
go get go.opentelemetry.io/otel
go get go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc
go get go.opentelemetry.io/otel/sdk/trace
```

#### Basic Setup
```go
package main

import (
    "context"
    "log"
    
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
)

func initTracer() (*sdktrace.TracerProvider, error) {
    ctx := context.Background()

    // Create OTLP exporter
    exporter, err := otlptracegrpc.New(ctx,
        otlptracegrpc.WithEndpoint("otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317"),
        otlptracegrpc.WithDialOption(grpc.WithTransportCredentials(insecure.NewCredentials())),
    )
    if err != nil {
        return nil, err
    }

    // Create resource
    res, err := resource.New(ctx,
        resource.WithAttributes(
            semconv.ServiceName("my-service"),
            semconv.ServiceVersion("1.0.0"),
            semconv.DeploymentEnvironment("production"),
        ),
    )
    if err != nil {
        return nil, err
    }

    // Create tracer provider
    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exporter),
        sdktrace.WithResource(res),
    )

    otel.SetTracerProvider(tp)
    return tp, nil
}
```

### Node.js

#### Install Dependencies
```bash
npm install @opentelemetry/api \
            @opentelemetry/sdk-node \
            @opentelemetry/auto-instrumentations-node \
            @opentelemetry/exporter-trace-otlp-grpc
```

#### Basic Setup
```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'my-service',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: 'production',
  }),
  traceExporter: new OTLPTraceExporter({
    url: 'grpc://otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317',
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();

// Graceful shutdown
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('Tracing terminated'))
    .catch((error) => console.log('Error terminating tracing', error))
    .finally(() => process.exit(0));
});
```

### Java

#### Add Dependencies (Maven)
```xml
<dependencies>
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-api</artifactId>
        <version>1.32.0</version>
    </dependency>
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-sdk</artifactId>
        <version>1.32.0</version>
    </dependency>
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-exporter-otlp</artifactId>
        <version>1.32.0</version>
    </dependency>
</dependencies>
```

#### Basic Setup
```java
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.resources.Resource;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;
import io.opentelemetry.semconv.resource.attributes.ResourceAttributes;

public class TracingConfig {
    public static OpenTelemetry initOpenTelemetry() {
        // Create OTLP exporter
        OtlpGrpcSpanExporter spanExporter = OtlpGrpcSpanExporter.builder()
            .setEndpoint("http://otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317")
            .build();

        // Create resource
        Resource resource = Resource.getDefault()
            .merge(Resource.create(Attributes.of(
                ResourceAttributes.SERVICE_NAME, "my-service",
                ResourceAttributes.SERVICE_VERSION, "1.0.0",
                ResourceAttributes.DEPLOYMENT_ENVIRONMENT, "production"
            )));

        // Create tracer provider
        SdkTracerProvider tracerProvider = SdkTracerProvider.builder()
            .addSpanProcessor(BatchSpanProcessor.builder(spanExporter).build())
            .setResource(resource)
            .build();

        return OpenTelemetrySdk.builder()
            .setTracerProvider(tracerProvider)
            .build();
    }
}
```

## Environment Variables

Instead of hardcoding the endpoint, use environment variables:

```yaml
env:
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: "otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317"
- name: OTEL_SERVICE_NAME
  value: "my-service"
- name: OTEL_RESOURCE_ATTRIBUTES
  value: "service.version=1.0.0,deployment.environment=production"
```

Most SDKs automatically read these environment variables.

## Kubernetes Deployment

Add the following to your Pod spec for automatic Kubernetes metadata enrichment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
spec:
  template:
    metadata:
      labels:
        app: my-service
        version: "1.0.0"
    spec:
      containers:
      - name: app
        image: my-service:latest
        env:
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317"
        - name: OTEL_SERVICE_NAME
          value: "my-service"
        - name: OTEL_RESOURCE_ATTRIBUTES
          value: "service.version=1.0.0,deployment.environment=production"
```

The OpenTelemetry Collector will automatically add:
- `k8s.namespace.name`
- `k8s.pod.name`
- `k8s.deployment.name`
- `k8s.container.name`
- And more...

## Structured Logging with Trace Correlation

### Python
```python
import logging
from opentelemetry import trace

# Configure structured logging
logging.basicConfig(
    format='{"timestamp":"%(asctime)s","level":"%(levelname)s","message":"%(message)s","traceId":"%(otelTraceID)s","spanId":"%(otelSpanID)s"}'
)

# In your code
span = trace.get_current_span()
logger.info(
    "User login successful",
    extra={
        "otelTraceID": format(span.get_span_context().trace_id, '032x'),
        "otelSpanID": format(span.get_span_context().span_id, '016x'),
        "userId": user_id
    }
)
```

## Custom Spans

### Creating Manual Spans
```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("database_query") as span:
    span.set_attribute("db.system", "postgresql")
    span.set_attribute("db.statement", "SELECT * FROM users WHERE id = ?")
    
    # Your code here
    result = execute_query()
    
    span.set_attribute("db.rows_returned", len(result))
```

### Adding Events and Exceptions
```python
try:
    result = risky_operation()
    span.add_event("operation_completed", {"result_count": len(result)})
except Exception as e:
    span.record_exception(e)
    span.set_status(trace.Status(trace.StatusCode.ERROR))
    raise
```

## Viewing Traces

### In Grafana
1. Navigate to Grafana: `http://grafana.127.0.0.1.nip.io`
2. Go to **Explore** → Select **Tempo** datasource
3. Search by:
   - Service name: `{service.name="my-service"}`
   - Operation: `{span.name="database_query"}`
   - Status: `{status=error}`
   - Time range and filters

### Common Queries
```
# All traces from a service
{service.name="my-service"}

# Slow traces (> 1 second)
{service.name="my-service" && duration > 1s}

# Error traces
{service.name="my-service" && status=error}

# Traces for specific operation
{service.name="my-service" && span.name="checkout"}
```

## Best Practices

1. **Use Semantic Conventions**: Follow [OpenTelemetry Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/) for attribute names
2. **Add Context**: Include relevant business context (user ID, transaction ID, etc.)
3. **Sample Strategically**: Use head-based or tail-based sampling to control data volume
4. **Correlate Logs**: Include trace and span IDs in log messages
5. **Monitor Costs**: Be mindful of trace volume, especially in high-traffic services
6. **Error Reporting**: Always record exceptions in spans
7. **Resource Attributes**: Set service name, version, and environment consistently

## Troubleshooting

### Traces Not Appearing

1. Check collector is running:
   ```bash
   kubectl get pods -n monitoring -l app.kubernetes.io/name=opentelemetry-collector
   ```

2. Check application logs for OTLP errors

3. Verify endpoint connectivity:
   ```bash
   kubectl exec -it <your-pod> -- nc -zv otel-collector-opentelemetry-collector.monitoring.svc.cluster.local 4317
   ```

4. Check collector logs:
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector --tail=100
   ```

### High Latency

If adding tracing increases latency:
- Use batch exporters (default in most SDKs)
- Adjust sampling rate
- Check network connectivity to collector

## Examples

See the complete sample application at:
`platform/apps/opentelemetry/sample-app/`

This includes:
- Full Flask application with tracing
- Nested span examples
- Error handling
- Structured logging
- Kubernetes deployment manifests

## References

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [OpenTelemetry Python](https://opentelemetry.io/docs/instrumentation/python/)
- [OpenTelemetry Go](https://opentelemetry.io/docs/instrumentation/go/)
- [OpenTelemetry Node.js](https://opentelemetry.io/docs/instrumentation/js/)
- [OpenTelemetry Java](https://opentelemetry.io/docs/instrumentation/java/)
- [Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/)
