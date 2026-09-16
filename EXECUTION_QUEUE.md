# Fawkes — Execution Queue

> **Horizon:** Weeks | **Owner:** @paruff | **Review cadence:** Weekly, or whenever `plan-for-the-day.md`'s retrospective surfaces a backlog delta

## Priority Tiers

> Synced against live GitHub issue state 2026-09-16 (per the `audit-backlog-against-live-issue-state` technique). The 2026-09-13 sync predated PRs #2091, #2112, #2114 (merged 9/14-9/16); this pass re-verified every row against current GitHub state and repo contents rather than trusting those PRs' own claims.

> **2026-09-16, later same day:** live incident response on `mac-mini-k3s` found the reliability problems traced almost entirely to the `mini-gamer` node (WSL2/Windows host) — 24h kubelet outage, an unresolved kubelet-log-proxy 502 bug, and a 3-day-stale `argocd` Helm release stuck in `failed` state (root cause: the chart's `argocd-redis-secret-init` pre-upgrade hook, not yet diagnosed — `argocd-server`/`argocd-repo-server` are still `CrashLoopBackOff` on this cluster as of this edit). **Decision: move to Azure AKS** rather than keep fighting `mini-gamer`. Cutover in progress: state backend + RBAC done, `terraform apply` for the AKS cluster is next. See #2117/#2120/#2124/#2126 for what this session's investigation actually found and scoped.

**P0 — blocks a release/phase gate.** Nothing else in this tier's phase can be honestly claimed done while these are open.

| # | Item | Why P0 | Status |
|---|---|---|---|
| — | ~~Decide + run the DevLake DB migration~~ | Still HTTP 428, still not agent-executable — but **no longer P0**: 2026-09-16 decision confirmed dropping DevLake for DORA metrics in favor of native PromQL. #1919/#2079/#1946/Phase 5 rescoped to depend on #2117 instead. DevLake pods left running (optional component, historical analytics only); migration approval deferred, not urgent. | **DEPRIORITIZED** (2026-09-16) |
| — | **Azure AKS cutover** | Superordinate to #2117 as of 2026-09-16: continuing to build out DORA metrics/Tekton on `mac-mini-k3s` while `mini-gamer` is this unreliable isn't worth it. New cluster becomes the target for #2117, #2120, and the Tekton work. | **IN PROGRESS** — state backend + storage RBAC done; `terraform apply` for AKS is next. `scripts/ignite.sh`'s kubeconfig bug (#1972) fixed first (PR #2123, merged) so the cutover can't silently misfire onto the wrong cluster. |
| #2117 | Wire real ArgoCD/Tekton/Alertmanager metrics into Prometheus | **P0, target moved to AKS.** `dora.yml`'s recording rules (deployed via `prometheus-application.yaml` on `mac-mini-k3s`) compute from metric names that don't exist there — verified live: zero `argocd_*`/`tekton_*`/`alertmanager_alert_*` series; ArgoCD had no metrics Service (fixed, PR #2118, merged, but never actually applied live — `mac-mini-k3s`'s ArgoCD Helm release has been `failed` since before this fix could take effect); Tekton was installed via a stale bootstrap fix but is `CrashLoopBackOff` for an undiagnosed reason. Redo this work on AKS instead of continuing to debug `mini-gamer`. | **OPEN** — blocked on the AKS cutover landing |
| — | **Replace Jenkins with Tekton across all pipelines** | Migrate every Jenkinsfile/JCasC to Tekton pipeline/task definitions; update all CI references from Jenkins to Tekton; retire Jenkins infrastructure. Blocks all pipeline-dependent work. | **DONE** (2026-09-16) — Tekton pipeline templates for all 3 service skeletons; `services/samples/*/Jenkinsfile` deleted; `jenkins` Backstage Component and `jenkins.io/job-full-name` annotations removed from all 3 `catalog-info.yaml` files. A stale local branch (`chore/remove-jenkins-integrations-and-docs`, unpushed) predates #2114 and deletes unrelated test files — not merged, not usable. |
| #1569 | Terraform remote state backend | `KL-01`: no state locking today — concurrent applies can corrupt state | **DONE** — Module created (`infra/terraform/modules/aws/terraform-state/`); terratest passes (not independently re-run this pass) |
| #1572 | Confirm DORA lead-time/deployment-frequency queryable in Grafana via native PromQL | Phase 1's last unverified acceptance criterion; replace DevLake-dependent queries with native PromQL | **NOT DONE** (corrected 2026-09-16, live-verified against `mac-mini-k3s`) — previously marked DONE for writing `dora.yml`, but the file was never deployed by anything (confirmed: zero `dora_*` series in Prometheus). Now actually wired into `prometheus-application.yaml` as of 2026-09-16, but still produces zero data — the source metrics it depends on don't exist on this cluster. See #2117. |
| #1855 | DevLake GitHub GraphQL collector | Root cause fixed (`KL-09`) but the issue itself is still open — re-verify and close once DevLake is reachable again (`KL-15`), don't just assume it's done | **CLOSED** (2026-09-16) — Root cause was missing token scopes (`read:user`, `user:email`); fix applied and verified live. DevLake now optional per KL-15. Previously marked CLOSED here while still open on GitHub — actually closed now. |
| #2004 | `extract-zip` arbitrary file write via symlinks (design-system build toolchain) | `p0-critical` security advisory, no patched version exists yet; related to the broader toolchain upgrade in #1715 | **ACCEPTED RISK** — Dev-only toolchain dep (`@lhci/cli` → Lighthouse CI → Puppeteer). No patched version exists (`extract-zip *` = all vulnerable). Documented as KL-20. Revisit when upstream migrates away from `extract-zip`. |

**P1 — this sprint.**

| # | Item | Notes |
|---|---|---|
| #2116 | **Collapse 17 Python services into 2 domain monoliths** | **0% done in code.** `services/` on `main` still has all 18 original dirs; no `fawkes-telemetry-engine`/`fawkes-devex-service` exist on any branch. Local dirs with those names exist only as untracked, source-free `__pycache__`/`.venv` residue from 2026-09-15 — not real code. PR #2091 updated `docs/ARCHITECTURE.md` and `AGENTS.md` to describe the 2-monolith layout as current, which is aspirational, not actual — corrected in AGENTS.md 2026-09-16. Phased plan filed as #2116. |
| #1797 | Replace `CHANGE_ME_*` with Sealed Secrets | PR #2114 added the generation script + a validation test — but the test is designed to fail until the actual 15 placeholders are sealed, which hasn't happened. **Blocked on real cluster/kubeseal cert access** (not agent-executable). |
| #1578 | Wire IRSA role ARN into python-fawkes-path | PR #2114 renamed the Terraform module and wired the output, but the ARN still needs `terraform apply` + hardcoding into the live `python-fawkes-path-gitops` ServiceAccount. **Blocked — CI-gated `terraform apply` only, not run by hand per AGENTS.md.** |
| ~~#1581~~ | ~~Verify CI quality gates are green~~ | **CLOSED 2026-09-16** — verified per PR #2114. |
| #1938 | python-fawkes-path integration test suite | PR #2114 added 16 *structure* tests (file/dir layout), not the live-environment integration suite the issue title asks for. Partially done. |
| #1942 | Wire chaos experiments into canary traffic-shift | **Genuinely blocked, not just a design question.** `python-fawkes-path-beta-applicationset.yaml`'s own comment confirms `python-fawkes-path-gitops` "only has a plain Deployment" — no Argo Rollouts `Rollout` resource exists yet, so there's no canary traffic-shift step to hook into. AnalysisTemplate and chaos-mesh experiment manifests exist in isolation but per the issue's own text, don't attempt integration until all 4 dependencies are confirmed working. Design decision recorded for whenever the canary conversion lands: **on-demand trigger only**, not automatic on every canary. |
| #2032 | java-fawkes-path golden path (Phase 2/Beta) | PR #2114 added a design spec only; implementation lives in the separate `paruff/java-fawkes-path` repo and is estimated ~16h — too large for this queue's per-item granularity. Phased plan posted as a comment on #2032. Now also the designated pilot for #2120's new ApplicationSet pattern — don't deploy it via the old `path-based-applications` generator. |
| #2120 | Redesign golden-path ApplicationSets for multi-language, multi-environment scale | New 2026-09-16. Found while debugging why `python-fawkes-path` vanished: the shared `path-based-applications` ApplicationSet mixed platform infra with product golden paths and had a hardcoded, silently-stale file-path generator. Scoped: separate `golden-paths` ApplicationSet, auto-discovery generator, per-language+per-environment namespace isolation (`fawkes-<lang>-<env>` instead of shared `fawkes`). |
| #2124 | SRE practices — detection/alerting first, error budgets second | New 2026-09-16. Prompted by today's incident pattern: every failure found today (node outage, stuck ArgoCD controller, stale Helm release, stale ApplicationSet generator) was found by accident, hours to days late, not by any alert. Phase 1 (detection, depends on #2117) before Phase 2 (error budget definitions). |
| #2126 | Build CI-gated terraform apply pipeline | New 2026-09-16. `AGENTS.md` says infra changes go through CI-gated apply; no such CI workflow exists — only plan/validate. Every apply today (Azure state backend, ArgoCD metrics, AKS cluster itself) was run by hand. Scope: PR-posted plan diff, human-approved apply in CI, apply-failure alerting. |

**P2 — next sprint.**

| # | Item | Depends on |
|---|---|---|
| #1919 | DevLake deployment-side webhook | Rescoped 2026-09-16, no longer DevLake — now: real DORA data compute for tracer-bullet via native PromQL. Depends on #2117. |
| #2079 | Alertmanager→DevLake incident-payload adapter | Rescoped 2026-09-16 — now: Alertmanager data into Prometheus for CFR. Depends on #2117. |
| #1946 | CFR panel on DORA dashboard | #1919 + #2079 (both rescoped, see above) |
| #2081 | Phase 5 self-measurement MVP (fawkes-on-fawkes DORA) | Rescoped 2026-09-16 — now depends on #2117 instead of KL-15/DevLake |

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
