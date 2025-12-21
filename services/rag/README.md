# RAG Service

## Overview

The RAG (Retrieval Augmented Generation) service provides AI-assisted development capabilities by storing and retrieving embeddings of internal documentation, code, and chat history. It offers a FastAPI-based REST API for semantic search over Fawkes platform documentation.

## Components

- **FastAPI Service**: REST API for context retrieval (`app/main.py`)
- **Weaviate Integration**: Vector database client for semantic search
- **Indexing Scripts**: Tools for indexing documentation and code
- **Kubernetes Manifests**: Deployment configurations for K8s

## Directory Structure

```
services/rag/
├── app/
│   ├── __init__.py
│   └── main.py             # FastAPI application
├── scripts/
│   ├── test-indexing.py    # Test script for Weaviate indexing
│   └── index-docs.py       # Production indexing script
├── tests/
│   └── unit/
│       └── test_main.py    # Unit tests
├── Dockerfile              # Multi-stage Docker build
├── requirements.txt        # Python dependencies
├── requirements-dev.txt    # Development dependencies
└── README.md              # This file
```

## Prerequisites

Install the required Python dependencies:

```bash
pip install -r requirements.txt
```

For development:
```bash
pip install -r requirements-dev.txt
```

## Quick Start

### 1. Index Documentation

Index internal documentation into Weaviate:

```bash
# Port forward to Weaviate (if testing locally)
kubectl port-forward -n fawkes svc/weaviate 8080:80

# Run indexing script
cd services/rag
python scripts/index-docs.py

# Or with custom URL
python scripts/index-docs.py --weaviate-url http://weaviate.fawkes.svc:80

# Dry run to see what would be indexed
python scripts/index-docs.py --dry-run
```

The indexing script will:
1. Scan `docs/`, `platform/`, `infra/` directories
2. Extract markdown, YAML, and code files
3. Chunk documents into 512-token segments
4. Generate embeddings via Weaviate's text2vec-transformers
5. Store in Weaviate with metadata
6. Handle incremental updates based on file hashes

### 2. Run the Service Locally

```bash
cd services/rag

# Set environment variables
export WEAVIATE_URL=http://localhost:8080
export SCHEMA_NAME=FawkesDocument

# Run with uvicorn
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Or run directly
python -m app.main
```

### 3. Test the API

```bash
# Health check
curl http://localhost:8000/api/v1/health

# Query for context
curl -X POST http://localhost:8000/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "How do I deploy a new service?",
    "top_k": 5,
    "threshold": 0.7
  }'

# Access OpenAPI docs
open http://localhost:8000/docs

# View metrics
curl http://localhost:8000/metrics
```

## Testing Weaviate

Test the Weaviate deployment and indexing functionality:

```bash
# Using default localhost URL
python scripts/test-indexing.py

# Using custom Weaviate URL
python scripts/test-indexing.py --weaviate-url http://weaviate.fawkes.svc:80

# Using port-forward to test Kubernetes deployment
kubectl port-forward -n fawkes svc/weaviate 8080:80
python scripts/test-indexing.py
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

## API Reference

### POST /api/v1/query

Query endpoint for context retrieval.

**Request Body:**
```json
{
  "query": "string",           // Search query (required)
  "top_k": 5,                  // Number of results (optional, default: 5)
  "threshold": 0.7             // Min relevance score (optional, default: 0.7)
}
```

**Response:**
```json
{
  "query": "string",
  "results": [
    {
      "content": "string",
      "relevance_score": 0.85,
      "source": "docs/architecture.md",
      "title": "Architecture Documentation",
      "category": "doc"
    }
  ],
  "count": 1,
  "retrieval_time_ms": 234.56
}
```

**Performance:**
- Target response time: <500ms
- Minimum relevance score: >0.7

### GET /api/v1/health

Health check endpoint.

**Response:**
```json
{
  "status": "UP",
  "service": "rag-service",
  "version": "0.1.0",
  "weaviate_connected": true,
  "weaviate_url": "http://weaviate.fawkes.svc:80"
}
```

## Kubernetes Deployment

### Prerequisites

- Kubernetes cluster with fawkes namespace
- Weaviate deployed and running
- ArgoCD installed

### Deploy with ArgoCD

```bash
# Apply ArgoCD Application
kubectl apply -f platform/apps/rag-service-application.yaml

