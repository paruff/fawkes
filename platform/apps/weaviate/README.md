# Weaviate - Vector Database for AI/ML

## Purpose

Weaviate is a cloud-native, modular vector search engine for storing and querying vector embeddings. It powers the RAG (Retrieval-Augmented Generation) architecture in Fawkes for AI-assisted development.

## Key Features

- **Vector Search**: Semantic search using ML models
- **Hybrid Search**: Combine vector and keyword search
- **GraphQL API**: Flexible query interface
- **Multiple Models**: Support for various embedding models
- **Kubernetes Native**: Designed for cloud deployment
- **CRUD Operations**: Full database functionality
- **Multi-tenancy**: Isolated data per tenant

## Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                     Application Layer                            │
│  ├─ RAG Service                                                 │
│  ├─ AI Assistant                                                │
│  └─ Documentation Search                                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Weaviate Cluster                             │
│  ├─ GraphQL API                                                 │
│  ├─ Vector Index (HNSW)                                         │
│  ├─ Inverted Index (BM25)                                       │
│  └─ Object Store                                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Embedding Models                               │
│  ├─ text2vec-transformers                                       │
│  ├─ text2vec-openai                                             │
│  └─ multi2vec-clip                                              │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Accessing Weaviate

```bash
# Port-forward to Weaviate
kubectl port-forward -n weaviate svc/weaviate 8080:80

# Access API
curl http://localhost:8080/v1/schema
```

### Creating a Schema

```graphql
mutation {
  createClass(
    class: {
      class: "Documentation"
      description: "Fawkes platform documentation"
      vectorizer: "text2vec-transformers"
      properties: [
        { name: "title", dataType: ["string"] }
        { name: "content", dataType: ["text"] }
        { name: "url", dataType: ["string"] }
      ]
    }
  )
}
```

### Importing Data

```python
import weaviate

client = weaviate.Client("http://weaviate.weaviate.svc:80")

# Add document
client.data_object.create(
    {
        "title": "Getting Started with Fawkes",
        "content": "Fawkes is an Internal Delivery Platform...",
        "url": "https://fawkes.io/docs/getting-started"
    },
    "Documentation"
)
```

### Semantic Search

```graphql
{
  Get {
    Documentation(nearText: { concepts: ["deploy kubernetes application"] }, limit: 5) {
      title
      content
      url
      _additional {
        certainty
      }
    }
  }
}
```

## RAG Integration

Weaviate powers the RAG system for AI-assisted coding:

```python
# RAG query flow
def query_rag(question: str) -> str:
    # 1. Generate embedding for question
    embedding = embed_text(question)

    # 2. Query Weaviate for relevant docs
    results = client.query.get("Documentation", ["content"]) \
        .with_near_vector({"vector": embedding}) \
        .with_limit(5) \
        .do()

    # 3. Construct context from results
    context = "\n\n".join([doc["content"] for doc in results])

    # 4. Send to LLM with context
    response = llm.generate(
        prompt=f"Context: {context}\n\nQuestion: {question}"
    )

    return response
```

## Use Cases

### Documentation Search

Index all platform documentation for semantic search:

```bash
# Index documentation
python scripts/index-docs.py --source docs/ --collection Documentation
```

### Code Search

Search code by semantic meaning:

```graphql
{
  Get {
    CodeSnippet(nearText: { concepts: ["kubernetes deployment configuration"] }) {
      code
      language
      description
    }
  }
}
```

### Issue Similarity

Find similar issues and tickets:

```graphql
{
  Get {
    Issue(nearText: { concepts: ["ArgoCD sync failure"] }) {
      title
      description
      resolution
    }
  }
}
```

## Scaling

Weaviate can be scaled horizontally:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: weaviate
spec:
  replicas: 3  # Scale to 3 nodes
  ...
```

## Backup and Restore

### Backup

```bash
# Backup Weaviate data
kubectl exec -n weaviate weaviate-0 -- \
  weaviate backup create --include-all
```

### Restore

```bash
# Restore from backup
kubectl exec -n weaviate weaviate-0 -- \
  weaviate backup restore --backup-id <backup-id>
```

## Monitoring

Weaviate exposes Prometheus metrics:

```yaml
# ServiceMonitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: weaviate
spec:
  selector:
    matchLabels:
      app: weaviate
  endpoints:
    - port: metrics
```

Key metrics:

- `weaviate_vector_dimensions` - Vector dimensions
- `weaviate_objects_total` - Total objects stored
- `weaviate_query_duration_seconds` - Query latency

## Troubleshooting

### High Memory Usage

Weaviate can use significant memory for large datasets:

```yaml
resources:
  requests:
    memory: 4Gi
  limits:
    memory: 8Gi
```

### Slow Queries

Optimize with:

- Increase `maxConnections` in HNSW config
- Use hybrid search for better performance
- Add filters to reduce search space

## Related Documentation

- [Weaviate Documentation](https://weaviate.io/developers/weaviate)
- [ADR-031: Vector Database Selection](../../../docs/adr/ADR-031%20Vector%20Database%20Selection.md)
- [RAG Architecture Guide](../../../docs/ai/vector-database.md)
