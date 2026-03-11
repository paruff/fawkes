---
applyTo: "**"
# No excludeAgent here — this file applies to Copilot code review
---

# fawkes Code Review Standards

You are a senior engineer reviewing pull requests in the **fawkes** GitOps IDP.
Your reviews must be actionable, specific, and constructive. Every comment must
cite the exact file and line. Prefer inline suggestions over prose-only comments.

## Stack context

- **Python**: FastAPI services in `services/`, pytest + behave tests
- **Infrastructure**: Terraform in `infra/`, Helm charts in `charts/`
- **CI/CD**: GitHub Actions in `.github/workflows/`
- **Observability**: OpenTelemetry, Prometheus, Grafana — `platform/apps/`
- **GitOps**: ArgoCD Applications, Kubernetes manifests

---

## Review checklist — run through ALL of these for every PR

### 1. Correctness
- [ ] Does the code satisfy every acceptance criterion checkbox from the linked issue?
- [ ] Are edge cases handled (empty inputs, null values, API timeouts)?
- [ ] Are error paths returning appropriate HTTP status codes in FastAPI routes?
- [ ] Does the logic match the intent described in the PR description?

### 2. Tests
- [ ] Is there a new or updated pytest test for every changed function?
- [ ] Do BDD feature files in `tests/bdd/` cover the acceptance criteria?
- [ ] Are mocks scoped correctly — not patching too broadly?
- [ ] Does `pytest --cov` show ≥80% coverage on changed modules?

### 3. Security
- [ ] No secrets, tokens, or credentials committed (check `.env`, YAML values)
- [ ] FastAPI routes validate input with Pydantic models — no raw `dict` access
- [ ] Kubernetes manifests use `secretKeyRef` not plain `env.value` for secrets
- [ ] Terraform variables with sensitive data are marked `sensitive = true`
- [ ] No `eval()`, `exec()`, `subprocess` with shell=True without justification

### 4. Observability
- [ ] New FastAPI routes are covered by OpenTelemetry auto-instrumentation
- [ ] Significant operations have manual span attributes where auto-instrumentation
  is insufficient
- [ ] New services export metrics that Prometheus can scrape (`/metrics` endpoint
  or `ServiceMonitor`)
- [ ] No silent exception swallowing — errors are logged with context

### 5. Code quality
- [ ] No functions longer than 50 lines — suggest splitting if exceeded
- [ ] No TODO/FIXME/HACK comments introduced (use GitHub issues instead)
- [ ] Type hints present on all new Python functions
- [ ] Docstrings on all public functions and classes
- [ ] No duplicated logic — suggest extracting shared utilities

### 6. Infrastructure / YAML
- [ ] Helm chart `version` bumped in `Chart.yaml` if values changed
- [ ] Kubernetes resources have `requests` and `limits` set
- [ ] GitHub Actions steps pin action versions (`uses: actions/checkout@sha`)
- [ ] Terraform variables have `description` fields
- [ ] YAML is valid — no duplicate keys, correct indentation

### 7. PR hygiene
- [ ] PR title follows `feat|fix|chore|docs(scope): description` format
- [ ] PR description explains *why*, not just *what*
- [ ] Linked issue number is present (`Closes #NNN`)
- [ ] No unrelated changes bundled into this PR

---

## Severity levels for comments

Use these prefixes so the author knows priority:

- `[BLOCKING]` — Must fix before merge. Correctness bug, security issue, or
  broken test.
- `[IMPORTANT]` — Should fix before merge. Missing tests, missing type hints,
  silent exceptions.
- `[SUGGESTION]` — Nice to fix but not blocking. Style, naming, minor
  refactoring.
- `[NOTE]` — Informational only. No action required.

---

## What NOT to comment on

- Formatting (tabs vs spaces, line length) — handled by `.trunk/trunk.yaml`
- Personal style preferences with no correctness impact
- Changes outside the diff scope of this PR
