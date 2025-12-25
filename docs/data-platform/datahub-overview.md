# DataHub Data Catalog - Overview

## What is DataHub?

DataHub is an open-source metadata platform that enables data discovery, observability, and governance across all data assets in the Fawkes platform. It acts as a centralized catalog where teams can find, understand, and trust their data.

### Why We Use DataHub

In modern data platforms, data is scattered across multiple systems - databases, data lakes, data warehouses, and streaming platforms. DataHub solves key challenges:

1. **Data Discovery**: Find the right data quickly through powerful search and browse capabilities
2. **Data Lineage**: Understand where data comes from and how it flows through systems
3. **Data Governance**: Manage data ownership, classification, and compliance
4. **Data Quality**: Track data quality metrics and identify issues
5. **Collaboration**: Share knowledge about data through descriptions, tags, and documentation
6. **Impact Analysis**: Understand downstream impacts before making changes

DataHub integrates seamlessly with our existing platform components:

- **PostgreSQL databases** for application data
- **Kafka/event streams** for real-time data (future)
- **S3/object storage** for data lakes (future)
- **dbt models** for transformation lineage (future)

---

## Architecture Overview

DataHub follows a microservices architecture with the following key components:

```text
┌─────────────────────────────────────────────────────────────────┐
│                        Data Sources                              │
│  ├─ PostgreSQL databases (Backstage, Focalboard, etc.)         │
│  ├─ Future: Kafka topics                                        │
│  ├─ Future: S3 buckets                                          │
│  └─ Future: dbt models                                          │
└────────────────────────┬────────────────────────────────────────┘
                         │ Metadata Ingestion
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   DataHub Components                             │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ GMS (Graph Metadata Service)                             │   │
│  │ - Core metadata API                                      │   │
│  │ - GraphQL endpoint                                       │   │
│  │ - REST API                                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                         │                                        │
│  ┌──────────────────────┴──────────────────────────────────┐   │
│  │                                                           │   │
│  ▼                                                           ▼   │
│  ┌─────────────────────┐              ┌──────────────────┐     │
│  │ PostgreSQL          │              │ OpenSearch       │     │
│  │ - Metadata storage  │              │ - Search index   │     │
│  │ - Versioning        │              │ - Full-text      │     │
│  └─────────────────────┘              └──────────────────┘     │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Frontend (React UI)                                      │   │
│  │ - Search & browse                                        │   │
│  │ - Lineage visualization                                  │   │
│  │ - Metadata management                                    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Users                                     │
│  ├─ Data Engineers                                              │
│  ├─ Data Scientists                                             │
│  ├─ Analytics Engineers                                         │
│  └─ Product Managers                                            │
└─────────────────────────────────────────────────────────────────┘
```

### Component Details

#### 1. GMS (Graph Metadata Service)

- **Purpose**: Core backend service that stores and serves metadata
- **Port**: 8080
- **APIs**: GraphQL and REST
- **Storage**: PostgreSQL for metadata, OpenSearch for search indexing
- **Features**:
  - CRUD operations on metadata entities
  - Relationship management
  - Search and discovery
  - Access control (future)

#### 2. DataHub Frontend

- **Purpose**: Web-based UI for interacting with metadata
- **Port**: 9002
- **Technology**: React.js
- **Features**:
  - Visual search and browse
  - Interactive lineage graphs
  - Metadata editing
  - User management

#### 3. PostgreSQL

- **Purpose**: Primary metadata storage
- **Implementation**: CloudNativePG cluster (db-datahub-dev)
- **Configuration**: HA with 3 replicas
- **Location**: `db-datahub-dev-rw.fawkes.svc.cluster.local:5432`

#### 4. OpenSearch

- **Purpose**: Search indexing for fast metadata discovery
- **Implementation**: Shared OpenSearch cluster in logging namespace
- **Location**: `opensearch-cluster-master.logging.svc.cluster.local:9200`

---

## How to Access DataHub

### Local Development

DataHub UI is accessible at:

```
http://datahub.127.0.0.1.nip.io
```

### Default Credentials (MVP)

For the initial MVP deployment, authentication is simplified:

- **Username**: `datahub`
- **Password**: `datahub`

> **⚠️ Production Note**: For production deployments, enable OIDC authentication with GitHub OAuth or use other enterprise SSO solutions.

### API Access

#### GraphQL API

```bash
# GraphQL endpoint
curl -X POST http://datahub.127.0.0.1.nip.io/api/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ search(input: {type: DATASET, query: \"*\", start: 0, count: 10}) { total } }"}'
```

