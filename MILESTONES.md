# Fawkes — Milestones

> **Horizon:** Months | **Owner:** @paruff | **Review cadence:** After each phase-completion claim, and monthly otherwise

## How Horizons Map

Fawkes already has a concrete 3-phase delivery model (`docs/BACKLOG.md`) — this file adopts it directly as the H1/H2/H3 horizon map rather than inventing a parallel one:

| Horizon | Phase | Epic | Goal |
|---|---|---|---|
| **H1 (now)** | Phase 1 — Alpha: Commit-to-Staging | #1804, #1808 | Push to `main` → Tekton build → scan → sign → SBOM → GHCR push → GitOps PR → ArgoCD sync → basic observability, live-verified |
| **H2** | Phase 2 — Beta: Shift-Left Security | #1805 | Failing quality gates block promotion; canary with automated rollback; chaos on staging; Change Failure Rate visible |
| **H3** | Phase 3 — Production: Human-in-the-Loop | #1806 | Production requires portal-gated human approval; traffic-split releases; all 5 DORA keys; error-budget-triggered rollback |

## Milestones

### H1 — Phase 1 (Alpha)

| Deliverable | Status | Evidence / Issue |
|---|---|---|
| Tekton build → scan → sign → SBOM → GHCR push | ✅ Live | `platform/apps/tekton/golden-path-pipeline.yaml` |
| GitOps PR + auto-merge → ArgoCD sync | ✅ Live | `gitops-promote` task |
| OTel collector + Prometheus + Grafana | ✅ Live | — |
| DORA 2-key (Deployment Frequency, Lead Time) in Grafana via native PromQL | 🟡 Needs verification | #1572 |
| Terraform remote state backend | 🔴 Open | #1569 |
| DevLake GitHub GraphQL collector | 🟡 Fixed, but DevLake itself now blocked on a DB migration | #1855, `docs/KNOWN_LIMITATIONS.md` KL-15 |
| Sealed Secrets replacing `CHANGE_ME_*` | 🔴 Open | #1797 |
| IRSA role ARN wired into python-fawkes-path | 🔴 Open | #1578 |
| CI quality gates verified green | 🔴 Open | #1581 |

