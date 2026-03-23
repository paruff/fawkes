# Flux CD

[Flux](https://fluxcd.io/) is a CNCF Graduated project for GitOps continuous delivery
on Kubernetes. Like ArgoCD, Flux follows a pull-based model: controllers running in the
cluster watch a Git repository and reconcile the live state to match.

## Flux vs ArgoCD

Fawkes primarily uses **ArgoCD** for GitOps. Flux is documented here as a reference
for teams that have existing Flux installations or are evaluating alternatives.

| Feature | Flux | ArgoCD |
|---------|------|--------|
| Architecture | Controller-based (no server) | Server + UI + CLI |
| UI | Minimal (3rd-party) | Rich built-in UI |
| Multi-tenancy | Native | App Projects |
| Helm support | HelmRelease CRD | Helm Application |
| Image automation | ✅ Built-in | Plugin required |
| RBAC | Kubernetes-native | ArgoCD RBAC |
| Community | CNCF Graduated | CNCF Graduated |

## Flux Core Components

- **source-controller** — Watches Git repositories, Helm repositories, and OCI
  registries for changes.
- **kustomize-controller** — Applies Kustomization objects to the cluster.
- **helm-controller** — Manages HelmRelease objects, driving Helm deployments.
- **notification-controller** — Sends alerts and receives webhooks.
- **image-automation-controller** — Automates image tag updates in Git.

## Quick Example

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: fawkes-platform
spec:
  url: https://github.com/paruff/fawkes
  ref:
    branch: main
  interval: 1m
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: platform-apps
spec:
  sourceRef:
    kind: GitRepository
    name: fawkes-platform
  path: ./platform/apps
  interval: 5m
  prune: true
```

## See Also

- [GitOps Strategy](../explanation/architecture/gitops-strategy.md)
- [Onboard Service to ArgoCD](../how-to/gitops/onboard-service-argocd.md)
- [Continuous Delivery Pattern](../patterns/continuous-delivery.md)
