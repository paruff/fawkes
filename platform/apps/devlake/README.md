# DevLake - DORA Metrics Collection

## Purpose

Apache DevLake automates DORA metrics collection from multiple data sources (GitHub, ArgoCD, Jenkins) and provides unified dashboards for measuring software delivery performance.

## Key Features

- **Automated Collection**: Pull data from GitHub, Jenkins, ArgoCD
- **DORA Metrics**: Deployment Frequency, Lead Time, CFR, MTTR
- **GraphQL API**: Query metrics programmatically
- **Dashboards**: Pre-built Grafana dashboards
- **Data Lake**: Unified data model for all metrics

## Quick Start

### Accessing DevLake

```bash
# UI
http://devlake.127.0.0.1.nip.io

# API
http://devlake-api.127.0.0.1.nip.io/graphql
```

## Data Sources

Configure data sources in DevLake UI:

### GitHub
- Repository discovery
- Commit and PR data
- Code review metrics

### ArgoCD (Primary for Deployments)
- Sync events = deployments
- Sync status = deployment success/failure
- Lead time tracking

### Jenkins
- Build metrics
- Test results
- Quality gates

## DORA Metrics

### Deployment Frequency
```graphql
query {
  deploymentFrequency(
    project: "fawkes"
    timeRange: "last30days"
  ) {
    daily
    weekly
    monthly
  }
}
```

### Lead Time for Changes
```graphql
query {
  leadTimeForChanges(
    project: "fawkes"
    timeRange: "last30days"
  ) {
    p50
    p95
    p99
  }
}
```

## Related Documentation

- [DevLake Documentation](https://devlake.apache.org/docs/Overview/Introduction)
- [ADR-016: DevLake DORA Strategy](../../../docs/adr/ADR-016-devlake-dora-strategy.md)
