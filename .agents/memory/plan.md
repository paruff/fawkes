# Fawkes Plan — MVP + Post-MVP Roadmap

> **Created:** 2026-06-08
> **Updated:** 2026-06-08 (added Phases 3–5)
> **Decisions:** AWS EKS, DCP-first, Security Plane advisory→progressive→strict, both local/cloud paths

---

## Completed

### Phase 1: CI Cleanup ✅
- [x] #3 — Remove duplicate ruff + flake8
- [x] #5 — Remove redundant checkout from quality-summary
- [x] #4 — Merge python-quality + python-coverage into python-lint-and-test
- [x] #11 — Align coverage gate to 80%
- [x] #7 — paths-ignore via detect-changes
- [x] #8 — Extract composite action `.github/actions/setup-python-env/`
- [x] Close 27 duplicates (#978–#1004)
- [x] Update PROJECT_STATUS.md

### Phase 2a: Wave 0 — Infra Prerequisites ✅
- [x] #1153 — Terraform remote state backend (S3 + DynamoDB + Azure Blob)
- [x] #683 — Sealed Secrets ArgoCD Application (Bitnami v0.28.0)
- [x] #634 — BATS tests for error_handling.sh
- [x] CI DORA timestamp fixes, .gitignore, label fixes

### Phase 2b: Wave 1 — Tracer Bullet Core ✅
- [x] #83 — Tracer bullet FastAPI service (app/main.py, Dockerfile, tests/)
- [x] #82 — Terraform module eks-app-namespace
- [x] #84 — K8s manifests (deployment, service, ingress, serviceaccount, kustomization)
- [x] #84 — ArgoCD Application with auto-sync
- [x] #85 — CI/CD pipeline (tracer-bullet-ci.yml: lint→test→build→push→GitOps)
- [x] Trivy blocking (exit-code=1), pin trivy-action@0.28.0

### Phase 2c: Wave 2 — Observable Golden Path ✅
- [x] #87 — OTEL tracing (OTLP gRPC→Collector→Tempo), auto-instrumentation
- [x] #88 — Structured logging (TraceContextFilter, trace_id+span_id injection)
- [x] #89 — E2E observability validation (BDD + validate-pipeline.sh)
- [x] #1156 — gen_ai.* Prometheus recording rules (6 rules)
- [x] #90 — CI/CD DORA metrics emission (tracer-bullet-ci.yml)

---

## Phase 3: Developer Control Plane (DCP)

**Goal:** Full-stack developer self-service — portal + APIs + DevEx metrics + feedback.
**Timeline:** Weeks 1–8 (parallel with Phase 4)

### 3a: Backstage as DCP Portal

| Priority | Issue | Work | Agent | Effort |
|----------|-------|------|-------|--------|
| P0 | — | Create `templates/location.yaml` with glob auto-discovery | `gpt41-default` | XS |
| P0 | — | Register Location entity in `catalog-info.yaml` | `gpt41-default` | XS |
| P0 | #81 | Decompose self-service catalog into sub-issues (templates, catalog, infra, scorecards, feedback) | Planning | S |
| P0 | #81 | Wire all 23 services into Backstage catalog (each needs `catalog-info.yaml`) | `gpt41-default` | L |
| P1 | #81 | Create shared parameter fragments in `templates/defaults/` (ownership, repo-picker) | `gpt41-default` | S |
| P1 | #49 | GitOps dashboard — ArgoCD plugin in Backstage showing sync status | `infra-gitops` | M |
| P1 | #81 | Self-service infrastructure provisioning (namespace, DB, queue via Backstage templates) | `infra-gitops` | XL |
| P2 | #81 | Service scorecards (DORA, security posture, test coverage, docs) | `gpt41-default` | L |

### 3b: Developer Experience Metrics

| Priority | Issue | Work | Agent | Effort |
|----------|-------|------|-------|--------|
| P1 | #270 | SPACE Framework metrics collection (extend discovery-metrics service) | `gpt41-default` | L |
| P1 | #271 | DevEx dashboard in Grafana (time-to-first-deploy, build times, PR merge time) | `gpt41-default` | L |
| P2 | #272 | DevEx survey automation (quarterly, results feed dashboard) | `gpt41-default` | M |
| P2 | #273 | Friction logging system + heatmap dashboard | `gpt41-default` | M |

### 3c: Feedback Loops

| Priority | Issue | Work | Agent | Effort |
|----------|-------|------|-------|--------|
| P1 | #300 | Enhanced feedback widget in Backstage sidebar | `gpt41-default` | S |
| P1 | #350 | Feedback-to-issue automation (low satisfaction → GitHub issue) | `gpt41-default` | M |
| P2 | #351 | Feedback analytics dashboard | `gpt41-default` | M |
| P2 | #316 | Mattermost feedback bot | `gpt41-default` | S |

### 3d: Design System Maturity

| Priority | Issue | Work | Agent | Effort |
|----------|-------|------|-------|--------|
| P1 | #353 | Component library (break into per-component sub-issues) | `design-system` agent | XL |
| P1 | #374 | Storybook deployment | `gpt41-default` | M |
| P2 | #396 | Automated accessibility testing (axe-core in CI) | `gpt41-default` | M |
| P2 | #373 | Design tool integration (Penpot/Figma sync) | `gpt41-default` | L |

---

## Phase 4: Security Plane Operationalization

**Goal:** Move from documented → enforced. 3-phase rollout.
**Timeline:** Weeks 1–8 (parallel with Phase 3)

### 4.1: Advisory Mode (Weeks 1–2)

| Priority | Work | Agent | Effort |
|----------|------|-------|--------|
| P0 | Wire `reusable-security-scanning.yml` into `code-quality.yml` (advisory, non-blocking) | `ci-debugger` | S |
| P0 | Run full scan, document all findings, create issues for CRITICAL/HIGH | `security-agent` | M |
| P1 | Enable SBOM generation (`reusable-sbom-generation.yml`) | `ci-debugger` | S |
| P1 | OPA policy dry-run in audit mode (`reusable-policy-enforcement.yml`) | `security-agent` | M |

### 4.2: Progressive Enforcement (Weeks 3–6)

| Priority | Work | Agent | Effort |
|----------|-------|------|--------|
| P0 | Block CRITICAL vulnerabilities (Trivy exit-code: 1) | `ci-debugger` | XS |
| P0 | Enforce mandatory K8s policies (Kyverno `mandatory-security.yaml`) | `infra-gitops` | M |
| P1 | Enforce resource constraints (Kyverno `resource-constraints.yaml`) | `infra-gitops` | S |
| P1 | Image signing (Cosign) + verification in ArgoCD | `security-agent` | L |
| P2 | Policy violation alerting (Grafana) | `gpt41-default` | S |

### 4.3: Strict Mode (Weeks 7–8)

| Priority | Work | Agent | Effort |
|----------|-------|------|--------|
| P0 | Full enforcement — all scans block on CRITICAL+HIGH | `security-agent` | M |
| P0 | Supply chain security — approved registries, image pinning | `security-agent` | M |
| P1 | Runtime security (Falco in fawkes-security namespace) | `infra-gitops` | L |
| P1 | Compliance dashboards (SOC2/PCI-DSS control status) | `gpt41-default` | L |
| P2 | Automated remediation (Kyverno generate policies) | `infra-gitops` | M |
| P2 | Security runbooks | `docs-writer` | M |

---

## Phase 5: Platform Maturity (Weeks 4–12)

### 5a: Multi-Environment Support
- Kustomize overlays for dev/staging/prod
- Helm values per environment
- ArgoCD ApplicationSets for multi-env
- Environment promotion pipeline

### 5b: BDD Test Coverage
- Implement step definitions for 45 BDD features (KL-05)
- E2E tests for all 23 services
- Terratest suite for Terraform modules (#647)

### 5c: Remaining Epic 0 Cleanup
- #707-#712: Documentation restructuring + 90% coverage
- #854: Comprehensive logging strategy (structlog rollout)
- #886: Advanced monitoring + Alertmanager integration
- #822: Pipeline-as-code templates for Jenkins

---

## Execution Sequence

```
Week 1-2:   Phase 3a (Backstage templates + catalog) ─────┐
              Phase 4.1 (Advisory security scans) ─────────┐
                                                            │
Week 3-4:   Phase 3b (DevEx metrics) ──────────────────────┤
              Phase 4.2 (Progressive enforcement) ──────────┤
                                                            │
Week 5-6:   Phase 3c (Feedback loops) ─────────────────────┤
              Phase 4.3 (Strict mode) ──────────────────────┤
                                                            │
Week 7-8:   Phase 3d (Design system) ──────────────────────┤
              Phase 5a (Multi-env) ─────────────────────────┤
                                                            │
Week 9-12:  Phase 5b (BDD tests) ──────────────────────────┘
              Phase 5c (Epic 0 cleanup)
```

---

## Issue Triage

**Close (cruft):** #39, #69, #70, #71 (empty templates)

**Label (unlabeled):** 34 issues need labels:
- #1368-#1376: `type-bug`, `type-performance`, `type-maintenance`
- #82-#90: `epic-1-dora`, `wave-1`, `wave-2`
- #1278, #1280: `type-testing`, `type-devex`

**Decompose:**
- #81 (Self-Service Catalog) → 5 sub-issues
- #54 (BDD tests) → per-service sub-issues
- #353 (Design System) → per-component sub-issues

---

## Guardrails

- Do not add new Terraform providers/modules without human approval
- Do not use `latest` image tags in any manifest
- All infra changes require `terraform plan` in CI before `apply`
- PR size > 400 lines → CI blocks
- Infra changes require 2 human approvals
- Security enforcement phases are sequential — do not skip advisory mode
