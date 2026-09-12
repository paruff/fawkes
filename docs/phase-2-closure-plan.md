# Implementation Plan: Fully Close Phase 2 (#1805)

> Saved 2026-09-12. Produced via `/plan` after a live investigation session that
> found Phase 2's code/GitOps work largely merged but not yet live-verified —
> see `docs/BACKLOG.md`'s Phase 2 table for current status.

## Requirements Restatement

Six remaining items, with real dependencies between them:

```
(1) Live-verify quality gate blocks a bad deploy ──┐
(2) Live canary rollout + observed rollback ───────┼─→ (3) #1942 chaos-in-canary wiring
(4) #1919 DevLake webhook (deployment side) ───────┬─→ (5) Alertmanager→DevLake adapter ─→ (6) #1946 dashboard panel
```

(1) and (4) are independent starting points. (2) depends on `argo-rollouts`/`chaos-mesh` actually finishing their sync (triggered live already, not yet confirmed `Synced`). (3) depends on (2). (5) depends on (4)'s schema being final (already is, per #1944). (6) depends on (4)+(5) producing real rows.

## Pattern Grounding (from live investigation)

| Category | Source | Pattern to mirror |
|---|---|---|
| Tekton task structure | `platform/apps/tekton/golden-path-pipeline.yaml` | Embedded scripts, no remote task resolution, pinned images, `runAfter` dependency chains |
| GitOps-promote / cross-repo write | `golden-path-pipeline.yaml`'s `gitops-promote` task | `gh` CLI + PAT-in-secret clone/commit/push, non-fatal `\|\| echo "WARNING"` for optional side-effects |
| ArgoCD Application conventions | `platform/apps/argo-rollouts/argo-rollouts-application.yaml`, `chaos-mesh-application.yaml` | `syncPolicy.automated{prune,selfHeal}`, resource limits on every container, maintainer-review flag in header comment |
| Standalone reusable GH Actions workflow | `.github/workflows/reusable-security-scanning.yml`, `reusable-sbom-generation.yml` | `workflow_call` with typed inputs, `image-ref` not `image-name`+`image-tag` for scanning specifically (bug fixed in fawkes#2056) |
| BDD/fixture test | `tests/bdd/step_definitions/test_dora_change_failure_rate_calculation_steps.py` | Background-free feature file, pure in-memory fixture, no live-cluster dependency |
| Chaos Mesh experiment manifest | `platform/apps/chaos-mesh/experiments/*.yaml` | Standalone, not wired into any Application/kustomization — manual `kubectl apply` trigger |
| DevLake webhook payload | `docs/dora-change-failure-rate-schema.md` | Already-designed schema for `deployments`/`issues` endpoints — use as-is, don't re-derive |

No existing pattern for: a live-verification runbook/checklist, or a webhook-adapter microservice — these are genuinely new, not reinventions.

## Implementation Phases

### Phase 0 — Prerequisite check (do first, ~15 min)

Before any of the 6 items, confirm the ground truth hasn't drifted further:
- `kubectl get applications -n argocd` — confirm `tekton`, `argo-rollouts`, `chaos-mesh` are now `Synced`/`Healthy` (they were freshly created but unsynced as of last check)
- `kubectl get pipeline golden-path -n fawkes` and `kubectl get rollout -n fawkes` — confirm the CRDs actually landed
- If anything is still stuck `OutOfSync`/`Degraded`, diagnose with `superpowers:systematic-debugging` before proceeding — don't build on top of infrastructure that hasn't actually synced

### Phase 1 — Live-verify the quality gate blocks a bad deploy

**Depends on:** Phase 0 (Tekton healthy)
1. Confirm `tekton-gitops-github-token` and `sonarqube-scan-token` secrets exist in the `fawkes` namespace (they didn't earlier this session — this is the most likely blocker)
2. Trigger a real `PipelineRun` against `golden-path` with a deliberately bad commit (e.g., a test file with an obvious code smell/vulnerability SonarCloud will flag) pushed to `python-fawkes-path`
3. Observe: `sonar-scan` step should now **wait** (per fawkes#2033's `sonar.qualitygate.wait=true`) and the pipeline should stop before `gitops-promote` runs
4. Re-run with a clean commit, confirm promotion proceeds normally
5. Update `docs/BACKLOG.md`'s Phase 2 row from 🟡 to 🟢 with the run link as evidence

**Risk:** Secrets may still be missing (flagged as a known gap in `golden-path-pipeline.yaml`'s own header comment) — this could block the whole phase. Mitigation: check secrets first, treat missing-secret as its own small fix, not a surprise mid-run.

### Phase 2 — Live canary rollout with observed rollback

**Depends on:** Phase 0 (argo-rollouts CRD live), tracer-bullet-gitops#6 merged (Rollout conversion)
1. Confirm `kubectl get rollout tracer-bullet -n fawkes` shows the Rollout object (replacing the old Deployment)
2. Push a **good** commit through the golden path → confirm the Rollout executes its `canary.steps` (50% → pause → 100%, per the conversion's own design) and the `tracer-bullet-canary-success` AnalysisTemplate runs against the (now-fixed) PromQL query
3. Push a **deliberately bad** commit (e.g., one that spikes the 5xx rate) → confirm the AnalysisTemplate's `failureLimit: 0` triggers an automated rollback, observed via `kubectl argo rollouts get rollout tracer-bullet` or `kubectl describe rollout`
4. Capture the rollback event as evidence; update `docs/DEPLOYMENT_STRATEGY.md`'s canary-deployments status line (currently 🟡) to 🟢

**Risk:** This is a **basic (replica-ratio) canary with no traffic-routing plugin** (documented tradeoff from the Rollout conversion) — at 2 replicas, "50%" is a coarse split. A rollback should still trigger correctly since the AnalysisTemplate gates on aggregate error rate, not per-replica precision, but don't expect a smooth gradual shift.

### Phase 3 — #1942: wire chaos into the canary traffic-shift step

**Depends on:** Phase 2 proven working
1. Add an `analysis.templates` step (or a parallel `steps` entry with an `experiment` hook) in the Rollout that triggers `platform/apps/chaos-mesh/experiments/tracer-bullet-pod-kill.yaml` automatically during the canary pause window — likely via a Tekton Task or a Kubernetes `Job` applying the PodChaos manifest, gated on the Rollout entering its `paused` phase
2. This is the one item where "automated, no human trigger" (the epic's literal acceptance criterion) genuinely requires new orchestration code, not just wiring — budget real design time here, don't treat it as a config tweak
3. Verify: trigger a canary, confirm the chaos experiment fires automatically during the pause step, and the AnalysisTemplate's error-rate check reflects the induced disruption

**Risk:** Highest-complexity item in this plan. Argo Rollouts doesn't have a first-class "run this arbitrary K8s object during canary" hook — likely needs a small controller or a Tekton-triggered-by-Rollout-event pattern. Recommend timeboxing investigation before committing to an approach.

### Phase 4 — #1919: DevLake webhook wiring for deployment signal

**Independent of Phases 1-3, can run in parallel**
1. Create the DevLake webhook connection via its REST API (same pattern as prior GitHub connection setup, per #1919's own acceptance criteria)
2. Modify `golden-path-pipeline.yaml`'s `gitops-promote` task to also `POST` a deployment event to DevLake's `/plugins/webhook/:connectionId/deployments` endpoint, using the exact payload shape already designed in `docs/dora-change-failure-rate-schema.md` — don't re-derive it
3. Verify live: after a real promotion, query `devlake-mysql`'s `cicd_tasks` table directly for a `type='Deployment'` row
4. Verify DevLake's own dashboard/API shows a deployment-frequency data point
5. Update `docs/KNOWN_LIMITATIONS.md` KL-12 to resolved

**Risk:** `devlake-lake` pod was in `CreateContainerConfigError` as of this session's last check — fix that first or this entire phase is blocked on infrastructure, not code.

### Phase 5 — Alertmanager→DevLake incident-payload adapter

**Depends on:** Phase 4 (needs a real webhook connection to target) and fawkes#2042 (Alertmanager receiver, already merged)
1. Build a small adapter (Tekton Task, or a lightweight Job/CronJob — no existing pattern to mirror, this is genuinely new) that receives Alertmanager's native webhook payload (`{version, status, alerts: [...]}`) and transforms it into DevLake's `issues` schema (`issueKey`, `title`, `type: INCIDENT`, `status`, `createdDate`, etc.)
2. Point the `devlake-cfr` receiver (already in `prometheus-application.yaml`) at this adapter instead of DevLake directly
3. Seal the real `devlake-webhook-url` secret now that Phase 4 has created a real connection (per the gap flagged in fawkes#2042's own header comment — follow that file's documented steps)
4. **Critical correctness check:** confirm the deployment webhook (Phase 4) and this incident adapter both submit into the *same DevLake project* — per `docs/dora-change-failure-rate-schema.md`, correlation is timestamp-based within a shared project scope, not an explicit field; getting this wrong means both events land but never correlate, with no error to signal it

**Risk:** This is the second-most novel piece of engineering in the plan (no existing adapter pattern in this repo). Consider whether a generic small FastAPI/Flask service (matching `services/`'s existing Python convention) is simpler than a Tekton Task for a persistent webhook receiver — a Task runs once per invocation, but Alertmanager needs a standing HTTP endpoint. **This may actually need to be a small deployed service, not a Task — flag this as a design decision to confirm before implementing**, since it changes the shape of the work substantially (new `platform/apps/` component + Deployment + Service, not just a CI task).

### Phase 6 — #1946: real CFR dashboard panel

**Depends on:** Phase 4 + Phase 5 producing real correlated data
1. Confirm CFR is actually computing: query DevLake's own API/dashboard for a real percentage
2. Add a MySQL Grafana datasource pointed at DevLake's DB (flagged as a prerequisite in this session's own investigation — no such datasource exists yet in the consolidated Grafana)
3. Import DevLake's own native DORA dashboard JSON (flagged in `devlake-application.yaml`'s own comment as a deferred manual step) rather than hand-writing a fifth bespoke panel — this avoids repeating the exact mistake already found this session (two existing CFR panels querying undefined Prometheus metrics)
4. Verify the panel shows a real, non-zero-context percentage, not just "no data"

**Risk:** Low technical risk, but fully blocked until Phase 4+5 produce real rows — don't start this early or it repeats the "panel with no data behind it" anti-pattern #1946 already flagged once.

## Dependencies Summary

| Phase | Blocks | Blocked by |
|---|---|---|
| 0 | 1, 2 | — |
| 1 | — | 0, missing secrets (unknown) |
| 2 | 3 | 0, tracer-bullet-gitops#6 (merged) |
| 3 | — | 2 |
| 4 | 5 | devlake-lake pod fix |
| 5 | 6 | 4, design decision (Task vs. deployed service) |
| 6 | — | 4, 5 |

## Risks (repo-wide)

| Risk | Likelihood | Mitigation |
|---|---|---|
| Tekton/argo-rollouts/chaos-mesh still not `Synced` despite the bootstrap re-apply | Medium | Phase 0 catches this before any other phase wastes effort |
| Missing Tekton secrets block Phase 1 entirely | Medium-High | Check first, treat as its own fix |
| #1942's chaos-in-canary hook has no existing pattern to mirror | High (design risk) | Timebox investigation, may need external research on Argo Rollouts + Chaos Mesh integration patterns |
| Alertmanager adapter's actual shape (Task vs. service) changes scope significantly | Medium | Confirm as a design decision before implementing, not mid-build |
| Azure subscription's 10-vCPU regional cap could block any node-pool scaling needed for canary steps at finer granularity | Low for this plan specifically | Not in scope unless Phase 2 requires more replicas |

## Estimated Complexity

- **Phase 0:** Low — ~15 min
- **Phase 1:** Low-Medium — mostly verification, possible secret provisioning
- **Phase 2:** Medium — real live testing, multiple pipeline runs
- **Phase 3:** **High** — genuinely new orchestration, no existing pattern
- **Phase 4:** Medium — real API integration, needs devlake-lake fixed first
- **Phase 5:** **High** — new component, possible architecture decision (adapter as Task vs. deployed service)
- **Phase 6:** Low — mostly Grafana import/config, but fully gated on 4+5

**Overall: this is not a single session's work.** Phases 0-2 and 4 are reasonably scoped for focused sessions each. Phases 3 and 5 are the two genuinely hard, novel pieces and each deserves its own dedicated design pass before implementation — treat them as separate GitHub issues with their own acceptance criteria rather than sub-tasks of a single push.

## Acceptance

- [ ] Phase 0: infrastructure confirmed synced before proceeding
- [ ] Phase 1: quality gate live-verified to block a bad deploy
- [ ] Phase 2: canary rollout + automated rollback observed live
- [ ] Phase 3: #1942 chaos-in-canary wiring implemented and verified
- [ ] Phase 4: #1919 DevLake webhook wiring live-verified
- [ ] Phase 5: Alertmanager→DevLake adapter built and verified (design decision resolved first)
- [ ] Phase 6: #1946 real CFR dashboard panel showing live data
