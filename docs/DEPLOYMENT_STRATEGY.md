# Deployment Strategy

## Current Model

The current deployment model is a minimal push-based trigger:

- **docs/ pages**: `deploy.yml` builds and deploys MkDocs to GitHub Pages on push to `main` affecting `docs/**`, `mkdocs.yml`, or `requirements.txt`
- **Tracer Bullet**: extracted out of the monorepo (#1813) into its own repo pair — app source + a Tekton-based CI pipeline (`platform/apps/tekton/golden-path-pipeline.yaml`, run in-cluster, not GitHub Actions) in [`paruff/tracer-bullet`](https://github.com/paruff/tracer-bullet), and desired-state manifests in [`paruff/tracer-bullet-gitops`](https://github.com/paruff/tracer-bullet-gitops). This is now a real, separate-repo GitOps flow — see "Update (2026-09-07)" below.
- **DORA Metrics**: `dora-metrics-ci.yml` still follows the older in-tree pattern (build → push → in-tree manifest update)
- **Infrastructure**: Terraform modules are validated in CI but deployed manually or via external pipelines
- **Reusable workflows**: Called from `paruff/ufawkespipe` and other repos; no cross-repo GitOps flow

**Correction (2026-09):** this file previously stated there is no automated rollback and no cross-repo GitOps flow. Both tracer-bullet and dora-metrics already implement real GitOps artifact promotion: their CI builds an image, pushes it to GHCR, then commits the new tag directly into `platform/apps/<service>/deployment.yaml` on `main`. Both services' ArgoCD `Application` manifests have `syncPolicy.automated: {prune: true, selfHeal: true}`, which means ArgoCD auto-syncs that commit to the cluster. This is in-tree GitOps (one repo, `platform/apps/`), not the separate GitOps repo the target model below describes — that's still a real gap, just a different one than "nothing works."

**Update (2026-09-05, #1751 Phase 1):** ArgoCD's `selfHeal` mechanism is now live-verified on a real cluster (see Rollback Protocol below) - previously this section could only say "in principle." Note this is cluster-specific: ArgoCD needs to actually be running and synced on whichever cluster you're targeting (it is not persistently running anywhere by default in this repo - it's redeployed per session via `scripts/lib/argocd.sh`/`infra/terraform/argocd`, and the AKS cluster it was verified against this week is deliberately stopped/deallocated between sessions to control cost).

**Update (2026-09-05):** all **17** Python services under `services/` now have CI-run lint/tests (`service-python-tests.yml`, added in #1747) but do not yet build/push images or participate in GitOps promotion — extending the tracer-bullet/dora-metrics pattern to them is a natural next step, in progress (#1751 Phase 2).

**Update (2026-09-05, later same day — #1751 Phase 3 hardening):** the in-tree GitOps flow above had two real bugs that were masked by non-obvious failure modes, both root-caused and fixed this session:
- The "Update GitOps" commit-and-push step had no retry, so it silently lost the race whenever another automated commit (a sibling service's own GitOps update, or `release-please`) landed on `main` between checkout and push. Fixed with a fetch-rebase-retry loop (5 attempts) in `tracer-bullet-ci.yml`, `smart-alerting-ci.yml`, `dora-metrics-ci.yml`.
- `docker/metadata-action`'s `outputs.version` silently resolved to the floating `:latest` tag instead of the immutable per-commit SHA tag whenever both tag types were configured — meaning the security scan, cosign signature, SBOM, and GitOps commit were all keyed off `:latest`, not the image actually built. Fixed by resolving the tag from `${GITHUB_SHA::7}` directly instead of trusting that output.
- A related, separately-diagnosed CI flake (Trivy vulnerability scan failing non-reproducibly on identical image digests) turned out to be a real CVE in pip's vendored dependency snapshot inside the runtime image (`CVE-2026-13346`), invisible in the UI because SARIF output produces no console findings by default. Fixed by stripping pip/setuptools from the runtime stage of `tracer-bullet`'s Dockerfile (never invoked at runtime in a multi-stage build).

The full build→scan→sign→SBOM→GitOps pattern was also factored into a new reusable workflow (`reusable-python-service-golden-path.yml`) and piloted on a 4th service, `anomaly-detection`, in addition to the existing `tracer-bullet`/`dora-metrics`/`smart-alerting`. 14 of the 17 services still only get lint+test (tracked in #1792).

PR #1798 re-triggers `tracer-bullet` and `smart-alerting` to confirm all of the above lands correctly end-to-end (build → scan → sign → SBOM → GitOps commit succeeds on the first real attempt → ArgoCD syncs → pod `Running`) — see that PR for the live result.

**Update (2026-09-07, #1804 Phase 1 tracer bullet):** tracer-bullet now runs the target Phase 2 model for real, not just in-tree. The full chain was exercised live on a local kind cluster: a commit to [`paruff/tracer-bullet`](https://github.com/paruff/tracer-bullet) triggers the Tekton `golden-path` pipeline (`platform/apps/tekton/golden-path-pipeline.yaml`) — fetch-source → lint-and-test → SonarCloud scan → build-and-push (real GHCR image, `ghcr.io/paruff/tracer-bullet`) → Trivy image scan → `gitops-promote`, which opens a real PR against [`paruff/tracer-bullet-gitops`](https://github.com/paruff/tracer-bullet-gitops). Merging that PR lets ArgoCD (via `platform/apps/tracer-bullet/tracer-bullet-application.yaml`, plus phase-scoped `tracer-bullet-{alpha,beta,prod}-applicationset.yaml`) auto-sync the new image into the cluster, producing a running, traced, metriced, logged pod. This is the separate-GitOps-repo model the gap table below previously listed as unmet — it is now proven for this one service. Two real gaps found and left open: SonarCloud quality-gate blocking is deliberately disabled for now (`sonar.qualitygate.wait=false` — new-project baseline was inconsistent; revisit in Phase 2), and DevLake's DORA collection for this repo is blocked by unresolved issue #1855.

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
- Automated smoke tests run at each step (health endpoints, BDD scenarios)
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
| GitOps separate repo | ✅ for tracer-bullet (`paruff/tracer-bullet-gitops`, proven live 2026-09-07); in-tree only for dora-metrics/smart-alerting | ✅ (separate repo) |
| Canary deployments | ❌ — Argo Rollouts controller installed (`platform/apps/argo-rollouts/argo-rollouts-application.yaml`); no service-level `Rollout` or `AnalysisTemplate` manifests yet | ✅ |
| Automated rollback | Mechanism verified live (2026-09-05, see Rollback Protocol above) - the `selfHeal` half is proven; a full `git revert` + PR merge cycle is not yet tested | ✅ |
| Post-deployment verification | ❌ | ✅ |
| deployment events | ❌ | ✅ |
