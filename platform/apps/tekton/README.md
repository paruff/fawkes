# Tekton - Golden Path CI/CD (Phase 1)

## Purpose

Phase 1 of the Jenkins → Tekton "Golden Path CI/CD" migration (see issues
1659, 1660, 1661). Jenkins (`platform/apps/jenkins/`) stays fully in place
and untouched — this stands up Tekton Pipelines and Triggers controllers
alongside it so later phases can port one pipeline step at a time with no
cutover risk. No `Task`/`Pipeline`/`Trigger` resources are deployed yet in
this phase — only the controllers, running healthy.

## Namespace

Deployed into `tekton-pipelines`, matching upstream Tekton's own default
namespace for both the Pipelines and Triggers release manifests (rather than
sharing Jenkins's `fawkes` namespace). Reasoning:

- Tekton ships its own CRDs, a validating/mutating webhook, and a webhook
  cache configmap — cluster-scoped surface that's simplest to reason about
  in its own namespace, matching how `cloudnativepg-system` and `monitoring`
  are already split out from `fawkes` in this repo.
- Keeps RBAC and any future `TriggerBinding`/`EventListener` service accounts
  fully isolated from Jenkins's own service account and RBAC in `fawkes`,
  eliminating any possibility of collision while both CI systems run side
  by side during the migration.
- Matches the upstream Tekton docs/release manifests as-shipped, minimizing
  drift from the release manifests referenced below.

## Deployment

Deployed via a plain-manifest ArgoCD `Application`
(`platform/apps/tekton-application.yaml`), not Helm — `tektoncd/pipeline` and
`tektoncd/triggers` do not publish an official Helm chart, only versioned
release YAML. `platform/apps/tekton/kustomization.yaml` references the
pinned release manifests **by URL** rather than vendoring a local copy —
the CRD-heavy Pipelines release alone is over 1.5MB and fails this repo's
`check-added-large-files` (1MB limit) and `yamllint` (upstream isn't
formatted to this repo's yamllint config) pre-commit hooks. Kustomize
fetches them at build/ArgoCD-sync time; the exact tag is pinned in each URL
so a version bump is still an explicit, reviewable PR diff, same as any
other pinned chart version in this repo:

- Tekton Pipelines v1.16.0
  (https://github.com/tektoncd/pipeline/releases/tag/v1.16.0)
- Tekton Triggers v0.37.0, plus its core interceptors bundle (webhook
  signature validation, CEL, GitHub/GitLab/Bitbucket helpers - required
  for the GitHub webhook `EventListener` skeleton, see issue 1660)
  (https://github.com/tektoncd/triggers/releases/tag/v0.37.0)

Trade-off: ArgoCD needs outbound network access to fetch these URLs at
every sync, unlike a fully vendored/self-contained repo. Accepted here
since it's the only way to keep the pre-commit gates green without
disabling or weakening them for this one directory.

## Verify

```bash
kustomize build platform/apps/tekton | kubeconform -summary
kubectl get pods -n tekton-pipelines
```

ArgoCD should show the `tekton` Application `Synced`/`Healthy`, with all
`tekton-pipelines-*` and `tekton-triggers-*` controller pods `Running`.

## Human review required

Per `AGENTS.md` section 6 ("Must Ask Before": creating or modifying ArgoCD
`Application` manifests) and this phase's own tracking issues (1659, 1660),
this was drafted by an agent and must not be merged without maintainer
review — flagged explicitly in the PR, not merged as routine.
