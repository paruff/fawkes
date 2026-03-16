# Extensions

Extensions are optional add-ons for organisations with specific needs. They are not
required for core Fawkes functionality.

## What Are Extensions?

Core Fawkes includes everything needed to run a production-grade Internal Developer
Platform: GitOps with ArgoCD, observability with Prometheus/Grafana, CI/CD with
Jenkins, security scanning, secrets management, and developer portals with Backstage.

Extensions add **advanced capabilities** that introduce additional operational
complexity, resource requirements, and specialist knowledge to manage. They are
designed for organisations that have already stabilised the core platform and need
to solve a specific problem.

## Available Extensions

| Extension | Directory | Components | When to Add |
|---|---|---|---|
| **Data Platform** | `extensions/data-platform/` | DataHub, Great Expectations | You need a data catalog, lineage tracking, or data quality validation |
| **AI** | `extensions/ai/` | Weaviate (vector DB), RAG service | You need semantic search, AI-powered docs retrieval, or LLM-backed tooling |

## How to Deploy an Extension

Extensions ship as ArgoCD Application manifests. To deploy one:

```bash
# 1. Review the extension's README and resource requirements
cat extensions/ai/README.md

# 2. Apply the ArgoCD Application manifest
kubectl apply -f extensions/ai/weaviate-application.yaml -n fawkes
kubectl apply -f extensions/ai/rag-service-application.yaml -n fawkes
```

Alternatively, add the extension directory to a new ArgoCD ApplicationSet targeting
`extensions/` to enable GitOps management of your chosen extensions.

## Design Principles

- **Opt-in only** — extensions are never deployed as part of `make dev-up` or the
  core bootstrap.
- **Self-contained** — each extension directory contains everything needed to
  deploy it: ArgoCD manifests, Helm values, and a README.
- **Documented trade-offs** — every extension README explains the resource costs,
  operational overhead, and prerequisite knowledge required.

## See Also

- [Core Platform Architecture](../docs/ARCHITECTURE.md)
- [Extensions Documentation](../docs/extensions/index.md)
