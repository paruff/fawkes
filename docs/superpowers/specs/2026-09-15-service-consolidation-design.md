# Service Consolidation Design: 17 Microservices → 2 Domain Monoliths

**Date:** 2026-09-15
**Status:** Approved
**Tracking:** P1 sprint — EXECUTION_QUEUE.md

---

## Context

The `services/` directory contains 17+ microservices, most of which are FastAPI apps on port 8000. They share no common libraries, duplicate middleware/config patterns, and each runs as a separate pod. The goal is to consolidate into 2 domain monoliths to:
- Reduce cluster resource footprint by ~70%
- Eliminate duplicated code (auth, middleware, config, models)
- Simplify local development and deployment
- Maintain the same API contracts

## Current State

| Domain | Services | Total Lines |
|--------|----------|-------------|
| Telemetry | vsm, analytics-dashboard, anomaly-detection, smart-alerting, discovery-metrics, space-metrics | ~9,200 |
| DevEx | feedback, feedback-bot, nps, devex-survey-automation, insights, experimentation | ~11,500 |
| Standalone | ai-code-review, friction-bot, friction-cli, feedback-cli, mcp-k8s-server | ~4,600 |

All services are FastAPI, port 8000, use `httpx` for inter-service calls, and follow the `app/main.py` → `app.{module}.py` pattern.

## Design

### Phase A: `services/common/` Shared Library

Create `services/common/` as an installable Python package providing:

- **`common/config.py`** — Base settings class (pydantic-settings pattern used across all services)
- **`common/middleware.py`** — CORS, request logging, error handling middleware
- **`common/models.py`** — Shared Pydantic models (health check response, error response, pagination)
- **`common/health.py`** — Standardized health check endpoint
- **`common/otel.py`** — OpenTelemetry FastAPI instrumentor setup
- **`pyproject.toml`** — Package definition, installed as `-e ../common` in each monolith

### Phase B: `fawkes-telemetry-engine`

Structure:
```
services/fawkes-telemetry-engine/
├── pyproject.toml
├── Dockerfile
├── app/
│   ├── main.py              # FastAPI app, mounts all routers
│   ├── config.py            # Telemetry-specific settings
│   ├── vsm/                 # From services/vsm/
│   │   ├── __init__.py
│   │   ├── router.py        # APIRouter prefix="/api/v1/vsm"
│   │   └── ...existing modules
│   ├── analytics/           # From services/analytics-dashboard/
│   │   ├── router.py        # APIRouter prefix="/api/v1/analytics"
│   │   └── ...
│   ├── anomaly/             # From services/anomaly-detection/
│   │   ├── router.py        # APIRouter prefix="/api/v1/anomaly"
│   │   └── ...
│   ├── alerting/            # From services/smart-alerting/
│   │   ├── router.py        # APIRouter prefix="/api/v1/alerting"
│   │   └── ...
│   ├── discovery/           # From services/discovery-metrics/
│   │   ├── router.py        # APIRouter prefix="/api/v1/discovery"
│   │   └── ...
│   └── space/               # From services/space-metrics/
│       ├── router.py        # APIRouter prefix="/api/v1/space"
│       └── ...
└── tests/
    ├── test_health.py
    └── ...
```

Each sub-module's existing API routes become `APIRouter` endpoints mounted under a domain prefix. Inter-service HTTP calls within the telemetry domain become direct Python imports.

### Phase C: `fawkes-devex-service`

Same pattern as Phase B, with sub-modules:
- `feedback/` ← services/feedback + services/feedback-bot
- `nps/` ← services/nps
- `surveys/` ← services/devex-survey-automation
- `insights/` ← services/insights
- `experimentation/` ← services/experimentation

### Phase D: Standalone Services

| Service | Decision | Rationale |
|---------|----------|-----------|
| ai-code-review | Keep separate | Different lifecycle (AI/LLM dependencies), larger footprint |
| friction-bot | Absorb into devex | Shares domain with feedback/insights |
| friction-cli | Keep separate | CLI tool, not a service |
| feedback-cli | Keep separate | CLI tool, not a service |
| mcp-k8s-server | Keep separate | MCP protocol server, different lifecycle |

### Phase E: Backstage + K8s

- Update `services/location.yaml` to reference 2 monoliths + retained standalones
- Create new `catalog-info.yaml` for each monolith
- Create Helm values overrides for `fawkes-telemetry-engine` and `fawkes-devex-service`

### Phase F: Cleanup

- Delete old service directories after consolidation is verified
- Update any cross-references in docs, CI, scripts

### Phase G: Integration Tests

- `tests/integration/test_telemetry_engine.py` — health, each sub-module's key endpoints
- `tests/integration/test_devex_service.py` — health, each sub-module's key endpoints
- Verify no regression in API contracts

## API Contract Preservation

Each service's existing endpoints are preserved under the same paths. The only change is the base URL shifts from `http://{service-name}:8000` to `http://{monolith}:8000/api/v1/{domain}/...`. Since these are internal services (not public API), and the K8s service names will be updated in manifests, this is acceptable.

## Testing Strategy

- TDD for each sub-module router migration (write test for existing endpoint, verify it works pre-migration, migrate, verify test still passes)
- Integration tests for cross-module dependencies
- Pre-commit hooks for linting/formatting

## Risks

- **Breaking internal HTTP calls**: Mitigated by preserving API paths and updating K8s service names
- **Large PR size**: Breaking into phases A–G keeps each PR under 400 lines
- **Shared state**: No global mutable state exists in current services; each uses dependency injection
