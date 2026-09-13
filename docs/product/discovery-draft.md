# Discovery Draft: Fawkes-on-Fawkes DORA Self-Measurement

> Tracks `docs/elite-engineering-bridge-plan.md` Phase 5 / issue #2081. This is the current live discovery-in-progress example for this repo — not a hypothetical template.

## Job to Be Done

When a skeptical platform engineer is deciding whether to trust Fawkes's DORA claims, they want to see the platform measuring *its own* delivery performance the same way it measures a tenant service's — so they can judge the platform by evidence, not by the same "documented as done" claims `docs/elite-engineering-bridge-plan.md` exists to stop making.

## Riskiest Assumption

That DevLake's standard GitHub `releases` collection can compute Deployment Frequency and Lead Time for a meta-repo with **no Kubernetes deployment target**, without hitting the same gap that blocked `tracer-bullet`: DevLake's `dora` plugin needs `cicd_tasks` rows with `type='Deployment'`, which are normally populated by converting GitHub Actions workflow-run data — not GitHub Releases (`docs/KNOWN_LIMITATIONS.md` KL-12). This repo doesn't run its CI on GitHub Actions workflow-runs in that shape either (it uses `release-please`-style automated release commits), so whether "a merged release" maps cleanly onto what DevLake's `dora` plugin expects is genuinely unverified — the assumption could fail exactly the way KL-12 did.

## Acceptance Criterion (measurable)

Once DevLake is queryable again (blocked on `docs/KNOWN_LIMITATIONS.md` KL-15) and `paruff/fawkes` is registered as a tracked project: a direct query against `devlake-mysql`'s `cicd_tasks` table shows at least one real row with `type='Deployment'` corresponding to an actual `chore(main): release` commit on `main` — not a fabricated row, not a docs claim.

## Test-Type Reasoning

This cannot be meaningfully unit-tested — a mock of DevLake's collection behavior would only assert what we already assume, not verify DevLake's actual plugin logic against real GitHub Releases data. It requires a live verification step (the same reasoning that resolved KL-12 for tracer-bullet): register the project, trigger a real collection pipeline, and directly query the resulting table. If it fails the same way KL-12 did, that's the answer, documented the same way — not a reason to fabricate a workaround.

## How This Connects

| Tier | File |
|---|---|
| Requirements derived from this draft | [spec.md](spec.md) |
| Backlog item this discovery serves | `EXECUTION_QUEUE.md` P2, issue #2081 |
