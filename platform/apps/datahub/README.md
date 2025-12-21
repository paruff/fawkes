# DataHub - Data Catalog and Lineage Platform

## Purpose

DataHub provides a unified data catalog for discovering, understanding, and governing data assets across the Fawkes platform. It tracks data lineage, quality, and usage metrics.

## Quick Start

### Deploy DataHub

DataHub is deployed via ArgoCD using the application manifest:

```bash
# Apply the ArgoCD application
kubectl apply -f ../datahub-application.yaml

# Wait for deployment to complete
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=datahub -n fawkes --timeout=300s

# Validate deployment
./validate-datahub.sh --namespace fawkes
```

### Access DataHub UI

Local development:
```
http://datahub.127.0.0.1.nip.io
```

Default credentials (MVP):
- Username: `datahub`
- Password: `datahub`

### Ingest Metadata

1. Install DataHub CLI:
```bash
pip install 'acryl-datahub[all]'
```

2. Set credentials:
```bash
export POSTGRES_USER="backstage_user"
export POSTGRES_PASSWORD="your-password"
```

3. Run ingestion:
```bash
datahub ingest -c postgres-ingestion-recipe.yml
```

## Key Features

- **Data Discovery**: Search and browse all data assets
- **Data Lineage**: Track data flow across systems
- **Data Quality**: Monitor data quality metrics
- **Schema Registry**: Centralized schema management
- **Access Control**: Fine-grained data governance
- **Metadata API**: Programmatic metadata management
- **Integrations**: PostgreSQL, Kafka, S3, and more

## Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                     Data Sources                                 │
│  ├─ PostgreSQL databases                                        │
│  ├─ Kafka topics                                                │
│  ├─ S3 buckets                                                  │
│  └─ dbt models                                                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DataHub Ingestion                            │
│  ├─ Metadata extractors                                         │
│  ├─ Schema parsers                                              │
│  └─ Lineage builders                                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DataHub Backend                              │
│  ├─ GMS (Graph Metadata Service)                                │
│  ├─ MAE (Metadata Audit Events)                                 │
│  ├─ MCE (Metadata Change Events)                                │
│  └─ Search Index (Elasticsearch)                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DataHub Frontend                             │
│  ├─ Web UI                                                      │
│  ├─ GraphQL API                                                 │
│  └─ REST API                                                    │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Accessing DataHub

Local development:
```bash
# Access UI
http://datahub.127.0.0.1.nip.io
```

Default credentials:
- Username: `datahub`
- Password: `datahub`

### Ingesting Metadata

```bash
# Install DataHub CLI
pip install 'acryl-datahub[all]'

# Ingest PostgreSQL metadata
datahub ingest -c postgres-recipe.yml
```

### PostgreSQL Ingestion Recipe

```yaml
# postgres-recipe.yml
source:
  type: postgres
  config:
    host_port: postgresql.fawkes.svc:5432
    database: backstage
    username: ${POSTGRES_USER}
    password: ${POSTGRES_PASSWORD}
    include_tables: true
    include_views: true
    profiling:
      enabled: true

sink:
  type: datahub-rest
  config:
    server: http://datahub-gms.datahub.svc:8080
```

## Data Lineage

Track data flow across the platform:

```python
from datahub.emitter.mce_builder import make_data_flow_urn
from datahub.emitter.rest_emitter import DatahubRestEmitter

emitter = DatahubRestEmitter("http://datahub-gms.datahub.svc:8080")

# Define lineage
lineage = {
    "upstream": [
        make_data_flow_urn("postgres", "backstage.services"),
        make_data_flow_urn("postgres", "backstage.catalog")
    ],
    "downstream": [
        make_data_flow_urn("postgres", "analytics.service_stats")
    ]
}

# Emit lineage
emitter.emit_lineage(lineage)
```

## Data Quality Monitoring

Integrate with Great Expectations:

```python
from datahub.integrations.great_expectations.datahub_context import DatahubContext

# Configure DataHub context
datahub_context = DatahubContext(
    datahub_url="http://datahub-gms.datahub.svc:8080",
    platform="postgres",
    platform_instance="production"
)

# Great Expectations validation
results = context.run_checkpoint(
    checkpoint_name="my_checkpoint",
    datahub_context=datahub_context
)
```

## Search and Discovery

### Search by Name

```graphql
query {
  search(
    input: {
      type: DATASET
      query: "backstage"
      start: 0
      count: 10
    }
  ) {
    searchResults {
      entity {
        ... on Dataset {
          name
          description
          platform
        }
      }
    }
  }
}
```

### Browse by Domain

```graphql
query {
  browse(
    input: {
      type: DATASET
      path: ["prod", "analytics"]
      start: 0
      count: 10
    }
  ) {
    entities {
      name
      type
    }
  }
}
```

## Data Governance

### Tag Assets

```python
from datahub.emitter.mcp import MetadataChangeProposalWrapper
from datahub.metadata.schema_classes import GlobalTagsClass

# Tag dataset as PII
tag_proposal = MetadataChangeProposalWrapper(
    entityType="dataset",
    entityUrn="urn:li:dataset:(urn:li:dataPlatform:postgres,backstage.users,PROD)",
    aspectName="globalTags",
    aspect=GlobalTagsClass(tags=[{"tag": "urn:li:tag:PII"}])
)

emitter.emit_mcp(tag_proposal)
```

### Set Ownership

```python
from datahub.metadata.schema_classes import OwnershipClass, OwnerClass

# Assign owner
ownership = OwnershipClass(
    owners=[
        OwnerClass(
            owner="urn:li:corpuser:platform-team",
            type="TECHNICAL_OWNER"
        )
    ]
)

emitter.emit_mcp(ownership_proposal)
```

## Integration with dbt

DataHub integrates with dbt for model documentation:

```yaml
# dbt_project.yml
models:
  my_project:
    +meta:
      datahub:
        domain: "urn:li:domain:analytics"
        tags: ["reporting", "dora-metrics"]
```

```bash
# Generate and push metadata
dbt docs generate
datahub ingest -c dbt-recipe.yml
```

## Monitoring

Monitor DataHub health:

```bash
# Check GMS health
curl http://datahub-gms.datahub.svc:8080/health

# Check ingestion status
datahub get --urn "urn:li:dataFlow:(airflow,my_dag,prod)"
```

## Troubleshooting

### Ingestion Failures

```bash
# Check ingestion logs
kubectl logs -n datahub deployment/datahub-datahub-actions -f

# Debug ingestion
datahub ingest -c recipe.yml --debug
```

### Search Not Working

```bash
# Rebuild search index
curl -X POST http://datahub-gms.datahub.svc:8080/gms/reindex
```

## Related Documentation

- [DataHub Documentation](https://datahubproject.io/docs/)
- [Great Expectations Integration](https://datahubproject.io/docs/metadata-ingestion/integration_docs/great-expectations)
- [ADR-022: Data Catalog Selection](../../../docs/adr/ADR-022-data-catalog.md)
