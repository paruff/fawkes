# ADR-011: Centralized Log Management

## Status
Accepted

## Context

The Fawkes platform requires comprehensive log management for both platform services and applications deployed by teams:

**Platform Service Logs**:
- Kubernetes control plane (API server, scheduler, controller manager, etcd)
- NGINX Ingress Controller (access logs, error logs)
- ArgoCD (deployment events, sync operations, application health)
- Jenkins (build logs, pipeline execution, agent activities)
- Backstage (catalog operations, template scaffolding, API requests)
- Mattermost (user activity, integrations, webhooks)
- Harbor (registry operations, image scanning, vulnerability reports)
- Grafana (dashboard access, alert notifications, data source queries)
- Prometheus (scrape operations, rule evaluations, alert firing)
- PostgreSQL (query logs, connection logs, errors)
- External Secrets Operator (secret synchronization, errors)

**Application Logs** (from teams using Fawkes):
- Microservice application logs (structured and unstructured)
- Container stdout/stderr
- Application performance metrics
- Error and exception tracking
- Audit logs for security and compliance
- Business event logs

**Logging Requirements**:
- **Centralized Storage**: All logs in one searchable location
- **Long-Term Retention**: 30 days hot storage, 90+ days cold storage
- **Fast Search**: Sub-second queries across billions of log entries
- **Structured Logging**: Support for JSON and structured formats
- **Log Correlation**: Trace ID correlation across services
- **Multi-Tenancy**: Team-level log isolation and access control
- **Real-Time Streaming**: Live log tailing for debugging
- **Alerting**: Trigger alerts based on log patterns
- **Visualization**: Dashboard creation from log data
- **Cost Efficiency**: Minimize storage and compute costs

**Security & Compliance Requirements**:
- Encryption at rest and in transit
- Role-based access control (RBAC)
- Audit trail of log access
- PII/sensitive data masking
- Retention policies for compliance (GDPR, SOC 2)
- Immutable log storage (tamper-proof)
- Log integrity verification

**Operational Requirements**:
- Cloud-agnostic (works on AWS, Azure, GCP, on-premises)
- Low operational overhead (minimal maintenance)
- Automatic log collection (no application code changes)
- Handling high throughput (10,000+ logs/second)
- Graceful degradation (buffering during outages)
- Easy troubleshooting (logs about logging)
- GitOps-compatible deployment

**Integration Requirements**:
- Kubernetes native (DaemonSet for log collection)
- Prometheus metrics integration
- Grafana dashboard integration
- Alert manager integration
- SIEM integration capabilities
- OpenTelemetry compatibility

**Dojo Learning Requirements**:
- Simple enough for learners to understand
- Clear troubleshooting workflows
- Hands-on labs for log analysis
- Integration with DORA metrics (deployment events, incident response)

## Decision

We will use **OpenSearch** as the centralized log storage and search engine, with **Fluent Bit** as the lightweight log collector.

### Architecture

