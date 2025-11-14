# Fawkes Dojo Module 13: Monitoring, Observability & DORA Metrics

## Module Overview

**Duration:** 3-4 hours
**Level:** Advanced
**Prerequisites:** Modules 1-4, Working Fawkes deployment, Basic understanding of Kubernetes and CI/CD

### Learning Objectives

By the end of this module, you will be able to:

1. Implement comprehensive monitoring and observability for your Fawkes platform
2. Configure and customize dashboards for platform health and performance
3. Measure and track the Four Key DORA metrics
4. Set up alerting and incident response workflows
5. Use observability data to drive continuous improvement
6. Implement distributed tracing for application performance monitoring

---

## Part 1: Understanding Observability in Platform Engineering

### The Three Pillars of Observability

**Metrics**: Numerical measurements over time
- Infrastructure metrics (CPU, memory, disk, network)
- Application metrics (request rate, error rate, latency)
- Business metrics (deployments, lead time, failure rate)

**Logs**: Event records from systems and applications
- Structured vs. unstructured logs
- Log aggregation and centralization
- Log levels and filtering

**Traces**: Request flows through distributed systems
- Distributed tracing concepts
- Span and trace relationships
- Performance bottleneck identification

### Why Observability Matters for DORA

The Four Key Metrics require robust observability:

1. **Deployment Frequency**: Track deployments through CI/CD events
2. **Lead Time for Changes**: Measure from commit to production
3. **Change Failure Rate**: Monitor deployment failures and rollbacks
4. **Mean Time to Restore (MTTR)**: Detect and measure incident resolution time

---

## Part 2: Fawkes Monitoring Stack

### Components Overview

Fawkes includes an integrated monitoring stack:

```
┌─────────────────────────────────────────────┐
│           Grafana Dashboards                │
│        (Visualization & Alerting)           │
└──────────────┬──────────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌─────▼──────┐
│ Prometheus  │  │    Loki    │
│  (Metrics)  │  │   (Logs)   │
└──────┬──────┘  └─────┬──────┘
       │                │
┌──────▼────────────────▼──────┐
│      Node Exporters          │
│   Application Exporters      │
│      Fluent Bit/Promtail     │
└──────────────┬────────────────┘
               │
    ┌──────────▼───────────┐
    │  Kubernetes Cluster  │
    │    Applications      │
    └──────────────────────┘
```

### Included Tools

- **Prometheus**: Metrics collection and storage
- **Grafana**: Dashboard visualization and alerting
- **Loki**: Log aggregation (lightweight alternative to ELK)
- **Tempo**: Distributed tracing (optional)
- **AlertManager**: Alert routing and notification
- **Node Exporter**: Infrastructure metrics
- **kube-state-metrics**: Kubernetes object metrics

---

## Part 3: Hands-On Lab - Deploying the Monitoring Stack

### Lab Setup

**Scenario**: You have a running Fawkes platform on Kubernetes. Now you'll deploy the full monitoring stack and configure dashboards.

### Step 1: Deploy Monitoring Components

```bash
# Navigate to the platform monitoring directory
cd fawkes/platform/monitoring

# Deploy Prometheus Operator and stack
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack (includes Prometheus, Grafana, AlertManager)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set grafana.adminPassword=admin123 \
  -f values/prometheus-values.yaml
```

### Step 2: Deploy Loki for Log Aggregation

```bash
# Install Loki
helm repo add grafana https://grafana.github.io/helm-charts
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=50Gi
```

### Step 3: Configure Data Sources in Grafana

```bash
# Get Grafana admin password
kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Port-forward to access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Visit `http://localhost:3000` and log in with admin credentials.

**Add Loki Data Source:**
1. Go to Configuration → Data Sources
2. Add data source → Loki
3. URL: `http://loki:3100`
4. Save & Test

