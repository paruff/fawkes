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


## Section 10 — Model Selection Policy

Fawkes is a polyglot GitOps IDP. All services in `services/` are **Python (FastAPI)**.
Infrastructure is **HCL + YAML**. CI/CD is **Groovy (Jenkins Shared Library)**.
Read this section before selecting a model for any task.

> **Budget context:** This repo runs on Copilot Pro (300 premium requests/month).
> GPT-4.1 has a multiplier of 0 — it is completely free and should be the default
> for all tasks unless a higher tier is explicitly justified in the table below.
> The coding agent uses exactly 1 premium request per session × the model multiplier.

### Model Ladder

| Level | Model | Multiplier | Rule |
|---|---|---|---|
| L0 — Free default | GPT-4.1 | 0 | Use for ALL tasks unless a higher level is explicitly listed below |
| L0 — Free lightweight | GPT-5 mini | 0 | Single-file mechanical edits only: .gitignore, version strings, one-line Markdown |
| L1 — IDE chat upgrade | Claude Haiku 4.5 | 0.33 | Interactive IDE chat sessions only — NOT for coding agent tasks |
| L2 — Justified premium | GPT-5.1-Codex | 1 | Only the three task types listed below; requires label `model:gpt-5.1-codex` on issue |
| PROHIBITED | Claude Opus 4.6 fast | 30 | Never use — 30× multiplier. Blocked without explicit written budget approval |
| AVOID | Claude Opus 4.5 / 4.6 | 3 | Do not use unless a 1× model has failed the same task type 3+ times |
| SKIP | Gemini 3 Flash | 0.33 | No advantage over GPT-4.1 (free) for any fawkes task type |

### Task → Model Routing Table

| Task type | Model | Cost | Notes |
|---|---|---|---|
| Python single-file bug fix | GPT-4.1 | 0 | |
| Python multi-file refactor | GPT-4.1 | 0 | |
| FastAPI unit tests (TestClient) | GPT-4.1 | 0 | Do not use mocking except for DB connections |
| Fix NameError / import order | GPT-5 mini | 0 | Mechanical single-line fix |
| Update .gitignore | GPT-5 mini | 0 | |
| Update AGENTS.md or copilot-instructions.md | GPT-5 mini | 0 | |
| Write or update any Markdown doc | GPT-5 mini | 0 | Provide output file path in issue |
| Write docs/ARCHITECTURE.md | GPT-4.1 | 0 | Needs full repo context |
| Write docs/API_SURFACE.md | GPT-4.1 | 0 | Must read all FastAPI route definitions first |
| Write runbooks or troubleshooting docs | GPT-5 mini | 0 | Provide template and kubectl/LogQL commands in issue body |
| GitHub Actions YAML edit (any workflow) | GPT-4.1 | 0 | |
| Remove continue-on-error from CI | GPT-5 mini | 0 | Mechanical find-and-replace |
| Add DORA timestamps to workflows | GPT-4.1 | 0 | Must apply consistently across all 13 affected files |
| Add timeout-minutes to workflows | GPT-5 mini | 0 | Single-line addition per job |
| Terraform single module edit | GPT-4.1 | 0 | |
| Terraform multi-module refactor | GPT-4.1 | 0 | Add human review requirement to PR |
| Terraform remote state backend | GPT-4.1 | 0 | Requires 2 human approvals before merge |
| Terraform validation / Terratest (Go) | GPT-4.1 | 0 | Specify bats-core not legacy bats |
| Kubernetes manifest standardisation | GPT-4.1 | 0 | Provide services/samples/sample-python-app/k8s/deployment.yaml as reference |
| Kustomize overlay (single service PoC) | GPT-4.1 | 0 | Scope to ONE service only; fleet rollout is a separate issue |
| Bash script refactoring (ignite.sh) | GPT-4.1 | 0 | Provide target file list in issue; do not change CLI interface |
| BATS test framework setup | GPT-4.1 | 0 | Use bats-core not legacy bats package |
| ADR authoring | GPT-4.1 | 0 | |
| Pre-commit config (.pre-commit-config.yaml) | GPT-4.1 | 0 | Specify all languages: Python, HCL, YAML, Groovy |
| score.yaml for golden path templates | GPT-5 mini | 0 | Provide existing score.yaml as reference in issue |
| BDD step definitions (Python behave) | GPT-4.1 | 0 | Provide .feature file content in issue body |
| Structured logging rollout (structlog) | GPT-4.1 | 0 | Add services/shared/logging.py as shared module first |
| PromQL recording rules or alert rules | GPT-5.1-Codex | 1 | Free models produce vector() arithmetic errors; justify with label `model:gpt-5.1-codex` |
| OTEL AI/LLM pipeline (gen_ai.* spans) | GPT-5.1-Codex | 1 | Risk of breaking existing pipelines; free models miss guard clauses |
| Grafana dashboard JSON | GPT-5.1-Codex | 1 | Structured multi-panel JSON requires coherence that free models lose |
| Interactive IDE chat (in VS Code) | Claude Haiku 4.5 | 0.33 | Chat only — do not assign agent tasks to Haiku |
| Git history rewrite (BFG) | Human | N/A | Requires coordinated force-push — cannot be delegated to any agent |
| Sprint retrospective | Human | N/A | Requires genuine reflection — AI output is not acceptable here |
| Security incident response | Human | N/A | Never delegate to any agent |

### Required issue body format

Every issue assigned to the Copilot coding agent must include this block:

```
**Suggested model:** [GPT-4.1 / GPT-5 mini / GPT-5.1-Codex]
**Task type:** [single-file bug / multi-file refactor / docs / YAML / structured JSON / test]
**Files to edit:** [explicit list — agent must not create new files unless listed here]
**Reference file:** [path to canonical example, if applicable]
**Do not:** [specific anti-patterns or files to avoid]
**Acceptance criteria:**
- [ ] [measurable criterion 1]
- [ ] [measurable criterion 2]
```

### Escalation rule

If rework rate for a task type exceeds 20% after 5 completed PRs with the recommended model:

1. First improve the issue body — add file targets, constraints, and reference files
2. If rework rate is still above 20% after improving the issue body, escalate to the next model tier
3. Document the decision in this section with the date and evidence

### Budget guardrails

- Never assign Claude Opus to any task without explicit written approval
- Check Settings → Billing → Copilot usage weekly — alert threshold is 240 requests used (80% of 300)
- If requests exceed 240 mid-month, switch all remaining agent tasks to GPT-4.1 regardless of task type
- The three GPT-5.1-Codex task types (PromQL, OTEL, Grafana JSON) together consume ~12 requests/month at 20 issues/week — this is the expected and justified premium spend
- 
## 11. See Also

- `.github/copilot-instructions.md` — Copilot-specific subset (merged with this file at runtime)
- `.github/agents/` — specialist agent profiles
- `.github/instructions/` — path-scoped instruction files by language
- `docs/GOLDEN_PATH.md` — standard feature development workflow (also in docs site)
- `docs/PROMPT_LIBRARY.md` — tested prompt templates for every repeating task
