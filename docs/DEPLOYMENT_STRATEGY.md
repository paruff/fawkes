# Deployment Strategy

## Current Model

The current deployment model is a minimal push-based trigger:

- **docs/ pages**: `deploy.yml` builds and deploys MkDocs to GitHub Pages on push to `main` affecting `docs/**`, `mkdocs.yml`, or `requirements.txt`
- **Tracer Bullet**: `tracer-bullet-ci.yml` builds a Docker image, pushes to GHCR, and updates the GitOps manifest in-tree on push to `main`
- **DORA Metrics**: `dora-metrics-ci.yml` follows the identical pattern (build → push → in-tree manifest update)
- **Infrastructure**: Terraform modules are validated in CI but deployed manually or via external pipelines
- **Reusable workflows**: Called from `paruff/ufawkespipe` and other repos; no cross-repo GitOps flow

**Correction (2026-09):** this file previously stated there is no automated rollback and no cross-repo GitOps flow. Both tracer-bullet and dora-metrics already implement real GitOps artifact promotion: their CI builds an image, pushes it to GHCR, then commits the new tag directly into `platform/apps/<service>/deployment.yaml` on `main`. Both services' ArgoCD `Application` manifests have `syncPolicy.automated: {prune: true, selfHeal: true}`, which means ArgoCD auto-syncs that commit to the cluster. This is in-tree GitOps (one repo, `platform/apps/`), not the separate GitOps repo the target model below describes — that's still a real gap, just a different one than "nothing works."

**Update (2026-09-05, #1751 Phase 1):** ArgoCD's `selfHeal` mechanism is now live-verified on a real cluster (see Rollback Protocol below) - previously this section could only say "in principle." Note this is cluster-specific: ArgoCD needs to actually be running and synced on whichever cluster you're targeting (it is not persistently running anywhere by default in this repo - it's redeployed per session via `scripts/lib/argocd.sh`/`infra/terraform/argocd`, and the AKS cluster it was verified against this week is deliberately stopped/deallocated between sessions to control cost).

**Update (2026-09-05):** all **17** Python services under `services/` now have CI-run lint/tests (`service-python-tests.yml`, added in #1747) but do not yet build/push images or participate in GitOps promotion — extending the tracer-bullet/dora-metrics pattern to them is a natural next step, in progress (#1751 Phase 2).

`paruff/ufawkespipe`'s `reusable-rollback.yml` was checked as a possible shortcut for the "Automated rollback" gap below — it is **not applicable**: it's built for SSH-based deployment to a single host (`DEPLOY_HOST`/`DEPLOY_USER`/`DEPLOY_KEY` + a remote `git reset` and restart command), not a Kubernetes/ArgoCD GitOps model. The real rollback mechanism here is git-revert + ArgoCD `selfHeal`, described above.

There is no progressive delivery or canary analysis. Deployments are all-or-nothing on `main` push, and rollback (where it exists at all) is an unverified manual `git revert`.

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
- Automated smoke tests run at each step (health endpoints, BDD scenarios)
- Rollback is automatic if smoke tests fail at any canary step
- Metrics (error budget, latency SLOs) are evaluated before promotion

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
| CI guard on main | ❌ | ✅ (Phase 1) |
| Versioned artifacts | Partial | ✅ |
| GitOps separate repo | In-tree only (works for tracer-bullet, dora-metrics) | ✅ (separate repo) |
| Canary deployments | ❌ | ✅ |
| Automated rollback | Mechanism verified live (2026-09-05, see Rollback Protocol above) - the `selfHeal` half is proven; a full `git revert` + PR merge cycle is not yet tested | ✅ |
| Post-deployment verification | ❌ | ✅ |
| deployment events | ❌ | ✅ |
