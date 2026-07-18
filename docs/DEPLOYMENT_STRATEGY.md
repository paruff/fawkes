# Deployment Strategy

## Current Model

The current deployment model is a minimal push-based trigger:

- **docs/ pages**: `deploy.yml` builds and deploys MkDocs to GitHub Pages on push to `main` affecting `docs/**`, `mkdocs.yml`, or `requirements.txt`
- **Tracer Bullet**: `tracer-bullet-ci.yml` builds a Docker image, pushes to GHCR, and updates the GitOps manifest in-tree on push to `main`
- **Infrastructure**: Terraform modules are validated in CI but deployed manually or via external pipelines
- **Reusable workflows**: Called from `paruff/ufawkespipe` and other repos; no cross-repo GitOps flow

There is no progressive delivery, canary analysis, or automated rollback. Deployments are all-or-nothing on `main` push.

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
| GitOps separate repo | ❌ | ✅ |
| Canary deployments | ❌ | ✅ |
| Automated rollback | ❌ | ✅ |
| Post-deployment verification | ❌ | ✅ |
| deployment events | ❌ | ✅ |