#### REST API (via GMS)

```bash
# Internal GMS REST API
curl http://datahub-datahub-gms.fawkes.svc:8080/entities
```

---

## How to Search for Data

DataHub provides multiple ways to discover data assets:

### 1. Search by Keywords

Navigate to the search bar and enter keywords:

- Dataset names (e.g., "backstage_users")
- Column names (e.g., "email")
- Descriptions
- Tags

**Example Searches:**

- `backstage` - Find all assets related to Backstage
- `user email` - Find datasets containing user email data
- `tag:PII` - Find all assets tagged as PII

### 2. Browse by Platform

Click on "Browse" and navigate through:

- **Platforms**: PostgreSQL, Kafka, S3, etc.
- **Domains**: Analytics, Operations, Product, etc.
- **Ownership**: Filter by team or owner

### 3. Advanced Filters

Use the filter panel to refine searches:

- **Entity Type**: Dataset, Dashboard, Pipeline, etc.
- **Platform**: PostgreSQL, MySQL, BigQuery, etc.
- **Domain**: Engineering, Marketing, Finance, etc.
- **Tags**: PII, Critical, Deprecated, etc.
- **Ownership**: Team or individual

### 4. Using the CLI

Install DataHub CLI:

```bash
pip install 'acryl-datahub[all]'
```

Search from command line:

```bash
# Search for datasets
datahub get --urn "urn:li:dataset:(urn:li:dataPlatform:postgres,backstage.users,PROD)"
```

---

## How to Add Metadata

### Method 1: Through the UI

1. **Navigate to an Asset**: Search or browse to find the dataset
2. **Click "Edit"**: Located in the top-right corner
3. **Add Information**:

   - **Description**: Explain what this dataset contains
   - **Tags**: Add relevant tags (e.g., PII, Critical, Deprecated)
   - **Domain**: Assign to a business domain
   - **Owners**: Add technical and business owners
   - **Custom Properties**: Add key-value pairs for additional context

4. **Save Changes**: Click "Save" to persist metadata

### Method 2: Using DataHub CLI

Create an ingestion recipe:

```yaml
# postgres-recipe.yml
source:
  type: postgres
  config:
    host_port: "db-backstage-dev-rw.fawkes.svc.cluster.local:5432"
    database: "backstage_db"
    username: "${POSTGRES_USER}"
    password: "${POSTGRES_PASSWORD}"
    include_tables: true
    include_views: true
    profiling:
      enabled: true
      profile_table_level_only: false

sink:
  type: datahub-rest
  config:
    server: "http://datahub-datahub-gms.fawkes.svc:8080"
```

Run ingestion:

```bash
# Set credentials
export POSTGRES_USER="backstage_user"
export POSTGRES_PASSWORD="your-password"

# Ingest metadata
datahub ingest -c postgres-recipe.yml
```

### Method 3: Programmatic API

Use Python SDK:

```python
from datahub.emitter.mce_builder import make_dataset_urn
from datahub.emitter.rest_emitter import DatahubRestEmitter
from datahub.metadata.schema_classes import GlobalTagsClass, TagAssociationClass

# Initialize emitter
emitter = DatahubRestEmitter("http://datahub-datahub-gms.fawkes.svc:8080")

# Create dataset URN
dataset_urn = make_dataset_urn(
    platform="postgres",
    name="backstage.users",
    env="PROD"
)

# Add tags
tags = GlobalTagsClass(
    tags=[
        TagAssociationClass(tag="urn:li:tag:PII"),
        TagAssociationClass(tag="urn:li:tag:Critical")
    ]
)

# Emit metadata
emitter.emit_mcp(
    entityType="dataset",
    entityUrn=dataset_urn,
    aspectName="globalTags",
    aspect=tags
)
```

---

## Understanding Lineage Graphs

Data lineage shows how data flows through your systems, helping you understand:

- **Upstream dependencies**: What data sources feed into this dataset?
- **Downstream consumers**: What processes or dashboards depend on this dataset?
- **Transformation logic**: How data changes as it moves through pipelines

### Viewing Lineage

1. **Navigate to a Dataset**: Search for the dataset
2. **Click "Lineage" Tab**: View the lineage graph
3. **Explore the Graph**:
   - **Upstream**: Click the left arrow to see data sources
   - **Downstream**: Click the right arrow to see consumers
   - **Depth**: Adjust the depth slider to show more hops

### Lineage Graph Elements

