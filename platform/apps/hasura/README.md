# Hasura GraphQL Engine

This directory contains the deployment configuration for Hasura GraphQL Engine, which provides a unified GraphQL API for all platform data.

## Overview

Hasura automatically generates GraphQL APIs from PostgreSQL databases, providing:

- **Unified Data API**: Single GraphQL endpoint for DORA metrics, Backstage catalog, VSM work items, and more
- **Real-time Subscriptions**: Live data updates via GraphQL subscriptions
- **RBAC**: Row-level and column-level security
- **Performance**: Built-in query optimization and Redis caching
- **Developer Experience**: GraphQL Playground for testing and exploration

## Architecture

```
┌─────────────┐
│   Clients   │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│   Hasura GraphQL Engine         │
│   - Query Engine                │
│   - Authorization               │
│   - Subscriptions               │
└─────────┬───────────────────────┘
          │
          ├──────────┬──────────┬──────────┐
          ▼          ▼          ▼          ▼
    ┌─────────┐ ┌─────────┐ ┌──────┐ ┌────────┐
    │ VSM DB  │ │Backstage│ │DevLake│ │ Redis  │
    │         │ │   DB    │ │  DB   │ │ Cache  │
    └─────────┘ └─────────┘ └──────┘ └────────┘
```

## Components

### Hasura GraphQL Engine

- **Image**: hasura/graphql-engine:v2.36.0
- **Replicas**: 2 (HA)
- **Resources**: 200m CPU / 256Mi memory (request)
- **Port**: 8080

### Redis Cache

- **Image**: redis:7-alpine
- **Replicas**: 1
- **Resources**: 100m CPU / 128Mi memory (request)
- **Purpose**: Query result caching

## Database Connections

Hasura connects to multiple PostgreSQL databases:

1. **VSM Database** (`db-vsm-dev`)

   - Work items
   - Stage transitions
   - Flow metrics

2. **Backstage Database** (`db-backstage-dev`)

   - Software catalog
   - Component metadata
   - API definitions

3. **DevLake Database** (TBD)
   - DORA metrics
   - Build data
   - Deployment events

## Access

### GraphQL API

- **Endpoint**: http://hasura.local/v1/graphql
- **Console**: http://hasura.local/console

### Authentication

For API access, include the admin secret in headers:

```bash
curl http://hasura.local/v1/graphql \
  -H "x-hasura-admin-secret: fawkes-hasura-admin-secret-dev-changeme" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __schema { types { name } } }"}'
```

### Role-Based Access

Hasura supports multiple roles with different permissions:

- **admin**: Full access to all data and operations
- **developer**: Read/write access to most tables
- **viewer**: Read-only access
- **anonymous**: Limited public access

## Configuration

### Metadata

Hasura metadata (tables, relationships, permissions) is stored in:

- `services/data-api/schema/` - Schema definitions
- `services/data-api/rbac/` - Permission configurations

### Environment Variables

Key environment variables (set in deployment.yaml):

- `HASURA_GRAPHQL_ADMIN_SECRET`: Admin authentication
- `HASURA_GRAPHQL_DATABASE_URL`: Primary database connection
- `HASURA_GRAPHQL_ENABLE_CONSOLE`: Enable web console
- `HASURA_GRAPHQL_REDIS_URL`: Redis cache connection
- `HASURA_GRAPHQL_RATE_LIMIT_PER_ROLE`: Rate limiting config

## Schema Management

### Tracking Tables

To expose a PostgreSQL table via GraphQL:

1. Access the Hasura console: http://hasura.local/console
2. Navigate to "Data" tab
3. Select the database
4. Click "Track" on desired tables

Or use the CLI:

```bash
hasura metadata apply --endpoint http://hasura.local --admin-secret <secret>
```

### Relationships

Define relationships between tables to enable nested queries:

```yaml
# Example: Work items to stage transitions
table: work_items
object_relationships:
  - name: current_stage
    using:
      foreign_key_constraint_on: stage_id

array_relationships:
  - name: transitions
    using:
      foreign_key_constraint_on:
        column: work_item_id
        table: stage_transitions
```

## RBAC Configuration

Permissions are configured per role per table:

