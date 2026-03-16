# Data Platform Extension

This extension adds data cataloging and data quality capabilities to Fawkes:
DataHub for data lineage and discovery, and Great Expectations for data quality
validation.

## Components

| Component | Purpose | Resource Requirement |
|---|---|---|
| **DataHub** | Data catalog, lineage tracking, and data discovery | 4–8 GB RAM, 4 vCPU |
| **Great Expectations** | Data quality validation and expectations | 512 MB RAM, 1 vCPU |

## Prerequisites

- Core Fawkes platform running (Tier 1 minimum)
- PostgreSQL deployed (included in Tier 2, or deploy standalone)
- At least 8 GB free cluster memory for DataHub
- `fawkes` namespace exists

## Deploying

```bash
# Deploy DataHub (includes its own internal dependencies)
kubectl apply -f extensions/data-platform/datahub-application.yaml -n fawkes

# Deploy data quality (Great Expectations exporter)
kubectl apply -f extensions/data-platform/data-quality-application.yaml -n fawkes

# Verify
kubectl get pods -n fawkes -l app=datahub
kubectl get pods -n fawkes -l app=data-quality
```

## Services

The data quality service lives in `extensions/data-platform/services/data-quality/`.
It exports Great Expectations validation results as Prometheus metrics.

## When to Add This Extension

Add this extension if your organisation:

- Needs a data catalog to discover and document datasets
- Wants automated data lineage tracking
- Requires data quality validation with alerting
- Is building a data mesh or data platform on top of Fawkes

## Operational Notes

- DataHub is resource-intensive; do not deploy on a laptop or small cluster.
- DataHub requires Elasticsearch (or OpenSearch) — this is included in Tier 2.
  If deploying on Tier 1, you must deploy OpenSearch separately first.
- Great Expectations validation rules are stored in `extensions/data-platform/data-quality/`.

## See Also

- [DataHub Overview](../../docs/data-platform/datahub-overview.md)
- [Data Platform Documentation](../../docs/data-platform/index.md)
- [Extensions Overview](../README.md)
