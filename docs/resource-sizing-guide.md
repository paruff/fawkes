# Resource Sizing Guide for Fawkes Platform

## Overview

This guide provides recommended resource allocations for different deployment scales of the Fawkes platform. All resource allocations have been optimized to maintain <70% CPU and memory utilization under typical workload conditions.

## Resource Optimization Principles

1. **Target Utilization**: Maintain average CPU and memory usage below 70% of allocated limits
2. **Burst Capacity**: Provide headroom for traffic spikes and batch processing
3. **No Pod Evictions**: Ensure requests are set appropriately to prevent OOM kills
4. **Cost Efficiency**: Balance performance requirements with resource costs

## Component Resource Allocations

### Development/MVP Scale (5 teams, 25 services)

#### Core Platform Components

| Component | Replicas | CPU Request | CPU Limit | Memory Request | Memory Limit | Notes |
|-----------|----------|-------------|-----------|----------------|--------------|-------|
| **Backstage** | 2 | 300m | 1 | 384Mi | 1Gi | Developer portal |
| **Jenkins Controller** | 1 | 500m | 1500m | 1Gi | 2Gi | CI/CD orchestration |
| **ArgoCD** | 1 | 250m | 500m | 256Mi | 512Mi | GitOps deployment |

#### Observability Stack

| Component | Replicas | CPU Request | CPU Limit | Memory Request | Memory Limit | Notes |
|-----------|----------|-------------|-----------|----------------|--------------|-------|
| **Prometheus** | 1 | 300m | 800m | 768Mi | 1536Mi | Metrics collection (7d retention) |
| **Prometheus Operator** | 1 | 80m | 150m | 100Mi | 200Mi | Operator for Prometheus |
| **Grafana** | 1 | 80m | 150m | 200Mi | 400Mi | Visualization |
| **Alertmanager** | 1 | 30m | 80m | 48Mi | 100Mi | Alert routing |
| **Node Exporter** | DaemonSet | 40m | 80m | 50Mi | 100Mi | Per-node metrics |
| **Kube State Metrics** | 1 | 40m | 80m | 50Mi | 100Mi | Kubernetes metrics |
| **OpenTelemetry Collector** | DaemonSet | 150m | 800m | 384Mi | 768Mi | Log/trace collection |
| **Grafana Tempo** | 1 | 100m | 500m | 256Mi | 512Mi | Distributed tracing |
| **OpenSearch** | 1 | 400m | 800m | 1536Mi | 1536Mi | Log aggregation/search |

#### Data Persistence

| Component | Replicas | CPU Request | CPU Limit | Memory Request | Memory Limit | Storage | Notes |
|-----------|----------|-------------|-----------|----------------|--------------|---------|-------|
| **PostgreSQL (Backstage)** | 3 | 300m | 1 | 384Mi | 1Gi | 20Gi | Catalog database |
| **PostgreSQL (Harbor)** | 3 | 300m | 1 | 768Mi | 1536Mi | 20Gi | Registry database |
| **PostgreSQL (SonarQube)** | 3 | 300m | 1 | 384Mi | 1Gi | 20Gi | Code analysis data |
| **PostgreSQL (Focalboard)** | 3 | 300m | 1 | 384Mi | 1Gi | 20Gi | Project management |

#### Security Components

| Component | Replicas | CPU Request | CPU Limit | Memory Request | Memory Limit | Notes |
|-----------|----------|-------------|-----------|----------------|--------------|-------|
| **Vault Server** | 3 | 200m | 800m | 200Mi | 400Mi | Secrets management |
| **Vault Injector** | 2 | 40m | 200m | 50Mi | 200Mi | Secret injection |
| **CSI Driver** | DaemonSet | 50m | 200m | 64Mi | 128Mi | Volume-based secrets |
| **Kyverno Admission** | 3 | 80m | 400m | 200Mi | 400Mi | Policy admission control |
| **Kyverno Background** | 2 | 80m | 400m | 100Mi | 200Mi | Policy reconciliation |
| **Kyverno Reports** | 1 | 80m | 400m | 100Mi | 200Mi | Policy reporting |
| **Kyverno Cleanup** | 1 | 80m | 400m | 100Mi | 200Mi | Resource cleanup |
| **SonarQube** | 1 | 500m | 1500m | 1536Mi | 3Gi | Code analysis |

### Total Resource Requirements by Scale

#### MVP Scale (5 teams, 25 services)

**Platform Core Services:**
- CPU Requests: ~5.5 cores
- CPU Limits: ~15 cores
- Memory Requests: ~11 GB
- Memory Limits: ~22 GB
- Storage: ~150 GB

**Recommended Cluster Configuration:**
- Nodes: 3-5 worker nodes
- Node Size: 4 vCPU, 16 GB RAM each
- Total Cluster: 12-20 vCPU, 48-80 GB RAM
- Platform Overhead: ~45% of cluster capacity
- Application Capacity: ~55% of cluster capacity

#### Production Scale (20 teams, 200 services)

**Scaling Recommendations:**

| Component | MVP → Production Change | Rationale |
|-----------|------------------------|-----------|
| Backstage | 2→3 replicas, +50% resources | More concurrent users |
| Prometheus | 1→2 replicas, 2x storage | HA and data retention |
| Grafana | 1→2 replicas | HA for dashboards |
| PostgreSQL | +50% resources per cluster | Larger datasets |
| OpenSearch | 1→3 nodes, 3x storage | Data volume and HA |
| Jenkins | +50% controller resources | More pipelines |

**Recommended Cluster Configuration:**
- Nodes: 10-20 worker nodes
- Node Size: 8 vCPU, 32 GB RAM each
- Total Cluster: 80-160 vCPU, 320-640 GB RAM
- Platform Overhead: ~30% of cluster capacity
- Application Capacity: ~70% of cluster capacity

