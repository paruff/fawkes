# Vector Database (Weaviate)

## Overview

This document explains the vector database implementation in Fawkes using Weaviate. The vector database is a core component of the RAG (Retrieval Augmented Generation) system that powers AI-assisted development features.

## What is a Vector Database?

A vector database is a specialized database designed to store and query high-dimensional vectors (embeddings) efficiently. Unlike traditional databases that store structured data, vector databases excel at:

- **Semantic Search**: Finding similar content based on meaning, not just keywords
- **Similarity Matching**: Finding items similar to a given item
- **Recommendation Systems**: Suggesting relevant content based on context
- **Machine Learning**: Supporting ML models with efficient vector operations

### Key Concepts

**Embeddings**: Numerical representations of data (text, images, etc.) as vectors in high-dimensional space. Similar items have vectors that are close to each other.

**Vector Search**: Finding vectors in the database that are most similar to a query vector using distance metrics (e.g., cosine similarity, Euclidean distance).

**HNSW (Hierarchical Navigable Small World)**: An efficient algorithm for approximate nearest neighbor search in high-dimensional spaces.

## Why Weaviate?

Weaviate was chosen as the vector database for Fawkes for several reasons:

### Technical Advantages

1. **Native Vector Search**: Built from the ground up for vector operations with HNSW algorithm
2. **GraphQL API**: Flexible, modern API that's easy to use and integrate
3. **Built-in Vectorization**: Supports multiple vectorization modules (transformers, OpenAI, etc.)
4. **Kubernetes Native**: Designed for cloud-native deployments with Helm charts
5. **Hybrid Search**: Combines vector search with traditional keyword search (BM25)
6. **Schema Flexibility**: Dynamic schema with strong typing

### Operational Advantages

1. **Active Community**: Large community with good documentation and examples
2. **Production Ready**: Battle-tested in production by many organizations
3. **Scalability**: Horizontal scaling support with replication
4. **Monitoring**: Prometheus metrics built-in
5. **Backup & Restore**: Built-in backup and disaster recovery features

### Alternatives Considered

| Database | Pros | Cons | Decision |
|----------|------|------|----------|
| **Weaviate** | Native vector DB, GraphQL API, K8s native | Learning curve | ✅ **Selected** |
| Pinecone | Fully managed, easy to use | Cloud-only, vendor lock-in | ❌ Not self-hosted |
| Milvus | High performance, FAISS-based | Complex setup, heavy | ❌ Too complex |
| PostgreSQL pgvector | Simple extension, familiar | Limited scale, slower | ❌ Not specialized |
| ChromaDB | Simple, Python-first | Immature, limited features | ❌ Too new |

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Application Layer                            │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ AI Assistant │  │ RAG Service  │  │ Doc Search   │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                  │                  │                  │
│         └──────────────────┴──────────────────┘                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ GraphQL/REST API
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                     Weaviate Cluster                             │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ GraphQL API Layer                                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                    │
│  ┌──────────────┬───────────┴──────────┬──────────────┐       │
│  │              │                       │              │        │
│  │  Vector Index│   Object Store       │ Inverted Index│       │
│  │  (HNSW)      │                      │ (BM25)       │        │
│  └──────────────┴──────────────────────┴──────────────┘        │
│                             │                                    │
│                    Persistent Storage                            │
│                         (10GB PVC)                               │
└─────────────────────────────┬───────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│              Embedding Models (text2vec-transformers)            │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ sentence-transformers/all-MiniLM-L6-v2                   │  │
│  │ - 384 dimensions                                          │  │
│  │ - Fast inference                                          │  │
│  │ - Good semantic understanding                             │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Data Model

Weaviate uses a class-based schema model:

```graphql
{
  "class": "FawkesDocument",
  "description": "Fawkes platform documentation and code",
  "vectorizer": "text2vec-transformers",
  "properties": [
    {
      "name": "title",
      "dataType": ["string"],
      "description": "Document title"
    },
    {
      "name": "content",
      "dataType": ["text"],
      "description": "Document content (vectorized)"
    },
    {
      "name": "filepath",
      "dataType": ["string"],
      "description": "File path in repository"
    },
    {
      "name": "category",
      "dataType": ["string"],
      "description": "Document category"
    }
  ]
}
```

## Deployment

### Kubernetes Deployment

Weaviate is deployed via ArgoCD using the official Helm chart:

