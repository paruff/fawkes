# Fawkes Architecture

> **Priority 2 context file** — read before making any cross-component change.
> See also: `AGENTS.md` §4 (Architecture Rules), `docs/CHANGE_IMPACT_MAP.md`.

---

## Table of Contents

1. [Component Overview](#component-overview)
2. [Layer Dependency Rules](#layer-dependency-rules)
3. [Component Diagram](#component-diagram)
4. [Data Flow: Commit to Metrics](#data-flow-commit-to-metrics)
5. [Allowed Inter-Service Communication](#allowed-inter-service-communication)
6. [Observability Stack](#observability-stack)
7. [Network Namespace Layout](#network-namespace-layout)
8. [Cross-Platform Dependencies](#cross-platform-dependencies)

---

## Component Overview

Fawkes is composed of four platform layers that must only depend downward:

| Layer | Directory | Primary Language | Responsibility |
|---|---|---|---|
| **Services** | `services/` | Python (FastAPI) | Stateless business-logic microservices. Go is **not** used here; Go appears only in `tests/terratest/` for infrastructure tests. |
| **Platform** | `platform/`, `charts/` | YAML + Helm | Kubernetes manifests, ArgoCD apps, Helm charts |
| **Infrastructure** | `infra/` | HCL (Terraform) | Cloud provisioning, IaC modules |
| **Scripts** | `scripts/` | Bash / Python | Automation helpers that call services and CLI tools |

---

## Layer Dependency Rules

Dependencies flow **downward only**. No layer may import or depend on a layer above it.

```
┌──────────────────────────────────────────────┐
│  Services  (services/)                        │  ← business logic, APIs
│  No direct cloud or infra calls              │
└─────────────────┬────────────────────────────┘
                  │ depends on ↓
┌─────────────────▼────────────────────────────┐
│  Platform  (platform/, charts/)               │  ← Helm, ArgoCD, K8s manifests
│  Declares desired state; does not call APIs  │
└─────────────────┬────────────────────────────┘
                  │ depends on ↓
┌─────────────────▼────────────────────────────┐
│  Infrastructure  (infra/)                     │  ← Terraform, cloud resources
│  Provisions what platform needs              │
└──────────────────────────────────────────────┘
```

**Violations that are never allowed:**

- `infra/` importing or calling anything in `services/` or `platform/`
- `platform/` containing application business logic
- `services/` directly provisioning cloud resources (use platform abstractions)
- `scripts/` containing business logic (call services instead)

---

## Component Diagram

```mermaid
graph TD
    Dev[Developer] -->|git push| GitHub[GitHub SCM]

    GitHub -->|webhook| Jenkins[Jenkins CI]
    GitHub -->|GitOps sync| ArgoCD[ArgoCD]

    Jenkins -->|build & push| Registry[Container Registry]
    Jenkins -->|deploy events| DevLake[DevLake DORA]

    ArgoCD -->|reconcile| K8s[Kubernetes Cluster]
    Registry -->|image pull| K8s

    K8s -->|hosts| Backstage[Backstage Portal]
    K8s -->|hosts| Services[Platform Services]
    K8s -->|hosts| Observability[Observability Stack]

    Backstage -->|catalog / templates| ArgoCD
    Backstage -->|plugin data| Jenkins
    Backstage -->|metrics display| DevLake

    Services -->|OTLP metrics + traces| OTel[OpenTelemetry Collector]
    Services -->|logs| FluentBitFwd[Fluent Bit]
    OTel -->|metrics| Prometheus[Prometheus]
    OTel -->|traces| Tempo[Grafana Tempo]
    FluentBitFwd --> OpenSearch[OpenSearch]

    Prometheus -->|data source| Grafana[Grafana]
    OpenSearch -->|data source| Grafana
    Tempo -->|data source| Grafana

    DevLake -->|DORA dashboards| Grafana

    subgraph Obstackd [Observability — obstackd]
        Prometheus
        Grafana
        Tempo
        OpenSearch
        OTel[OpenTelemetry Collector]
    end

    subgraph Deliveryd [CI/CD — deliveryd]
        Jenkins
        ArgoCD
        DevLake
    end
```

---

## Data Flow: Commit to Metrics

The end-to-end journey from a code commit to DORA metrics:

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant Jenkins as Jenkins CI
    participant Registry as Container Registry
    participant ArgoCD as ArgoCD
    participant K8s as Kubernetes
    participant DevLake as DevLake
    participant Grafana as Grafana

    Dev->>GH: git push / PR merge
    GH->>Jenkins: webhook trigger
    Jenkins->>Jenkins: build, test, scan (SAST, container)
    Jenkins->>Registry: push image (pinned tag/digest)
    Jenkins->>GH: update image tag in GitOps repo
    Jenkins->>DevLake: emit build event (lead-time start)

    GH->>ArgoCD: detect diff in desired state
    ArgoCD->>K8s: apply manifests / Helm upgrade
    K8s-->>ArgoCD: reconciled (healthy)
    ArgoCD->>DevLake: emit deploy event (lead-time end)

    DevLake->>DevLake: calculate DORA metrics
    DevLake->>Grafana: expose metrics via API
    Grafana-->>Dev: DORA dashboard updated
```

---

## Allowed Inter-Service Communication

Services communicate via HTTP/REST only. Direct database sharing is not permitted.

| Caller | Callee | Protocol | Notes |
|---|---|---|---|
| Backstage (portal) | `analytics-dashboard` | HTTP | DORA trend data for portal widgets |
| Backstage (portal) | `discovery-metrics` | HTTP | Service health summaries |
| `feedback-bot` | `feedback` service | HTTP | Store feedback events |
| `friction-bot` | `friction-cli` | HTTP | Friction signal aggregation |
| `smart-alerting` | Grafana Alertmanager | HTTP | Route alert rules |
| `anomaly-detection` | Prometheus | HTTP (PromQL) | Pull metrics for ML analysis |
| `insights` | `analytics-dashboard` | HTTP | Aggregated insight queries |
| `vsm` service | DevLake | HTTP | Value stream mapping data |
| `rag` service | Weaviate | HTTP | Vector store queries |
| Any service | OpenTelemetry Collector | OTLP/gRPC | Traces and metrics export |

**Rules:**

- Services do **not** call `infra/` APIs or Terraform directly.
- Services do **not** share databases — each service owns its own data store.
- All external traffic routes through the Kubernetes Ingress controller.
- Service-to-service calls within the cluster use Kubernetes DNS (`svc.cluster.local`).

---

## Observability Stack

All platform components emit telemetry through a unified stack (deployed via `platform/apps/`):

```mermaid
graph LR
    Apps[Platform Services] -->|OTLP| OTel[OpenTelemetry Collector]
    OTel -->|metrics| Prom[Prometheus]
    OTel -->|traces| Tempo[Grafana Tempo]
    OTel -->|logs| FluentBit[Fluent Bit]
    FluentBit --> OpenSearch[OpenSearch]

    Prom --> Grafana[Grafana]
    Tempo --> Grafana
    OpenSearch --> Grafana

    Grafana -->|DORA dashboards| DevLake[DevLake]
    Grafana -->|alerts| Alertmanager[Alertmanager]
    Alertmanager -->|notify| SmartAlerting[smart-alerting service]
```

| Signal | Collector | Storage | Query |
|---|---|---|---|
| Metrics | OpenTelemetry Collector | Prometheus | Grafana / PromQL |
| Logs | Fluent Bit | OpenSearch | Grafana / Lucene |
| Traces | OpenTelemetry Collector | Grafana Tempo | Grafana / TraceQL |
| DORA metrics | DevLake | DevLake DB | Grafana / DevLake API |

---

## Network Namespace Layout

All Fawkes workloads run within a dedicated Kubernetes namespace hierarchy:

```mermaid
graph TD
    Cluster[Kubernetes Cluster]

    Cluster --> NS_Argocd[argocd]
    Cluster --> NS_Platform[fawkes-platform]
    Cluster --> NS_Obs[fawkes-observability]
    Cluster --> NS_CICD[fawkes-cicd]
    Cluster --> NS_Security[fawkes-security]
    Cluster --> NS_Apps[fawkes-apps]

    NS_Argocd -->|manages| NS_Platform
    NS_Argocd -->|manages| NS_Obs
    NS_Argocd -->|manages| NS_CICD

    NS_Platform -->|Backstage, Backstage DB| PlatComp[Portal Components]
    NS_Obs -->|Prometheus, Grafana, Tempo, OpenSearch| ObsComp[Observability Components]
    NS_CICD -->|Jenkins, DevLake| CICDComp[CI/CD Components]
    NS_Security -->|Vault, SonarQube, Trivy| SecComp[Security Components]
    NS_Apps -->|team workloads| AppComp[Application Services]
```

| Namespace | Components | Ingress |
|---|---|---|
| `argocd` | ArgoCD server, repo-server, application-controller | Internal only |
| `fawkes-platform` | Backstage portal, PostgreSQL | External (HTTPS) |
| `fawkes-observability` | Prometheus, Grafana, Tempo, OpenSearch, OTel Collector | Internal + Grafana external |
| `fawkes-cicd` | Jenkins, DevLake | Internal + Jenkins external |
| `fawkes-security` | Vault, SonarQube, Trivy operator | Internal only |
| `fawkes-apps` | Platform microservices (`services/`) | Per-service ingress rules |

**NetworkPolicy rule**: namespaces may only receive traffic from namespaces explicitly listed in their `NetworkPolicy` manifests (`platform/policies/`). Cross-namespace calls require explicit policy approval.

---

## Cross-Platform Dependencies

### Fawkes ↔ Obstackd (Observability Platform)

Fawkes services instrument themselves using the OpenTelemetry SDK and export to the in-cluster OpenTelemetry Collector. The collector fans out to Prometheus (metrics), Tempo (traces), and Fluent Bit → OpenSearch (logs). Grafana provides the unified query and dashboard layer.

**Dependency direction:** `services/` → OTel Collector → Obstackd storage backends. Obstackd does not call back into Fawkes services.

### Fawkes ↔ Deliveryd (CI/CD Platform)

Jenkins receives webhooks from GitHub and emits build/deploy events to DevLake. ArgoCD polls the GitOps repository and applies manifests to Kubernetes. DevLake aggregates events from both Jenkins (build lead time) and ArgoCD (deployment frequency, change failure rate) to compute DORA metrics.

**Dependency direction:** GitHub → Jenkins → DevLake ← ArgoCD ← GitHub. DevLake and Grafana are read-only consumers of these events.

### Fawkes ↔ External Identity (GitHub OAuth / Vault)

Backstage and ArgoCD authenticate users via GitHub OAuth. Secrets (API keys, DB passwords, image pull secrets) are stored in Vault and synced to Kubernetes Secrets by the External Secrets Operator.

**Dependency direction:** Platform components → Vault (read). `infra/` Terraform provisions Vault; `platform/` manifests consume it.

---

> For cross-component change impact, see [`docs/CHANGE_IMPACT_MAP.md`](CHANGE_IMPACT_MAP.md).
> `docs/API_SURFACE.md` and `docs/KNOWN_LIMITATIONS.md` are planned context files (AGENTS.md §3 Priority 3 and 4) that do not yet exist. They should be created before those priorities can be satisfied.
