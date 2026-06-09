# Fawkes Plan — MVP + Post-MVP Roadmap

> **Created:** 2026-06-08
> **Updated:** 2026-06-08 (DORA research integration)
> **Decisions:** AWS EKS, DCP-first, Security Plane advisory→progressive→strict, both local/cloud paths
> **Research basis:** DORA 2025 State of AI-assisted Software Development, DORA AI Capabilities Model, Faros AI Engineering Report 2026

---

## DORA Research Findings — Implications for Fawkes

### The Amplifier Effect (DORA 2025)

> "AI's primary role in software development is that of an amplifier. It magnifies the strengths of high-performing organizations and the dysfunctions of struggling ones."

**Implication:** Fawkes' investment in platform quality (Golden Paths, linters, Helm charts, ArgoCD) is the single biggest multiplier for AI effectiveness. Weak foundations get worse faster with AI.

### The AI Productivity Paradox (Faros 2025-2026)

- Individual output: +21% tasks, +98% PRs merged
- Organizational delivery: **flat** in 2025, improving in 2026 but at a cost
- PR review time: +441% (2026)
- Bugs per developer: +54% (2026, up from +9% in 2025)
- Incidents per PR: +242.7% (2026)

**Implication:** Fawkes must measure **end-to-end delivery**, not just individual velocity. VSM (Value Stream Management) is critical.

### DORA AI Capabilities Model — 7 Foundations

| #   | Capability                       | Fawkes Status | Gap                                                          |
| --- | -------------------------------- | ------------- | ------------------------------------------------------------ |
| 1   | Clear and communicated AI stance | ⚠️ Partial    | AGENTS.md exists but not socialized beyond this repo         |
| 2   | Healthy data ecosystems          | ⚠️ Partial    | Type hints + structured logs exist; no unified data platform |
| 3   | AI-accessible internal data      | ✅ Strong     | AGENTS.md context files, ARCHITECTURE.md, API_SURFACE.md     |
| 4   | Strong version control practices | ✅ Strong     | Small PRs, CI gates, conventional commits                    |
| 5   | Working in small batches         | ⚠️ Partial    | 400-line PR gate exists; AI generates large changes          |
| 6   | User-centric focus               | ⚠️ Partial    | Backstage templates exist; no user research yet              |
| 7   | Quality internal platforms       | ✅ Strong     | This IS the platform — paved paths, linters, Helm, ArgoCD    |

### The J-Curve (DORA ROI 2026)

> "Navigate the J-Curve: explicitly budget for the 'tuition cost' — a necessary investment in learning before long-term ROI materializes."

**Implication:** Expect a **productivity dip** when rolling out AI tools. Budget for it. Don't reduce headcount prematurely — reinvest freed capacity.

### The Acceleration Whiplash (Faros 2026)

- Developers interact with 67.4% more PR contexts daily
- Work restarts up 13.8%
- 26% more in-progress tasks stalled for 7+ days
- "Easy to begin, hard to finish"

**Implication:** Fawkes must enforce **small batch discipline** and **PR size limits** more aggressively. AI will push developers toward larger changes.

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
- [x] #1156 — gen_ai.\* Prometheus recording rules (6 rules)
- [x] #90 — CI/CD DORA metrics emission (tracer-bullet-ci.yml)

---

## Phase 3: Developer Control Plane (DCP)

**Goal:** Full-stack developer self-service — portal + APIs + DevEx metrics + feedback.
**Timeline:** Weeks 1–8 (parallel with Phase 4)
**DORA alignment:** Builds Capabilities #3 (AI-accessible internal data), #6 (User-centric focus), #7 (Quality internal platforms)

### 3a: Backstage as DCP Portal

| Priority | Issue | Work                                                       | Agent           | Effort | DORA Cap |
| -------- | ----- | ---------------------------------------------------------- | --------------- | ------ | -------- |
| P0       | —     | Create `templates/location.yaml` with glob auto-discovery  | `gpt41-default` | XS     | #7       |
| P0       | —     | Register Location entity in `catalog-info.yaml`            | `gpt41-default` | XS     | #7       |
| P0       | #81   | Decompose self-service catalog into sub-issues             | Planning        | S      | #6       |
| P0       | #81   | Wire all 23 services into Backstage catalog                | `gpt41-default` | L      | #3       |
| P1       | #81   | Create shared parameter fragments in `templates/defaults/` | `gpt41-default` | S      | #7       |
| P1       | #49   | GitOps dashboard — ArgoCD plugin in Backstage              | `infra-gitops`  | M      | #3       |
| P1       | #81   | Self-service infrastructure provisioning                   | `infra-gitops`  | XL     | #7       |
| P2       | #81   | Service scorecards (DORA, security, coverage, docs)        | `gpt41-default` | L      | #6       |

### 3b: Developer Experience Metrics

**DORA alignment:** Addresses the AI Productivity Paradox — measure end-to-end delivery, not just individual velocity.