```bash
# Deployed automatically via ArgoCD
kubectl get application -n fawkes weaviate

# Check deployment status
kubectl get pods -n fawkes -l app.kubernetes.io/name=weaviate
```

### Configuration

Key configuration parameters in `platform/apps/weaviate-application.yaml`:

- **Resources**: 1 CPU, 2Gi memory
- **Storage**: 10GB persistent volume
- **Replicas**: 1 (can scale horizontally)
- **Modules**: text2vec-transformers enabled
- **Authentication**: Anonymous access enabled (MVP)

### Accessing Weaviate

**Local Development (Port Forward)**:
```bash
kubectl port-forward -n fawkes svc/weaviate 8080:80
```

**Within Cluster**:
```
http://weaviate.fawkes.svc:80
```

**Via Ingress**:
```
http://weaviate.127.0.0.1.nip.io
```

## How to Index New Documents

### Using Python Client

```python
import weaviate

# Connect to Weaviate
client = weaviate.Client("http://weaviate.fawkes.svc:80")

# Create or get class
schema = {
    "class": "FawkesDocument",
    "vectorizer": "text2vec-transformers",
    "properties": [
        {
            "name": "title",
            "dataType": ["string"]
        },
        {
            "name": "content",
            "dataType": ["text"]
        }
    ]
}

# Create class if doesn't exist
try:
    client.schema.create_class(schema)
except:
    pass  # Already exists

# Index a document
doc = {
    "title": "Getting Started Guide",
    "content": "This guide will help you get started with Fawkes...",
    "filepath": "docs/getting-started.md",
    "category": "documentation"
}

client.data_object.create(
    data_object=doc,
    class_name="FawkesDocument"
)

# Batch indexing for better performance
with client.batch as batch:
    batch.batch_size = 100
    
    for doc in documents:
        batch.add_data_object(
            data_object=doc,
            class_name="FawkesDocument"
        )
```

### Indexing Strategies

**Full Re-index**: Index all documents from scratch (for initial setup)
```bash
python services/rag/scripts/index-all-docs.py
```

**Incremental Indexing**: Index only changed files (for CI/CD pipeline)
```bash
python services/rag/scripts/index-changed-docs.py --since HEAD~1
```

**Scheduled Indexing**: Daily re-index via CronJob
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: weaviate-indexing
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: indexer
            image: fawkes-rag-indexer:latest
            command: ["python", "index-all-docs.py"]
```

## How to Query and Retrieve Context

### Semantic Search

Find documents by semantic similarity:

```python
# Query by text
result = (
    client.query
    .get("FawkesDocument", ["title", "content", "filepath"])
    .with_near_text({
        "concepts": ["How to deploy applications with ArgoCD"]
    })
    .with_limit(5)
    .with_additional(["certainty", "distance"])
    .do()
)

# Process results
for doc in result["data"]["Get"]["FawkesDocument"]:
    print(f"Title: {doc['title']}")
    print(f"Certainty: {doc['_additional']['certainty']}")
    print(f"Content: {doc['content'][:200]}...")