## Resource Tuning Guidelines

### When to Scale Up

**CPU:**
- Sustained usage >70% of limits
- Increased request latency (P95 >2x baseline)
- Container throttling metrics increasing
- Queue depths growing

**Memory:**
- Sustained usage >70% of limits
- Increasing GC frequency (for JVM apps)
- OOM kill events
- Disk swapping activity

### When to Scale Down

**CPU:**
- Sustained usage <30% of requests
- No performance degradation observed
- After workload analysis over 7+ days

**Memory:**
- Sustained usage <40% of requests
- No OOM events for 30+ days
- After workload analysis over 7+ days

### Monitoring Metrics

**Key Metrics to Track:**
```
# CPU
container_cpu_usage_seconds_total
rate(container_cpu_usage_seconds_total[5m])

# Memory
container_memory_usage_bytes
container_memory_working_set_bytes

# Throttling
container_cpu_cfs_throttled_seconds_total

# OOM
container_oom_events_total

# Evictions
kube_pod_status_reason{reason="Evicted"}
```

### Resource Request/Limit Ratio Guidelines

**Recommended Ratios:**
- CPU: Request = 30-50% of Limit (allows bursting)
- Memory: Request = 70-100% of Limit (memory is not compressible)

**Example:**
```yaml
resources:
  requests:
    cpu: 300m      # 30% of limit
    memory: 768Mi  # 75% of limit
  limits:
    cpu: 1         # Allows 3x burst
    memory: 1Gi    # Prevents OOM
```

## Pod Disruption Budgets

For HA components, always configure PDBs:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: backstage-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: backstage
```

## Horizontal Pod Autoscaling (HPA)

For stateless components that can scale horizontally:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backstage-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backstage
  minReplicas: 2
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 70
```

## Vertical Pod Autoscaling (VPA)

For components with variable resource needs:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: backstage-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backstage
  updatePolicy:
    updateMode: "Auto"  # or "Recreate" or "Initial"
  resourcePolicy:
    containerPolicies:
      - containerName: backstage
        minAllowed:
          cpu: 300m
          memory: 384Mi
        maxAllowed:
          cpu: 2
          memory: 4Gi
```

## Validation

### Manual Validation

```bash
# Check current resource usage
kubectl top nodes
kubectl top pods -n fawkes

# Check for evicted pods
kubectl get pods -A --field-selector=status.phase=Failed

# Check resource pressure
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Automated Validation

Use the provided validation script:

```bash
# Run resource usage validation
./scripts/validate-resource-usage.sh --namespace fawkes

# Run with custom targets
./scripts/validate-resource-usage.sh --namespace fawkes --target-cpu 70 --target-memory 70

# Verbose output
./scripts/validate-resource-usage.sh --namespace fawkes --verbose
```

### Continuous Monitoring

Set up Prometheus alerts for resource pressure:

```yaml
groups:
  - name: resource-usage
    interval: 60s
    rules:
      - alert: HighCPUUsage
        expr: |
          (sum(rate(container_cpu_usage_seconds_total{namespace="fawkes"}[5m])) by (pod, container)
          / sum(container_spec_cpu_quota{namespace="fawkes"} / container_spec_cpu_period{namespace="fawkes"}) by (pod, container)) > 0.7
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "Pod {{ $labels.pod }} container {{ $labels.container }} CPU usage is above 70%"

      - alert: HighMemoryUsage
        expr: |
          (sum(container_memory_working_set_bytes{namespace="fawkes"}) by (pod, container)
          / sum(container_spec_memory_limit_bytes{namespace="fawkes"}) by (pod, container)) > 0.7
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Pod {{ $labels.pod }} container {{ $labels.container }} memory usage is above 70%"
```

## Performance Benchmarks

### Expected Performance After Optimization

| Metric | Target | Measurement Window |
|--------|--------|-------------------|
| Backstage Page Load | <2s | P95 |
| Jenkins Build Queue Time | <30s | P95 |
| ArgoCD Sync Time | <30s | P95 |
| Prometheus Query Time | <5s | P95 |
| Grafana Dashboard Load | <3s | P95 |
| API Response Time | <200ms | P95 |

### Load Testing

Before deploying to production, perform load testing:

```bash
# Example load test for Backstage
kubectl run -it --rm load-test \
  --image=williamyeh/hey:latest \
  --restart=Never \
  -- -n 1000 -c 10 -m GET \
  http://backstage.fawkes.svc.cluster.local:7007/catalog

# Monitor during load test
watch kubectl top pods -n fawkes
```

## Troubleshooting

### Pod Evictions

**Symptoms:**
- Pods restarting frequently
- Status: `Evicted`
- Reason: `OutOfMemory` or `DiskPressure`

**Solution:**
1. Check memory limits: `kubectl describe pod <pod-name> -n fawkes`
2. Increase memory requests/limits
3. Check for memory leaks in application code

### CPU Throttling

**Symptoms:**
- Slow application response times
- High CPU throttling metrics
- No increase in actual CPU usage

**Solution:**
1. Check throttling: `kubectl top pods -n fawkes --containers`
2. Increase CPU limits (but keep requests low for scheduling)
3. Consider HPA for scaling out instead of up

### Out of Memory (OOM)

**Symptoms:**
- Pod terminated with exit code 137
- `OOMKilled` in pod status

**Solution:**
1. Increase memory limits
2. Review application memory consumption
3. Check for memory leaks
4. Tune JVM heap sizes (for Java apps)

## References

- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [DORA Metrics Research](https://dora.dev/)
- [Fawkes Architecture](../architecture.md)

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-16 | Initial resource optimization for Issue #35 |
