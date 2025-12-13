# OpenSearch - Log Aggregation and Search

## Purpose

OpenSearch provides centralized log storage and full-text search capabilities for all platform and application logs collected by Fluent Bit.

## Key Features

- **Full-Text Search**: Fast log search with Lucene
- **Index Management**: ILM for log retention
- **Dashboards**: Kibana-compatible visualizations
- **Alerting**: Query-based alerts
- **Security**: RBAC and encryption

## Quick Start

### Accessing OpenSearch

```bash
# API
curl http://opensearch.logging.svc:9200

# Dashboards
http://opensearch-dashboards.127.0.0.1.nip.io
```

## Index Structure

```text
fawkes-logs-YYYY.MM.DD    Daily log indices
fawkes-metrics-*          Metric data
fawkes-traces-*           Trace data
```

## Searching Logs

### Query DSL
```json
{
  "query": {
    "bool": {
      "must": [
        { "match": { "kubernetes.namespace": "fawkes" }},
        { "match": { "level": "ERROR" }}
      ],
      "filter": {
        "range": {
          "@timestamp": {
            "gte": "now-1h"
          }
        }
      }
    }
  }
}
```

### Simple Query
```bash
curl -X GET "http://opensearch.logging.svc:9200/fawkes-*/_search?q=ERROR"
```

## Index Lifecycle Management

```json
{
  "policy": {
    "description": "Fawkes log retention policy",
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "transitions": [
          {
            "state_name": "warm",
            "conditions": { "min_index_age": "7d" }
          }
        ]
      },
      {
        "name": "warm",
        "transitions": [
          {
            "state_name": "delete",
            "conditions": { "min_index_age": "30d" }
          }
        ]
      }
    ]
  }
}
```

## Related Documentation

- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
