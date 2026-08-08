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

## 2. How to Work — Behavioral Guidelines

These bias toward caution over speed. Use judgment on trivial tasks.

**Think before coding.** State assumptions explicitly; if uncertain, ask instead of guessing.
If multiple interpretations exist, present them rather than picking silently. If a simpler
approach exists, say so — push back when warranted.

**Simplicity first.** Minimum code that solves the problem. No speculative features,
no unrequested abstractions or configurability, no error handling for impossible scenarios.
If it could be a third of the size, rewrite it.

**Surgical changes.** Touch only what the task requires. Don't "improve" adjacent code,
comments, or formatting. Match existing style even if you'd do it differently. Remove
imports/variables your change orphaned; leave pre-existing dead code alone (mention it,
don't delete it). Every changed line should trace to the request.

**Goal-driven execution.** Turn tasks into verifiable goals: "fix the bug" → write a test
that reproduces it, then make it pass. For multi-step work, state a brief plan with a
verification check per step, then loop to green independently.

---

## 3. The Polyglot Language & Layer Map

Read this before touching any file. Each area of the repo has a primary language and rules.

| Directory                 | Language         | What Lives Here                                     | Do Not                                                   |
| ------------------------- | ---------------- | ----------------------------------------------------- | --------------------------------------------------------- |
| `services/`               | Python (FastAPI) | Microservices, APIs, business logic                 | Embed shell business logic here — use `scripts/` instead |
| `infra/`                  | HCL (Terraform)  | Cloud provisioning, IaC modules                     | Hardcode cloud credentials or region defaults            |
| `platform/`               | YAML + Helm      | Kubernetes manifests, ArgoCD apps, Backstage config | Bypass Helm templating with raw manifests                |
| `scripts/`                | Bash / Python    | Automation helpers, `ignite.sh`, dev tooling        | Put business logic here — scripts call services          |
| `design-system/`          | CSS / JS         | UI components for platform web interfaces           | Mix with backend logic                                   |
| `jenkins-shared-library/` | Groovy           | Shared Jenkins pipeline steps                       | Put Groovy logic in `scripts/`                           |
| `tests/`                  | Python / Go      | Unit, integration, BDD tests                        | Delete failing tests to make CI pass                     |
| `charts/`                 | Helm / YAML      | Helm chart definitions                              | Override chart values in the chart itself                |
| `docs/`                   | Markdown         | MkDocs site (Diataxis)                              | Add non-Diataxis content without a category decision     |
| `templates/`              | YAML / Devfile   | Golden path templates for Backstage                 | Hardcode team-specific values                            |
| `data/issues/`            | JSON / CSV       | Issue data for import                               | Edit manually — use scripts                              |

---

## 4. Context Files — Read Before Generating Any Code

| Priority | File                              | What You Learn                                                          |
| -------- | ---------------------------------- | ------------------------------------------------------------------------- |
| 1        | `AGENTS.md` (this file)           | Language map, boundaries, PM contract                                   |
| 2        | `docs/ARCHITECTURE.md`            | Component relationships, allowed dependencies                           |
| 3        | `docs/API_SURFACE.md`             | Public interfaces across services                                       |
| 4        | `docs/KNOWN_LIMITATIONS.md`       | Known issues — do not make these worse                                  |
| 5        | `docs/CHANGE_IMPACT_MAP.md`       | Which files break when a component changes                              |
| 6        | `.github/copilot-instructions.md` | Copilot-specific coding standards                                       |
| 7        | `docs/BACKLOG.md`                 | Triaged backlog — value/effort scores, agent assignments, MVP wave plan |
| 8        | `docs/PR_STANDARD.md`             | Conventional Commits, branch naming, CI requirements, PR body rules     |
| 9        | `docs/DEPLOYMENT_STRATEGY.md`     | Current deploy model, target progressive delivery, rollback protocol    |

---

## 5. Architecture Rules — Never Violate These

### Platform Boundaries

```
services/     → Stateless Python (FastAPI) microservices. No direct infra provisioning.
infra/        → Terraform only. No application code. No shell business logic.
platform/     → Kubernetes/Helm declarative state. No imperative scripts.
scripts/      → Call services and CLI tools. Never contain business logic.
tests/        → Test the above layers. Never import from multiple layers in one test.
```

### IaC (Terraform)

- Every `variable` has a `description`; no hardcoded regions, account IDs, or credentials
- `module` calls reference a versioned module, not a local path, in production
- `terraform plan` must pass in CI before any `apply`

### Helm / Kubernetes

- Environment-specific values live in overrides, not base `values.yaml`
- No `latest` image tags — pin digest or version; resource limits required on every container
- Labels must include: `app`, `version`, `component`, `managed-by: fawkes`

### Python (FastAPI) Services

> Go is not used in `services/` — only in `tests/terratest/` for infra tests.

Prefer established PyPI packages over reinventing. Type hints on all signatures.
Explicit exceptions with context, never silently discarded. No global mutable state.

### CI / GitHub Actions

Every job logs start timestamp, commit SHA, finish timestamp (DORA logging).
Secrets via `${{ secrets.NAME }}` only. Matrix builds where applicable.
Jobs must set `timeout-minutes`.

---

## 6. The PM–Agent Contract

### May Do Without Asking

Read any file. Write to `services/`, `tests/`, `docs/`, `scripts/`, `design-system/`.
Run linters, formatters, test suites, `terraform validate`, `helm lint`.
Open draft PRs, add comments, update docstrings.

### Must Ask Before

Adding a Terraform provider/module. Creating or modifying ArgoCD `Application` manifests.
Changing Backstage catalog descriptors. Modifying `.github/workflows/`. Adding Helm chart
dependencies. Touching more than 5 files in one task.

### Must Never

Commit secrets, API keys, cloud credentials, or kubeconfig content. Modify `AGENTS.md`
without maintainer instruction. Delete tests — fix the code instead. Push to `main`
directly. Merge their own PRs. Apply the `large-pr-approved` label (humans only).
Bypass pre-commit hooks with `--no-verify`. Use `latest` image tags.

---

## 7. Coding Standards by Language

| Language        | Required checks                              | Notes                                                                 |
| ---------------- | --------------------------------------------- | ----------------------------------------------------------------------- |
| Go               | `gofmt`, `golangci-lint`                     | Table-driven tests; lowercase error strings, no trailing punctuation |
| Terraform (HCL) | `tflint`, `terraform fmt`, `tfsec`           | Module outputs documented; one resource type per file where practical |
| Helm / YAML     | `helm lint`, `yamllint`                      |                                                                       |
| Python          | `ruff`, `black`, `pytest`                    | Type hints on new functions; pin exact versions (`==`) in requirements files — see ADR-034 |
| Bash            | `shellcheck`                                 | `set -euo pipefail` at the top; no hardcoded paths                   |

Conventional commits throughout: `feat(scope):`, `fix(scope):`, `test(scope):`.

---

## 8. PR Requirements

Every PR includes: what it does (one sentence), which layer(s) it touches, tests
added/updated, linters passing locally, judgment calls flagged for human review,
`make lint` output.

---

## 9. Instability Safeguards

- PR size > 400 lines → CI blocks; override needs `large-pr-approved` label from a human
- `infra/` changes require a second human reviewer
- New Helm chart versions require `helm lint` + `helm template` output in the PR
- Rework rate > 10% → stop adding features, fix the instructions instead

### Deployment Gates

- Every PR targeting `main` must pass `paruff/ufawkespipe/.github/workflows/reusable-main-ci-guard.yml@v1.2.0`
- Post-deployment verification and auto-rollback on failure are targets, not yet built — see `docs/DEPLOYMENT_STRATEGY.md`
- Every CI/CD job logs `job-start`/`job-finish` with workflow, job, and SHA for DORA traceability

This repo calls reusable workflows from `paruff/ufawkespipe@v1.2.0` (currently:
`reusable-main-ci-guard.yml`). More may be added as the deployment lifecycle matures.

---

## 10. Fawkes-Specific Principles

Fawkes **is** a DORA platform — its own development must model what it teaches:

1. Prefer many small PRs over large batched ones (deployment frequency)
2. Every issue completable in < 2 days of agent work (lead time)
3. All infra changes behind `terraform plan` in CI (change failure rate)
4. Runbooks in `docs/runbooks/` tested quarterly (MTTR)
5. Rework rate tracked weekly in `docs/METRICS.md` (`scripts/weekly-metrics.sh`)
6. Frictionless tooling and paved paths are the biggest AI-effectiveness multiplier (DORA 2025)
7. AI amplifies existing practices — a weak foundation gets worse faster, not better

---

## 11. Model Selection (Copilot Coding Agent)

Budget: Copilot Pro, 300 premium requests/month. **Default to GPT-4.1 (multiplier 0, free)
for everything** unless a task below justifies a higher tier.

| Task                                              | Model         | Cost |
| --------------------------------------------------- | --------------- | ------ |
| Everything by default (bug fixes, refactors, docs, YAML, Terraform, tests) | GPT-4.1       | 0    |
| Purely mechanical single-line edits (`.gitignore`, version bumps, one-line docs) | GPT-5 mini    | 0    |
| PromQL/alert rules, OTEL `gen_ai.*` spans, Grafana dashboard JSON | GPT-5.1-Codex | 1    |
| Interactive IDE chat (not agent tasks)            | Claude Haiku 4.5 | 0.33 |
| Git history rewrite, sprint retro, security incident response | Human         | N/A  |

**Prohibited:** Claude Opus (any variant) without explicit written budget approval — 3–30×
multiplier. **Sticky UI:** the GitHub model selector doesn't read this file — set it manually
per issue.

Every Copilot issue should state: suggested model, task type, files to edit, reference file
(if any), what not to do, and measurable acceptance criteria.

If rework rate for a task type exceeds 20% after 5 PRs: first improve the issue body
(file targets, constraints, reference files); only escalate model tier if that doesn't help.

---

## 12. AI Trust & Verify

DORA 2025 names seven foundations for AI to accelerate rather than destabilize delivery:
policy clarity, healthy/accessible data, version control discipline, small batches,
user-centric focus, and platform quality. Fawkes implements these via this file, type
hints + structured logs, `docs/API_SURFACE.md`, the 400-line PR gate, golden-path
templates, and CI.

Follow **Read → Run → Review** for all AI-generated code:

1. **Read** the existing module/test before writing — never invent function names or paths
2. **Run** tests and confirm they pass before opening a PR
3. **Review** — security, RBAC, and infra changes always need human approval
4. **Declare** which sections of a PR were AI-generated or AI-reviewed

A module is "AI-ready" when it has type hints, docstrings, green tests, single
responsibility, contextual error messages, and BDD coverage. Note gaps as TODO issues.

---

## 13. See Also

- `.github/copilot-instructions.md` — Copilot-specific subset (merged with this file at runtime)
- `.github/agents/` — specialist agent profiles
- `.github/instructions/` — path-scoped instruction files by language
- `docs/BACKLOG.md` — triaged backlog with value/effort scores, agent assignments, MVP wave plan
- `docs/GOLDEN_PATH.md` — standard feature development workflow (also in docs site)
- `docs/PROMPT_LIBRARY.md` — tested prompt templates for every repeating task