```

### Hybrid Search

Combine vector search with keyword search:

```python
result = (
    client.query
    .get("FawkesDocument", ["title", "content"])
    .with_hybrid(
        query="ArgoCD deployment",
        alpha=0.5  # 0=keyword only, 1=vector only, 0.5=balanced
    )
    .with_limit(10)
    .do()
)
```

### Filtered Search

Add filters to narrow results:

```python
result = (
    client.query
    .get("FawkesDocument", ["title", "content"])
    .with_near_text({"concepts": ["security scanning"]})
    .with_where({
        "path": ["category"],
        "operator": "Equal",
        "valueString": "documentation"
    })
    .with_limit(5)
    .do()
)
```

### GraphQL Queries

Direct GraphQL query:

```graphql
{
  Get {
    FawkesDocument(
      nearText: {
        concepts: ["kubernetes deployment guide"]
      }
      where: {
        path: ["category"]
        operator: Equal
        valueString: "documentation"
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

### RAG Integration Pattern

Integrate with LLM for RAG:

```python
def answer_question(question: str, llm_client) -> str:
    """Answer question using RAG pattern."""
    
    # 1. Retrieve relevant context from Weaviate
    result = (
        client.query
        .get("FawkesDocument", ["title", "content"])
        .with_near_text({"concepts": [question]})
        .with_limit(5)
        .with_additional(["certainty"])
        .do()
    )
    
    docs = result["data"]["Get"]["FawkesDocument"]
    
    # 2. Filter by relevance threshold
    relevant_docs = [
        doc for doc in docs 
        if doc["_additional"]["certainty"] > 0.7
    ]
    
    # 3. Construct context
    context = "\n\n".join([
        f"# {doc['title']}\n{doc['content']}"
        for doc in relevant_docs
    ])
    
    # 4. Create prompt with context
    prompt = f"""Based on the following context from Fawkes documentation, 
answer the question.

Context:
{context}

Question: {question}

Answer:"""
    
    # 5. Get answer from LLM
    answer = llm_client.generate(prompt)
    
    return answer
```

## Performance Tuning

### Query Performance

**HNSW Configuration**: Tune for speed vs. accuracy trade-off

```python
schema = {
    "class": "FawkesDocument",
    "vectorIndexConfig": {
        "efConstruction": 128,  # Higher = better accuracy, slower build
        "maxConnections": 64,   # Higher = better accuracy, more memory
        "ef": 64                # Higher = better accuracy, slower query
    }
}
```

**Batch Size**: Optimize batch operations

```python
with client.batch as batch:
    batch.batch_size = 100      # Tune based on document size
    batch.num_workers = 4       # Parallel processing
    batch.connection_error_retries = 3
```

### Indexing Performance

**Parallel Indexing**: Use multiple workers

```python
from concurrent.futures import ThreadPoolExecutor

def index_documents_parallel(documents, num_workers=4):
    with ThreadPoolExecutor(max_workers=num_workers) as executor:
        executor.map(lambda doc: index_document(doc), documents)
```

**Incremental Updates**: Only index changed documents

```bash
# Get changed files since last index
git diff --name-only HEAD~1 docs/ | \
  xargs python services/rag/scripts/index-docs.py
```

### Resource Optimization

**Memory**: Adjust based on dataset size
```yaml
resources:
  requests:
    memory: 2Gi    # Minimum for small dataset
  limits:
    memory: 4Gi    # Scale based on # of vectors
```

**CPU**: Scale for query throughput
```yaml
resources:
  requests:
    cpu: 1
  limits:
    cpu: 2
```

**Storage**: Plan for growth
```yaml
persistence:
  size: 10Gi  # Start size
  # Monitor usage and scale as needed
```

### Monitoring Performance

**Key Metrics**:
```bash
# Query latency
weaviate_query_duration_seconds

# Object count
weaviate_objects_total

# Vector index size
weaviate_vector_index_size

# Memory usage
weaviate_memory_usage_bytes
```

**Query Performance Dashboard**:
```promql
# 95th percentile query latency
histogram_quantile(0.95, 
  rate(weaviate_query_duration_seconds_bucket[5m])
)

# Queries per second
rate(weaviate_queries_total[1m])
```

## Troubleshooting

### Common Issues

#### Weaviate Not Ready

**Symptom**: Weaviate returns 503 or connection refused

**Solution**:
```bash
# Check pod status
kubectl get pods -n fawkes -l app.kubernetes.io/name=weaviate

# Check logs
kubectl logs -n fawkes -l app.kubernetes.io/name=weaviate

# Restart if needed
kubectl rollout restart statefulset/weaviate -n fawkes
```

#### Indexing Failures

**Symptom**: Documents not appearing in search results

**Solution**:
```python
# Check if class exists
schema = client.schema.get("FawkesDocument")
print(schema)

# Verify object count
result = client.query.aggregate("FawkesDocument").with_meta_count().do()
print(f"Objects: {result['data']['Aggregate']['FawkesDocument'][0]['meta']['count']}")

# Check batch import errors
with client.batch as batch:
    batch.batch_size = 10
    # ... add objects ...
    
    # Check for errors
    if batch.failed_objects:
        print(f"Failed: {batch.failed_objects}")
```

#### Low Relevance Scores

**Symptom**: Search results have certainty < 0.7

**Possible Causes**:
1. Documents not properly indexed
2. Query doesn't match document content
3. Wrong vectorizer model

**Solution**:
```python
# Try hybrid search instead
result = (
    client.query
    .get("FawkesDocument", ["title"])
    .with_hybrid(query="your query", alpha=0.5)
    .with_limit(5)
    .do()
)

# Verify vectorizer is working
modules = client.get_meta()["modules"]
print(f"Available modules: {modules}")
```

#### Out of Memory

**Symptom**: Weaviate pod OOMKilled

**Solution**:
```bash
# Increase memory limits
kubectl edit statefulset weaviate -n fawkes

# Or scale vertically in ArgoCD app
# resources.limits.memory: 4Gi

# Monitor memory usage
kubectl top pod -n fawkes weaviate-0
```

#### Slow Queries

**Symptom**: Queries taking >1 second

**Solution**:
```python
# Increase ef for better performance
client.schema.update_config(
    "FawkesDocument",
    {
        "vectorIndexConfig": {
            "ef": 128  # Increase from default 64
        }
    }
)

# Use filters to reduce search space
result = (
    client.query
    .get("FawkesDocument", ["title"])
    .with_near_text({"concepts": ["query"]})
    .with_where({
        "path": ["category"],
        "operator": "Equal",
        "valueString": "documentation"
    })
    .with_limit(5)
    .do()
)
```

### Debugging Tips

**Enable Verbose Logging**:
```yaml
env:
  LOG_LEVEL: "debug"
```

**Check API Endpoints**:
```bash
# Health check
curl http://weaviate.fawkes.svc:80/v1/.well-known/ready

# Meta information
curl http://weaviate.fawkes.svc:80/v1/meta

# Schema
curl http://weaviate.fawkes.svc:80/v1/schema

# Objects count
curl http://weaviate.fawkes.svc:80/v1/objects
```

**Test Connection**:
```python
import weaviate

client = weaviate.Client("http://weaviate.fawkes.svc:80")
print(f"Ready: {client.is_ready()}")
print(f"Live: {client.is_live()}")
print(f"Meta: {client.get_meta()}")
```

## Security Considerations

### Authentication (Production)

For production, enable authentication:

```yaml
env:
  AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED: "false"
  AUTHENTICATION_APIKEY_ENABLED: "true"
  AUTHENTICATION_APIKEY_ALLOWED_KEYS: "admin-key,readonly-key"
  AUTHORIZATION_ADMINLIST_ENABLED: "true"
  AUTHORIZATION_ADMINLIST_USERS: "admin"
```

### Network Policies

Restrict access to Weaviate:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: weaviate-netpol
  namespace: fawkes
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: weaviate
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: rag-service
    ports:
    - protocol: TCP
      port: 8080
```

### Data Privacy

**Sensitive Data**: Don't index sensitive information (credentials, PII)

**Access Control**: Implement RBAC for API access

**Encryption**: Enable TLS for API communication

## Backup and Disaster Recovery

### Manual Backup

```bash
# Create backup
kubectl exec -n fawkes weaviate-0 -- \
  curl -X POST http://localhost:8080/v1/backups/filesystem

# List backups
kubectl exec -n fawkes weaviate-0 -- \
  curl http://localhost:8080/v1/backups/filesystem
```

### Automated Backup

Create a CronJob for regular backups:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: weaviate-backup
  namespace: fawkes
spec:
  schedule: "0 1 * * *"  # Daily at 1 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: bitnami/kubectl:latest
            command:
            - /bin/sh
            - -c
            - |
              kubectl exec weaviate-0 -n fawkes -- \
                curl -X POST http://localhost:8080/v1/backups/filesystem
          restartPolicy: OnFailure
```

### Restore from Backup

```bash
# List available backups
kubectl exec -n fawkes weaviate-0 -- \
  curl http://localhost:8080/v1/backups/filesystem

# Restore
kubectl exec -n fawkes weaviate-0 -- \
  curl -X POST http://localhost:8080/v1/backups/filesystem/<backup-id>/restore
```

## Related Documentation

- [Weaviate Official Documentation](https://weaviate.io/developers/weaviate)
- [ADR-031: Vector Database Selection](../adr/ADR-031%20Vector%20Database%20Selection.md)
- [RAG Service README](../../services/rag/README.md)
- [Platform Architecture](../architecture.md)
- [Weaviate Application Manifest](../../platform/apps/weaviate-application.yaml)

## References

- [Weaviate Helm Chart](https://github.com/weaviate/weaviate-helm)
- [Weaviate Python Client](https://weaviate.io/developers/weaviate/client-libraries/python)
- [HNSW Algorithm](https://arxiv.org/abs/1603.09320)
- [Sentence Transformers](https://www.sbert.net/)