```text
┌────────────────┐
│ Source Table 1 │─────┐
└────────────────┘     │
                       ▼
┌────────────────┐   ┌──────────────┐   ┌──────────────┐
│ Source Table 2 │──▶│ Transform    │──▶│ Target Table │
└────────────────┘   │ (dbt model)  │   └──────────────┘
                     └──────────────┘          │
                                               ▼
                                      ┌────────────────┐
                                      │   Dashboard    │
                                      └────────────────┘
```

- **Blue boxes**: Datasets (tables, views)
- **Green boxes**: Transformations (dbt models, pipelines)
- **Purple boxes**: Dashboards and reports
- **Arrows**: Data flow direction

### Adding Lineage

#### Using Python SDK

```python
from datahub.emitter.mce_builder import make_dataset_urn, make_data_flow_urn
from datahub.emitter.rest_emitter import DatahubRestEmitter
from datahub.metadata.schema_classes import UpstreamLineageClass, UpstreamClass

# Define upstream datasets
upstream = UpstreamLineageClass(
    upstreams=[
        UpstreamClass(
            dataset=make_dataset_urn("postgres", "backstage.services"),
            type="TRANSFORMED"
        ),
        UpstreamClass(
            dataset=make_dataset_urn("postgres", "backstage.catalog"),
            type="TRANSFORMED"
        )
    ]
)

# Emit lineage
emitter.emit_mcp(
    entityType="dataset",
    entityUrn=make_dataset_urn("postgres", "analytics.service_stats"),
    aspectName="upstreamLineage",
    aspect=upstream
)
```

#### Using dbt Integration

DataHub automatically extracts lineage from dbt models:

```yaml
# dbt_project.yml
models:
  fawkes:
    +meta:
      datahub:
        enabled: true
```

```bash
# Generate and ingest dbt metadata
dbt docs generate
datahub ingest -c dbt-recipe.yml
```

---

## Common Use Cases

### Use Case 1: Finding PII Data

**Scenario**: You need to identify all tables containing personally identifiable information for GDPR compliance.

**Steps**:

1. Search for `tag:PII` in the search bar
2. Review all results
3. Verify ownership and access controls
4. Document data retention policies

### Use Case 2: Impact Analysis Before Schema Change

**Scenario**: You want to change a column in the `users` table but need to know what will break.

**Steps**:

1. Navigate to the `users` dataset
2. Click the "Lineage" tab
3. Set depth to 3-4 hops
4. Identify all downstream consumers
5. Coordinate with downstream owners before making changes

### Use Case 3: Data Quality Monitoring

**Scenario**: Track data quality metrics for critical datasets.

**Steps**:

1. Integrate Great Expectations with DataHub
2. Run validation checks
3. View results in DataHub UI under "Validation" tab
4. Set up alerts for failures

### Use Case 4: New Team Member Onboarding

**Scenario**: A new data engineer joins and needs to understand data assets.

**Steps**:

1. Browse by domain (e.g., "User Analytics")
2. Review dataset descriptions and schemas
3. Check lineage to understand data flows
4. Contact dataset owners for questions

---

## Troubleshooting Common Issues

### Issue 1: DataHub UI Not Loading

**Symptoms**: Browser shows connection error or blank page

**Checks**:

```bash
# Check if pods are running
kubectl get pods -n fawkes | grep datahub

# Check frontend logs
kubectl logs -n fawkes deployment/datahub-datahub-frontend -f

# Check GMS logs
kubectl logs -n fawkes deployment/datahub-datahub-gms -f

# Check ingress
kubectl get ingress -n fawkes datahub-datahub-frontend
```

**Solutions**:

1. Verify PostgreSQL is running: `kubectl get pods -n fawkes | grep db-datahub`
2. Verify OpenSearch is accessible: `kubectl get pods -n logging | grep opensearch`
3. Check resource limits aren't exceeded
4. Review pod events: `kubectl describe pod -n fawkes <pod-name>`

### Issue 2: Search Not Returning Results

**Symptoms**: Metadata exists but search returns empty results

**Checks**:

```bash
# Check OpenSearch is healthy
kubectl exec -it -n logging opensearch-cluster-master-0 -- \
  curl -XGET "http://localhost:9200/_cluster/health?pretty"

# Check indices exist
kubectl exec -it -n logging opensearch-cluster-master-0 -- \
  curl -XGET "http://localhost:9200/_cat/indices?v"
```

**Solutions**:

1. Rebuild search index:
   ```bash
   # Access DataHub pod and trigger reindex
   kubectl exec -n fawkes deployment/datahub-datahub-gms -- \
     curl -X POST http://localhost:8080/gms/operations?action=restoreIndices
   ```
