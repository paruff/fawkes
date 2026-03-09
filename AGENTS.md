# Agent Instructions — Fawkes IDP

> Universal instructions for all agents: GitHub Copilot, VS Code agent mode, Claude, and all others.
> Fawkes is a polyglot platform. Read the **Language & Layer Map** before touching any file.
> **Do not modify this file without maintainer approval.**

---

## 1. What Fawkes Is

Fawkes is a modular GitOps Internal Developer Platform combining CI/CD, observability,
security, and multi-cloud provisioning. It is also a **learning platform** (belt-level dojo)
and a **DORA metrics showcase**. The development process itself must exemplify what the
platform teaches.

**Repository:** github.com/paruff/fawkes

---

## 2. The Polyglot Language & Layer Map

Read this before touching any file. Each area of the repo has a primary language and rules.

| Directory | Language | What Lives Here | Do Not |
|---|---|---|---|
| `services/` | Python (FastAPI) | Microservices, APIs, business logic | Embed shell business logic here — use `scripts/` instead |
| `infra/` | HCL (Terraform) | Cloud provisioning, IaC modules | Hardcode cloud credentials or region defaults |
| `platform/` | YAML + Helm | Kubernetes manifests, ArgoCD apps, Backstage config | Bypass Helm templating with raw manifests |
| `scripts/` | Bash / Python | Automation helpers, `ignite.sh`, dev tooling | Put business logic here — scripts call services |
| `design-system/` | CSS / JS | UI components for platform web interfaces | Mix with backend logic |
| `jenkins-shared-library/` | Groovy | Shared Jenkins pipeline steps | Put Groovy logic in `scripts/` |
| `tests/` | Python / Go | Unit, integration, BDD tests | Delete failing tests to make CI pass |
| `charts/` | Helm / YAML | Helm chart definitions | Override chart values in the chart itself |
| `docs/` | Markdown | MkDocs site (Diataxis) | Add non-Diataxis content without a category decision |
| `templates/` | YAML / Devfile | Golden path templates for Backstage | Hardcode team-specific values |
| `data/issues/` | JSON / CSV | Issue data for import | Edit manually — use scripts |

---

## 3. Context Files — Read Before Generating Any Code

| Priority | File | What You Learn |
|---|---|---|
| 1 | `AGENTS.md` (this file) | Language map, boundaries, PM contract |
| 2 | `docs/ARCHITECTURE.md` | Component relationships, allowed dependencies |
| 3 | `docs/API_SURFACE.md` | Public interfaces across services |
| 4 | `docs/KNOWN_LIMITATIONS.md` | Known issues — do not make these worse |
| 5 | `docs/CHANGE_IMPACT_MAP.md` | Which files break when a component changes |
| 6 | `.github/copilot-instructions.md` | Copilot-specific coding standards |

---

## 4. Architecture Rules — Never Violate These

### Platform Boundaries

```
services/     → Stateless Python (FastAPI) microservices. No direct infra provisioning.
infra/        → Terraform only. No application code. No shell business logic.
platform/     → Kubernetes/Helm declarative state. No imperative scripts.
scripts/      → Call services and CLI tools. Never contain business logic.
tests/        → Test the above layers. Never import from multiple layers in one test.
```

### IaC Rules (Terraform)
- All variables must have `description` fields
- No hardcoded regions, account IDs, or credentials — use variables with defaults
- Every `module` call must reference a versioned module, not a local path in production
- `terraform plan` must pass in CI before any `apply`

### Helm / Kubernetes Rules
- All environment-specific values live in values overrides, not in base `values.yaml`
- No `latest` image tags — always use digest or pinned version
- Resource limits required on every container spec
- Labels must include: `app`, `version`, `component`, `managed-by: fawkes`

### Python (FastAPI) Service Rules
> **Note:** Go is not currently used in `services/`. Go is only used in `tests/terratest/` for infrastructure tests.
- Prefer established PyPI packages over reinventing common functionality
- Type hints on all function signatures
- Errors raised with explicit exceptions and context — never silently discarded
- No global mutable state

