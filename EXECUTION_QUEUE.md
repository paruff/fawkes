# Fawkes — Execution Queue

> **Horizon:** Weeks | **Owner:** @paruff | **Review cadence:** Weekly, or whenever `plan-for-the-day.md`'s retrospective surfaces a backlog delta

## Priority Tiers

> Synced against live GitHub issue state 2026-09-16 (per the `audit-backlog-against-live-issue-state` technique). The 2026-09-13 sync predated PRs #2091, #2112, #2114 (merged 9/14-9/16); this pass re-verified every row against current GitHub state and repo contents rather than trusting those PRs' own claims.

**P0 — blocks a release/phase gate.** Nothing else in this tier's phase can be honestly claimed done while these are open.

| # | Item | Why P0 | Status |
|---|---|---|---|
| — | **Decide + run the DevLake DB migration** (`docs/KNOWN_LIMITATIONS.md` KL-15) | Every DevLake endpoint returns HTTP 428 until this is approved. Blocks #1919, #2079, #1946, and all of Phase 5. Requires direct cluster access — not agent-executable (see `AI_STANCE.md`). | **BLOCKED** (not agent-executable — needs human with cluster access) |
| — | **Replace Jenkins with Tekton across all pipelines** | Migrate every Jenkinsfile/JCasC to Tekton pipeline/task definitions; update all CI references from Jenkins to Tekton; retire Jenkins infrastructure. Blocks all pipeline-dependent work. | **DONE** (2026-09-16) — Tekton pipeline templates for all 3 service skeletons; `services/samples/*/Jenkinsfile` deleted; `jenkins` Backstage Component and `jenkins.io/job-full-name` annotations removed from all 3 `catalog-info.yaml` files. A stale local branch (`chore/remove-jenkins-integrations-and-docs`, unpushed) predates #2114 and deletes unrelated test files — not merged, not usable. |
| #1569 | Terraform remote state backend | `KL-01`: no state locking today — concurrent applies can corrupt state | **DONE** — Module created (`infra/terraform/modules/aws/terraform-state/`); terratest passes (not independently re-run this pass) |
| #1572 | Confirm DORA lead-time/deployment-frequency queryable in Grafana via native PromQL | Phase 1's last unverified acceptance criterion; replace DevLake-dependent queries with native PromQL | **DONE** — `dora.yml` recording rules rewritten to match Grafana dashboard metric names (`dora_deployments_total`, `dora_lead_time_seconds`, `dora_deployment_failures_total`, `dora_mttr_seconds`); not independently re-verified live in Grafana this pass |
| #1855 | DevLake GitHub GraphQL collector | Root cause fixed (`KL-09`) but the issue itself is still open — re-verify and close once DevLake is reachable again (`KL-15`), don't just assume it's done | **CLOSED** (2026-09-16) — Root cause was missing token scopes (`read:user`, `user:email`); fix applied and verified live. DevLake now optional per KL-15. Previously marked CLOSED here while still open on GitHub — actually closed now. |
| #2004 | `extract-zip` arbitrary file write via symlinks (design-system build toolchain) | `p0-critical` security advisory, no patched version exists yet; related to the broader toolchain upgrade in #1715 | **ACCEPTED RISK** — Dev-only toolchain dep (`@lhci/cli` → Lighthouse CI → Puppeteer). No patched version exists (`extract-zip *` = all vulnerable). Documented as KL-20. Revisit when upstream migrates away from `extract-zip`. |

**P1 — this sprint.**

| # | Item | Notes |
|---|---|---|
| — | **Collapse 17 Python services into 2 domain monoliths** | **0% done in code.** `services/` on `main` still has all 18 original dirs; no `fawkes-telemetry-engine`/`fawkes-devex-service` exist on any branch. Local dirs with those names exist only as untracked, source-free `__pycache__`/`.venv` residue from 2026-09-15 — not real code. PR #2091 updated `docs/ARCHITECTURE.md` and `AGENTS.md` to describe the 2-monolith layout as current, which is aspirational, not actual — corrected in AGENTS.md 2026-09-16. See phased plan (to be filed as a tracking issue) before starting. |
| #1797 | Replace `CHANGE_ME_*` with Sealed Secrets | PR #2114 added the generation script + a validation test — but the test is designed to fail until the actual 15 placeholders are sealed, which hasn't happened. **Blocked on real cluster/kubeseal cert access** (not agent-executable). |
| #1578 | Wire IRSA role ARN into python-fawkes-path | PR #2114 renamed the Terraform module and wired the output, but the ARN still needs `terraform apply` + hardcoding into the live `python-fawkes-path-gitops` ServiceAccount. **Blocked — CI-gated `terraform apply` only, not run by hand per AGENTS.md.** |
| ~~#1581~~ | ~~Verify CI quality gates are green~~ | **CLOSED 2026-09-16** — verified per PR #2114. |
| #1938 | python-fawkes-path integration test suite | PR #2114 added 16 *structure* tests (file/dir layout), not the live-environment integration suite the issue title asks for. Partially done. |
| #1942 | Wire chaos experiments into canary traffic-shift | **Genuinely blocked, not just a design question.** `python-fawkes-path-beta-applicationset.yaml`'s own comment confirms `python-fawkes-path-gitops` "only has a plain Deployment" — no Argo Rollouts `Rollout` resource exists yet, so there's no canary traffic-shift step to hook into. AnalysisTemplate and chaos-mesh experiment manifests exist in isolation but per the issue's own text, don't attempt integration until all 4 dependencies are confirmed working. Design decision recorded for whenever the canary conversion lands: **on-demand trigger only**, not automatic on every canary. |
| #2032 | java-fawkes-path golden path (Phase 2/Beta) | PR #2114 added a design spec only; implementation lives in the separate `paruff/java-fawkes-path` repo and is estimated ~16h — too large for this queue's per-item granularity. See phased plan (to be filed as a tracking issue). |

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