| Priority | Issue | Work                                                                                                                                                        | Agent           | Effort | DORA Cap |
| -------- | ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- | ------ | -------- |
| P0       | —     | **VSM Dashboard** — End-to-end pipeline visibility (lead time, PR review time, deployment frequency, change failure rate, MTTR)                             | `gpt41-default` | L      | #2       |
| P1       | #270  | SPACE Framework metrics (Satisfaction, Performance, Activity, Communication, Efficiency)                                                                    | `gpt41-default` | L      | #2       |
| P1       | #271  | DevEx dashboard (time-to-first-deploy, build times, PR merge time)                                                                                          | `gpt41-default` | L      | #2       |
| P1       | —     | **AI Amplification Metrics** — Track AI adoption vs. delivery stability. Alert when AI adoption rises but stability drops (Acceleration Whiplash detection) | `gpt41-default` | M      | #2       |
| P2       | #272  | DevEx survey automation (quarterly, results feed dashboard)                                                                                                 | `gpt41-default` | M      | #6       |
| P2       | #273  | Friction logging system + heatmap dashboard                                                                                                                 | `gpt41-default` | M      | #6       |

### 3c: Feedback Loops

| Priority | Issue | Work                                                           | Agent           | Effort | DORA Cap |
| -------- | ----- | -------------------------------------------------------------- | --------------- | ------ | -------- |
| P1       | #300  | Enhanced feedback widget in Backstage sidebar                  | `gpt41-default` | S      | #6       |
| P1       | #350  | Feedback-to-issue automation (low satisfaction → GitHub issue) | `gpt41-default` | M      | #6       |
| P2       | #351  | Feedback analytics dashboard                                   | `gpt41-default` | M      | #6       |
| P2       | #316  | Mattermost feedback bot                                        | `gpt41-default` | S      | #6       |

### 3d: Design System Maturity

| Priority | Issue | Work                                                    | Agent                 | Effort | DORA Cap |
| -------- | ----- | ------------------------------------------------------- | --------------------- | ------ | -------- |
| P1       | #353  | Component library (break into per-component sub-issues) | `design-system` agent | XL     | #7       |
| P1       | #374  | Storybook deployment                                    | `gpt41-default`       | M      | #7       |
| P2       | #396  | Automated accessibility testing (axe-core in CI)        | `gpt41-default`       | M      | #7       |
| P2       | #373  | Design tool integration (Penpot/Figma sync)             | `gpt41-default`       | L      | #7       |

### 3e: AI-Specific Capabilities (NEW — DORA-driven)

**Rationale:** DORA's research shows AI amplifies existing conditions. These capabilities ensure AI works FOR Fawkes, not against it.

| Priority | Issue | Work                                                                                                                                                                                          | Agent           | Effort | DORA Cap |
| -------- | ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- | ------ | -------- |
| P0       | —     | **AI Policy Document** — Clear stance on permitted AI tools, usage guidelines, code review expectations. Socialize beyond this repo.                                                          | `docs-writer`   | S      | #1       |
| P0       | —     | **Small Batch Enforcement** — Reduce PR size gate from 400→200 lines. Add PR size warning at 150 lines. Enforce AI-generated changes to be chunked.                                           | `ci-debugger`   | S      | #5       |
| P1       | —     | **AI Code Review Agent** — Context-aware review agent that enforces organizational standards before human review. Shift AI feedback to author, not reviewer.                                  | `gpt41-default` | L      | #4, #5   |
| P1       | —     | **AI-Accessible Internal Data** — Wire ARCHITECTURE.md, API_SURFACE.md, and AGENTS.md into AI tool context windows. Ensure AI tools have Fawkes-specific context, not just generic knowledge. | `gpt41-default` | M      | #3       |
| P2       | —     | **Skill Preservation Program** — Pairing sessions, manual coding for complex components, architectural decision records. Combat skill degradation from AI reliance.                           | `docs-writer`   | M      | #1       |

---

## Phase 4: Security Plane Operationalization

**Goal:** Move from documented → enforced. 3-phase rollout.
**Timeline:** Weeks 1–8 (parallel with Phase 3)
**DORA alignment:** Capability #4 (Strong version control practices) — security scanning is a safety net.

### 4.1: Advisory Mode (Weeks 1–2) ✅

| Priority | Work                                                                                   | Agent            | Effort | Status  |
| -------- | -------------------------------------------------------------------------------------- | ---------------- | ------ | ------- |
| P0       | Wire `reusable-security-scanning.yml` into `code-quality.yml` (advisory, non-blocking) | `ci-debugger`    | S      | ✅ Done |
| P0       | Run full scan, document all findings, create issues for CRITICAL/HIGH                  | `security-agent` | M      | Next    |
| P1       | Enable SBOM generation (`reusable-sbom-generation.yml`)                                | `ci-debugger`    | S      |         |
| P1       | OPA policy dry-run in audit mode (`reusable-policy-enforcement.yml`)                   | `security-agent` | M      |         |