```
┌────────────────────────────────────────────────────────────────┐
│  Kubernetes Cluster                                            │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ Application  │  │ Application  │  │ Platform     │        │
│  │ Pod          │  │ Pod          │  │ Service Pod  │        │
│  │              │  │              │  │              │        │
│  │ stdout/stderr│  │ stdout/stderr│  │ stdout/stderr│        │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘        │
│         │                  │                  │                 │
│         ▼                  ▼                  ▼                 │
│  ┌──────────────────────────────────────────────────────┐     │
│  │ /var/log/containers/*.log                            │     │
│  │ (Kubernetes logs each container to host filesystem)  │     │
│  └──────────────────────────────────────────────────────┘     │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────────────────────────────────────────┐      │
│  │ Fluent Bit DaemonSet (runs on every node)          │      │
│  │ - Tail container logs                               │      │
│  │ - Parse and enrich (add metadata)                   │      │
│  │ - Filter and transform                              │      │
│  │ - Buffer during outages                             │      │
│  │ - Forward to OpenSearch                             │      │
│  └───────────────────┬─────────────────────────────────┘      │
│                      │                                          │
└──────────────────────┼──────────────────────────────────────────┘
                       │ HTTPS (with buffering)
                       │
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│  OpenSearch Cluster                                              │
│                                                                   │
│  ┌───────────────────┐  ┌───────────────────┐  ┌─────────────┐ │
│  │ Master Node       │  │ Master Node       │  │ Master Node │ │
│  │ (Cluster mgmt)    │  │ (Cluster mgmt)    │  │ (Cluster mgmt)│
│  └───────────────────┘  └───────────────────┘  └─────────────┘ │
│                                                                   │
│  ┌───────────────────┐  ┌───────────────────┐  ┌─────────────┐ │
│  │ Data Node         │  │ Data Node         │  │ Data Node   │ │
│  │ - Log storage     │  │ - Log storage     │  │ - Log storage│ │
│  │ - Indexing        │  │ - Indexing        │  │ - Indexing  │ │
│  │ - Query execution │  │ - Query execution │  │ - Query exec│ │
│  └───────────────────┘  └───────────────────┘  └─────────────┘ │
│                                                                   │
│  Index Management:                                                │
│  - Hot tier (last 7 days): SSD storage, fast queries            │
│  - Warm tier (7-30 days): HDD storage, slower queries           │
│  - Cold tier (30-90 days): S3/object storage, archive           │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
                       │
                       │ Query Interface
                       │
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│  Visualization & Query Interfaces                                │
│                                                                   │
│  ┌───────────────────┐  ┌───────────────────┐  ┌─────────────┐ │
│  │ OpenSearch        │  │ Grafana           │  │ CLI Tools   │ │
│  │ Dashboards        │  │ (Loki datasource) │  │ (kubectl)   │ │
│  │ - Log search      │  │ - Unified view    │  │             │ │
│  │ - Dashboards      │  │ - Log + metrics   │  │             │ │
│  │ - Alerting        │  │ - Correlations    │  │             │ │
│  └───────────────────┘  └───────────────────┘  └─────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

### Log Flow

1. **Collection**: Fluent Bit DaemonSet collects logs from `/var/log/containers/`
2. **Enrichment**: Add Kubernetes metadata (namespace, pod, container, labels)
3. **Parsing**: Parse JSON logs, multiline logs (stack traces), timestamps
4. **Filtering**: Filter out noisy logs, health checks, debug messages (configurable)
5. **Buffering**: Buffer logs during OpenSearch unavailability
6. **Forwarding**: Send to OpenSearch via HTTPS with authentication
7. **Indexing**: OpenSearch indexes logs by date and namespace
8. **Retention**: Automatically move logs to warm/cold tiers based on age
9. **Querying**: Users search via OpenSearch Dashboards or Grafana

### OpenSearch Configuration

**Cluster Sizing (Production)**:
```yaml
Master Nodes: 3 replicas
  - CPU: 2 cores
  - Memory: 4 GB
  - Storage: 20 GB (minimal, only metadata)
  - Purpose: Cluster coordination, no data

Data Nodes (Hot): 3 replicas
  - CPU: 4 cores
  - Memory: 16 GB (50% heap)
  - Storage: 500 GB SSD
  - Purpose: Recent logs (last 7 days)

Data Nodes (Warm): 2 replicas (optional for MVP)
  - CPU: 2 cores
  - Memory: 8 GB
  - Storage: 1 TB HDD
  - Purpose: Older logs (7-30 days)
```

**Index Template**:
```json
{
  "index_patterns": ["fawkes-logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "index.refresh_interval": "30s",
      "index.lifecycle.name": "fawkes-log-policy"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "kubernetes": {
          "properties": {
            "namespace": { "type": "keyword" },
            "pod_name": { "type": "keyword" },
            "container_name": { "type": "keyword" },
            "labels": { "type": "object" }
          }
        },
        "log": { "type": "text" },
        "level": { "type": "keyword" },
        "message": { "type": "text" },
        "trace_id": { "type": "keyword" },
        "span_id": { "type": "keyword" }
      }
    }
  }
}
```

**Index Lifecycle Policy (ILM)**:
```json
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_age": "1d",
            "max_size": "50gb"
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "shrink": { "number_of_shards": 1 },
          "forcemerge": { "max_num_segments": 1 }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "searchable_snapshot": {
            "snapshot_repository": "fawkes-logs-s3"
          }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

### Fluent Bit Configuration

**DaemonSet Deployment**:
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: fawkes-logging
spec:
  selector:
    matchLabels:
      app: fluent-bit
  template:
    metadata:
      labels:
        app: fluent-bit
    spec:
      serviceAccountName: fluent-bit
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:2.2
        resources:
          limits:
            cpu: 200m
            memory: 256Mi
          requests:
            cpu: 100m
            memory: 128Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: fluent-bit-config
          mountPath: /fluent-bit/etc/
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: fluent-bit-config
        configMap:
          name: fluent-bit-config
```

**Fluent Bit Pipeline Configuration**:
```ini
[SERVICE]
    Flush         5
    Daemon        off
    Log_Level     info
    Parsers_File  parsers.conf

