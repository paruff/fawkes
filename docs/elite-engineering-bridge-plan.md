# Implementation Plan: Bridging Fawkes to "0.1% Engineer" Quality

> Saved 2026-09-12. Produced via `/plan` in response to the question "what
> would a top 0.1% engineer/architect think of Fawkes as a product?" after an
> extensive live-verification session. See that critique's full text in the
> session transcript; this plan operationalizes it.

## Requirements Restatement

The critique boiled down to four systemic gaps, not feature gaps:
1. **"Documented as done" ≠ "actually working"** — no enforced verification loop
2. **The backlog doesn't reflect reality** — hand-maintained status, drifts in both directions
3. **Infrastructure identity crisis** — which cluster is canonical, self-healing bootstrap gaps, resource ceilings nobody's reconciled
4. **Scope ambition outruns verification capacity** — phases sized for a quarter, tracked like a sprint

This plan closes those four gaps directly. It's process and tooling work, not new features — the kind of thing that changes how a 0.1% engineer reads the *next* six months of this repo's history, not just today's snapshot.

## Pattern Grounding

| Category | Source | Pattern to mirror / extend |
|---|---|---|
| Verification scripts already exist | `scripts/validate-golden-path-*.sh` (8 files) | These already do real live checks — they're just not wired to anything automatically. Extend, don't rebuild. |
| CI health gating | `.github/workflows/` "Main CI Gate" (found while debugging fawkes PR #2049) | Already has a pattern for "block on upstream health" — same idea can gate backlog claims |
| DORA self-measurement | `docs/METRICS.md`'s rework-rate tracking, `scripts/weekly-metrics.sh` | Fawkes already tracks itself for one metric — the pattern exists, just isn't applied to phase-completion claims |
| Known-limitation discipline | `docs/KNOWN_LIMITATIONS.md` | Good existing convention for "documented, not hidden" — extend to infra drift, not just feature bugs |
| ArgoCD bootstrap | `platform/bootstrap/*.yaml` + `scripts/lib/argocd.sh` | The self-apply mechanism exists but isn't itself GitOps-managed (chicken-and-egg) — needs its own closing loop |

## Implementation Phases

### Phase 1 — Make "done" mean "verified," automatically

**Goal:** No backlog cell can claim 🟢 without a machine having checked it recently.

1. Wire the 8 existing `scripts/validate-golden-path-*.sh` scripts into a scheduled GitHub Actions workflow (nightly + on-demand `workflow_dispatch`) that runs against whichever cluster is currently live, and posts a structured summary (pass/fail per plane) as a workflow artifact and a PR-visible check
2. Add a `docs/PLATFORM_STATUS.md` (or a `status.json` consumed by a small script) that's **generated from that workflow's output**, not hand-typed — this becomes the single source of truth `BACKLOG.md` links to instead of duplicating
3. Retrofit `BACKLOG.md`'s status cells to link to the last verification run's timestamp/result rather than carrying a static emoji a human has to remember to update
4. Add a lightweight pre-merge check: any PR claiming to close a Phase-N acceptance-criterion issue must link to a passing verification run, enforced by a simple GitHub Actions check parsing the PR body for the issue reference + a green run link (soft-enforce first — warn, don't block — then tighten once the habit sticks)

**Why this first:** every other gap in this plan is downstream of not having this. Fixing it stops new drift from accumulating while the rest of the plan executes.

### Phase 2 — Reconcile the backlog with reality once, then keep it honest

1. Run a full audit pass (already done for Phase 2 this session — see `docs/phase-2-closure-plan.md` and the `docs/BACKLOG.md` update) across every other phase, not just Phase 2 — Phase 1 and Phase 3 likely have the same "claimed vs. real" gap
2. For every 🟢/✅ claim in `BACKLOG.md`, attach either a link to Phase 1's new verification run, or downgrade it honestly if nothing currently proves it
3. Close or re-scope stale issues found to be already-done-but-untracked (the #1842 pattern found this session) and already-blocked-but-marked-active issues
4. Adopt a rule going forward (add to `AGENTS.md` §9 or §11): **no phase-completion claim in `BACKLOG.md` without a linked verification artifact** — this is the actual fix for "the team doesn't trust its own dashboard"

### Phase 3 — Resolve the infrastructure identity crisis

1. **Decide, explicitly, in a short ADR**: is the golden path's canonical proving ground the LAN k3s cluster, a local kind cluster, or Azure AKS? This session found evidence of all three being used at different points with no reconciliation — that ambiguity alone would fail a due-diligence review
2. Fix the concrete blockers found this session as part of that decision:
   - Azure subscription's 10-vCPU regional cap blocking the recommended D4s_v5 migration (needs a quota-increase request, tracked as its own issue with the request already drafted)
   - The ArgoCD bootstrap chicken-and-egg problem: `platform/bootstrap/*.yaml` changes require a manual `kubectl apply -k platform/bootstrap` and don't self-heal from git — either accept this explicitly as a documented one-time bootstrap step (with a runbook), or wrap it in a periodic reconciliation job that diffs live ApplicationSets against git and alerts on drift
   - `devlake-lake`'s `CreateContainerConfigError` — small, concrete, blocks Phase 2's DORA work entirely, fix it first before building on top
3. Document the decision and the current real state (not aspirational state) in `docs/ARCHITECTURE.md`'s cluster-topology section

### Phase 4 — Right-size the phases

1. Split Phase 2's epic (#1805) acceptance criteria into independently-completable, independently-verifiable issues where they aren't already (the chaos-in-canary and Alertmanager-adapter items from `docs/phase-2-closure-plan.md` are exactly this problem — each is a quarter of a sprint's own novel design work, not a checklist line)
2. Adopt an explicit WIP limit or phase-gate rule: a new phase doesn't open until the previous one's Phase-1-verification-loop (above) shows genuinely green, not "PRs merged"
3. Add the estimated-complexity/risk table (like the one in `docs/phase-2-closure-plan.md`) as a required section of every epic issue going forward, so "quarter's worth of work tracked as a sprint" becomes visible before it happens, not after

### Phase 5 — Make the platform prove itself on itself (the highest-leverage, most "0.1%" move available)

1. Wire Fawkes's own repo through its own golden path concept: track *fawkes-the-repo's* deployment frequency, lead time, and change failure rate using the same DORA pipeline it's building for tenant services — `docs/METRICS.md`'s rework-rate tracking is already halfway there
2. Publish this as a real, live Grafana dashboard (not a doc) that's linked from the README — this is the single artifact that would most directly answer a skeptical 0.1% engineer's question, because it's not a claim, it's the platform demonstrating its own thesis in real time
3. This also directly produces the "verification culture" evidence the rest of this plan builds toward — it's the capstone, not a separate initiative

## Dependencies

```
Phase 1 (verification loop) ─────┬─→ Phase 2 (backlog reconciliation)
                                  ├─→ Phase 4 (right-size phases, needs real signal)
                                  └─→ Phase 5 (self-measurement, needs Phase 1's plumbing)
Phase 3 (infra identity) ────────────→ Phase 1 (verification runs need a stable target cluster)
```

Phase 3 should actually run in parallel with or slightly before Phase 1 — the verification workflow needs to know which cluster to check.

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Verification workflow becomes noisy/flaky (transient cluster issues) and gets ignored, recreating the original problem | Medium-High | Start advisory (Phase 1.4's soft-enforce), tighten only once signal is trustworthy |
| The ADR in Phase 3 surfaces that the "right" cluster isn't actually provisioned/funded yet | Medium | Better to know this now than after more work is built on an ambiguous foundation |
| Phase 4's right-sizing feels like process overhead to a small team | Medium | Frame as "the estimated-complexity table already exists in `docs/phase-2-closure-plan.md` — just make it mandatory," not a new invention |
| Phase 5 is genuinely novel work with no existing pattern (self-referential DORA) | Medium | Lowest-risk version: start by just exposing fawkes-repo's own PR-merge-to-deploy timestamps as a Prometheus metric via the existing recording-rule mechanism, don't over-build |

## Complexity Estimate

- **Phase 1:** Medium — mostly wiring existing scripts, not new logic
- **Phase 2:** Medium — time-consuming audit work, low technical risk
- **Phase 3:** Medium-High — one real architectural decision, several small concrete fixes
- **Phase 4:** Low — process/documentation change
- **Phase 5:** Medium-High — genuinely new, but high leverage; can be scoped down to an MVP easily

**This is the actual highest-value work available right now** — more so than any single remaining Phase 2 feature — because it's what determines whether the *next* six months of this repo produce the same "looks done, isn't" pattern found repeatedly this session, or whether it stops recurring.

## Acceptance

- [x] Phase 1: verification workflow live, `BACKLOG.md` linked to real run results — `.github/workflows/golden-path-verification.yml` live, first run [34715862843](https://github.com/paruff/fawkes/actions/runs/34715862843), `docs/PLATFORM_STATUS.md` on the `platform-status` branch
- [x] Phase 2: full backlog audit complete, stale claims corrected — #2075 (15 stale closed-issue entries removed)
- [x] Phase 3: ADR written, concrete infra blockers resolved — cluster-topology ADR (#2070); Azure scheduling fix #2073 (works around the vCPU quota cap rather than requesting an increase); `devlake-lake` confirmed healthy and bootstrap chicken-and-egg documented (#2078, `KL-14`). New blocker found while verifying this: DevLake's own API is down pending an unapproved migration (`KL-15`) — a human decision, not resolved here
- [x] Phase 4: epic-sizing rule adopted, applied to at least the next new phase — rule + template requirement (#2074), applied by splitting the untracked Alertmanager-adapter step into #2079 (#2080)
- [ ] Phase 5: fawkes-on-fawkes DORA dashboard live and linked from README — scoped and filed as #2081, blocked on `KL-15` (DevLake API down) before it can start
