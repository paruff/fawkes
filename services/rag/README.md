# RAG Service

## Overview

The RAG (Retrieval Augmented Generation) service provides AI-assisted development capabilities by storing and retrieving embeddings of internal documentation, code, and chat history.

## Components

- **Weaviate**: Vector database for storing embeddings
- **Indexing Scripts**: Tools for indexing documentation and code
- **Query Interface**: API for retrieving context for AI systems

## Directory Structure

```
services/rag/
├── scripts/
│   └── test-indexing.py    # Test script for Weaviate indexing
└── README.md               # This file
```

## Prerequisites

Install the required Python dependencies:

```bash
pip install weaviate-client
```

## Testing Weaviate

Test the Weaviate deployment and indexing functionality:

```bash
# Using default localhost URL
python services/rag/scripts/test-indexing.py

# Using custom Weaviate URL
python services/rag/scripts/test-indexing.py --weaviate-url http://weaviate.fawkes.svc:80

# Using port-forward to test Kubernetes deployment
kubectl port-forward -n fawkes svc/weaviate 8080:80
python services/rag/scripts/test-indexing.py
```

The test script will:
1. Connect to Weaviate
2. Create a test schema for documents
3. Index sample documents (ADRs, README, docs)
4. Perform semantic search queries
5. Validate relevance scores (>0.7)

## Accessing Weaviate

### Port Forward (Local Development)

```bash
kubectl port-forward -n fawkes svc/weaviate 8080:80
```

### GraphQL Endpoint

Access the GraphQL API at:
- Local: `http://localhost:8080/v1/graphql`
- Kubernetes: `http://weaviate.fawkes.svc:80/v1/graphql`

### REST API

Check Weaviate status:

```bash
curl http://localhost:8080/v1/meta
```

## Usage Examples

### Python Client

```python
import weaviate

# Connect to Weaviate
client = weaviate.Client("http://weaviate.fawkes.svc:80")

# Check if ready
print(client.is_ready())

# Query schema
schema = client.schema.get()
print(schema)

# Semantic search
result = (
    client.query
    .get("FawkesDocument", ["title", "content"])
    .with_near_text({"concepts": ["deployment guide"]})
    .with_limit(5)
    .do()
)
```

### GraphQL Query

```graphql
{
  Get {
    FawkesDocument(
      nearText: {
        concepts: ["kubernetes deployment"]
      }
      limit: 5
    ) {
      title
      filepath
      content
      _additional {
        certainty
        distance
      }
    }
  }
}
```

## Troubleshooting

### Connection Issues

If you can't connect to Weaviate:

1. Check pod status:
   ```bash
   kubectl get pods -n fawkes -l app.kubernetes.io/name=weaviate
   ```

2. Check pod logs:
   ```bash
   kubectl logs -n fawkes -l app.kubernetes.io/name=weaviate
   ```

3. Verify service:
   ```bash
   kubectl get svc -n fawkes weaviate
   ```

### Indexing Failures

If indexing fails:

1. Ensure Weaviate is ready:
   ```bash
   curl http://localhost:8080/v1/.well-known/ready
   ```

2. Check transformers module:
   ```bash
   kubectl get pods -n fawkes -l app=weaviate-t2v-transformers
   ```

3. Verify schema:
   ```bash
   curl http://localhost:8080/v1/schema
   ```

## Next Steps

- Implement production indexing pipeline for all documentation
- Add incremental indexing for code changes
- Integrate with AI assistant for context retrieval
- Add monitoring and alerting

## Related Documentation

- [Vector Database Documentation](../../docs/ai/vector-database.md)
- [Weaviate README](../../platform/apps/weaviate/README.md)
- [Architecture Documentation](../../docs/architecture.md)
