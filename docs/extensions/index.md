# Extensions

Extensions are optional add-ons for organisations with specific needs. They are **not
required** for core Fawkes functionality.

## What Is Core vs Extension?

**Core Fawkes** provides everything needed to run a production-grade Internal Developer
Platform out of the box:

- GitOps delivery with ArgoCD
- Developer portal with Backstage
- CI/CD pipelines with Jenkins
- Observability (Prometheus, Grafana, OpenSearch, Tempo)
- Security scanning (SonarQube, Trivy, Vault)
- Collaboration (Mattermost, Focalboard)
- DORA metrics collection and dashboards
- Dojo learning environment

**Extensions** add advanced capabilities that come with meaningful operational
overhead. They are designed for organisations that have already stabilised the
core platform and have a specific need.

## Available Extensions

### Data Platform

> **Directory**: `extensions/data-platform/`

Adds data cataloging, lineage tracking, and data quality validation.

| Component | Purpose |
|---|---|
| **DataHub** | Enterprise data catalog — discover, document, and track lineage across datasets |
| **Great Expectations** | Data quality validation with Prometheus metrics export |

**When to add**: Your organisation manages multiple data sources and needs a
catalog, or you have data quality requirements that need automated validation.

**Resource cost**: 4–8 GB RAM, 4 vCPU additional. Requires OpenSearch (Tier 2).

the Data Platform Extension (available in the repository under `extensions/data-platform/`)

---

### AI

> **Directory**: `extensions/ai/`

Adds a vector database and Retrieval-Augmented Generation (RAG) service for
semantic search and LLM-powered tooling.

| Component | Purpose |
|---|---|
| **Weaviate** | Vector database for storing and querying AI embeddings |
| **RAG Service** | FastAPI service providing semantic search over platform knowledge |

**When to add**: You are building LLM-powered developer tooling, need semantic
search over internal documentation, or want to experiment with AI-assisted platform
capabilities.

**Resource cost**: 2–4 GB RAM, 2 vCPU additional.

the AI Extension (available in the repository under `extensions/ai/`)

---

## Deployment Pattern

Extensions are self-contained ArgoCD Application manifests in the `extensions/`
directory. They are **not** included in the core `platform/apps/` bootstrap, so
they will not be deployed unless explicitly applied.

```bash
# Example: deploy the AI extension
kubectl apply -f extensions/ai/weaviate-application.yaml -n fawkes
kubectl apply -f extensions/ai/rag-service-application.yaml -n fawkes
```

## Extension Design Principles

- **Opt-in**: Extensions are never deployed by `make dev-up` or the core bootstrap.
- **Self-contained**: Each extension directory includes all manifests, Helm values,
  and documentation needed to deploy it independently.
- **Documented trade-offs**: Every extension README lists resource costs, prerequisites,
  and operational considerations.

## See Also

- [Core Architecture](../ARCHITECTURE.md) — overview of what is included in the core platform
- [AI Documentation](../ai/index.md) — AI usage policy, Copilot setup, and more
- [Data Platform Documentation](../data-platform/index.md) — DataHub and data quality guides
