---
name: service-blueprint
description: New service template for Fawkes — file structure, main.py, Dockerfile. Load when creating a service.
license: MIT
compatibility: opencode
---

# New Service — Fawkes

Structure:

```
services/NAME/
  app/main.py          # FastAPI + OTEL + health endpoints
  app/routes/health.py
  requirements.txt     # pinned deps
  Dockerfile           # multi-stage, non-root
  README.md
```

main.py:

```python
from fastapi import FastAPI
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

app = FastAPI(title="NAME", version="0.1.0")
FastAPIInstrumentor.instrument_app(app)

@app.get("/health")
async def health(): return {"status": "ok", "service": "NAME"}

@app.get("/ready")
async def ready(): return {"status": "READY"}
```

Dockerfile:

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim AS runtime
RUN useradd -r appuser
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY app/ ./app/
USER appuser
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

After creating: add to `docs/API_SURFACE.md`.
