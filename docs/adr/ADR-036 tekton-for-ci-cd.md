# ADR-036: Tekton for CI/CD

## Status

Accepted - 2026-09-16

## Context

[ADR-004](ADR-004%20jenkins%204%20ci.md) chose Jenkins for CI/CD in October 2025. By
2026-09-16, Fawkes runs Tekton in-cluster instead — this ADR records that decision, which
had already been made and implemented (`platform/apps/tekton/`) without a corresponding
ADR, a gap this audit closes.

### Why Jenkins Was Replaced

- **Kubernetes-native fit**: Tekton pipelines are CRDs (`Pipeline`, `Task`, `PipelineRun`)
  reconciled by ArgoCD like everything else in `platform/apps/` — no separate stateful
  controller (Jenkins needs a persistent-volume-backed controller pod) or plugin ecosystem
  to secure and patch.
- **No official Helm chart existed** for Jenkins either, but Tekton's upstream install
  method (pinned release YAML) vendors cleanly via Kustomize — see
  `platform/apps/tekton/kustomization.yaml` header comment for why remote-URL references
  don't work (kustomize misidentifies `storage.googleapis.com` URLs as git repos) and why
  the ~30k lines of upstream CRD YAML are vendored locally instead.
- **DORA traceability**: Tekton Tasks emit OTel spans to the collector (`AGENTS.md` §5),
  and `tekton_pipelines_controller_pipelinerun_duration_seconds_bucket` feeds Lead Time
  for Changes directly (`platform/apps/prometheus/rules/dora.yml`) — no webhook relay to a
  separate DORA service, unlike ADR-004's `curl -X POST .../webhook/build` pattern.

ADR-004's original objections to Tekton (Section "Alternative 3") were: immature,
steep learning curve, no UI, smaller ecosystem, complex setup. As of 2026, Tekton is a
graduated CNCF project with a decade of production use; the CRD/no-UI tradeoffs were
accepted as reasonable for a platform-engineering audience rather than disqualifying.

## Decision

**Tekton Pipelines + Triggers replace Jenkins as Fawkes' CI/CD platform.**

- Core controllers run in the `fawkes` namespace (not the upstream-default
  `tekton-pipelines` namespace) — see `platform/apps/tekton/kustomization.yaml` for the
  namespace-remap patch and why the isolated `tekton-pipelines-resolvers` namespace is
  kept separate.
- `platform/apps/tekton/golden-path-pipeline.yaml` defines the reusable pipeline template
  (Jenkins' role for "Shared Pipeline Library" in ADR-004).
- `platform/apps/tekton/eventlistener-github-skeleton.yaml` provides the GitHub webhook
  trigger path (EventListener/TriggerBinding/TriggerTemplate) — security-sensitive, see
  that file's own header (exposes a webhook Ingress endpoint).
- A `ServiceMonitor` (`platform/apps/tekton/tekton-servicemonitor.yaml`) scrapes the
  controller's real metrics port (`tekton-pipelines-controller:9090`, confirmed live
  2026-09-16 — NOT `tekton_pipelinerun_*` as an earlier assumption elsewhere in this repo
  had it).
- User node pool taint tolerance: Tekton's vendored Deployments needed an explicit Spot
  taint toleration added via a Kustomize JSON6902 patch (AKS Spot node pool cost
  optimization) — none of the upstream manifests tolerate it by default.

## Consequences

### Positive

- One fewer stateful controller to operate (no Jenkins controller PVC/backup story).
- Pipeline definitions are ordinary Kubernetes YAML, reconciled by the same GitOps loop
  (ArgoCD) as every other platform component — no separate CasC/JCasC layer.
- Direct DORA metric emission via OTel + Prometheus scrape, no custom webhook service.

### Negative

- No built-in web UI for pipeline visualization (Tekton Dashboard would be a separate
  component to deploy, not yet done) — pipeline status is read via `kubectl` or Backstage
  integration, not a Jenkins-Blue-Ocean-style browser view.
- Smaller reusable-task ecosystem than Jenkins' 1,800+ plugins; golden-path Tasks are
  hand-written in this repo rather than pulled from a marketplace.

## Related Decisions

- Supersedes [ADR-004: Jenkins for CI/CD](ADR-004%20jenkins%204%20ci.md)
- [ADR-003: ArgoCD](ADR-003%20argocd.md) — Tekton triggers ArgoCD sync via GitOps repo
  commits, same separation of concerns ADR-004 already established (CI builds, CD
  reconciles)
- [ADR-038: Native PromQL DORA Metrics](ADR-038%20native-promql-dora-metrics.md) — consumes
  Tekton's PipelineRun duration metric for Lead Time for Changes