```yaml
# Example: Developer role permissions on work_items
role: developer
permission:
  columns: [id, title, type, status, created_at, updated_at]
  filter:
    team: { _eq: "X-Hasura-Team-Id" }
  check:
    team: { _eq: "X-Hasura-Team-Id" }
```

See `services/data-api/rbac/` for detailed permission configurations.

## Caching

Redis caching is configured for query results:

- **TTL by query type**:

  - Catalog queries: 5 minutes
  - DORA metrics: 1 minute
  - VSM data: 30 seconds
  - Real-time data: No caching

- **Cache warming**: Automated for common queries
- **Cache monitoring**: Prometheus metrics exposed

## Performance

### Query Optimization

Hasura automatically:

- Uses database indexes
- Batches related queries
- Limits query depth
- Implements rate limiting

### Performance Targets

- **P95 latency**: < 1 second
- **Cache hit rate**: > 70%
- **Concurrent users**: 100+

## Monitoring

### Metrics

Hasura exposes Prometheus metrics at `/v1/metrics`:

- `hasura_graphql_requests_total`: Total requests
- `hasura_graphql_execution_time_seconds`: Query execution time
- `hasura_cache_hit_ratio`: Cache effectiveness
- `hasura_postgres_connections`: Database connections

### Grafana Dashboard

A pre-configured Grafana dashboard is available showing:

- Request rate and latency
- Cache hit ratio
- Database connection pool
- Error rates

## Deployment

### Manual Deployment

```bash
# Deploy via kubectl
kubectl apply -k platform/apps/hasura/

# Verify deployment
kubectl get pods -n fawkes -l app=hasura
kubectl get svc -n fawkes hasura
kubectl get ingress -n fawkes hasura
```

### ArgoCD Deployment

```bash
# Deploy via ArgoCD
kubectl apply -f platform/apps/hasura-application.yaml

# Check sync status
argocd app get hasura
argocd app sync hasura
```

## Testing

### Health Check

```bash
curl http://hasura.local/healthz
```

### GraphQL Query Test

```bash
curl http://hasura.local/v1/graphql \
  -H "x-hasura-admin-secret: fawkes-hasura-admin-secret-dev-changeme" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { __schema { types { name } } }"
  }'
```

### Performance Test

```bash
# Using k6 for load testing
k6 run tests/performance/graphql-load-test.js
```

## Troubleshooting

### Common Issues

1. **Connection errors to PostgreSQL**

   - Check database credentials in secrets
   - Verify database is running: `kubectl get clusters.postgresql.cnpg.io -n fawkes`
   - Check connection string format

2. **Console not accessible**

   - Verify ingress: `kubectl get ingress -n fawkes hasura`
   - Check DNS/hosts file for `hasura.local`
   - Port-forward: `kubectl port-forward -n fawkes svc/hasura 8080:8080`

3. **High latency**

   - Check Redis cache: `kubectl logs -n fawkes -l app=hasura-redis`
   - Review query complexity
   - Check database indexes

4. **Permission denied errors**
   - Review RBAC configuration in `services/data-api/rbac/`
   - Check role headers in requests
   - Verify row-level security rules

### Logs

```bash
# Hasura logs
kubectl logs -n fawkes -l app=hasura --tail=100 -f

# Redis logs
kubectl logs -n fawkes -l app=hasura-redis --tail=100 -f
```

## Security

### Admin Secret

The admin secret is stored in Kubernetes Secret `hasura-admin-secret`.

**IMPORTANT**: Change the default secret in production!

```bash
kubectl create secret generic hasura-admin-secret \
  -n fawkes \
  --from-literal=admin-secret=$(openssl rand -base64 32)
```

### Database Credentials

Database credentials are stored in separate secrets:

- `db-vsm-credentials`
- `db-backstage-credentials`
- `devlake-db-credentials`

### Network Security

- Hasura runs as non-root user (UID 1000)
- All capabilities dropped
- Ingress with TLS (production)
- Rate limiting per role

## References

- [Hasura Documentation](https://hasura.io/docs/latest/index/)
- [GraphQL Best Practices](https://graphql.org/learn/best-practices/)
- [Issue #53: Deploy unified GraphQL data API](https://github.com/paruff/fawkes/issues/53)
- [Architecture Decision Record - Data API Strategy](../../docs/adr/)
