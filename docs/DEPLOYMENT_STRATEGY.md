# Deployment Strategy

## Current Model

The current deployment model uses **Tekton CI + ArgoCD GitOps** for all pipelines:

- **docs/ pages**: `deploy.yml` builds and deploys MkDocs to GitHub Pages on push to `main` affecting `docs/**`, `mkdocs.yml`, or `requirements.txt`
- **python-fawkes-path**: extracted out of the monorepo (#1813) into its own repo pair — app source + a Tekton-based CI pipeline (`platform/apps/tekton/golden-path-pipeline.yaml`, run in-cluster, not GitHub Actions) in [`paruff/python-fawkes-path`](https://github.com/paruff/python-fawkes-path), and desired-state manifests in [`paruff/python-fawkes-path-gitops`](https://github.com/paruff/python-fawkes-path-gitops). This is now a real, separate-repo GitOps flow.
- **DORA Metrics**: Computed natively in Prometheus via recording rules (no DevLake ETL). `dora-metrics-ci.yml` follows the in-tree pattern for backward compatibility only.
- **Infrastructure**: Terraform modules are validated in CI but deployed manually or via external pipelines
- **Reusable workflows**: Called from `paruff/ufawkespipe` and other repos; no cross-repo GitOps flow

**Correction (2026-09):** Both python-fawkes-path and dora-metrics implement real GitOps artifact promotion: their CI builds an image, pushes it to GHCR, then commits the new tag directly into `platform/apps/<service>/deployment.yaml` on `main`. Both services' ArgoCD `Application` manifests have `syncPolicy.automated: {prune: true, selfHeal: true}`, which means ArgoCD auto-syncs that commit to the cluster.

**Update (2026-09-05, #1751 Phase 1):** ArgoCD's `selfHeal` mechanism is now live-verified on a real cluster (see Rollback Protocol below).

**Major Architecture Update (2026-09):**
- **Jenkins retired** — All CI/CD pipelines are Tekton-based running in-cluster. Legacy Jenkinsfiles and JCasC configs removed.
- **17 services → 2 domain monoliths** — `services/` consolidated into `fawkes-telemetry-engine` and `fawkes-devex-service` (see `docs/ARCHITECTURE.md` §Platform Services).
- **DevLake optional** — DORA metrics computed natively via PromQL recording rules. DevLake retained only for historical cross-repo analytics.
- **Vault → OpenBao** — Secrets management migrated to OpenBao (MPL-2.0 fork).

**Update (2026-09-07, #1804 Phase 1 tracer bullet):** python-fawkes-path runs the target Phase 2 model live on kind: Tekton `golden-path` pipeline → GHCR push → Trivy scan → `gitops-promote` PR → ArgoCD auto-sync → running pod. Two gaps: SonarCloud quality-gate disabled (`sonar.qualitygate.wait=false`), DevLake DORA collection blocked (#1855) but no longer required.

**Update (2026-09-13):** Native DORA metrics via PromQL recording rules deployed. All 5 DORA keys computable without DevLake.

`paruff/ufawkespipe`'s `reusable-rollback.yml` was checked as a possible shortcut for the "Automated rollback" gap below — it is **not applicable**: it's built for SSH-based deployment to a single host (`DEPLOY_HOST`/`DEPLOY_USER`/`DEPLOY_KEY` + a remote `git reset` and restart command), not a Kubernetes/ArgoCD GitOps model. The real rollback mechanism here is git-revert + ArgoCD `selfHeal`, described above.

There is no progressive delivery or canary analysis deployed for services yet — the Argo Rollouts controller is installed (see Progressive Delivery Decision below) but no service-level `Rollout` or `AnalysisTemplate` manifests exist. Deployments are all-or-nothing on `main` push, and rollback (where it exists at all) is an unverified manual `git revert`.

## Progressive Delivery Decision: Canary over Blue/Green

Phase 2 (#1805) evaluated both Blue/Green and Canary deployment strategies.
**Canary was chosen** for the following reasons:

- **Traffic-based validation**: Canary shifts traffic incrementally (10% → 50% → 100%),
  allowing smoke tests and SLO checks against real production traffic before full rollout.
  Blue/Green switches all traffic at once — a bad deploy hits 100% of users immediately.
- **Automated rollback via analysis**: Argo Rollouts' `AnalysisTemplate` can query Prometheus
  metrics (error rate, latency) at each canary step and automatically promote or roll back.
  Blue/Green rollback is fast (switch back to the old ReplicaSet) but has no automated
  quality gate — it requires a human decision or a separate verification step.
- **Reduced blast radius**: A canary step that fails analysis terminates before the next step,
  limiting exposure to the percentage of traffic routed to the canary. Blue/Green's
  instantaneous switch means full blast radius until rollback completes.
- **GitOps alignment**: both strategies work with GitOps, but canary's incremental nature
  pairs better with the staged promotion model (staging → production) already planned in
  the target architecture.

The tradeoff is that canary requires more infrastructure (Argo Rollouts controller, traffic
splitting via service mesh or Ingress annotations, `AnalysisTemplate` resources) and slightly
more complex rollback logic. This was accepted because the infrastructure is now in place
(Argo Rollouts controller deployed via `platform/apps/argo-rollouts/argo-rollouts-application.yaml`)
and the operational benefits outweigh the setup cost.

> **Status**: The Argo Rollouts controller is installed and synced on the cluster. No
> service-level `Rollout` or `AnalysisTemplate` manifests have been created yet — these
> are tracked in the Phase 2 issues in this list. The concrete manifest shapes will be
> documented in Phase 3 below once they exist for real.

## Target Progressive Delivery Model

The target model follows a canary → staging → production progression with automated gates at each stage.

### Phases

#### Phase 1: Main CI Guard (NOW)

- All PRs targeting `main` must pass `code-quality.yml` via the reusable main CI guard from `paruff/ufawkespipe`
- Block merge if CI fails
- Lay the foundation for artifact-based promotion

#### Phase 2: Artifact Promotion with GitOps

- Every `main` merge produces a versioned immutable artifact (Docker image + SBOM + signature)
- A GitOps repo (separate from application code) tracks the desired state per environment
- CI updates the GitOps overlay for the `staging` environment on every `main` merge
- ArgoCD syncs the GitOps state to the staging cluster automatically

#### Phase 3: Canary on Staging

- Staging deployments use a canary strategy: 10% → 50% → 100% traffic shift
- Automated smoke tests run at each step (health endpoints, pytest integration tests)
- Rollback is automatic if smoke tests fail at any canary step
- Metrics (error budget, latency SLOs) are evaluated before promotion
- Implementation: per-service `Rollout` manifests replace `Deployment` resources; `AnalysisTemplate` resources query Prometheus for golden-signal checks at each canary step
- **Pending**: no service-level `Rollout` or `AnalysisTemplate` manifests exist yet — tracked in the Phase 2 issues in this epic (#1805). This section will be updated with cross-links to the actual manifest files once they are implemented.

#### Phase 4: Production Gate

- Production promotion requires manual approval (human in the loop)
- Post-deployment verification runs in production: smoke tests + metric validation
- Full rollback on verification failure (revert GitOps commit → ArgoCD auto-syncs)
- Observability: every deployment emits `deploy-start` / `deploy-finish` / `deploy-result` events

### Rollback Protocol

1. Detection: post-deployment smoke tests fail or error budget is breached within 15 minutes
2. Action: revert the GitOps commit for the affected environment
3. Verification: ArgoCD syncs the previous known-good state; smoke tests re-run
4. Communication: tag the incident in `#platform` Slack channel with deployment SHA and rollback reason

**Verified (2026-09-05, Phase 1 of #1751):** the underlying mechanism this protocol
depends on - ArgoCD's `selfHeal` detecting and correcting drift between the live
cluster and the git-defined desired state - was live-tested on a real AKS cluster
(`fawkes-aks-dev`), not just assumed. Manually patched a live Deployment's resource
request away from what git specifies (drift, the same effect a stale/un-reverted
bad deploy would leave behind); ArgoCD detected the mismatch and reverted the live
resource back to match git within one sync cycle, with no manual intervention.
This confirms the "ArgoCD syncs the previous known-good state" step of the
protocol actually works as designed. Not yet tested: the full protocol end-to-end
via an actual `git revert` + PR merge, or the post-deployment smoke-test trigger
in step 1.

### Observability Built-in

- Every CI job logs `job-start` and `job-finish` timestamps (already implemented across all workflows)
- Deployments emit structured events: `deploy-start`, `deploy-finish`, `deploy-result`
- Post-deployment verification logs `verify-start`, `verify-pass`/`verify-fail`, `verify-finish`
- All events include: workflow name, job name, commit SHA, environment, duration

### Current Gaps vs Target

| Capability | Current | Target |
|---|---|---|
| CI guard on main | ✅ (Phase 1, `code-quality.yml` via reusable workflow) | ✅ (Phase 1) |
| Versioned artifacts | Partial | ✅ |
| GitOps separate repo | ✅ for python-fawkes-path (`paruff/python-fawkes-path-gitops`, proven live 2026-09-07); in-tree only for dora-metrics/smart-alerting | ✅ (separate repo) |
| Canary deployments | ✅ **Live-verified 2026-09-17** on `fawkes-dev-aks` via `ignite.sh`: forced two new `python-fawkes-path` Rollout revisions (pod-template annotation change); both correctly paused at `setWeight: 50` (step 1/3), started a Background `AnalysisRun` against the `python-fawkes-path-canary-success` template, and — because the `error-rate` Prometheus query returned no data (see gap below) — both were automatically `RolloutAborted` by Argo Rollouts (`consecutiveErrors (5) > consecutiveErrorLimit (4)`), scaling the canary ReplicaSet back to 0 and restoring the stable revision to full replica count with zero manual intervention. The gate-and-rollback mechanism itself is proven; the "canary succeeds with real passing metrics" happy path is not yet demonstrated (blocked on the gap below). | ✅ |
| Automated rollback | ✅ **Live-verified 2026-09-17** (analysis-triggered path, `fawkes-dev-aks`) in addition to the `selfHeal` path verified 2026-09-05 below — see Canary deployments row. A full `git revert` + PR merge cycle is still not tested. | ✅ |
| Post-deployment verification | ❌ | ✅ |
| Deployment events | ❌ | ✅ |
| Native DORA metrics (PromQL) | ✅ (2026-09-13) | ✅ |
| 2 monoliths (vs 17 services) | 🟡 In progress | ✅ |
| OpenBao secrets | ✅ (migrated) | ✅ |

**New gap found 2026-09-17 (during the canary live-verification above):** `python-fawkes-path`'s `ServiceMonitor` (`platform/apps/python-fawkes-path/...`, selector `app: python-fawkes-path`, port `http`) never appeared in `prometheus-prometheus`'s active targets on `fawkes-dev-aks`, even ~10 minutes after both the ServiceMonitor and a healthy `prometheus-stack` existed — while `tekton-pipelines-controller`'s `ServiceMonitor` in the same `fawkes` namespace, created around the same time, *was* picked up correctly. Selector labels and port names match the Service on both sides (checked directly); `prometheus-operator` logged no error for this object. Root cause not found — looks like a `prometheus-operator` reconcile-ordering/timing issue specific to this object, not a config mistake. This is why the `AnalysisTemplate`'s `error-rate` query returned "no data" both times above (a real gap, not a stale artifact of a too-fresh cluster) and why the canary's *success* path (passing metrics → full promotion) is still unverified. Needs its own investigation before Phase 3 (chaos-in-canary, #1942) is worth starting — no point wiring chaos experiments into an analysis gate that currently always errors regardless of injected failure.
