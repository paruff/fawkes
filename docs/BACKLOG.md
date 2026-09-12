# Fawkes IDP — Roadmap, Backlog & DORA Strategy

> **Purpose:** Single source of truth for the Fawkes Internal Developer Platform roadmap,
> prioritized backlog, and DORA metrics strategy. Integrates IDP core features,
> phased delivery, and the belt-level learning curriculum.
>
> **Last Updated:** 2026-09-11
> **Current State:** Phase 1 (Alpha) — live-verified on mac-mini-k3s cluster
> **Source of Truth for Live Status:** [#1751](https://github.com/paruff/fawkes/issues/1751)

---

## What Fawkes Is

Fawkes is a **modular GitOps Internal Developer Platform** that combines CI/CD,
observability, security, and multi-cloud provisioning. It is also a **learning
platform** (belt-level dojo) and a **DORA metrics showcase**.

The platform teaches what it implements: every feature maps to a DORA capability,
a belt level, and a concrete IDP function.

---

## IDP Core Features

| Feature | Description | Fawkes Implementation | Status |
|---------|-------------|----------------------|--------|
| **Self-Service Portal** | Central dashboard for developers to request resources | Backstage Developer Portal | 🔴 Not started |
| **Infra Provisioning** | Automated cloud resource provisioning (DBs, clusters, networks) | Terraform modules + ArgoCD | 🟡 Partial (local k3s) |
| **Deployment Management** | Automated pipelines: testing → staging → production | Tekton CI + ArgoCD GitOps | 🟡 Alpha (staging only) |
| **Service Catalog** | Searchable registry of microservices, templates, components | Backstage catalog | 🔴 Not started |
| **CI/CD Orchestration** | Integrated CI/CD tools to test and build software | Tekton (CI) + ArgoCD (CD) | 🟡 Alpha (build+scan+deploy) |
| **Observability** | Dashboards and alerts: health, logs, metrics, errors | Prometheus + Grafana + OTel + Tempo + Loki | 🟢 Live (Prometheus/Grafana/Tempo) |
| **RBAC** | Security rules: who can view, change, or deploy | ArgoCD RBAC + Sealed Secrets | 🔴 Not started |

---

## DORA Metrics Strategy

Fawkes tracks all four DORA metrics plus a fifth (Reliability) and a
platform-specific sixth (Rework Rate).

| Metric | Elite Target | Alpha (Phase 1) | Beta (Phase 2) | Production (Phase 3) |
|--------|-------------|-----------------|----------------|---------------------|
| **Deployment Frequency** | ≥ 1/day | ✅ Tracked | ✅ Tracked | ✅ Tracked |
| **Lead Time for Changes** | < 1 hour | ✅ Tracked | ✅ Tracked | ✅ Tracked |
| **Change Failure Rate** | < 5% | — | ✅ Added | ✅ Added |
| **MTTR** | < 1 hour | — | — | ✅ Added |
| **Reliability (SLO)** | 99.9% | — | — | ✅ Added |
| **Rework Rate** (Fawkes-specific) | < 10% | 🟡 Baseline TBD | 🟡 Tracked | 🟢 Tracked |

**Data pipeline:** GitHub Events → DevLake → Prometheus → Grafana dashboards

**Rework Rate thresholds:** <10% 🟢 | 10-20% 🟡 | >20% 🔴
Weekly review via `scripts/weekly-metrics.sh`

---

## Delivery Phases

> **Live status:** the status cells below are hand-maintained snapshots and can
> drift from reality (see the Phase 2 audit and `docs/elite-engineering-bridge-plan.md`
> for why). The authoritative, machine-generated source of truth is the
> [`platform-status` branch's `docs/PLATFORM_STATUS.md`](https://github.com/paruff/fawkes/blob/platform-status/docs/PLATFORM_STATUS.md),
> regenerated nightly (and on-demand) by `.github/workflows/golden-path-verification.yml`
> from the real `scripts/validate-golden-path-*.sh` results. Check there before
> trusting a 🟢 here.

```
Phase 1 (Alpha)     Phase 2 (Beta)      Phase 3 (Production)
  Commit→Staging      Shift-Left Security   Human-in-the-Loop
  Basic Observability  Progressive Delivery  5-Key DORA
  2-Key DORA           Self-Service Portal   SLO-Based Rollback
        │                     │                     │
        ▼                     ▼                     ▼
  #1804 / #1808         #1805                 #1806
```

### Phase 1 — Alpha: Commit-to-Staging (#1804, #1808)

**Goal:** Push to `main` → CI builds → scans → signs → pushes image → GitOps PR → ArgoCD syncs to staging → basic observability visible.

| IDP Feature | Deliverable | Status |
|-------------|-------------|--------|
| CI/CD Orchestration | Build → scan → sign → SBOM → GHCR push | ✅ Live |
| Deployment Management | GitOps PR + auto-merge → ArgoCD sync | ✅ Live |
| Observability | OTel collector + Prometheus + Grafana | ✅ Live |
| DORA (2-key) | Deployment Frequency + Lead Time in Grafana | 🟡 Needs verification |

**Remaining tasks:**
- #1572 — Confirm DORA metrics queryable in Grafana (P0)
- #1569 — Terraform remote state backend (P0)
- #1959 — ArgoCD stability (P0 — crash-looping under load)
- #1855 — DevLake GitHub GraphQL collector fix (P0)
- #1693 — rag-service Dockerfile fix (PR #1998 ready)
- #1797 — Replace CHANGE_ME_* with Sealed Secrets
- #1578 — Wire IRSA role ARN into python-fawkes-path
- #1581 — Verify CI quality gates are green
- #1936 — BDD step definitions for quality gates
- ~~#1842 — ApplicationSet for platform-applications~~ ✅ Done — confirmed live 2026-09-12: both `platform-applications` and `path-based-applications` ApplicationSets are the real, active owners of every current Application (verified via `ownerReferences` on the live cluster)

### Phase 2 — Beta: Shift-Left Security (#1805)

**Goal:** Failing quality gates block promotion. At least one service deploys via canary/blue-green with automated rollback. Chaos experiments on staging. Change Failure Rate visible.

**Status as of 2026-09-12:** code and GitOps wiring for every row below has landed and merged; what's marked 🟡 is real, running infrastructure that hasn't yet had its specific end-to-end behavior (a blocked bad deploy, an exercised rollback, a real incident-correlated CFR number) live-observed. This table was previously stale (showed 🔴 across the board despite #1930-1933 having merged earlier) — see the linked PRs for the actual work.

| IDP Feature | Deliverable | Status |
|-------------|-------------|--------|
| CI/CD Orchestration | Quality gates block bad deploys | 🟡 `sonar.qualitygate.wait=true` merged (#2033); Tekton itself only just got wired onto the cluster (#2051 + `platform/bootstrap` re-apply) — no live pipeline run has yet proven a bad quality gate actually blocks promotion |
| Deployment Management | Argo Rollouts canary/blue-green | 🟡 Controller (#1930), `AnalysisTemplate` (#1931, query bug fixed in #2045), and tracer-bullet's `Rollout` conversion (tracer-bullet-gitops#6) are all merged; ApplicationSet wiring (#2049) applied live — `argo-rollouts`/`chaos-mesh` Applications now exist on-cluster. No live canary rollout has been triggered yet, so automated rollback is unverified |
| Observability | Alertmanager + crash-loop notifications | 🟢 Live since Phase 1 (`KubernetesPodCrashLooping` → `platform-team` Slack receiver). A second receiver routing the same alert to DevLake for Change Failure Rate correlation is merged (#2042) but not yet functional — no SealedSecret exists yet, and Alertmanager's own webhook payload shape doesn't match DevLake's `/issues` API without an adapter (tracked as its own issue, #2079, per Phase 4's epic-splitting rule) |
| Security | Shift-left SAST/DAST in pipeline | 🟡 SAST (SonarCloud gate) live via the row above. DAST (`dast-baseline-scan` OWASP ZAP task, #2048) is merged but standalone — not yet wired into a pipeline trigger path or run against a live target |
| DORA (3-key) | Add Change Failure Rate | 🔴 Schema design (#1944), Alertmanager receiver (#2042), and a deterministic BDD test for the formula (#1947) are merged, but no real CFR number is computing yet — #1919 (DevLake webhook wiring for the deployment side) hasn't been started, and the dashboard panel (#1946) is explicitly blocked pending real data |

**Key issues:** #1925 (verified, no fix needed), #1934 (#2033), #1937 (#2035), #1938 (python-fawkes-path#3), #1939 (#2037), #1940/#1941 (#2038), #1942 (blocked on live canary), #1944 (#2040), #1945 (#2042), #1946 (blocked, see above), #1947 (#2044)

**Remaining to fully close Phase 2:**
- Live-verify the quality gate actually blocks a bad deploy (needs a real pipeline run once Tekton is confirmed `Synced`/`Healthy`)
- Trigger a real canary rollout on tracer-bullet/python-fawkes-path and observe an automated rollback
- #1942 — wire chaos experiments into the canary traffic-shift step (depends on the above)
- #1919 — DevLake webhook plugin wiring for deployment signal (real prerequisite for CFR)
- #2079 — Build the Alertmanager→DevLake incident-payload adapter
- #1946 — add the real CFR dashboard panel once #1919 + the adapter produce real data

### Phase 3 — Production: Human-in-the-Loop (#1806)

**Goal:** Production deployment requires human approval through portal. Traffic split between versions. All 5 DORA metrics visible. Error-budget breach triggers automated rollback.

| IDP Feature | Deliverable | Status |
|-------------|-------------|--------|
| Self-Service Portal | Backstage with pipeline status, TechDocs | 🔴 Not started |
| Service Catalog | Backstage catalog for all services | 🔴 Not started |
| RBAC | Portal-gated production promotion | 🔴 Not started |
| Deployment Management | Production traffic routing | 🔴 Not started |
| DORA (5-key) | All metrics in one dashboard | 🔴 Not started |

**Key issues:** #1805, #1806, Backstage portal work

---

## Education Principles (Belt Levels)

Fawkes teaches platform engineering through a belt-level curriculum:

| Belt | Focus | DORA Capability |
|------|-------|-----------------|
| **White** | Basic CI/CD, Git fundamentals | Deployment Frequency |
| **Yellow** | Observability basics, structured logging | Lead Time for Changes |
| **Orange** | Security scanning, secrets management | Change Failure Rate |
| **Green** | Progressive delivery, chaos engineering | MTTR |
| **Blue** | Self-service portals, developer experience | Reliability |
| **Black** | Full platform ownership, DORA optimization | All 5 metrics |

Each belt maps to concrete issues and verification planes. See
`docs/golden-path-verification-planes.md` for the 7 verification planes:
Pipeline, GitOps, Observability, DORA, Security, Resources, DevEx.

---

## Open Issues by Phase

### Phase 1 — Alpha (Critical Path)

| # | Title | Priority | Agent? |
|---|-------|----------|--------|
| #1959 | ArgoCD repo-server/controller crash-looping | P0 | infra (cluster) |
| #1855 | DevLake GitHub GraphQL collector failing | P0 | infra (cluster) |
| #1569 | Terraform remote state backend | P0 | infra (credentials) |
| #1572 | Confirm DORA metrics queryable in Grafana | P0 | infra (cluster) |
| #1693 | rag-service Dockerfile missing scripts/ | P1 | ✅ PR #1998 |
| #1797 | Replace CHANGE_ME_* with Sealed Secrets | P1 | mimo ✅ |
| #1578 | Wire IRSA role ARN into python-fawkes-path | P1 | mimo ✅ |
| #1581 | Verify CI quality gates are green | P1 | mimo ✅ |
| #1842 | Replace platform-applications.yaml with ApplicationSet | P1 | mimo ✅ |
| #1573 | Refresh BACKLOG.md and PROJECT_STATUS.md | P1 | mimo ✅ |

### Phase 1 — Alpha (Important)

| # | Title | Priority | Agent? |
|---|-------|----------|--------|
| #1936 | BDD step definitions for quality gates | P1 | mimo ✅ |
| #1947 | BDD scenario for Change Failure Rate | P1 | mimo ✅ |
| #1944 | Design incident-to-deployment webhook payload | P1 | mimo ✅ |
| #1945 | Add Alertmanager webhook receiver for DevLake | P1 | infra (cluster) |
| #1946 | Add CFR panel to DORA Grafana dashboard | P1 | mimo ✅ |
| #1796 | BDD step-definition gap for 42 feature files | P1 | mimo ✅ |
| #1792 | Extend build→scan→sign→SBOM→GitOps to 14 services | P1 | mimo ✅ |

### Phase 1 — Alpha (Nice to Have)

| # | Title | Priority | Agent? |
|---|-------|----------|--------|
| #1948 | Document CFR methodology in docs/METRICS.md | P2 | mimo ✅ |
| #1943 | Write chaos-testing runbook | P2 | mimo ✅ |
| #1495 | Pre-commit hook for requirements pinning | P2 | mimo ✅ |
| #1496 | Weekly CI job for pip determinism | P2 | mimo ✅ |
| #1950 | Add scripts/validate-golden-path-devportal.sh | P2 | mimo ✅ |
| #1949 | Add pipeline-status card for Backstage | P2 | mimo ✅ |

### Phase 2 — Beta

| # | Title | Priority | Agent? |
|---|-------|----------|--------|
| #1925 | Verify gitops-promote step is Rollout-aware | P1 | mimo ✅ |
| #1934 | Re-enable sonar.qualitygate.wait=true | P1 | mimo ✅ |
| #1937 | Design ephemeral per-PR test environment | P1 | infra |
| #1938 | Add python-fawkes-path integration test suite | P1 | mimo ✅ |
| #1939 | Add Chaos Mesh controller ArgoCD Application | P1 | infra |
| #1940 | Write pod-kill chaos experiment manifest | P1 | mimo ✅ |
| #1941 | Write network-latency chaos experiment manifest | P1 | mimo ✅ |
| #1942 | Wire chaos experiments into canary traffic-shift | P2 | mimo ✅ |

### Phase 2/3 — Cross-cutting

| # | Title | Priority | Agent? |
|---|-------|----------|--------|
| #1715 | Upgrade design-system toolchain (storybook 7→10, vite 5→8) | P2 | mimo ✅ |
| #1735 | Upgrade kube-prometheus-stack 66→89 | P2 | infra |
| #1737 | Upgrade OpenSearch 2→3.8 | P2 | infra |
| #1680 | Consolidate to one DORA implementation | P2 | infra |
| #1856 | Tekton: set up tunnel for GitHub webhook | P1 | infra |
| #1858 | Tekton: exercise gitops-promote end-to-end | P1 | infra |
| #1661 | Tekton: validate Phase 1 deployment | P2 | mimo ✅ |
| #1922 | Move k8s dev off MacBook to multi-node pool | P2 | human |

### Not Phase-Scoped (Infrastructure / Ops)

| # | Title | Priority |
|---|-------|----------|
| #684 | Audit and purge secrets from Git history | P1 (human) |
| #1153 | Terraform remote state backend (Azure Blob) | P0 |
| #1156 | Wire gen_ai.* OTEL spans to Prometheus | P2 |

---

## Scoring System

| Field | Values | Meaning |
|-------|--------|---------|
| **V** (Value) | 1–5 | 5 = Phase blocker; 4 = high value; 3 = medium; 2 = nice-to-have; 1 = minimal |
| **E** (Effort) | XS / S / M / L / XL | XS < 2h; S = 2–4h; M = 4–8h; L = 1–2d; XL > 2d |
| **Score** | integer | `(V × 2) − effort_pts` where XS=1, S=2, M=3, L=4, XL=5. Higher = do first. |
| **Agent Ready** | Y / P / N | Y = fully specced; P = run `issue-writer` first; N = human-only |

---

## Agent Assignment Map

| Agent | Specialty | Example Issues |
|-------|-----------|----------------|
| `mimo` (opencode) | Python, YAML, docs, config edits, test writing | #1693, #1797, #1578, #1936, #1947 |
| `infra-gitops` | Terraform, Helm, ArgoCD, K8s manifests | #1153, #1842, #1939 |
| `test-engineer` | pytest, behave BDD, BATS, acceptance tests | #1581, #1936, #1947 |
| `docs-writer` | README, ADRs, runbooks, API docs | #1573, #1948, #1943 |
| **Human only** | Git history rewrite, cluster debugging, architecture decisions | #684, #1959, #1855 |

---

## Known Limitations

| ID | Description | Impact | Tracking |
|----|-------------|--------|----------|
| KL-01 | No Terraform remote backend | State corruption risk | #1153 |
| KL-02 | Weaviate required for RAG (no local fallback) | RAG service can't run locally | — |
| KL-03 | Focalboard integration degraded | DORA CFR incomplete | Post-MVP |
| KL-04 | Azure module duplication | Maintenance burden | — |
| KL-05 | 45 BDD features with no step definitions | False test coverage | #1796 |
| KL-06 | DevLake ArgoCD plugin manual config | DORA breaks after reinstall | — |
| KL-10 | SonarCloud default branch mismatch | Quality gate can't wait | #1934 |

See `docs/KNOWN_LIMITATIONS.md` for full details.

---

## How to Use This Document

1. **Pick the top-scored issue from the current phase** that is `Agent Ready = Y`.
2. **Check cluster state** — P0 issues require cluster access; P1/P2 may be mimo-compatible.
3. **For `Agent Ready = P` issues**, run `issue-writer` first to expand the issue body.
4. **After completion**, update issue status and move to the next.
5. **Update this document** after each phase completes.

---

_Maintained by `@docs-agent`. Update after each sprint or triage session._
_Score formula: `(V × 2) − effort_points` where effort_points: XS=1, S=2, M=3, L=4, XL=5_