# Check deployment status
argocd app get rag-service

# Sync if needed
argocd app sync rag-service
```

### Manual Deployment

```bash
# Apply all manifests
kubectl apply -f platform/apps/rag-service/

# Check pods
kubectl get pods -n fawkes -l app=rag-service

# Check service
kubectl get svc -n fawkes rag-service

# Port forward for local testing
kubectl port-forward -n fawkes svc/rag-service 8000:80

# Test health endpoint
curl http://localhost:8000/api/v1/health
```

### Configuration

Configuration is managed via ConfigMap (`platform/apps/rag-service/configmap.yaml`):

- `weaviate_url`: Weaviate service URL
- `schema_name`: Weaviate schema name (default: FawkesDocument)
- `default_top_k`: Default number of results (default: 5)
- `default_threshold`: Default relevance threshold (default: 0.7)

### Resource Limits

- CPU Request: 500m
- Memory Request: 1Gi
- CPU Limit: 1 core
- Memory Limit: 1Gi

## Development

### Running Tests

```bash
# Run unit tests
cd services/rag
pytest tests/unit -v

# Run with coverage
pytest tests/unit --cov=app --cov-report=html

# Run BDD tests
cd ../..
behave tests/bdd/features/rag-service.feature
```

### Building Docker Image

```bash
cd services/rag

# Build image
docker build -t rag-service:latest .

# Run container
docker run -p 8000:8000 \
  -e WEAVIATE_URL=http://host.docker.internal:8080 \
  rag-service:latest

# Test in container
curl http://localhost:8000/api/v1/health
```

### Code Quality

```bash
# Format code
black app/ tests/

# Lint
flake8 app/ tests/

# Type checking
mypy app/
```

## Monitoring

### Prometheus Metrics

The service exposes Prometheus metrics at `/metrics`:

- `rag_requests_total`: Total number of requests
- `rag_query_duration_seconds`: Query execution time histogram
- `rag_relevance_score`: Relevance score histogram

### Health Checks

Kubernetes health probes:

- **Liveness**: `GET /api/v1/health` (30s interval)
- **Readiness**: `GET /ready` (10s interval)

## Troubleshooting

### Service Not Starting

```bash
# Check pod status
kubectl get pods -n fawkes -l app=rag-service

# Check logs
kubectl logs -n fawkes -l app=rag-service --tail=100

# Describe pod for events
kubectl describe pod -n fawkes <pod-name>
```

### Weaviate Connection Issues

```bash
# Check Weaviate is running
kubectl get pods -n fawkes -l app.kubernetes.io/name=weaviate

# Test Weaviate connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://weaviate.fawkes.svc:80/v1/meta

# Check ConfigMap
kubectl get configmap rag-service-config -n fawkes -o yaml
```

### Slow Query Performance

1. Check Weaviate resource usage: `kubectl top pods -n fawkes`
2. Review query logs: `kubectl logs -n fawkes -l app=rag-service | grep "Query completed"`
3. Verify index size: Check Weaviate metrics
4. Consider adjusting `top_k` and `threshold` parameters

### Low Relevance Scores

1. Re-index documentation with latest content
2. Check embedding model configuration in Weaviate
3. Review document chunking strategy (current: 512 tokens)
4. Verify text2vec-transformers module is running

## Next Steps

- ✅ Implement production indexing pipeline for all documentation
- ✅ Add incremental indexing for code changes (hash-based)
- ✅ Integrate with AI assistant for context retrieval
- [ ] Add scheduled re-indexing (CronJob)
- [ ] Implement caching for frequent queries
- [ ] Add authentication and rate limiting
- [ ] Create Grafana dashboard for monitoring

## Related Documentation

- [Vector Database Documentation](../../docs/ai/vector-database.md)
- [Weaviate README](../../platform/apps/weaviate/README.md)
- [Architecture Documentation](../../docs/architecture.md)
- [AT-E2-002 Acceptance Test](../../tests/bdd/features/rag-service.feature)
