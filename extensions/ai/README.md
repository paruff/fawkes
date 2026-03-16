# AI Extension

This extension adds AI-powered capabilities to Fawkes: a vector database (Weaviate)
and a Retrieval-Augmented Generation (RAG) service for semantic search over platform
documentation and knowledge bases.

## Components

| Component | Purpose | Resource Requirement |
|---|---|---|
| **Weaviate** | Vector database for semantic search | 2–4 GB RAM, 2 vCPU |
| **RAG Service** | FastAPI service wrapping Weaviate for doc retrieval | 256 MB RAM, 0.5 vCPU |

## Prerequisites

- Core Fawkes platform running (Tier 1 minimum)
- At least 6 GB free cluster memory
- `fawkes` namespace exists

## Deploying

```bash
# Deploy Weaviate first (RAG service depends on it)
kubectl apply -f extensions/ai/weaviate-application.yaml -n fawkes

# Wait for Weaviate to be ready, then deploy RAG service
kubectl apply -f extensions/ai/rag-service-application.yaml -n fawkes

# Verify
kubectl get pods -n fawkes -l component=ai
```

## Services

The Python service that powers the RAG endpoint lives in `extensions/ai/services/rag/`.
It is deployed via `rag-service-application.yaml` and depends on Weaviate being available.

## When to Add This Extension

Add this extension if your organisation:

- Wants semantic search over internal documentation
- Is building LLM-powered developer tooling
- Needs a vector store for AI embeddings

## Operational Notes

- Weaviate requires persistent storage in production; review the `weaviate/values.yaml`
  for storage class configuration.
- Index population is handled by the RAG service's indexing job.
- Monitor Weaviate memory usage — it caches vectors in RAM.

## See Also

- [AI Usage Policy](../../docs/ai/usage-policy.md)
- [Vector Database Reference](../../docs/ai/vector-database.md)
- [Extensions Overview](../README.md)
