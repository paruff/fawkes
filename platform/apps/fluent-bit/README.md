# Fluent Bit - Log Collection and Forwarding

## Purpose

Fluent Bit is a lightweight, high-performance log processor and forwarder that collects logs from all Kubernetes pods and forwards them to OpenSearch for centralized log management.

## Key Features

- **Low Resource Usage**: < 1MB memory footprint
- **High Performance**: 15k+ events/sec per core
- **Kubernetes Native**: Built-in Kubernetes metadata enrichment
- **Multiple Outputs**: OpenSearch, S3, Kafka, etc.
- **Filtering**: Log parsing and transformation
- **Buffering**: Reliable log delivery with backpressure

## Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                     Kubernetes Pods                              │
│  ├─ Application logs (stdout/stderr)                            │
│  └─ Container logs (/var/log/containers/*.log)                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Fluent Bit DaemonSet                             │
│  ├─ Input: tail /var/log/containers/*.log                      │
│  ├─ Parser: JSON, multiline, regex                             │
│  ├─ Filter: Kubernetes metadata enrichment                      │
│  └─ Output: OpenSearch, S3, etc.                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     OpenSearch Cluster                           │
│  ├─ Indexed logs with full-text search                         │
│  └─ Retention policies and ILM                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Configuration

### Input Configuration

```yaml
[INPUT]
    Name              tail
    Path              /var/log/containers/*.log
    Parser            docker
    Tag               kube.*
    Refresh_Interval  5
    Mem_Buf_Limit     5MB
```

### Kubernetes Filter

Enriches logs with Kubernetes metadata:

```yaml
[FILTER]
    Name                kubernetes
    Match               kube.*
    Kube_URL            https://kubernetes.default.svc:443
    Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
    Merge_Log           On
    K8S-Logging.Parser  On
    K8S-Logging.Exclude On
```

### OpenSearch Output

```yaml
[OUTPUT]
    Name            es
    Match           *
    Host            opensearch.logging.svc
    Port            9200
    Index           fawkes-logs
    Type            _doc
    Logstash_Format On
    Logstash_Prefix fawkes
    Retry_Limit     5
```

## Log Enrichment

Fluent Bit automatically adds Kubernetes metadata:

```json
{
  "log": "Application log message",
  "kubernetes": {
    "namespace_name": "fawkes",
    "pod_name": "myapp-5d7f9c-xyz",
    "container_name": "app",
    "labels": {
      "app": "myapp",
      "version": "v1.0.0"
    }
  },
  "@timestamp": "2024-12-13T18:00:00.000Z"
}
```

## Filtering and Parsing

### Multiline Logs

Handle Java stack traces and multi-line logs:

```yaml
[PARSER]
    Name        multiline-java
    Format      regex
    Regex       ^\d{4}-\d{2}-\d{2}
    Time_Key    time
    Time_Format %Y-%m-%d %H:%M:%S
```

### Exclude System Logs

```yaml
[FILTER]
    Name    grep
    Match   kube.*
    Exclude log kube-system
```

## Resource Management

Fluent Bit runs as a DaemonSet with resource limits:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

## Monitoring

Fluent Bit exposes Prometheus metrics:

```yaml
[SERVICE]
    HTTP_Server  On
    HTTP_Listen  0.0.0.0
    HTTP_Port    2020
```

Key metrics:
- `fluentbit_input_records_total` - Records received
- `fluentbit_output_records_total` - Records sent
- `fluentbit_output_errors_total` - Output errors

## Troubleshooting

### Check Fluent Bit Logs

```bash
# View logs from all nodes
kubectl logs -n logging daemonset/fluent-bit -f

# View logs from specific node
kubectl logs -n logging fluent-bit-<pod-id> -f
```

### Test Log Flow

```bash
# Create test pod
kubectl run test-logger --image=busybox --restart=Never -- sh -c "while true; do echo 'Test log message'; sleep 1; done"

# Check logs appear in OpenSearch
curl -X GET "http://opensearch.logging.svc:9200/fawkes-*/_search?q=Test+log+message"
```

### High Memory Usage

If Fluent Bit consumes too much memory:

1. Reduce `Mem_Buf_Limit` in input configuration
2. Increase `Flush` interval to reduce output frequency
3. Add filters to exclude verbose logs

## Related Documentation

- [Fluent Bit Documentation](https://docs.fluentbit.io/)
- [Kubernetes Logging](https://kubernetes.io/docs/concepts/cluster-administration/logging/)
