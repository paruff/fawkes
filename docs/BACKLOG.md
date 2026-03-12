# Fawkes Backlog — Triage, Prioritization & MVP Path

> **Purpose:** Triaged backlog with value/effort scoring, agent-readiness, and a
> wave-by-wave path to a deployable MVP.
>
> **Last Updated:** 2026-03-12
> **MVP Target:** Tracer-Bullet — one service, deployed via GitOps, fully observable,
> DORA metrics automated.
> **Triage Method:** See [Scoring System](#scoring-system) below.

---

## Table of Contents

1. [MVP Definition](#mvp-definition)
2. [Scoring System](#scoring-system)
3. [MVP Wave Plan](#mvp-wave-plan)
4. [Full Issue Triage](#full-issue-triage)
   - [Wave 0 — CI Quality Gates](#wave-0--ci-quality-gates-prerequisite)
   - [Wave 1 — Tracer Bullet Core](#wave-1--tracer-bullet-core)
   - [Wave 2 — Observable Golden Path](#wave-2--observable-golden-path)
   - [Wave 3 — Self-Service & GitOps Polish](#wave-3--self-service--gitops-polish)
   - [Post-MVP — Epic 3 Discovery & UX](#post-mvp--epic-3-discovery--ux)
   - [Post-MVP — Remaining Epic 0](#post-mvp--remaining-epic-0)
   - [GAP Issues](#gap-issues)
   - [Needs Closure / Cruft](#needs-closure--cruft)
   - [Duplicates to Close](#duplicates-to-close)
5. [Agent Assignment Map](#agent-assignment-map)
6. [Known Blockers](#known-blockers)

---

## MVP Definition

A **deployable MVP** for Fawkes is defined as:

| Capability | Description | Issues |
|---|---|---|
| **Hello World service** | A containerised Python/Go service with a working Dockerfile | #83 |
| **Infrastructure as Code** | Terraform module provisions EKS namespace + IAM roles | #82 |
| **Helm chart + ArgoCD** | Helm chart deployed via ArgoCD (GitOps) | #84, #86 |
| **CI pipeline** | Jenkins (or GH Actions) builds, scans, and pushes image; updates GitOps repo | #85 |
| **Observability** | OpenTelemetry traces + Prometheus metrics visible in Grafana | #87, #89 |
| **Structured logging** | JSON logs with trace-ID injection | #88 |
| **DORA metrics** | Deployment frequency + lead-time visible in Grafana | #90 |
| **CI quality gates pass** | `ruff`, `black`, `mypy`, `shellcheck`, `helm lint`, `tflint` all green | #621 |
| **Secrets managed safely** | No secrets in Git; Sealed Secrets deployed | #683, #684 |
| **Remote Terraform state** | S3 + DynamoDB backend prevents state-file corruption | #1153 |

**Definition of Done:** A developer can `git push` to a feature branch, watch the CI
pipeline build and scan the image, see ArgoCD automatically deploy it to the cluster,
and view traces/metrics in Grafana — all without manual steps.

---

## Scoring System

| Field | Values | Meaning |
|---|---|---|
| **V** (Value) | 1–5 | 5 = MVP blocker; 4 = high value; 3 = medium; 2 = nice-to-have; 1 = minimal |
| **E** (Effort) | XS / S / M / L / XL | XS < 2 h; S = 2–4 h; M = 4–8 h; L = 1–2 d; XL > 2 d |
| **Score** | integer | `(V × 2) − effort_pts` where XS=1, S=2, M=3, L=4, XL=5. Higher = do first. Negative score = defer until higher-value work is done. |
| **Agent Ready** | Y / P / N | Y = fully specced (start now), P = partial (run `issue-writer` first), N = human-only |
| **Agent** | agent name | Recommended agent from `AGENTS.md`. Maps to GitHub Actions labels via AGENTS.md §10. |

---

## MVP Wave Plan

```
Wave 0  ──► Wave 1  ──► Wave 2  ──► Wave 3  ──► MVP ✅
  CI           Tracer     Observable   Self-       Deployable
  Quality      Bullet     Golden       Service     IDP
  Gates        Core       Path         Catalog
 (parallel)
```

| Wave | Focus | Key Issues | Est. Effort | State |
|---|---|---|---|---|
| **0** | CI quality gates — prerequisite for merge | #621, #632, #634, #646, #683, #684, #1153 | ~3 d | 🔴 Not started |
| **1** | Tracer bullet — deploy Hello World via GitOps | #82, #83, #84, #85, #86 | ~4 d | 🔴 Not started |
| **2** | Observable golden path — traces, metrics, logs | #87, #88, #89, #90, #1156 | ~3 d | 🔴 Not started |
| **3** | Self-service & ArgoCD polish | #49, #81 | ~3 d | 🔴 Not started |

**Wave 0 runs in parallel with Wave 1.** Agents can begin Wave 1 stories while CI
quality work is in review, as long as the quality gate issues do not block the Wave 1
PR merges.

---

## Full Issue Triage

### Wave 0 — CI Quality Gates (Prerequisite)

> Must pass before Wave 1 PRs can merge. Run in parallel with Wave 1 story work.

| # | Title | V | E | Score | Agent Ready | Agent | Notes |
|---|---|---|---|---|---|---|---|
| **#621** | Validate Code Quality Standards (AT-E0-001) | 5 | S | 8 | Y | `test-engineer` | Run `ruff`, `black`, `mypy`, `shellcheck`; fix any failures |
| **#632** | Refactor ignite.sh into Modular Architecture | 4 | L | 4 | Y | `gpt41-default` | Split monolithic script into modules (do not change CLI interface); `shellcheck` must pass; break into sub-issues if > 400 lines changed; flag for human review if module boundaries are unclear |
| **#633** | Implement Comprehensive Error Handling | 3 | M | 3 | Y | `gpt41-default` | Add trap-based error handling in Bash scripts |
| **#634** | Create BATS Testing Framework for Scripts | 4 | M | 5 | Y | `test-engineer` | Use bats-core (not legacy bats); see AGENTS.md |
| **#635** | Validate Script Refactoring (AT-E0-002) | 3 | S | 4 | Y | `test-engineer` | Run bats tests; assert shellcheck clean |
| **#645** | Refactor Terraform for Module Reusability | 3 | L | 2 | P | `infra-gitops` | Needs list of modules to consolidate; add descriptions to all variables |
| **#646** | Implement Terraform State Management Best Practices | 4 | M | 5 | P | `infra-gitops` | Add S3 backend + DynamoDB locking; see KL-01 and #1153 (GAP-07) |
| **#647** | Create Terratest Suite for Infrastructure | 3 | L | 2 | P | `test-engineer` | Use `tests/terratest/`; go 1.24.11 required (see repo memories) |
| **#648** | Standardize Kubernetes Manifests | 4 | M | 5 | Y | `infra-gitops` | Add required labels (`app`, `version`, `component`, `managed-by: fawkes`); add resource limits |
| **#649** | Implement Kustomize for Environment Management | 3 | M | 3 | Y | `infra-gitops` | Scope to ONE service PoC first (see AGENTS.md task routing) |
| **#650** | Validate Infrastructure Refactoring (AT-E0-003) | 3 | S | 4 | Y | `test-engineer` | `terraform validate`; `tflint`; `helm lint` |
| **#683** | Deploy Sealed Secrets for Secret Management | 5 | M | 7 | Y | `infra-gitops` | MVP blocker — no plaintext secrets in Git |
| **#684** | Audit and Purge Secrets from Git History | 5 | M | 7 | N | **Human** | Requires coordinated BFG force-push; cannot be delegated to agent |
| **#685** | Create Environment-Specific Configuration System | 3 | M | 3 | Y | `infra-gitops` | Helm values override pattern per environment |
| **#686** | Validate Configuration Management (AT-E0-004) | 3 | S | 4 | Y | `test-engineer` | Assert no `env.value` with secrets; assert sealed-secret CRDs exist |

---

### Wave 1 — Tracer Bullet Core

> The simplest possible end-to-end path from `git push` to running pod.

| # | Title | V | E | Score | Agent Ready | Agent | Notes |
|---|---|---|---|---|---|---|---|
| **#74** | Epic 1: DORA-Driven IDP Foundation | 5 | XS | 9 | Y | — | Parent epic; track progress here |
| **#76** | Feature 1.1: The Tracer Bullet End-to-End Walkthrough | 5 | XS | 9 | Y | — | Parent feature; decomposed into #77–#90 |
| **#77** | 1.1.1. Minimal Service Blueprint | 5 | XS | 9 | Y | — | Parent story group; decomposed into #82–#84 |
| **#82** | STORY: Boilerplate Terraform Module — EKS Namespace & IAM Roles | 5 | M | 7 | Y | `infra-gitops` | Create `infra/terraform/modules/eks-app-namespace/`; IRSA binding |
| **#83** | STORY: Minimal App Code — "Hello World" Service and Dockerfile | 5 | S | 8 | Y | `gpt41-default` | Python FastAPI; multi-stage Dockerfile; Jenkinsfile stub |
| **#84** | STORY: Helm/ArgoCD Config — Define Deployment Manifests | 5 | M | 7 | Y | `infra-gitops` | Helm chart in `charts/tracer-bullet/`; ArgoCD Application manifest |
| **#85** | STORY: CI Pipeline Logic — Build, Scan, and Update GitOps Repo | 5 | L | 6 | Y | `infra-gitops` | Jenkins Jenkinsfile; Trivy scan; git-commit image tag to values |
| **#86** | STORY: ArgoCD Configuration — Automatic Sync and Deployment | 5 | S | 8 | Y | `infra-gitops` | Enable `automated.prune` + `selfHeal` in ArgoCD Application |

---

### Wave 2 — Observable Golden Path

> Every service deployed through Fawkes must be observable from day one.

| # | Title | V | E | Score | Agent Ready | Agent | Notes |
|---|---|---|---|---|---|---|---|
| **#78** | FEATURE: GitOps End-to-End Pipeline — Connect CI/CD and ArgoCD | 4 | XS | 7 | Y | — | Parent feature; covered by #85 + #86 |
| **#79** | FEATURE: Observable Golden Path — Implement Logging, Metrics, and Tracing | 4 | XS | 7 | Y | — | Parent feature; covered by #87–#89 |
| **#87** | STORY: App Instrumentation — OpenTelemetry Tracing and Custom Metrics | 5 | M | 7 | Y | `gpt41-default` | Add OTEL SDK to the tracer-bullet service; export to Tempo + Prometheus |
| **#88** | STORY: Log Correlation — Structured Logging and Trace ID Injection | 4 | S | 6 | Y | `gpt41-default` | structlog JSON; inject `trace_id` + `span_id` into every log line |
| **#89** | STORY: E2E Observability — Validate Data Flow to Dashboards | 4 | M | 5 | Y | `test-engineer` | BDD scenario; Grafana Tempo + Prometheus queries return data |
| **#90** | STORY: CI/CD Metrics — Expose Pipeline Duration and Status | 4 | M | 5 | Y | `infra-gitops` | Emit `dora_lead_time_seconds` and `dora_deployment_frequency` from Jenkins |
| **#1156** | FAW-GAP-10 — Wire AI/LLM OTEL pipeline: gen_ai.* spans → Prometheus | 3 | L | 2 | P | `gpt41-default` | Wire existing `gen_ai.*` metrics from `services/ai-code-review/` to Prometheus scrape; use GPT-5.1-Codex per AGENTS.md if free model struggles |

---

### Wave 3 — Self-Service & GitOps Polish

> After the tracer bullet works, make it self-service and robust.

| # | Title | V | E | Score | Agent Ready | Agent | Notes |
|---|---|---|---|---|---|---|---|
| **#49** | I want ArgoCD to deploy all the apps via GitOps | 4 | L | 4 | P | `infra-gitops` | Needs issue body expanded with list of apps and dependency order; use `issue-writer` first |
| **#81** | FEATURE: User-Centric "Day 1" Experience — Self-Service Catalog & Automation | 3 | XL | 1 | P | `gpt41-default` | Backstage Software Template; scaffolder; needs infra from Wave 1 first |
| **#53** | I want a standardized build tool for paved paths | 3 | L | 2 | P | `infra-gitops` | Cloud Native Buildpacks in Jenkins Shared Library; needs issue body |
| **#54** | I want comprehensive BDD tests | 3 | L | 2 | P | `test-engineer` | BDD step definitions for KL-05 gap; needs issue body per service |
| **#55** | I want comprehensive integration tests | 3 | L | 2 | P | `test-engineer` | pytest integration suite; needs per-service scope in issue body |

---

### Post-MVP — Epic 3 Discovery & UX

> User research, DevEx metrics, feedback loops, and design system.
> Start after MVP is deployed and receiving real user feedback.

| # | Title | V | E | Score | Agent Ready | Agent | Notes |
|---|---|---|---|---|---|---|---|
| #189 | Deploy research repository in Backstage | 3 | M | 3 | Y | `gpt41-default` | Only issue with `type-ai-agent` label; already specced |
| #259 | Create Persona Templates and Initial Personas | 2 | S | 2 | Y | `docs-writer` | Documentation work |
| #260 | Create Interview Guides for User Research | 2 | S | 2 | Y | `docs-writer` | Documentation work |
| #261 | Create Insights Database and Tracking System | 2 | M | 1 | P | `gpt41-default` | Needs database choice decision |
| #262 | Build Research Dashboard for Insights Visualization | 2 | L | 0 | P | `gpt41-default` | Depends on #261 |
| #263 | Validate Research Infrastructure (AT-E3-001) | 2 | S | 2 | Y | `test-engineer` | — |
| #264 | Create User Research Repository Structure | 2 | S | 2 | Y | `docs-writer` | — |
| #270 | Implement SPACE Framework Metrics Collection | 3 | L | 2 | P | `gpt41-default` | Extend SPACE metrics service; needs schema |
| #271 | Build DevEx Dashboard in Grafana | 3 | L | 2 | P | `gpt41-default` | Use GPT-5.1-Codex for Grafana JSON per AGENTS.md |
| #272 | Create DevEx Survey Automation System | 2 | M | 1 | P | `gpt41-default` | — |
| #273 | Implement Friction Logging System | 2 | M | 1 | P | `gpt41-default` | — |
| #274 | Deploy Cognitive Load Assessment Tool | 2 | L | 0 | P | `gpt41-default` | — |
| #275 | Validate DevEx Measurement System (AT-E3-002) | 2 | S | 2 | Y | `test-engineer` | — |
| #300 | Deploy Enhanced Feedback Widget in Backstage | 2 | M | 1 | P | `gpt41-default` | — |
| #301 | Create CLI Feedback Tool | 2 | M | 1 | P | `gpt41-default` | — |
| #304 | Create Interview Guides for User Research | 2 | S | 2 | Y | `docs-writer` | Likely duplicate of #260 — verify before starting |
| #316 | Deploy Mattermost Feedback Bot | 2 | M | 1 | P | `gpt41-default` | — |
| #350 | Implement Feedback-to-Issue Automation | 2 | M | 1 | P | `gpt41-default` | — |
| #351 | Build Feedback Analytics Dashboard | 2 | L | 0 | P | `gpt41-default` | Use GPT-5.1-Codex for Grafana JSON per AGENTS.md |
| #352 | Validate Multi-Channel Feedback System (AT-E3-003) | 2 | S | 2 | Y | `test-engineer` | — |
| #353 | Create Design System Component Library | 2 | XL | -1 | P | `gpt41-default` | Large scope; break into sub-issues first |
| #373 | Integrate Design Tool (Figma/Penpot) | 2 | M | 1 | P | `gpt41-default` | — |
| #374 | Deploy Storybook for Component Documentation | 2 | M | 1 | P | `gpt41-default` | — |
| #396 | Implement Automated Accessibility Testing | 3 | M | 3 | Y | `test-engineer` | — |
| #397 | Create User Journey Maps (5 Key Workflows) | 2 | M | 1 | Y | `docs-writer` | — |
| #398 | Validate Design Systems (AT-E3-004, AT-E3-005, AT-E3-009) | 2 | S | 2 | Y | `test-engineer` | — |
| #423 | Deploy Product Analytics Platform (Plausible/Matomo) | 2 | L | 0 | P | `infra-gitops` | — |
| #450 | Implement Event Tracking Infrastructure | 2 | L | 0 | P | `gpt41-default` | — |
| #451 | Deploy Feature Flags Platform (Unleash) | 2 | L | 0 | P | `infra-gitops` | — |
| #452 | Build Experimentation Framework | 2 | XL | -1 | P | `gpt41-default` | Break into sub-issues |
| #37 | I want Crossplane | 1 | XL | -3 | N | **Human** | Significant architecture decision; add ADR first |
| #50 | I want add VSM to Backstage | 2 | M | 1 | P | `gpt41-default` | Needs Backstage plugin design; use `issue-writer` first |
| #51 | I want p3d configuration | 1 | XL | -3 | N | **Human** | Needs product decision on p3d scope |
| #56 | I want user via PostHog | 2 | M | 1 | P | `gpt41-default` | PostHog privacy review required first |

---

### Post-MVP — Remaining Epic 0

> Code quality improvements that are valuable but not MVP-blocking.
> Work in parallel with post-MVP features.

| # | Title | V | E | Score | Agent Ready | Agent | Notes |
|---|---|---|---|---|---|---|---|
| #666 | Implement Hierarchical Configuration Management | 3 | M | 3 | Y | `infra-gitops` | — |
| #707 | Restructure Documentation with Clear Information Architecture | 2 | L | 0 | Y | `docs-writer` | — |
| #708 | Implement Automated Documentation Generation | 3 | M | 3 | Y | `docs-writer` | — |
| #709 | Create Comprehensive Runbooks | 3 | L | 2 | Y | `docs-writer` | — |
| #710 | Build Troubleshooting Knowledge Base | 2 | L | 0 | Y | `docs-writer` | — |
| #711 | Achieve 90%+ Documentation Coverage | 2 | L | 0 | P | `docs-writer` | Measure first; automate gap-finding |
| #712 | Validate Documentation Excellence (AT-E0-005) | 2 | S | 2 | Y | `test-engineer` | `markdownlint` sweep |
| #765 | Optimize CI/CD Pipeline Performance | 3 | L | 2 | P | `ci-debugger` | Needs baseline measurement first |
| #793 | Implement Pipeline Failure Analysis and Alerting | 3 | M | 3 | Y | `infra-gitops` | Alertmanager rules for Jenkins |
| #822 | Create Pipeline-as-Code Templates | 3 | M | 3 | Y | `infra-gitops` | Jenkinsfile shared library templates |
| #823 | Validate CI/CD Optimization (AT-E0-006) | 2 | S | 2 | Y | `test-engineer` | — |
| #854 | Implement Comprehensive Logging Strategy | 3 | M | 3 | Y | `gpt41-default` | structlog rollout; add `services/shared/logging.py` first |
| #886 | Deploy Advanced Monitoring and Alerting | 3 | L | 2 | Y | `infra-gitops` | Alertmanager + PagerDuty integration |
| #887 | Create Observability Runbooks | 2 | M | 1 | Y | `docs-writer` | — |
| #888 | Validate Observability Enhancement (AT-E0-007) | 2 | S | 2 | Y | `test-engineer` | — |
| #923 | Conduct Code Review of All Epic 0 Changes | 2 | M | 1 | Y | `code-reviewer` | Use `@copilot` review or PR review button |
| #924 | Perform Regression Testing | 2 | M | 1 | Y | `test-engineer` | `pytest tests/` + `behave tests/bdd/` |
| #961 | Measure and Document Technical Debt Reduction | 2 | S | 2 | Y | `docs-writer` | Update METRICS.md |
| #962 | Create Epic 0 Retrospective and Lessons Learned | 1 | S | 1 | N | **Human** | Genuine reflection required |
| #963 | Update Onboarding Documentation for New Contributors | 2 | S | 2 | Y | `docs-writer` | — |
| #964 | Validate Final Epic 0 Integration (AT-E0-008) | 2 | S | 2 | Y | `test-engineer` | — |

---

### GAP Issues

> Known platform gaps that were added as tracked issues outside the epic structure.

| # | Title | V | E | Score | Agent Ready | Agent | Notes |
|---|---|---|---|---|---|---|---|
| **#1153** | FAW-GAP-07 — Add Terraform remote state backend configuration | 5 | M | 7 | Y | `infra-gitops` | MVP blocker; resolves KL-01; S3 + DynamoDB locking |
| **#1156** | FAW-GAP-10 — Wire AI/LLM OTEL pipeline: gen_ai.* spans → Prometheus | 3 | L | 2 | P | `gpt41-default` | Gen AI telemetry; use GPT-5.1-Codex if PromQL work needed |

---

### Needs Closure / Cruft

> These issues are empty templates or stubs with no real content. Close them.

| # | Title | Reason |
|---|---|---|
| #39 | I want (template) | Empty template stub — no content |
| #69 | Story: | Empty story template — no content |
| #70 | Feature: | Empty feature template — no content |
| #71 | Epic: | Empty epic template — no content |

**Action:** Close each with comment: `"Closing: empty template stub. Use the issue
templates in .github/ISSUE_TEMPLATE/ for new issues."`

---

### Duplicates to Close

> Issues #978–#1006 are numbered re-imports of issues #649–#964. The canonical issues
> (lower number) are the ones to track. Close the duplicates with a reference to the
> original.

| Duplicate | Original | Title |
|---|---|---|
| #978 | #649 | Implement Kustomize for Environment Management |
| #979 | #650 | Validate Infrastructure Refactoring (AT-E0-003) |
| #980 | #666 | Implement Hierarchical Configuration Management |
| #981 | #683 | Deploy Sealed Secrets for Secret Management |
| #982 | #684 | Audit and Purge Secrets from Git History |
| #983 | #685 | Create Environment-Specific Configuration System |
| #984 | #686 | Validate Configuration Management (AT-E0-004) |
| #985 | #707 | Restructure Documentation with Clear Information Architecture |
| #986 | #708 | Implement Automated Documentation Generation |
| #987 | #709 | Create Comprehensive Runbooks |
| #988 | #710 | Build Troubleshooting Knowledge Base |
| #989 | #711 | Achieve 90%+ Documentation Coverage |
| #990 | #712 | Validate Documentation Excellence (AT-E0-005) |
| #991 | #765 | Optimize CI/CD Pipeline Performance |
| #992 | #793 | Implement Pipeline Failure Analysis and Alerting |
| #993 | #822 | Create Pipeline-as-Code Templates |
| #994 | #823 | Validate CI/CD Optimization (AT-E0-006) |
| #995 | #854 | Implement Comprehensive Logging Strategy |
| #996 | #886 | Deploy Advanced Monitoring and Alerting |
| #997 | #887 | Create Observability Runbooks |
| #998 | #888 | Validate Observability Enhancement (AT-E0-007) |
| #999 | #923 | Conduct Code Review of All Epic 0 Changes |
| #1000 | #924 | Perform Regression Testing |
| #1001 | #961 | Measure and Document Technical Debt Reduction |
| #1002 | #962 | Create Epic 0 Retrospective and Lessons Learned |
| #1003 | #963 | Update Onboarding Documentation for New Contributors |
| #1004 | #964 | Validate Final Epic 0 Integration (AT-E0-008) |
| #1005 | — | Calculate and Publish Epic 0 ROI Report (no lower-numbered original exists; keep as canonical) |
| #1006 | — | Final Epic 0 Validation and Sign-off (AT-E0-009) (no lower-numbered original exists; keep as canonical) |

> **Why #1005 and #1006 are kept:** The numbered re-import batch covers items #121–#148
> (mapped to issues #649–#1004). Items labelled "149" and "150" in the batch (#1005 and
> #1006) have no lower-numbered canonical counterparts in the backlog — they are net-new
> issues, not re-imports. Close only #978–#1004.

**Action:** Close #978–#1004 with comment: `"Closing: duplicate of #NNN. Track work on
the original issue."`

---

## Agent Assignment Map

| Agent | Issues | Specialty |
|---|---|---|
| `gpt41-default` | #83, #87, #88, #1156, #633, #632, #854, #189, #270, #50, #53–55 (after speccing) | Python FastAPI services, GitHub Actions YAML, Bash scripts, multi-file refactor |
| `infra-gitops` | #82, #84, #85, #86, #90, #646, #648, #649, #645, #683, #685, #793, #822, #886, #1153, #49 | Terraform modules, Helm charts, ArgoCD Applications, K8s manifests, Jenkins pipelines |
| `test-engineer` | #621, #634, #635, #647, #650, #686, #89, #888, #712, #263, #275, #352, #396, #398, #823, #924, #964 | pytest, behave BDD, BATS, acceptance tests |
| `docs-writer` | #259, #260, #264, #397, #707, #709, #710, #711, #887, #961, #963 | README, ADRs, runbooks, API docs |
| `ci-debugger` | #765 | CI pipeline performance analysis, failure root-cause |
| `code-reviewer` | #923 | PR review sweeps |
| `issue-writer` | #49, #50, #51, #53, #54, #55, #81 (before starting) | Convert vague "I want..." issues into fully-specced agent-ready issues |
| **Human only** | #684, #37, #51, #962 | Git history rewrite (BFG), architecture decisions, retrospective |

---

## Known Blockers

| Blocker | Impact | Issues Affected | Resolution |
|---|---|---|---|
| AWS credits / EKS cluster not provisioned | Wave 1 cannot deploy | #82, #83, #84, #85, #86 | AWS Activate application pending; use `kind` or `k3s` locally as interim |
| No Terraform remote backend (KL-01) | State corruption risk in CI | #646, #1153 | Fix #1153 first before any `terraform apply` in CI |
| 45 BDD features with no step definitions (KL-05) | False sense of test coverage | #634, #54 | Create step definitions incrementally; start with Wave 1 service |
| Secrets possibly in Git history (KL) | Security risk | #684 | Human-led BFG run required before public launch |
| Focalboard integration degraded (KL-03) | DORA change-failure-rate incomplete | — | Post-MVP; add alerting on degraded mode |
| DevLake ArgoCD plugin manual config (KL-06) | DORA metrics break after re-install | #90 | Add post-install Helm hook; include in Wave 2 |
| `type-ai-agent` GitHub label used on only one issue (#189) | Agents cannot filter the backlog using GitHub label search | All issues | The `Agent Ready = Y` column in this document is the source of truth. Optionally create a `agent-ready` GitHub label and apply it to Wave 0–2 issues as they are specced. The GitHub label mirrors the `Agent Ready = Y` status — they mean the same thing. |

---

## How to Use This Document

1. **Pick the top-scored issue from the current wave** that is `Agent Ready = Y`.
2. **Assign it to the recommended agent** from the Agent Assignment Map.
3. **After completion**, update the wave status and move to the next.
4. **For `Agent Ready = P` issues**, run the `issue-writer` agent first to expand the
   issue body with: goal, context, affected files, acceptance criteria, and "do not" list.
5. **Close duplicates** (#978–#1004) as you encounter them to keep the backlog clean.
6. **Update this document** after each wave completes — mark issues ✅ and update wave
   status emoji.

---

_Maintained by `@docs-agent`. Update after each sprint or triage session._
_Score formula: `(V × 2) − effort_points` where effort_points: XS=1, S=2, M=3, L=4, XL=5_
