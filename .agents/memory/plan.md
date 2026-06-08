# Fawkes MVP Plan — Tracer Bullet

> **Created:** 2026-06-08
> **Decisions:** AWS EKS, MVP-focused scope, update PROJECT_STATUS.md
> **Source:** Agent-assessed from GitHub issues, BACKLOG.md, ARCHITECTURE.md, and codebase exploration

---

## Current State Assessment

### What exists (real)
- 22 Python FastAPI microservices in `services/`
- 14 GitHub Actions workflows (with quality issues)
- Terraform modules for AWS + Azure in `infra/`
- Helm chart (`charts/score-transformer/`)
- Platform manifests (ArgoCD, observability, networking, policies) in `platform/`
- Local dev environment (`make dev-up`) — works
- 76 validation/acceptance scripts in `scripts/`
- Comprehensive documentation (ARCHITECTURE, API_SURFACE, KNOWN_LIMITATIONS, BACKLOG, METRICS)
- 9 custom Copilot agents in `.github/agents/`
- 6 language-scoped instruction files in `.github/instructions/`
- Pinned action SHAs, security scanning, PR size checks

### What's broken or missing
| Gap | Impact | Issues |
|-----|--------|--------|
| CI has duplicate linters, redundant jobs, no path filtering | Wastes ~5 min/PR, confuses contributors | #3, #4, #5, #7, #8, #11 |
| No Terraform remote state | Can't collaborate on infra, state corruption risk | #1153 (KL-01) |
| No E2E testing framework | Can't validate the "tracer bullet" end-to-end | #1280 |
| No ArgoCD local dev workflow | Can't test GitOps locally | #1278 |
| OTEL pipeline for AI metrics incomplete | Dashboard exists but has no data | #1156 |
| 27 duplicate issues (#978–#1004) | Backlog is noisy, hard to triage | Backlog |
| 45 BDD features with no step definitions | False sense of test coverage | KL-05 |
| `PROJECT_STATUS.md` is 8 months stale | Misleading project status | — |
| `otel-engineer` agent referenced but not created | Routing table incomplete | — |

---

## Phase 1: Fix the Foundation (This Week)

| # | Issue | Action | Agent | Est | Done |
|---|-------|--------|-------|-----|------|
| 1a | #3 | Remove duplicate `ruff` step + drop `flake8` | `gpt41-default` | 30 min | ✅ |
| 1b | #5 | Remove redundant checkout from `quality-summary` | `gpt41-default` | 15 min | ✅ |
| 1c | #4 | Merge `python-quality` + `python-coverage` into `python-lint-and-test` | `gpt41-default` | 2 hrs | ✅ |
| 1d | #11 | Align coverage gate to `--cov-fail-under=80` | `gpt41-default` | 15 min | ✅ |
| 1e | #7 | paths-ignore: handled via existing `detect-changes` job (no change needed) | — | — | ✅ |
| 1f | #8 | Extract composite action `.github/actions/setup-python-env/` | `gpt41-default` | 3 hrs | |
| 1g | — | Close duplicates #978–#1004 (27 issues) | `gpt41-default` | 15 min | |
| 1h | — | Update `PROJECT_STATUS.md` to current state | `docs-writer` | 30 min | |

**Exit criteria:** CI ~40% faster, 8 jobs (down from 9), no duplicate linters, 27 fewer open issues.
**Note:** #7 paths-ignore skipped — `detect-changes` job already handles this more precisely at job level.

---

## Phase 2a: Wave 0 — CI Quality Gates + Infra Prerequisites

| # | Issue | Action | Agent | Est |
|---|-------|--------|-------|-----|
| 2a | #1153 | Terraform remote state backend (S3 + DynamoDB) | `infra-gitops` | 4 hrs |
| 2b | #683 | Deploy Sealed Secrets | `infra-gitops` | 4 hrs |
| 2c | #684 | Purge secrets from git history (BFG) | **Human** | 1 hr |
| 2d | #621 | Validate code quality standards pass | `test-engineer` | 2 hrs |
| 2e | #634 | BATS testing framework for scripts | `test-engineer` | 4 hrs |
| 2f | #648 | Standardize Kubernetes manifests | `infra-gitops` | 4 hrs |
| 2g | #9 | Wire DORA telemetry to DevLake API | `gpt41-default` | 4 hrs |

---

## Phase 2b: Wave 1 — Tracer Bullet Core

| # | Issue | Action | Agent | Est |
|---|-------|--------|-------|-----|
| 3a | #83 | Hello World service (FastAPI) + Dockerfile | `gpt41-default` | 2 hrs |
| 3b | #82 | Terraform module `eks-app-namespace` | `infra-gitops` | 4 hrs |
| 3c | #84 | Helm chart + ArgoCD Application | `infra-gitops` | 4 hrs |
| 3d | #85 | CI pipeline (build, scan, push, update GitOps) | `infra-gitops` | 1–2 d |
| 3e | #86 | ArgoCD auto-sync config | `infra-gitops` | 2 hrs |

**Note:** Use `kind`/`k3s` locally if EKS cluster is not yet available.

---

## Phase 2c: Wave 2 — Observable Golden Path

| # | Issue | Action | Agent | Est |
|---|-------|--------|-------|-----|
| 4a | #87 | OTEL tracing + custom metrics in tracer service | `gpt41-default` | 4 hrs |
| 4b | #88 | Structured logging with trace ID injection | `gpt41-default` | 2 hrs |
| 4c | #89 | E2E observability validation (BDD) | `test-engineer` | 4 hrs |
| 4d | #90 | CI/CD DORA metrics emission | `infra-gitops` | 4 hrs |
| 4e | #1156 | Wire gen_ai.* OTEL pipeline | `gpt41-default` | 1 d |
| 4f | #1280 | E2E testing framework | `test-engineer` | 1–2 d |

---

## Execution Sequence

```
Week 1:  Phase 1 (CI cleanup) ────────────────────────────┐
         Phase 2a (Wave 0 infra) ──────────────┐          │
                                                │          │
Week 2:  Phase 2b (Wave 1 tracer bullet) ──────┤──────────┤
                                                │          │
Week 3:  Phase 2c (Wave 2 observability) ───────┘──────────┘
                                                           MVP ✅
```

---

## Guardrails

- Do not start Epic 3 until MVP tracer bullet is deployed and validated
- Do not add new Terraform providers/modules without human approval
- Do not use `latest` image tags in any manifest
- All infra changes require `terraform plan` in CI before `apply`
- PR size > 400 lines → CI blocks
- Infra changes require 2 human approvals
