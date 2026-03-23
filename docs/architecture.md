# Platform Architecture

Fawkes is a Kubernetes-native Internal Developer Platform (IDP) that provides
development teams with paved paths to production, integrated observability, and
built-in DORA metrics measurement.

## Architectural Principles

The platform is designed around five architectural principles:

- **GitOps-first** — All configuration lives in Git. ArgoCD continuously
  reconciles the desired state declared in this repository with the live cluster.
- **Declarative over imperative** — Infrastructure and application state are
  described, not scripted.
- **Immutable artifacts** — Container images and infrastructure modules are built
  once and promoted through environments without modification.
- **Observable by default** — Every workload exposes metrics, logs, and traces
  without developer effort.
- **Secure by default** — Zero-trust networking, least-privilege RBAC, and
  policy-as-code guardrails are applied to all workloads.

## Three-Plane Architecture

The platform is organised into three conceptual planes:

### Developer Plane

The developer plane is the surface developers interact with daily.

| Component | Purpose |
|-----------|---------|
| **Backstage** | Software catalog, TechDocs, golden-path templates, and self-service scaffolding |
| **VS Code / Eclipse Che** | Cloud Development Environments pre-configured for each service type |
| **Jenkins** | CI pipelines defined as code in `Jenkinsfile`; shared library in `jenkins-shared-library/` |

### Platform Plane

The platform plane manages workloads and policies across the cluster.

| Component | Purpose |
|-----------|---------|
| **ArgoCD** | GitOps controller; reconciles `platform/apps/` manifests to the live cluster |
| **Kyverno** | Policy-as-code engine; enforces labels, resource limits, and security contexts |
| **External Secrets Operator** | Syncs secrets from HashiCorp Vault into Kubernetes `Secret` objects |
| **Cert-Manager** | Issues and renews TLS certificates automatically |
| **NGINX Ingress** | Routes external traffic to platform services with TLS termination |

### Infrastructure Plane

The infrastructure plane provisions cloud resources and provides the Kubernetes
substrate on which the platform runs.

| Component | Purpose |
|-----------|---------|
| **Terraform** | Provisions cloud resources (EKS/AKS clusters, VPCs, storage) under `infra/` |
| **HashiCorp Vault** | Centralised secrets management; accessed by workloads via the Vault Agent injector |
| **Container Registry** | Stores immutable, versioned container images (GitHub Container Registry) |

## Core Component Interactions

```
Developer commits → GitHub → Jenkins CI pipeline
                                  │
                         Build & test pass
                                  │
                         Image pushed to GHCR
                                  │
                         GitOps manifest updated
                                  │
                          ArgoCD detects delta
                                  │
                         Deploy to Kubernetes
                                  │
                     OpenTelemetry emits spans & metrics
                                  │
                   Prometheus / Grafana / Tempo
```

## Observability Stack

All workloads are instrumented automatically using the OpenTelemetry Operator.

- **Metrics** — Prometheus scrapes `/metrics` from every service; Grafana renders dashboards.
- **Logs** — Structured JSON logs are collected by Fluent Bit and shipped to Loki.
- **Traces** — Distributed traces are stored in Tempo and visualised in Grafana.
- **DORA Metrics** — DevLake aggregates deployment, PR, and incident data to compute
  Deployment Frequency, Lead Time for Changes, Change Failure Rate, and MTTR.

## GitOps Workflow

```
Git repository (source of truth)
       │
 mkdocs.yml / Helm charts / ArgoCD Applications
       │
 ArgoCD watches platform/apps/**
       │
 Sync → Kubernetes applies desired state
       │
 Live cluster matches Git state
```

Full details on the GitOps strategy are available in
[GitOps Strategy](explanation/architecture/gitops-strategy.md).

## Security Architecture

All inter-service communication is encrypted with mutual TLS managed by a service
mesh. Pod Security Admission enforces restricted profiles. Secrets never appear in
Git; they are injected at runtime from Vault.

See [Zero Trust Model](explanation/security/zero-trust-model.md) for the full
security architecture.

## Related Documentation

- [GitOps Strategy](explanation/architecture/gitops-strategy.md) — How ArgoCD manages state
- [Getting Started](getting-started.md) — Deploy your first service
- [Tutorials](tutorials/index.md) — Step-by-step learning paths
