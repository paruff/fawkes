# Fawkes — Milestones

> **Horizon:** Months | **Owner:** @paruff | **Review cadence:** After each phase-completion claim, and monthly otherwise

## How Horizons Map

Fawkes already has a concrete 3-phase delivery model (`docs/BACKLOG.md`) — this file adopts it directly as the H1/H2/H3 horizon map rather than inventing a parallel one:

| Horizon | Phase | Epic | Goal |
|---|---|---|---|
| **H1 (now)** | Phase 1 — Alpha: Commit-to-Staging | #1804, #1808 | Push to `main` → build → scan → sign → GitOps PR → ArgoCD sync → basic observability, live-verified |
| **H2** | Phase 2 — Beta: Shift-Left Security | #1805 | Failing quality gates block promotion; canary/blue-green with automated rollback; chaos on staging; Change Failure Rate visible |
| **H3** | Phase 3 — Production: Human-in-the-Loop | #1806 | Production requires portal-gated human approval; traffic-split releases; all 5 DORA keys; error-budget-triggered rollback |

## Milestones

### H1 — Phase 1 (Alpha)

| Deliverable | Status | Evidence / Issue |
|---|---|---|
| Build → scan → sign → SBOM → GHCR push | ✅ Live | `platform/apps/tekton/golden-path-pipeline.yaml` |
| GitOps PR + auto-merge → ArgoCD sync | ✅ Live | `gitops-promote` task |
| OTel collector + Prometheus + Grafana | ✅ Live | — |
| DORA 2-key (Deployment Frequency, Lead Time) in Grafana | 🟡 Needs verification | #1572 |
| Terraform remote state backend | 🔴 Open | #1569 |
| DevLake GitHub GraphQL collector | 🟡 Fixed, but DevLake itself now blocked on a DB migration | #1855, `docs/KNOWN_LIMITATIONS.md` KL-15 |
| Sealed Secrets replacing `CHANGE_ME_*` | 🔴 Open | #1797 |
| IRSA role ARN wired into python-fawkes-path | 🔴 Open | #1578 |
| CI quality gates verified green | 🔴 Open | #1581 |

### H2 — Phase 2 (Beta)

**Status:** code/GitOps wiring for every row is merged; what's open is *live end-to-end verification*, not new construction — see `docs/phase-2-closure-plan.md`.

| Deliverable | Status | Evidence / Issue |
|---|---|---|
| Quality gate blocks a bad deploy | 🟡 Merged, unverified live | needs a real bad-commit pipeline run |
| Canary/blue-green with automated rollback | 🟡 Merged, unverified live | needs a real triggered rollback |
| Chaos wired into canary traffic-shift | 🔴 Open, highest-complexity item in this phase | #1942 |
| DevLake deployment-side webhook | 🔴 Open, blocked on `KL-15` | #1919 |
| Alertmanager→DevLake incident-payload adapter | 🔴 Open, blocked on `KL-15` | #2079 |
| CFR panel on DORA dashboard | 🔴 Open, blocked on the two rows above | #1946 |

### H3 — Phase 3 (Production)

All 🔴 not started — correctly so, this is the next horizon, not a current gap:

| Deliverable | Status |
|---|---|
| Backstage self-service portal + catalog | 🔴 Not started |
| RBAC-gated production promotion | 🔴 Not started |
| Production traffic routing | 🔴 Not started |
| All 5 DORA keys in one dashboard | 🔴 Not started |

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

## How This Connects

| Tier | File | What it answers |
|---|---|---|
| ↑ Years | [VISION.md](VISION.md) | Why does any of this matter, and what won't we build? |
| ↓ Weeks | [EXECUTION_QUEUE.md](EXECUTION_QUEUE.md) | What's actually being worked on this sprint, in priority order? |
| Reality check | [docs/BACKLOG.md](docs/BACKLOG.md) | The full triaged issue-level backlog this file's milestones are drawn from |
| Reality check | `platform-status` branch's [PLATFORM_STATUS.md](https://github.com/paruff/fawkes/blob/platform-status/docs/PLATFORM_STATUS.md) | Machine-generated: is any of this *actually* verified live right now? |
