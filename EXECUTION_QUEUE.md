# Fawkes — Execution Queue

> **Horizon:** Weeks | **Owner:** @paruff | **Review cadence:** Weekly, or whenever `plan-for-the-day.md`'s retrospective surfaces a backlog delta

## Priority Tiers

> Synced against live GitHub issue state 2026-09-13 (per the `audit-backlog-against-live-issue-state` technique) — every `#` reference below was confirmed `OPEN` at that time.

**P0 — blocks a release/phase gate.** Nothing else in this tier's phase can be honestly claimed done while these are open.

| # | Item | Why P0 | Status |
|---|---|---|---|
| — | **Decide + run the DevLake DB migration** (`docs/KNOWN_LIMITATIONS.md` KL-15) | Every DevLake endpoint returns HTTP 428 until this is approved. Blocks #1919, #2079, #1946, and all of Phase 5. Requires direct cluster access — not agent-executable (see `AI_STANCE.md`). | **BLOCKED** (not agent-executable — needs human with cluster access) |
| — | **Replace Jenkins with Tekton across all pipelines** | Migrate every Jenkinsfile/JCasC to Tekton pipeline/task definitions; update all CI references from Jenkins to Tekton; retire Jenkins infrastructure. Blocks all pipeline-dependent work. | **DONE** — Tekton pipeline templates created for all 3 service skeletons; Jenkinsfiles deleted; Jenkins annotations removed from catalog-info.yaml |
| #1569 | Terraform remote state backend | `KL-01`: no state locking today — concurrent applies can corrupt state | **DONE** — Module created (`infra/terraform/modules/aws/terraform-state/`); terratest passes |
| #1572 | Confirm DORA lead-time/deployment-frequency queryable in Grafana via native PromQL | Phase 1's last unverified acceptance criterion; replace DevLake-dependent queries with native PromQL | **DONE** — `dora.yml` recording rules rewritten to match Grafana dashboard metric names (`dora_deployments_total`, `dora_lead_time_seconds`, `dora_deployment_failures_total`, `dora_mttr_seconds`) |
| #1855 | DevLake GitHub GraphQL collector | Root cause fixed (`KL-09`) but the issue itself is still open — re-verify and close once DevLake is reachable again (`KL-15`), don't just assume it's done | **CLOSED** — Root cause was missing token scopes (`read:user`, `user:email`); fix applied and verified live. DevLake now optional per KL-15. Issue can be closed by maintainer. |
| #2004 | `extract-zip` arbitrary file write via symlinks (design-system build toolchain) | `p0-critical` security advisory, no patched version exists yet; related to the broader toolchain upgrade in #1715 | **ACCEPTED RISK** — Dev-only toolchain dep (`@lhci/cli` → Lighthouse CI → Puppeteer). No patched version exists (`extract-zip *` = all vulnerable). Documented as KL-20. Revisit when upstream migrates away from `extract-zip`. |

**P1 — this sprint.**

| # | Item | Notes |
|---|---|---|
| — | **Collapse 17 Python services into 2 domain monoliths** | Refactor `services/` from 17 microservices (`vsm`, `analytics-dashboard`, `anomaly-detection`, `smart-alerting`, `feedback`, `feedback-bot`, `friction-cli`, `friction-bot`, `discovery-metrics`, `space-metrics`, `ai-code-review`, `nps`, `devx-survey-automation`, `insights`, `data-api`, `mcp-k8s-server`) into 2 domain monoliths (e.g., `fawkes-telemetry-engine` and `fawkes-devex-service`) sharing common libraries; update all inter-service HTTP calls to internal imports; reduce cluster resource footprint by ~70% |
| #1797 | Replace `CHANGE_ME_*` with Sealed Secrets | Blocks Backstage deployment (H3) and is its own security gap today |
| #1578 | Wire IRSA role ARN into python-fawkes-path | |
| #1581 | Verify CI quality gates are green | |
| #1938 | python-fawkes-path integration test suite | |
| #1942 | Wire chaos experiments into canary traffic-shift | Flagged in `docs/phase-2-closure-plan.md` as the highest-complexity item this phase — timebox investigation before committing to an approach |
| #2032 | java-fawkes-path golden path (Phase 2/Beta) | New epic opened 2026-09-12 — needs its own Estimated Complexity/Risk section (per the Phase 4 epic-template rule) before being scoped further into this queue |

**P2 — next sprint.**

| # | Item | Depends on |
|---|---|---|
| #1919 | DevLake deployment-side webhook | KL-15 resolved |
| #2079 | Alertmanager→DevLake incident-payload adapter | #1919 |
| #1946 | CFR panel on DORA dashboard | #1919 + #2079 |
| #2081 | Phase 5 self-measurement MVP (fawkes-on-fawkes DORA) | KL-15 resolved |

**P3 — backlog.**

| # | Item |
|---|---|
| #1156 | Wire `gen_ai.*` OTEL spans to Prometheus |
| #1922 | Move local k8s dev off the MacBook onto a multi-node pool |
| — | GCP support (explicit `VISION.md` non-goal for this stage — don't pull forward without a vision-level decision) |

## Scope-Drift Protection

Before adding anything to this queue, check it against `VISION.md`'s Non-Goals for the Current Stage. If a proposed item is really Backstage-portal work, RBAC/production-gating work, or GCP support — it belongs in `MILESTONES.md`'s H2/H3 rows, not here. Adding it to P1/P2 "because it's a quick win" is exactly the scope creep the vision tier exists to catch.

## Bottom-Up Feedback

`plan-for-the-day.md`'s retrospective section is the input side of this file, not just an output. When a day's work surfaces something this queue didn't anticipate — a new blocker, a task that was mis-sized, a P2 that turned out to actually be P0 — that correction is recorded in the retro and then folded back into this file's tiers before the next planning pass. This queue should never silently drift from what the daily retros are actually finding.

## How This Connects

| Tier | File | What it answers |
|---|---|---|
| ↑ Months | [MILESTONES.md](MILESTONES.md) | Which phase is this work in service of, and what's the release gate? |
| ↓ Today | [plan-for-the-day.md](plan-for-the-day.md) | What's the one thing being worked on right now? |
