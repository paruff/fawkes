# Fawkes — Plan for the Day

> **Horizon:** Today (2026-09-13) | **Owner:** @paruff | **Review cadence:** Rewritten at the start of every work session

## Primary Goal

Close out Phase 1's last two unverified P0 items (Terraform remote state, DORA queryability) so Phase 1 (Alpha) can honestly move from "mostly done" to "verified done" — per `MILESTONES.md`'s H1 row and the phase-gate rule in `AGENTS.md` §9.

The DevLake migration blocker (`docs/KNOWN_LIMITATIONS.md` KL-15) is tracked in parallel but is **not** today's primary goal — it needs direct human action on the cluster (see `EXECUTION_QUEUE.md` P0), not agent execution.

## Target Issues (pulled from `EXECUTION_QUEUE.md` P0/P1)

1. **#1569** — Activate the real Terraform S3+DynamoDB (or Azure Blob) remote state backend
2. **#1572** — Confirm DORA deployment-frequency/lead-time metrics are actually queryable in Grafana
3. **#1581** — Verify CI quality gates are green repo-wide
4. **#1797** — Replace `CHANGE_ME_*` placeholder credentials with Sealed Secrets (pick up if 1-3 finish early)

## TDD Execution Protocol (per `AGENTS.md` §2)

For each issue above, before writing implementation/config:

1. **State the goal as a verifiable check** — for #1569, that's a `terraform plan` showing the backend block active and a real lock-table write/read; for #1572, that's a specific PromQL/Grafana query returning non-empty data; for #1581, that's the actual CI run link, not "should be green."
2. **Run it and confirm it fails for the right reason** (red) — e.g. #1569's plan should currently show local-only state, not an unrelated provider auth error.
3. **Make the minimum change to pass** (green) — don't refactor unrelated Terraform modules or Grafana dashboards while doing this.
4. **Re-run the same check** to confirm green, and link the run/output as evidence in the PR — no phase-completion claim without a linked artifact.
5. **Refactor only if the green state is stable** — not before.

## Retrospective

_Fill in at the end of the session._

**What actually got done:**
- _(fill in)_

**What surprised us (feeds `EXECUTION_QUEUE.md`'s bottom-up feedback):**
- _(fill in)_

**Backlog deltas** (new P0/P1 items found, items that turned out mis-sized, items to close as already-done)
- _(fill in)_

**Carry over to tomorrow:**
- _(fill in)_

## How This Connects

| Tier | File | What it answers |
|---|---|---|
| ↑ Weeks | [EXECUTION_QUEUE.md](EXECUTION_QUEUE.md) | Why these issues, and what's next after today? |