[INPUT]
    Name              tail
    Path              /var/log/containers/*.log
    Parser            docker
    Tag               kube.*
    Refresh_Interval  5
    Mem_Buf_Limit     5MB
    Skip_Long_Lines   On

[FILTER]
    Name                kubernetes
    Match               kube.*
    Kube_URL            https://kubernetes.default.svc:443
    Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
    Kube_Tag_Prefix     kube.var.log.containers.
    Merge_Log           On
    Keep_Log            Off
    K8S-Logging.Parser  On
    K8S-Logging.Exclude On
    Labels              On
    Annotations         Off

[FILTER]
    Name         modify
    Match        *
    Add          cluster_name fawkes-production

[FILTER]
    Name         nest
    Match        *
    Operation    lift
    Nested_under kubernetes
    Add_prefix   k8s_

[FILTER]
    Name         grep
    Match        *
    Exclude      log /healthz|/readyz|/livez

[OUTPUT]
    Name            opensearch
    Match           *
    Host            opensearch.fawkes-logging.svc.cluster.local
    Port            9200
    Index           fawkes-logs
    Type            _doc
    Logstash_Format On
    Logstash_Prefix fawkes-logs
    Logstash_DateFormat %Y.%m.%d
    Suppress_Type_Name On
    TLS             On
    TLS.Verify      On
    HTTP_User       ${OPENSEARCH_USER}
    HTTP_Passwd     ${OPENSEARCH_PASSWORD}
    Retry_Limit     5
    Buffer_Size     False
```

**Parsing Configuration** (parsers.conf):
```ini
[PARSER]
    Name         docker
    Format       json
    Time_Key     time
    Time_Format  %Y-%m-%dT%H:%M:%S.%LZ
    Time_Keep    On

[PARSER]
    Name         json
    Format       json
    Time_Key     timestamp
    Time_Format  %Y-%m-%dT%H:%M:%S.%LZ

[PARSER]
    Name         java_multiline
    Format       regex
    Regex        /^(?<time>\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}.\d{3})\s+(?<level>[A-Z]+)\s+(?<message>.*)/
    Time_Key     time
    Time_Format  %Y-%m-%d %H:%M:%S.%L
```

### Multi-Tenancy & Access Control

**Namespace-Based Log Isolation**:
```yaml
apiVersion: v1
kind: Role
metadata:
  name: log-reader
  namespace: team-alpha
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-alpha-log-readers
  namespace: team-alpha
subjects:
- kind: Group
  name: team-alpha
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: log-reader
  apiGroup: rbac.authorization.k8s.io
```

**OpenSearch Role-Based Access**:
```json
{
  "team-alpha-logs": {
    "cluster_permissions": [],
    "index_permissions": [
      {
        "index_patterns": ["fawkes-logs-*"],
        "dls": "{\"term\": {\"k8s_namespace\": \"team-alpha\"}}",
        "fls": [],
        "masked_fields": [],
        "allowed_actions": ["read"]
      }
    ]
  }
}
```

### Grafana Integration

**Loki Datasource Configuration** (simulated via OpenSearch):
```yaml
apiVersion: 1
datasources:
  - name: OpenSearch Logs
    type: grafana-opensearch-datasource
    access: proxy
    url: http://opensearch.fawkes-logging.svc.cluster.local:9200
    basicAuth: true
    basicAuthUser: grafana
    secureJsonData:
      basicAuthPassword: ${OPENSEARCH_GRAFANA_PASSWORD}
    jsonData:
      timeField: "@timestamp"
      esVersion: "7.10.0"
      logMessageField: log
      logLevelField: level
      database: "fawkes-logs-*"
```

### Structured Logging Best Practices

**Recommended Log Format (JSON)**:
```json
{
  "@timestamp": "2024-12-07T10:30:00.123Z",
  "level": "INFO",
  "logger": "com.example.UserService",
  "message": "User login successful",
  "trace_id": "a1b2c3d4e5f6",
  "span_id": "1234567890",
  "user_id": "user-123",
  "ip_address": "192.168.1.100",
  "duration_ms": 45,
  "kubernetes": {
    "namespace": "team-alpha",
    "pod": "user-service-abc123",
    "container": "user-service"
  }
}
```

**Fields to Always Include**:
- `@timestamp`: ISO 8601 timestamp
- `level`: Log level (ERROR, WARN, INFO, DEBUG)
- `message`: Human-readable message
- `trace_id`: Distributed tracing ID (OpenTelemetry)
- `span_id`: Span ID for correlation
- Context fields: user_id, request_id, correlation_id

### Common Query Patterns

**Search for Errors in Namespace**:
```
k8s_namespace:"team-alpha" AND level:"ERROR"
```

**Find Logs with Trace ID**:
```
trace_id:"a1b2c3d4e5f6"
```

**Logs from Specific Pod**:
```
k8s_pod_name:"jenkins-agent-*"
```

**Slow Requests (Duration > 1000ms)**:
```
duration_ms:>1000
```

**Deployment Events**:
```
message:"deployment" AND k8s_namespace:"production"
```

### Alerting Rules

**High Error Rate**:
```json
{
  "trigger": {
    "schedule": { "interval": "5m" },
    "condition": {
      "script": {
        "source": "ctx.results[0].hits.total.value > 100"
      }
    }
  },
  "input": {
    "search": {
      "request": {
        "indices": ["fawkes-logs-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                { "term": { "level": "ERROR" }},
                { "range": { "@timestamp": { "gte": "now-5m" }}}
              ]
            }
          }
        }
      }
    }
  },
  "actions": {
    "slack": {
      "webhook": {
        "url": "https://hooks.slack.com/...",
        "body": "High error rate detected: {{ctx.results.0.hits.total.value}} errors in last 5 minutes"
      }
    }
  }
}
```

**Service Unavailable**:
```json
{
  "trigger": {
    "schedule": { "interval": "1m" },
    "condition": {
      "script": {
        "source": "ctx.results[0].hits.total.value > 0"
      }
    }
  },
  "input": {
    "search": {
      "request": {
        "indices": ["fawkes-logs-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                { "match": { "message": "connection refused" }},
                { "term": { "k8s_namespace": "production" }},
                { "range": { "@timestamp": { "gte": "now-1m" }}}
              ]
            }
          }
        }
      }
    }
  }
}
```

## Consequences

### Positive

1. **Cloud Agnostic**: OpenSearch works identically across AWS, Azure, GCP, on-premises
2. **Open Source**: No licensing costs, Apache 2.0 license, community-driven
3. **Scalable**: Handles billions of log entries, horizontal scaling via data nodes
4. **Fast Search**: Sub-second queries across large datasets, optimized inverted indices
5. **Rich Query Language**: SQL and DSL query support, aggregations, complex filters
6. **Multi-Tenancy**: Document-level security for team isolation
7. **Cost Efficient**: Tiered storage (hot/warm/cold) reduces costs significantly
8. **Integration Rich**: Grafana, Prometheus, SIEM tools, OpenTelemetry
9. **Lightweight Collection**: Fluent Bit minimal resource footprint (~100MB memory)
10. **GitOps Compatible**: Declarative configuration, ArgoCD-managed

### Negative

1. **Operational Complexity**: OpenSearch cluster requires careful sizing, monitoring, tuning
2. **Resource Intensive**: Data nodes need significant CPU/memory/storage
3. **Learning Curve**: Query DSL, index management, cluster operations require training
4. **Index Management Overhead**: Need to configure ILM policies, monitor shard distribution
5. **No Native Multi-Line Support**: Requires Fluent Bit parser configuration
6. **Storage Costs**: Hot storage on SSD can be expensive (mitigated by tiered storage)
7. **Backup Complexity**: Snapshot repository setup, restoration testing required

### Neutral

1. **Elasticsearch Compatibility**: OpenSearch fork maintains compatibility (mostly)
2. **Alternative to ELK**: Uses OpenSearch instead of Elasticsearch (licensing differences)
3. **Dashboards vs. Kibana**: OpenSearch Dashboards UI similar to Kibana
4. **S3 Cold Storage**: Requires object storage configuration for cold tier

## Alternatives Considered

### Alternative 1: Grafana Loki

**Pros**:
- Designed for Kubernetes logging (cloud-native)
- Very cost-efficient (indexes only metadata, not log content)
- Tight Grafana integration (unified metrics + logs)
- Simple deployment and operation
- LogQL query language (similar to PromQL)
- Good for high-volume, short-retention use cases

**Cons**:
- Limited full-text search capabilities (no inverted index)
- Less powerful query language than OpenSearch DSL
- Smaller community and ecosystem than OpenSearch/Elasticsearch
- Less suitable for compliance (long-term retention, complex queries)
- Fewer visualization options in dashboards
- Multi-tenancy requires Loki enterprise features

**Reason for Rejection**: While Loki is excellent for operational logging, Fawkes requires robust full-text search for debugging, compliance auditing, and security investigations. OpenSearch's powerful query DSL and proven scalability better support DORA metrics analysis and incident post-mortems. However, Loki remains a strong alternative for cost-sensitive deployments.

### Alternative 2: Elastic Cloud (ELK Stack)

**Pros**:
- Industry standard (Elasticsearch, Logstash, Kibana)
- Massive ecosystem and community
- Extremely powerful search and analytics
- Best-in-class visualization (Kibana)
- Mature machine learning features
- Extensive documentation and training

**Cons**:
- **Licensing concerns** (Elastic License 2.0, not fully open source)
- High cost for managed service ($50-500+/month)
- Vendor lock-in potential
- Self-hosted ELK requires significant operational expertise
- Logstash resource-heavy (replaced by Fluent Bit in modern stacks)
- Complex licensing tiers (basic, gold, platinum)

**Reason for Rejection**: Elastic's move away from Apache 2.0 license conflicts with Fawkes' open-source principles. O