**Planes required this phase** (per `docs/golden-path-verification-planes.md`; "Alpha" here is the platform-maturity phase, not a golden path's `alpha` environment tier): Pipeline, GitOps, Observability, DORA (2-key: deployment frequency, lead time).

### H2 — Phase 2 (Beta)

**Status:** DORA is done (exceeded — all 5 keys live via native PromQL, not the 3-key target below). What's open: quality-gate/canary live-verification (unblocked, not new construction) and DevEx (not started) — see `docs/phase-2-closure-plan.md`.

| Deliverable | Status | Evidence / Issue |
|---|---|---|
| Quality gate blocks a bad deploy | 🟡 Merged, unverified live | needs a real bad-commit pipeline run — recommended next goal, see `EXECUTION_QUEUE.md` P0 |
| Canary/blue-green with automated rollback | 🟡 Merged, unverified live | needs a real triggered rollback |
| Chaos wired into canary traffic-shift | 🔴 Open, highest-complexity item in this phase | #1942 |
| Deployment Frequency, Lead Time, CFR, MTTR (native PromQL) | 🟢 **Done 2026-09-17**, superseding the DevLake-based rows this table previously listed here | `platform/apps/prometheus/rules/dora.yml`, ADR-038 |
| Rework Rate (5th key, beyond this phase's original 3-key scope) | 🟢 **Done 2026-09-17** — definition resolved, GitHub-derived implementation live | `scripts/weekly-metrics.sh`, `docs/METRICS.md`, ADR-038 |
| CFR panel on DORA dashboard | 🟡 Data is live, panel not yet wired — small, unblocked | #1946 |

**Planes required this phase**: Security (core — quality gates actually block a bad deploy), Progressive Delivery (canary/blue-green with rollback, chaos wired into the traffic-shift step), DORA (+CFR = 3-key, **exceeded 2026-09-17 — all 5 keys live**). DevEx (basic: `catalog-info.yaml` exists, Backstage deployed, component registered in its live catalog) — added 2026-09-16. Rationale: Beta is when the platform needs to be genuinely usable by other developers, not just a pipeline proof-of-concept, so basic discoverability belongs here rather than waiting for Production's deeper DevEx (self-service portal, RBAC-gated approval). **DevEx is 🔴 not started** — `fawkes.io/golden-path` annotations were added to the 3 golden-path templates 2026-09-16 as prep, but Backstage itself isn't deployed and no component is registered in a live catalog yet.

### H3 — Phase 3 (Production)

All 🔴 not started — correctly so, this is the next horizon, not a current gap:

| Deliverable | Status |
|---|---|
| Backstage self-service portal + catalog | 🔴 Not started |
| RBAC-gated production promotion | 🔴 Not started |
| Production traffic routing | 🔴 Not started |
| All 5 DORA keys in one dashboard | 🔴 Not started |

**Planes required this phase**: DevEx (deep — self-service portal, RBAC-gated approval, beyond Beta's basic catalog registration), Progressive Delivery (deepened — production traffic routing), DORA (all 5 keys), Security (deepened — the four "planned additions" already listed in `docs/golden-path-verification-planes.md`: secrets management enforcement, policy enforcement, code analysis, network-based security), Resources (production-grade — CPU/memory limits enforced with real usage data, PVCs Bound, backing database healthy under production load).

## Release Gates

What must be true before any change ships to `main`, per `AGENTS.md` §9 and `docs/RELEASE.md`:

- [ ] `reusable-main-ci-guard.yml@v1.2.0` passes (the shared CI gate every PR targeting `main` must pass)
- [ ] Commit messages pass Conventional Commits lint (`ci-commit-lint.yml`), every commit in the PR — not just the title
- [ ] Tests for the touched layer pass locally and in CI (§7 language-specific checks: `pytest`/`ruff`/`black` for Python, `tflint`/`terraform validate`/`tfsec` for Terraform, `helm lint` for charts)
- [ ] `CHANGELOG.md`'s `[Unreleased]` section is current (semi-automated via `chore(main): release` commits, per `docs/RELEASE.md`)
- [ ] A version tag is cut and a GitHub Release published (automated)
- [ ] For anything the golden-path-verification workflow covers: a passing run is linked, not just "PRs merged" (`AGENTS.md` §9's phase-gate rule, `docs/elite-engineering-bridge-plan.md` Phase 1)
- [ ] Post-deployment verification + auto-rollback: **not yet built** — a documented gap, not silently skipped (`AGENTS.md` §9)

## Traceability — Milestone → Vision Principle

| Milestone area | `VISION.md` principle |
|---|---|
| Build→scan→sign→SBOM, quality gates | Security is non-negotiable |
| DORA 2-key / 3-key / 5-key rollout | Measure everything |
| Canary/blue-green, chaos engineering | Security is non-negotiable + Measure everything (failure must be observable, not just prevented) |
| Backstage self-service portal | Developer experience is paramount + Opinionated but extensible |
| RBAC-gated production promotion | Security is non-negotiable |
| Multi-cloud (AWS/Azure now, GCP deferred) | Multi-cloud from day one |
| Dojo/belt-level curriculum tie-in per phase | Learn while building |
| Tekton-first CI/CD (Jenkins retired) | Tekton-first CI/CD |
| 17 Python services → 2 domain monoliths | Opinionated but extensible |

## How This Connects

| Tier | File | What it answers |
|---|---|---|
| ↑ Years | [VISION.md](VISION.md) | Why does any of this matter, and what won't we build? |
| ↓ Weeks | [EXECUTION_QUEUE.md](EXECUTION_QUEUE.md) | What's actually being worked on this sprint, in priority order? |
| Reality check | [docs/BACKLOG.md](docs/BACKLOG.md) | The full triaged issue-level backlog this file's milestones are drawn from |
| Reality check | `platform-status` branch's [PLATFORM_STATUS.md](https://github.com/paruff/fawkes/blob/platform-status/docs/PLATFORM_STATUS.md) | Machine-generated: is any of this *actually* verified live right now? |