### Step 4: Verify Metrics Collection

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Open http://localhost:9090/targets
# Verify all targets are "UP"
```

**Expected targets:**
- kubernetes-apiservers
- kubernetes-nodes
- kubernetes-pods
- kubernetes-service-endpoints
- kube-state-metrics
- node-exporter

---

## Part 4: Configuring DORA Metrics Dashboards

### Creating Custom Metrics

To track DORA metrics, we need to instrument our CI/CD pipeline to emit custom metrics.

### Deployment Frequency Metric

Add to your CI/CD pipeline (e.g., Jenkins, GitLab CI, ArgoCD):

```yaml
# Example: Prometheus metrics endpoint in your deployment controller
apiVersion: v1
kind: ConfigMap
metadata:
  name: deployment-metrics
  namespace: fawkes-platform
data:
  record-deployment.sh: |
    #!/bin/bash
    # Record deployment event
    cat <<EOF | curl --data-binary @- http://prometheus-pushgateway:9091/metrics/job/deployments
    # TYPE deployment_total counter
    # HELP deployment_total Total number of deployments
    deployment_total{environment="$ENV",application="$APP",status="$STATUS"} 1
    EOF
```

### Lead Time for Changes

Track commit-to-deployment time:

```python
# Example Python script to calculate lead time
from prometheus_client import Gauge, push_to_gateway
import os
from datetime import datetime

lead_time_gauge = Gauge('lead_time_seconds', 'Time from commit to deployment', ['application', 'environment'])

def record_lead_time(commit_timestamp, deploy_timestamp, app, env):
    lead_time = (deploy_timestamp - commit_timestamp).total_seconds()
    lead_time_gauge.labels(application=app, environment=env).set(lead_time)
    push_to_gateway('prometheus-pushgateway:9091', job='lead_time', registry=registry)
```

### Change Failure Rate

Monitor deployment failures and rollbacks:

```bash
# In your deployment script, record success/failure
deployment_status="success"  # or "failure"

