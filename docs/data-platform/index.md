# Data Platform Documentation

This section covers the data platform components, including DataHub, data quality, and analytics infrastructure.

## Overview

The Fawkes data platform provides centralized data cataloging, lineage tracking, quality monitoring, and analytics capabilities. It enables teams to understand their data assets, trace data flows end-to-end, and enforce quality standards automatically across pipelines.

The platform is built on open-source components selected for their extensibility and integration with the broader Fawkes toolchain. All data platform components are deployed via ArgoCD, managed through Helm charts in `charts/`, and configured declaratively in `platform/apps/`.

## Data Catalog

### DataHub

DataHub is the primary metadata and data catalog tool. It ingests schema, lineage, and ownership metadata from databases, pipelines, and APIs.

- [DataHub Deployment Summary](../implementation-notes/DATAHUB_DEPLOYMENT_SUMMARY.md) - DataHub setup and configuration
- [DataHub Ingestion Summary](../implementation-notes/DATAHUB_INGESTION_SUMMARY.md) - Data ingestion pipelines
- [Hasura Quick Start](../how-to/data-platform/hasura-quickstart.md) - GraphQL API for data access

## Data Quality

Data quality is enforced through automated validation rules that run in CI and as scheduled jobs in Kubernetes.

- [Great Expectations Implementation](../implementation-notes/GREAT_EXPECTATIONS_IMPLEMENTATION.md) - Data quality validation

## APIs

- [GraphQL API Implementation](../implementation-notes/GRAPHQL_API_IMPLEMENTATION.md) - GraphQL API for data queries

## Related Documentation

- [Architecture Overview](../architecture.md) - Platform architecture
- [Implementation Summaries](../implementation-notes/README.md) - Technical details
- [How-To Guides](../how-to/index.md) - Step-by-step guides