2. Verify OpenSearch connectivity from DataHub pods
3. Check OpenSearch resource limits

### Issue 3: Ingestion Failures

**Symptoms**: DataHub CLI ingestion fails or doesn't show metadata

**Checks**:

```bash
# Run with debug mode
datahub ingest -c recipe.yml --debug

# Check GMS logs during ingestion
kubectl logs -n fawkes deployment/datahub-datahub-gms -f
```

**Solutions**:

1. Verify database credentials are correct
2. Check network connectivity from ingestion source
3. Ensure ingestion recipe format is correct
4. Review DataHub version compatibility

### Issue 4: Slow Performance

**Symptoms**: UI is slow, searches take long time

**Checks**:

```bash
# Check resource usage
kubectl top pods -n fawkes | grep datahub
kubectl top pods -n logging | grep opensearch

# Check database connections
kubectl exec -it -n fawkes db-datahub-dev-1 -- \
  psql -U datahub_user -d datahub -c "SELECT count(*) FROM pg_stat_activity;"
```

**Solutions**:

1. Increase resource limits for DataHub components
2. Scale OpenSearch replicas if needed
3. Optimize PostgreSQL queries
4. Enable query result caching

### Issue 5: Authentication Problems

**Symptoms**: Cannot log in or access is denied

**Checks**:

```bash
# Check frontend environment variables
kubectl get deployment -n fawkes datahub-datahub-frontend -o yaml | grep -A 10 env

# Check GMS auth settings
kubectl get deployment -n fawkes datahub-datahub-gms -o yaml | grep AUTH
```

**Solutions**:

1. For MVP: Verify basic auth is enabled (`AUTH_JAAS_ENABLED: false`)
2. For production: Configure OIDC with GitHub OAuth
3. Check user exists in DataHub user management
4. Reset admin password if needed

---

## Best Practices

### 1. Metadata Governance

- **Assign Owners**: Every dataset should have a technical and business owner
- **Use Tags Consistently**: Establish standard tags (PII, Critical, Deprecated, etc.)
- **Add Descriptions**: Write clear, concise descriptions for all datasets
- **Keep Lineage Updated**: Ensure lineage reflects actual data flows

### 2. Search Optimization

- **Use Specific Terms**: Search for exact table or column names when possible
- **Leverage Filters**: Combine keywords with filters for better results
- **Save Searches**: Bookmark frequently used searches
- **Browse by Domain**: Organize data assets by business domains

### 3. Data Quality

- **Integrate with Great Expectations**: Automate data quality checks
- **Monitor Critical Datasets**: Set up alerts for important datasets
- **Document Quality Issues**: Use DataHub to track known issues
- **Regular Reviews**: Schedule periodic data quality reviews

### 4. Collaboration

- **Use Comments**: Discuss datasets directly in DataHub
- **Share Knowledge**: Add helpful documentation and examples
- **Ask Questions**: Use the UI to ask dataset owners questions
- **Stay Informed**: Subscribe to notifications for critical datasets

---

## Integration with Fawkes Platform

DataHub integrates with other Fawkes components:

### Backstage Integration

- Link to DataHub from Backstage catalog
- Show data lineage for services
- Display data quality metrics in service pages

### DORA Metrics

- Track data pipeline deployment frequency
- Measure time to restore data after incidents
- Monitor change failure rate for data pipelines

### Observability

- Send DataHub metrics to Prometheus
- Create Grafana dashboards for metadata health
- Alert on ingestion failures or data quality issues

---

## Related Documentation

- [DataHub Official Documentation](https://datahubproject.io/docs/)
- [Great Expectations Integration](https://datahubproject.io/docs/metadata-ingestion/integration_docs/great-expectations)
- [PostgreSQL Ingestion](https://datahubproject.io/docs/metadata-ingestion/integration_docs/postgres)
- [dbt Integration](https://datahubproject.io/docs/metadata-ingestion/integration_docs/dbt)
- [Architecture Documentation](../../architecture.md)
- [Data Platform Epic](../../implementation-plan/fawkes-handoff-doc.md)

---

## Getting Help

- **Internal Support**: Post in `#data-platform` Mattermost channel
- **DataHub Community**: [Slack](https://datahubspace.slack.com/)
- **GitHub Issues**: [DataHub GitHub](https://github.com/datahub-project/datahub/issues)
- **Documentation**: [Official Docs](https://datahubproject.io/docs/)