cat <<EOF | curl --data-binary @- http://prometheus-pushgateway:9091/metrics/job/deployment_results
deployment_result{application="$APP",environment="$ENV",status="$deployment_status"} 1
EOF
```

### MTTR (Mean Time to Restore)

Use AlertManager and incident tracking:

```yaml
# PromQL query for MTTR
rate(alert_duration_seconds_sum[7d]) / rate(alert_duration_seconds_count[7d])
```

### Import DORA Dashboard

Create a Grafana dashboard (`dora-metrics-dashboard.json`):

```json
{
  "dashboard": {
    "title": "DORA Four Key Metrics",
    "panels": [
      {
        "title": "Deployment Frequency",
        "targets": [
          {
            "expr": "sum(rate(deployment_total[1d])) by (environment)"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Lead Time for Changes (Average)",
        "targets": [
          {
            "expr": "avg(lead_time_seconds) by (application)"
          }
        ],
        "type": "stat"
      },
      {
        "title": "Change Failure Rate",
        "targets": [
          {
            "expr": "sum(rate(deployment_result{status='failure'}[7d])) / sum(rate(deployment_result[7d])) * 100"
          }
        ],
        "type": "gauge"
      },
      {
        "title": "Mean Time to Restore (MTTR)",
        "targets": [
          {
            "expr": "avg(alert_duration_seconds) by (severity)"
          }
        ],
        "type": "stat"
      }
    ]
  }
}
```

Import into Grafana:
```bash
# Import dashboard
curl -X POST http://admin:admin123@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @dora-metrics-dashboard.json
```

---

## Part 5: Alerting and Incident Response

### Configuring AlertManager

Edit AlertManager configuration:

```yaml
# alertmanager-config.yaml
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default'
  routes:
  - match:
      severity: critical
    receiver: 'pagerduty-critical'
  - match:
      severity: warning
    receiver: 'slack-warnings'

receivers:
- name: 'default'
  slack_configs:
  - channel: '#alerts'
    title: 'Alert: {{ .GroupLabels.alertname }}'
    text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

- name: 'pagerduty-critical'
  pagerduty_configs:
  - service_key: 'YOUR_PAGERDUTY_KEY'

- name: 'slack-warnings'
  slack_configs:
  - channel: '#warnings'
    title: 'Warning: {{ .GroupLabels.alertname }}'
```

Apply configuration:
```bash
kubectl create secret generic alertmanager-config \
  --from-file=alertmanager.yaml=alertmanager-config.yaml \
  -n monitoring

kubectl rollout restart statefulset/alertmanager-prometheus-kube-prometheus-alertmanager -n monitoring
```

### Creating Alert Rules

```yaml
# prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: fawkes-platform-alerts
  namespace: monitoring
spec:
  groups:
  - name: platform_health
    interval: 30s
    rules:
    - alert: HighPodCrashRate
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0.1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High pod crash rate detected"
        description: "Pod {{ $labels.pod }} is crash-looping"

    - alert: DeploymentFailed
      expr: increase(deployment_result{status="failure"}[5m]) > 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Deployment failure detected"
        description: "Deployment for {{ $labels.application }} failed"

    - alert: HighChangeFailureRate
      expr: |
        sum(rate(deployment_result{status="failure"}[7d]))
        / sum(rate(deployment_result[7d])) * 100 > 15
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Change failure rate exceeds 15%"
        description: "Current CFR: {{ $value }}%"

    - alert: LowDeploymentFrequency
      expr: sum(rate(deployment_total[1d])) < 0.1
      for: 1h
      labels:
        severity: warning
      annotations:
        summary: "Deployment frequency is low"
        description: "Less than 1 deployment per 10 days"

    - alert: HighLeadTime
      expr: avg(lead_time_seconds) > 86400
      for: 1h
      labels:
        severity: warning
      annotations:
        summary: "Lead time exceeds 24 hours"
        description: "Average lead time: {{ $value }}s"
```

Apply rules:
```bash
kubectl apply -f prometheus-rules.yaml
```

---

## Part 6: Application Performance Monitoring with Tracing

### Deploy Tempo for Distributed Tracing

```bash
# Install Tempo
helm install tempo grafana/tempo \
  --namespace monitoring \
  --set persistence.enabled=true
```

### Instrument Your Application

Example using OpenTelemetry (Java Spring Boot):

```xml
<!-- pom.xml -->
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-api</artifactId>
    <version>1.32.0</version>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
    <version>1.32.0</version>
</dependency>
```

```java
// Application configuration
@Configuration
public class TracingConfig {
    @Bean
    public OpenTelemetry openTelemetry() {
        OtlpGrpcSpanExporter spanExporter = OtlpGrpcSpanExporter.builder()
            .setEndpoint("http://tempo:4317")
            .build();

        SdkTracerProvider tracerProvider = SdkTracerProvider.builder()
            .addSpanProcessor(BatchSpanProcessor.builder(spanExporter).build())
            .build();

        return OpenTelemetrySdk.builder()
            .setTracerProvider(tracerProvider)
            .buildAndRegisterGlobal();
    }
}
```

### Configure Tempo in Grafana

1. Add Tempo data source in Grafana
2. URL: `http://tempo:3100`
3. Enable trace to logs correlation with Loki

---

## Part 7: Log Analysis and Troubleshooting

### Effective Log Queries with LogQL

**Find errors in the last hour:**
```logql
{namespace="fawkes-platform"} |= "ERROR" | json | line_format "{{.timestamp}} {{.level}} {{.message}}"
```

**Track deployment events:**
```logql
{job="deployment-controller"} |= "deployment" | json | status="success"
```

**Analyze slow requests:**
```logql
{app="api-gateway"} | json | duration > 1000 | line_format "Slow request: {{.path}} took {{.duration}}ms"
```

### Creating Log-Based Alerts

```yaml
# Grafana alert from logs
- alert: HighErrorRate
  expr: |
    sum(rate({namespace="fawkes-platform"} |= "ERROR" [5m]))
    > 10
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High error rate in platform logs"
```

---

## Part 8: Dashboarding Best Practices

### Dashboard Design Principles

1. **Top-down approach**: Overall health → Specific components
2. **Red method for services**: Rate, Errors, Duration
3. **USE method for resources**: Utilization, Saturation, Errors
4. **Actionable metrics**: Every panel should inform decisions
5. **Consistent time ranges**: Synchronize across panels

### Example Platform Health Dashboard Structure

```
┌─────────────────────────────────────────────┐
│  Overall Platform Health (Single stat)      │
│  ● Cluster Status  ● Deployments  ● Alerts │
└─────────────────────────────────────────────┘

┌──────────────────────┐ ┌───────────────────┐
│  Deployment Freq.    │ │  Lead Time Trend  │
│  (Time series)       │ │  (Time series)    │
└──────────────────────┘ └───────────────────┘

┌──────────────────────┐ ┌───────────────────┐
│  Change Failure %    │ │  MTTR (Avg)       │
│  (Gauge)             │ │  (Stat)           │
└──────────────────────┘ └───────────────────┘

┌─────────────────────────────────────────────┐
│  Recent Deployments (Table)                 │
│  Time | App | Env | Status | Duration       │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  Active Alerts (Table)                      │
│  Severity | Alert | Time | Status           │
└─────────────────────────────────────────────┘
```

---

## Part 9: Practical Exercise

### Exercise: Complete Observability Implementation

**Objective**: Implement end-to-end observability for a sample application deployed on Fawkes.

**Steps:**

1. **Deploy Sample Application**
   ```bash
   kubectl apply -f exercises/sample-app/
   ```

2. **Configure Application Metrics**
   - Expose Prometheus metrics endpoint
   - Add custom business metrics
   - Verify scraping in Prometheus

3. **Set Up Logging**
   - Ensure structured JSON logs
   - Verify logs appear in Loki
   - Create useful log queries

4. **Create Dashboard**
   - Import base dashboard template
   - Add custom panels for your app
   - Configure variables for filtering

5. **Configure Alerts**
   - Create alert for high error rate
   - Create alert for deployment failures
   - Test alert firing and resolution

6. **Implement Tracing**
   - Add OpenTelemetry instrumentation
   - Generate sample traces
   - Correlate traces with logs

7. **Measure DORA Metrics**
   - Deploy multiple times
   - Introduce a failure
   - Calculate all four metrics
   - Identify improvement opportunities

**Validation Checklist:**
- [ ] Application metrics visible in Prometheus
- [ ] Logs searchable in Grafana/Loki
- [ ] Dashboard shows real-time data
- [ ] Alerts fire and resolve correctly
- [ ] Traces show request flows
- [ ] DORA metrics calculated and displayed

---

## Part 10: Advanced Topics

### Cost Optimization

**Reduce metric cardinality:**
```yaml
# Drop unnecessary labels
metric_relabel_configs:
  - source_labels: [__name__]
    regex: 'go_.*'
    action: drop
```

**Adjust retention:**
```yaml
# Shorter retention for high-volume metrics
- record: aggregated:deployment_total:sum
  expr: sum(rate(deployment_total[5m])) by (environment)
```

### High Availability Setup

```yaml
# Prometheus HA with Thanos
prometheus:
  prometheusSpec:
    replicas: 2
    thanos:
      image: quay.io/thanos/thanos:v0.32.0
      objectStorageConfig:
        secret: thanos-objstore-config
```

### Multi-Cluster Monitoring

```bash
# Use Thanos or Cortex for cross-cluster metrics
helm install thanos bitnami/thanos \
  --set query.enabled=true \
  --set storegateway.enabled=true
```

---

## Part 11: Troubleshooting Common Issues

### Prometheus Not Scraping Targets

**Symptom**: Targets show as "DOWN" in Prometheus

**Solution:**
```bash
# Check ServiceMonitor configuration
kubectl get servicemonitors -n monitoring

# Verify service selector matches
kubectl describe servicemonitor <name> -n monitoring

# Check network policies
kubectl get networkpolicies -n monitoring
```

### High Cardinality Problems

**Symptom**: Prometheus using excessive memory

**Solution:**
```bash
# Identify high-cardinality metrics
curl http://localhost:9090/api/v1/status/tsdb | jq .

# Drop or aggregate problematic metrics
# Add to prometheus-values.yaml
```

### Missing Logs in Loki

**Symptom**: No logs appearing in Grafana

**Solution:**
```bash
# Check Promtail is running
kubectl get pods -n monitoring -l app=promtail

# Verify Promtail configuration
kubectl logs -n monitoring -l app=promtail

# Check Loki ingester
kubectl logs -n monitoring -l app=loki -c ingester
```

---

## Part 12: Summary and Next Steps

### Key Takeaways

1. Observability is critical for platform reliability and DORA metrics
2. The three pillars (metrics, logs, traces) provide complementary insights
3. Automation of metric collection reduces manual work
4. Dashboards should be actionable and inform decisions
5. Alerting requires tuning to avoid fatigue
6. DORA metrics drive continuous improvement

### Measuring Success

After completing this module, you should have:
- ✅ Working Prometheus + Grafana + Loki stack
- ✅ Custom dashboards for DORA metrics
- ✅ Configured alerts for platform health
- ✅ Application instrumentation for tracing
- ✅ Log aggregation and search capability
- ✅ Understanding of observability best practices

### Continuous Improvement

**Weekly Activities:**
- Review DORA metrics trends
- Analyze alert patterns
- Optimize slow queries
- Update dashboards based on team feedback

**Monthly Activities:**
- Review and adjust alert thresholds
- Archive old metrics data
- Update documentation
- Train team members on new features

### Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [OpenTelemetry Specification](https://opentelemetry.io/docs/)
- [DORA Research](https://dora.dev/)
- [Google SRE Book - Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)
- [Loki LogQL Documentation](https://grafana.com/docs/loki/latest/logql/)

---

## Module Assessment

### Knowledge Check Questions

1. What are the three pillars of observability?
2. How do you calculate the Change Failure Rate?
3. What's the difference between metrics and traces?
4. When should you use Prometheus vs. Loki?
5. What is metric cardinality and why does it matter?
6. How do you correlate traces with logs in Grafana?
7. What's the purpose of AlertManager's grouping?
8. How can you reduce monitoring costs?

### Practical Assessment

Complete the following tasks:
1. Deploy a complete monitoring stack
2. Create a custom dashboard with DORA metrics
3. Configure three meaningful alerts
4. Instrument an application with tracing
5. Write five useful LogQL queries
6. Generate a weekly DORA metrics report

### Bonus Challenge

Implement a complete observability solution for a multi-service application that:
- Tracks deployments across three environments
- Correlates traces across microservices
- Provides SLO/SLA dashboards
- Alerts on DORA metric degradation
- Exports metrics to external systems

---

## Appendix A: Metric Examples Reference

### Infrastructure Metrics
```promql
# Node CPU usage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Node memory usage
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

# Disk usage
100 - (node_filesystem_avail_bytes / node_filesystem_size_bytes * 100)
```

### Kubernetes Metrics
```promql
# Pod restart rate
rate(kube_pod_container_status_restarts_total[1h])

# Deployment replicas available
kube_deployment_status_replicas_available / kube_deployment_spec_replicas

# Node readiness
kube_node_status_condition{condition="Ready",status="true"}
```

### Application Metrics
```promql
# Request rate (RED method)
sum(rate(http_requests_total[5m])) by (service)

# Error rate
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Request duration (p95)
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
```

---

## Appendix B: Dashboard JSON Templates

See the Fawkes repository for complete dashboard templates:
- `dashboards/platform-overview.json`
- `dashboards/dora-metrics.json`
- `dashboards/application-health.json`
- `dashboards/infrastructure.json`

---

## Feedback and Contributions

Have feedback on this module? Found errors or want to suggest improvements?

- Open an issue: https://github.com/paruff/fawkes/issues
- Submit a PR: https://github.com/paruff/fawkes/pulls
- Join discussions: https://github.com/paruff/fawkes/discussions

---

**Module 5 Complete! 🎉**

You now have the knowledge to implement comprehensive observability and measure DORA metrics for your Fawkes platform. Continue to Module 6 for advanced platform operations and troubleshooting.

**Next Module Preview:** Module 6 - Platform Operations & Advanced Troubleshooting