### CI / GitHub Actions Rules
- Every job logs: start timestamp, commit SHA, finish timestamp (DORA logging)
- Secrets via `${{ secrets.NAME }}` only — never `env:` with hardcoded values
- Matrix builds for multi-platform where applicable
- Jobs must have `timeout-minutes` set

---

## 5. The PM–Agent Contract

### Agents MAY Do Without Asking
- Read any file in the repository
- Write to `services/`, `tests/`, `docs/`, `scripts/`, `design-system/`
- Run: linters, formatters, test suites, `terraform validate`, `helm lint`
- Open draft PRs, add comments, update docstrings

### Agents MUST Ask Before
- Adding any new Terraform provider or module
- Creating or modifying ArgoCD `Application` manifests
- Changing Backstage catalog descriptors
- Modifying `.github/workflows/` CI pipelines
- Adding new Helm chart dependencies
- Touching more than 5 files in one task

### Agents Must NEVER
- Commit secrets, API keys, cloud credentials, or kubeconfig content
- Modify `AGENTS.md` without maintainer instruction
- Delete tests — fix the code instead
- Push to `main` directly
- Merge their own PRs
- Apply the `large-pr-approved` label (humans only)
- Bypass pre-commit hooks by using `--no-verify`
- Use `latest` image tags in any manifest

---

## 6. Coding Standards by Language

### Go
> **Note:** Go is not currently used in `services/`. Go is only used in `tests/terratest/` for infrastructure tests.
- `gofmt` + `golangci-lint` — both must pass
- Table-driven tests in `*_test.go` files
- Error strings lowercase, no trailing punctuation
- Conventional commits: `feat(service):`, `fix(service):`, `test(service):`

### Terraform (HCL)
- `tflint` + `terraform fmt` — both must pass
- `tfsec` for security scanning (existing config in `.tflint.hcl`)
- Module outputs documented with `description`
- One resource type per file where practical

### Helm / YAML
- `helm lint` must pass
- `yamllint` must pass (config in `.yamllint`)
- `prettier` for formatting (config in `.prettierrc`)

### Python (scripts, tests)
- `ruff` + `black` — both must pass
- Type hints on new functions
- pytest for tests

### Bash
- `shellcheck` on all `.sh` files
- `set -euo pipefail` at the top of every script
- No hardcoded paths — use variables

---

## 7. PR Requirements

Every PR must include the AI-Assisted Review Block:
- What this PR does (one sentence)
- Which layer(s) are touched (services / infra / platform / scripts / docs)
- Tests added or updated
- Linters passing locally
- Any judgment calls flagged for human review
- `make lint` output: ✅ / ❌

---

## 8. Instability Safeguards

- PR size > 400 lines → CI blocks. Override requires `large-pr-approved` label from a human.
- Infrastructure changes (anything in `infra/`) require a second human reviewer
- New Helm chart versions require `helm lint` + `helm template` output in the PR
- Rework rate > 10%: stop adding features, fix instructions

---

## 9. Fawkes-Specific Principles

Because Fawkes **is** a DORA platform, its own development must model what it teaches:

1. **Deployment frequency** — prefer many small PRs over large batched ones
2. **Lead time** — every issue should be completable in < 2 days of agent work
3. **Change failure rate** — all infra changes behind `terraform plan` gate in CI
4. **MTTR** — every runbook in `docs/runbooks/` must be tested quarterly
5. **Rework rate** — tracked in `docs/METRICS.md`; checked weekly via `scripts/weekly-metrics.sh`

---

## 10. See Also

- `.github/copilot-instructions.md` — Copilot-specific subset (merged with this file at runtime)
- `.github/agents/` — specialist agent profiles
- `.github/instructions/` — path-scoped instruction files by language
- `docs/GOLDEN_PATH.md` — standard feature development workflow (also in docs site)
- `docs/PROMPT_LIBRARY.md` — tested prompt templates for every repeating task
