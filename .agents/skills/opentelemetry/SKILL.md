---
name: opentelemetry
description: OTEL integration for Fawkes — Python packages, FastAPI instrumentor, gen_ai spans, metric naming. Load when instrumenting services.
license: MIT
compatibility: opencode
---

# OTEL — Fawkes

Add to `requirements.txt`:

```
opentelemetry-sdk>=1.20.0
opentelemetry-instrumentation-fastapi>=0.41b0
```

FastAPI auto-instrument:

```python
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
app = FastAPI()
FastAPIInstrumentor.instrument_app(app)
```

Custom span:

```python
from opentelemetry import trace
tracer = trace.get_tracer(__name__)
with tracer.start_as_current_span("operation") as span:
    span.set_attribute("key", value)
```

gen_ai.\* attributes: `gen_ai.operation.name`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`

Metric naming: `<service>_<noun>_total` (counter), `<service>_<noun>_seconds` (histogram)

Collector config: `platform/apps/opentelemetry/collector.yaml`

Validate:

```bash
cd services/SVC && python -c "from opentelemetry import trace; print('OK')"
python -c "import yaml; yaml.safe_load(open('platform/apps/opentelemetry/collector.yaml'))"
```