### 4.2: Progressive Enforcement (Weeks 3–6)

| Priority | Work                                                               | Agent            | Effort |
| -------- | ------------------------------------------------------------------ | ---------------- | ------ |
| P0       | Block CRITICAL vulnerabilities (Trivy exit-code: 1)                | `ci-debugger`    | XS     |
| P0       | Enforce mandatory K8s policies (Kyverno `mandatory-security.yaml`) | `infra-gitops`   | M      |
| P1       | Enforce resource constraints (Kyverno `resource-constraints.yaml`) | `infra-gitops`   | S      |
| P1       | Image signing (Cosign) + verification in ArgoCD                    | `security-agent` | L      |
| P2       | Policy violation alerting (Grafana)                                | `gpt41-default`  | S      |

### 4.3: Strict Mode (Weeks 7–8)

| Priority | Work                                                       | Agent            | Effort |
| -------- | ---------------------------------------------------------- | ---------------- | ------ |
| P0       | Full enforcement — all scans block on CRITICAL+HIGH        | `security-agent` | M      |
| P0       | Supply chain security — approved registries, image pinning | `security-agent` | M      |
| P1       | Runtime security (Falco in fawkes-security namespace)      | `infra-gitops`   | L      |
| P1       | Compliance dashboards (SOC2/PCI-DSS control status)        | `gpt41-default`  | L      |
| P2       | Automated remediation (Kyverno generate policies)          | `infra-gitops`   | M      |
| P2       | Security runbooks                                          | `docs-writer`    | M      |

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

## DORA Metrics Instrumentation

Fawkes must track and display these metrics as the primary measure of platform effectiveness:

### DORA 5 Metrics (Primary)

| Metric                    | What to Measure                          | Where                                        |
| ------------------------- | ---------------------------------------- | -------------------------------------------- |
| **Deployment Frequency**  | How often code is deployed to production | `tracer-bullet-ci.yml` + ArgoCD sync events  |
| **Lead Time for Changes** | Time from commit to production           | Git commit timestamp → ArgoCD sync timestamp |
| **Change Failure Rate**   | % of deployments causing failures        | ArgoCD sync health + alertmanager incidents  |
| **Mean Time to Recovery** | Time to restore after failure            | Alertmanager incident → resolution timestamp |
| **Rework Rate**           | % of work that is rework                 | PR labels (rework) / total PRs               |

### AI Amplification Metrics (NEW)

| Metric                          | What to Measure                              | Why                                    |
| ------------------------------- | -------------------------------------------- | -------------------------------------- |
| **AI Adoption Rate**            | % of PRs using AI assistance                 | Track adoption curve                   |
| **AI vs. Non-AI PR Size**       | Average PR size for AI-assisted vs manual    | Detect Acceleration Whiplash           |
| **AI vs. Non-AI Review Time**   | Review time by AI-assisted vs manual         | Detect verification tax                |
| **AI vs. Non-AI Incident Rate** | Incident rate by AI-assisted vs manual       | Detect quality degradation             |
| **PR Context Load**             | Average concurrent PRs per developer         | Detect cognitive overload              |
| **Work Restart Rate**           | % of tasks that re-open after moving to done | Detect "easy to start, hard to finish" |

### Value Stream Mapping

Map the full path: `Commit → CI → Build → Push → GitOps Commit → ArgoCD Sync → Running in Cluster`

- Instrument each stage with timestamps
- Identify bottlenecks (PR review is typically the biggest)
- Dashboard showing where time is spent

---

## Execution Sequence

```
Week 1-2:   Phase 3a (Backstage templates + catalog) ─────┐
              Phase 3e.0 (AI Policy + Small Batch) ────────┤  ← NEW: DORA-driven
              Phase 4.1 ✅ (Advisory security scans) ──────┤
                                                            │
Week 3-4:   Phase 3b (DevEx + VSM metrics) ────────────────┤  ← ENHANCED: VSM focus
              Phase 3e.1 (AI Code Review Agent) ────────────┤  ← NEW: DORA-driven
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

**New issues to create:**

- AI Policy Document (DORA Capability #1)
- VSM Dashboard (end-to-end pipeline visibility)
- AI Amplification Metrics (Acceleration Whiplash detection)
- AI Code Review Agent
- AI-Accessible Internal Data wiring
- Skill Preservation Program
- Small Batch Enforcement (PR size reduction)

---

## Guardrails

- Do not add new Terraform providers/modules without human approval
- Do not use `latest` image tags in any manifest
- All infra changes require `terraform plan` in CI before `apply`
- PR size > 400 lines → CI blocks (reducing to 200 in Phase 3e)
- Infra changes require 2 human approvals
- Security enforcement phases are sequential — do not skip advisory mode
- **DORA guardrail:** Never reduce estimates before investing in AI capabilities
- **DORA guardrail:** Measure end-to-end delivery, not just individual velocity
- **DORA guardrail:** Reinvest freed capacity, don't cut headcount (J-Curve)
