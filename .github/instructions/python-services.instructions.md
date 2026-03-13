---
name: Python Services Instructions
description: Applied automatically when working in services/
applyTo: "services/**/*.py"
---

# Python Services Instructions — Fawkes

## Read First

Before writing any code:
- `AGENTS.md` → Language & Layer Map, Python FastAPI Service Rules, DORA 2025 AI Capabilities
- `docs/ARCHITECTURE.md` → service boundary rules, allowed dependencies
- `docs/API_SURFACE.md` → existing service interfaces (don't duplicate)
- `docs/CHANGE_IMPACT_MAP.md` → which other services break when this one changes

## DORA 2025: Read → Run → Review

All AI-generated Python code in `services/` follows this mandatory sequence:

1. **Read** the existing module completely before modifying it — never invent function names, imports, or class hierarchies.
2. **Run** `pytest` and confirm all tests pass before opening a PR. Writing files without running them is not done.
3. **Review** — any change touching auth, RBAC, data validation, or secret handling requires a human approval step.
4. **Declare** in the PR description which sections were AI-generated.

## Service Structure

Every `services/{name}/` follows:

```
services/{service-name}/
  app/
    __init__.py
    main.py          → FastAPI app factory, router registration
    routes/          → one file per feature domain
    models/          → Pydantic request/response models
    services/        → business logic, no FastAPI imports here
    dependencies/    → FastAPI dependency injection providers
  tests/             → service-specific tests (if not in tests/)
  requirements.txt   → pinned production dependencies
  requirements-dev.txt → linting and test tools
  Dockerfile         → multi-stage, non-root user
  pytest.ini         → test configuration
  README.md          → service-level documentation
```

## FastAPI Patterns

### Route Definition

```python
from fastapi import APIRouter, HTTPException, Depends
from app.models.my_model import MyRequest, MyResponse
from app.services.my_service import process_request

router = APIRouter()


@router.post("/my-endpoint", response_model=MyResponse, status_code=200)
async def my_endpoint(request: MyRequest) -> MyResponse:
    """Process a request and return the result.

    Args:
        request: Validated input from the caller.

    Returns:
        MyResponse with the computed result.

    Raises:
        HTTPException: 422 on invalid business logic, 500 on unexpected errors.
    """
    try:
        result = await process_request(request.field)
        return MyResponse(result=result)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Internal error") from exc
```

### Pydantic Models

```python
from pydantic import BaseModel, Field


class MyRequest(BaseModel):
    field: str = Field(..., min_length=1, description="Non-empty input value")
    count: int = Field(default=1, ge=1, le=100, description="Repetition count")


class MyResponse(BaseModel):
    result: str
    processed_at: str  # ISO 8601 timestamp
```

### Dependency Injection

```python
# ✅ Use FastAPI DI for shared resources
from collections.abc import AsyncGenerator
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession  # or your ORM of choice


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    async with SessionLocal() as session:
        yield session


@router.get("/items", response_model=list[ItemResponse])
async def list_items(session: AsyncSession = Depends(get_db_session)) -> list[ItemResponse]:
    ...


# ❌ Never use global mutable state — module-level singletons are forbidden
# db_session = SessionLocal()  # wrong: shared across requests, not thread-safe
```

## Type Hints and Docstrings

Type hints are required on **all** function signatures. Docstrings are required on
all public functions and classes.

```python
# ✅ Correct
async def calculate_lead_time(
    commit_time: datetime,
    deploy_time: datetime,
) -> timedelta:
    """Calculate the lead time from commit to deployment.

    Args:
        commit_time: UTC timestamp when the commit was created.
        deploy_time: UTC timestamp when the deployment completed.

    Returns:
        The duration between commit and deploy.

    Raises:
        ValueError: If deploy_time is before commit_time.
    """
    if deploy_time < commit_time:
        raise ValueError(
            f"deploy_time ({deploy_time}) must be >= commit_time ({commit_time})"
        )
    return deploy_time - commit_time


# ❌ Never — no type hints, no docstring
def calculate_lead_time(commit_time, deploy_time):
    return deploy_time - commit_time
```

## Error Handling

```python
# ✅ Raise specific exceptions with context
def parse_metric(raw: str) -> float:
    try:
        return float(raw)
    except ValueError as exc:
        raise ValueError(f"parse_metric: '{raw}' is not a valid float") from exc

# ❌ Never silently discard errors
def parse_metric(raw: str) -> float:
    try:
        return float(raw)
    except Exception:
        return 0.0  # hides bugs

# ❌ Never use bare except
try:
    do_something()
except:  # catches KeyboardInterrupt, SystemExit — never do this
    pass
```

## No Global Mutable State

```python
# ❌ Never
_cache: dict[str, Any] = {}

def get_cached(key: str) -> Any:
    return _cache.get(key)

# ✅ Use dependency injection or class-scoped state
class MetricsCache:
    def __init__(self) -> None:
        self._data: dict[str, Any] = {}

    def get(self, key: str) -> Any:
        return self._data.get(key)
```

## Observability

Every service must be observable. The DORA 2025 report identifies observability as a
direct predictor of elite delivery performance.

```python
from opentelemetry import trace
from opentelemetry.trace import Span

tracer = trace.get_tracer(__name__)

async def process_request(request_id: str) -> str:
    with tracer.start_as_current_span("process_request") as span:
        span.set_attribute("request.id", request_id)
        span.set_attribute("service.name", "my-service")
        try:
            result = await _do_work(request_id)
            span.set_attribute("result.status", "success")
            return result
        except Exception as exc:
            span.record_exception(exc)
            span.set_attribute("result.status", "error")
            raise
```

Structured logging rules:
- Use `structlog` (or the project's `services/shared/logging.py` if available)
- Every log line must include `service`, `request_id`, and `level`
- Never use bare `print()` for logs
- Exceptions must be logged with `exc_info=True`

## AI-Readiness Checklist

A module is AI-ready when agents can work on it reliably. If gaps exist, open a
tracking issue rather than silently skipping them.

- [ ] Type hints on all public functions and methods
- [ ] Docstrings on all public classes and functions (Google style)
- [ ] Tests exist and are green before adding new ones
- [ ] Module is single-purpose (< 200 lines, one responsibility)
- [ ] Clear, contextual error messages — no bare `raise Exception("error")`
- [ ] Covered by at least one BDD scenario in `tests/bdd/features/`

## Linters That Must Pass

```bash
ruff check services/{name}/           # import ordering, style, common bugs
black --check services/{name}/        # formatting
mypy services/{name}/ --ignore-missing-imports  # type checking
```

Run all three before every commit. CI will reject PRs where any linter fails.

## Testing Requirements

- **Minimum 80% line coverage** on changed modules: `pytest --cov=services/{name} --cov-report=term-missing`
- Every new route must have at minimum: happy path, invalid input (422), and server error (500) tests
- Use `fastapi.testclient.TestClient` — never call a live service in unit tests
- Mock all external dependencies (databases, Prometheus, external APIs)

```python
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_my_endpoint_returns_200() -> None:
    response = client.post("/my-endpoint", json={"field": "value"})
    assert response.status_code == 200


def test_my_endpoint_returns_422_on_empty_field() -> None:
    response = client.post("/my-endpoint", json={"field": ""})
    assert response.status_code == 422
```

## DORA 2025 Foundations Applied to Python Services

| Foundation | How it applies here |
|---|---|
| **Healthy data ecosystem** | Type hints + docstrings make every function AI-consumable without reading its implementation |
| **Working in small batches** | One route, one model, or one service function per PR — never batch unrelated changes |
| **Quality internal platforms** | `ruff` + `black` + `mypy` in CI catch regressions before review; fix linter config, not the lint |
| **User-centric focus** | Route names and error messages written from the caller's perspective, not the implementer's |
| **Strong version control** | Conventional commits: `feat(service-name):`, `fix(service-name):`, `test(service-name):` |

## What Requires Human Approval

- Adding a new PyPI dependency to `requirements.txt`
- New inter-service HTTP contracts (adding or removing endpoints)
- Changes to authentication, RBAC, or secret handling logic
- Modifying Dockerfile base image or security context
- Any change to `services/shared/` modules used by multiple services
