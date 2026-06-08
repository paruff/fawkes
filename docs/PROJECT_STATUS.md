# Fawkes Project Status

> **Last Updated**: June 8, 2026
> **Current Phase**: Phase 1 Complete — MVP Tracer Bullet In Progress
> **Target MVP Date**: Q3 2026

---

## Quick Status

| Category | Status | Notes |
|----------|--------|-------|
| **Services** | 22 Python FastAPI microservices | None deployed yet |
| **CI/CD** | 14 GitHub Actions workflows | Quality issues fixed Jun 8 |
| **Infrastructure** | 123 Terraform files (AWS + Azure) | No remote state (KL-01) |
| **Kubernetes** | Helm chart + platform manifests | ArgoCD configured, not deployed |
| **Local Dev** | `make dev-up` works | k3d cluster + Helm repos |
| **Testing** | 53 test files | 45 BDD features without step defs (KL-05) |
| **Scripts** | 83 shell scripts | Validation + dev tooling |
| **Documentation** | ARCHITECTURE, API_SURFACE, BACKLOG, etc. | 8 months stale until Jun 8 |

---

## What Exists (Real)

### Services (`services/`)
22 Python FastAPI microservices covering: auth, backstage-creator, cost-optimizer, dora-metrics, ghes-mirror, harvest-hawk, knowledge-graph, notification, onboarding-workshop, openssf-scorecard, orchestration-engine, pipeline-engine, policy-engine, provisioner, repo-scaffolder, runtime-tracker, security-scanner, snyk-integration, template-engine, tfa-service, validation-engine, weaviate-rag-platform.

None are deployed to a live cluster.

### Infrastructure (`infra/`)
- Terraform modules for AWS (EKS, RDS, S3, IAM) and Azure (AKS, CosmosDB)
- No remote state backend configured (KL-01) — state files are local only

### Platform (`platform/`)
- ArgoCD Application manifests
- Prometheus + Grafana observability stack
- Helm chart: `charts/score-transformer/`
- Network policies, RBAC, pod security standards

### CI/CD (`.github/workflows/`)
- 14 workflows: code quality, security scanning, Terraform validation, BATS tests, Backstage publishing, deploy, and more
- Phase 1 fixes applied Jun 8: removed duplicate linters, merged Python jobs, aligned coverage gate, pinned action versions

### Local Development
- `make dev-up` provisions k3d cluster with ArgoCD, Backstage, monitoring
- `scripts/dev-up.sh` trimmed to essentials (ArgoCD only Helm repo)

---

## Known Limitations (KL)

| ID | Issue | Impact |
|----|-------|--------|
| KL-01 | No Terraform remote state | Can't collaborate on infra, state corruption risk |
| KL-02 | Weaviate required for RAG | Knowledge graph service blocked |
| KL-05 | 45 BDD features with no step definitions | False sense of test coverage |
| KL-06 | No E2E testing framework | Can't validate tracer bullet end-to-end |
| KL-07 | No ArgoCD local dev workflow | Can't test GitOps locally |
| KL-08 | OTEL pipeline for AI metrics incomplete | Dashboard exists, no data |
| KL-09 | PROJECT_STATUS.md stale | This file was 8 months out of date |
| KL-10 | 45+ GitHub labels, many unused | Label noise from Sprint 01 |

---

## Backlog Snapshot

- **95 open issues** (27 duplicates from Epic 0 batch closed Jun 8)
- **MVP tracer bullet** (#83): Hello World FastAPI service → Helm → ArgoCD → EKS
- Full triaged backlog: `docs/BACKLOG.md`
- Value/effort scores assigned, agent model routing defined in `AGENTS.md`

---

## Agent System

### OpenCode Skills (`.agents/skills/`)
6 skills for free-tier models (gemma4:e4b, deepseek v4 flash, mimo v2.5):
- `kubernetes-manifests` — K8s labels, limits, security context
- `opentelemetry` — OTEL SDK, FastAPI instrumentor, gen_ai.* conventions
- `github-actions` — SHA pinning, timeout-minutes, path filtering
- `service-blueprint` — New service structure, main.py, Dockerfile templates
- `security-hardening` — Container security, RBAC, SAST
- `terraform-modules` — Variables, remote backend, tagging

### Copilot Agents (`.github/agents/`)
8 agents for GitHub.com Copilot workflows: gpt41-default, infra-gitops, test-engineer, docs-writer, issue-writer, code-reviewer, ci-debugger, security-agent.

### Model Selection Policy
AGENTS.md Section 10 defines model routing by task type. GPT-4.1 (free) is default. GPT-5.1-Codex (1x multiplier) reserved for PromQL, OTEL, and Grafana JSON tasks only.

---

## Recent Changes (June 2026)

| Date | Change |
|------|--------|
| Jun 8 | CI Phase 1 fixes: duplicate linters removed, Python jobs merged, coverage aligned |
| Jun 8 | Composite action `.github/actions/setup-python-env/` extracted |
| Jun 8 | 27 duplicate Epic 0 issues closed (#978–#1004) |
| Jun 8 | 6 OpenCode skills created for free-tier models |
| Jun 8 | Copilot agent index simplified to 8 agents |
| Jun 8 | `dev-up.sh` trimmed: Docker check, ArgoCD-only Helm repo |

---

## Next Steps

1. **Tracer bullet service** (#83): Create Hello World FastAPI + Dockerfile
2. **Terraform remote state** (#1153): S3 + DynamoDB backend
3. **Standardize K8s manifests** (#648): Labels, limits, security context
4. **E2E testing framework** (#1280): Validate the full pipeline
5. **ArgoCD local dev** (#1278): Test GitOps workflows locally

---

**Previous content (Sprint 01, Oct 2025) archived in git history: `git show HEAD~5:docs/PROJECT_STATUS.md`**
