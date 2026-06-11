---
name: lang-python
description: "Python toolchain: ruff, mypy, pytest, pytest-cov, uv/pip. CI gate commands, file layout, pyproject.toml config. Use when working on a Python project."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Language — Python

> **Load trigger:** `"load lang-python skill"`
> **Stack:** Python 3.11+, ruff, mypy, pytest, pytest-cov, uv or pip
> **Token cost:** Low

## Toolchain Reference

| Gate      | Tool       | Command                                      | Config file                                |
| --------- | ---------- | -------------------------------------------- | ------------------------------------------ |
| Lint      | ruff       | `ruff check .`                               | `pyproject.toml [tool.ruff]`               |
| Format    | ruff       | `ruff format .`                              | `pyproject.toml [tool.ruff.format]`        |
| Typecheck | mypy       | `mypy src/`                                  | `pyproject.toml [tool.mypy]`               |
| Test      | pytest     | `pytest`                                     | `pyproject.toml [tool.pytest.ini_options]` |
| Coverage  | pytest-cov | `pytest --cov=src --cov-report=term-missing` | `.coveragerc`                              |
| Preflight | shell      | `./scripts/preflight.sh`                     | `scripts/preflight.sh`                     |

## File Layout Convention

```
src/
  [package_name]/
    __init__.py
    services/           ← business logic
    utils/              ← pure functions
    models/             ← data models (Pydantic or dataclasses)
    api/                ← HTTP handlers / FastAPI routers
tests/
  test_services/        ← mirrors src/services/
  test_utils/           ← mirrors src/utils/
  conftest.py           ← shared fixtures
pyproject.toml          ← all tool config here (not setup.py)
```

## CI Gate Commands (ci-quality.yml)

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: "3.11"

- name: Install dependencies
  run: pip install -e ".[dev]"

- name: Lint
  run: ruff check .

- name: Typecheck
  run: mypy src/

- name: Test with coverage
  run: pytest --cov=src --cov-fail-under=80 --cov-report=xml
```

## Type Standards

- All public function signatures fully annotated
- Use `from __future__ import annotations` for forward references
- Prefer `TypeAlias` over bare assignments for complex types
- Pydantic v2 for data validation at service boundaries
- No `# type: ignore` without an inline comment explaining why

## pyproject.toml Minimum Config

```toml
[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B"]

[tool.mypy]
strict = true
python_version = "3.11"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--strict-markers"

[tool.coverage.run]
source = ["src"]
omit = ["tests/*"]
```

## OTEL SDK (for obs-agent)

```bash
pip install opentelemetry-sdk opentelemetry-exporter-otlp-proto-http
```

Init pattern: call `configure_otel()` at application entry point before importing
service modules. Read `OTEL_SERVICE_NAME` and `OTEL_EXPORTER_OTLP_ENDPOINT` from env.

## fawkes Repo Context

paruff/fawkes uses Python extensively (43.5% of codebase). Primary patterns:

- FastAPI for HTTP services
- Pydantic v2 for models
- pytest with conftest fixtures
- `.flake8` and `.coveragerc` exist in root (legacy — ruff supersedes flake8)
