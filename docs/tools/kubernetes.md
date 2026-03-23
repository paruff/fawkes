# Kubernetes

[Kubernetes](https://kubernetes.io/) (K8s) is an open-source container orchestration
platform that automates deployment, scaling, and management of containerised workloads.
Fawkes is built on Kubernetes and uses it as the runtime foundation for all platform
components and application workloads.

## How Fawkes Uses Kubernetes

Kubernetes manifests and Helm chart values live in `platform/` and `charts/`. ArgoCD
reconciles these declarative definitions with the live cluster continuously.

```
platform/
  apps/           # ArgoCD Application manifests
  bootstrap/      # Cluster bootstrap (ArgoCD install, Kyverno, cert-manager)
  policies/       # OPA/Kyverno policies
charts/
  backstage/      # Helm chart for Backstage portal
  ...
```

## Key Resources

**Deployment** — Manages a replicated set of pods. The standard unit for stateless
application workloads. Fawkes requires resource `requests` and `limits` on every container.

**Service** — Provides a stable network endpoint for a set of pods. ClusterIP for
internal traffic, LoadBalancer or Ingress for external access.

**Ingress** — Routes HTTP/HTTPS traffic from outside the cluster to internal services,
handling TLS termination via cert-manager.

**Namespace** — Provides isolation between platform components (`argocd`, `backstage`,
`monitoring`) and team workloads.

**ConfigMap / Secret** — Store configuration and sensitive data. Fawkes uses the
External Secrets Operator to sync secrets from HashiCorp Vault into `Secret` objects —
never store raw secrets in Git.

## Required Labels

Every Kubernetes resource in Fawkes must carry these labels:

```yaml
labels:
  app: my-service
  version: "1.2.3"
  component: backend
  managed-by: fawkes
```

These labels drive observability dashboards, policy enforcement (Kyverno), and ArgoCD
application grouping.

## Resource Limits

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

All containers must declare resource requests and limits. The `validate-resources` make
target checks actual utilisation against a 70% target.

## See Also

- [Architecture Overview](../architecture.md)
- [GitOps Strategy](../explanation/architecture/gitops-strategy.md)
- [Onboard Service to ArgoCD](../how-to/gitops/onboard-service-argocd.md)
