---
title: "Playbook: DORA Metrics Implementation"
description: "Implement automated collection and visualization of DORA metrics to measure and improve software delivery performance"
---

# Playbook: DORA Metrics Implementation

> **Estimated Duration**: 4-8 hours
> **Complexity**: ⭐⭐ Medium
> **Target Audience**: Platform Engineers / DevOps Engineers / Consultants

---

## I. Business Objective

!!! info "Diátaxis: Explanation / Conceptual"
This section defines the "why"—the risk mitigated, compliance goal achieved, and value delivered.

### What We're Solving

Organizations often struggle to objectively measure their software delivery performance. Without data, improvement efforts are based on intuition rather than evidence, making it impossible to identify true bottlenecks, demonstrate progress to stakeholders, or justify investment in engineering improvements.

DORA (DevOps Research and Assessment) research has identified four key metrics that reliably predict software delivery and organizational performance. This playbook implements automated collection and visualization of these metrics within the Fawkes platform.

### Risk Mitigation

| Risk                              | Impact Without Action                       | How This Playbook Helps                 |
| --------------------------------- | ------------------------------------------- | --------------------------------------- |
| Invisible bottlenecks             | Teams waste effort on wrong improvements    | Data reveals actual constraints         |
| Unable to demonstrate improvement | Stakeholders lose confidence in engineering | Dashboards show measurable progress     |
| Slow incident response            | Prolonged outages damage customer trust     | MTTR tracking drives faster recovery    |
| High change failure rate          | Quality issues erode user satisfaction      | Early detection enables proactive fixes |

### Expected Outcomes

- ✅ Automated collection of all four DORA metrics
- ✅ Real-time dashboards showing current performance levels
- ✅ Historical trend analysis for improvement tracking
- ✅ Team-level breakdowns for targeted interventions
- ✅ Alerts for performance degradation

### Business Value

| Metric                               | Before        | After                | Improvement         |
| ------------------------------------ | ------------- | -------------------- | ------------------- |
| Visibility into delivery performance | None/Manual   | Automated, Real-time | ∞ improvement       |
| Time to identify bottlenecks         | Days/Weeks    | Minutes              | 90%+ reduction      |
| Engineering productivity discussions | Opinion-based | Data-driven          | Qualitative shift   |
| Stakeholder confidence               | Low           | High                 | Measurable progress |

---

## II. Technical Prerequisites

!!! abstract "Diátaxis: Reference"
This section lists required Fawkes components, versions, and environment specifications.

### Required Fawkes Components

| Component  | Minimum Version | Required    | Documentation                                                              |
| ---------- | --------------- | ----------- | -------------------------------------------------------------------------- |
| Kubernetes | 1.28+           | ✅          | See [Getting Started](../getting-started.md)                               |
| Prometheus | 2.47+           | ✅          | See [Prometheus Tool](../tools/prometheus.md)                              |
| Grafana    | 10.2+           | ✅          | See [Observability](../observability/dora-metrics-guide.md)                |
| Jenkins    | 2.426+          | ✅          | See [Jenkins Tool](../tools/jenkins.md)                                    |
| ArgoCD     | 2.9+            | ✅          | See [GitOps Module](../dojo/modules/green-belt/module-09-gitops-argocd.md) |
| DevLake    | 0.19+           | ⬜ Optional | See [DevLake ADR](../adr/ADR-016%20devlake-dora-strategy.md)               |

### Environment Requirements

```yaml
# Minimum cluster resources for DORA metrics stack
nodes: 3
cpu_per_node: 4 cores
memory_per_node: 16 GB
storage: 50 GB (for metrics retention)

# Network requirements
ingress_controller: nginx or traefik
external_access: required for dashboards
```

### Access Requirements

- [ ] Cluster admin access to Kubernetes
- [ ] Git repository webhook configuration rights
- [ ] Jenkins admin access for plugin installation
- [ ] ArgoCD admin access for webhook configuration

### Pre-Implementation Checklist

- [ ] CI/CD pipeline (Jenkins) is operational
- [ ] GitOps (ArgoCD) is deployed and managing applications
- [ ] Prometheus and Grafana are running in the cluster
- [ ] At least one application is being deployed via GitOps
- [ ] Stakeholder approval for metrics collection obtained

---

## III. Implementation Steps

!!! tip "Diátaxis: How-to Guide (Core)"
This is the core of the playbook—step-by-step procedures using Fawkes components.

### Step 1: Configure Deployment Event Collection

**Objective**: Capture deployment events from ArgoCD to measure deployment frequency and lead time.

**Estimated Time**: 45 minutes

1. Create the DORA metrics namespace:

```bash
kubectl create namespace dora-metrics
```

2. Deploy the deployment event collector:

```yaml
# dora-deployment-collector.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dora-collector-config
  namespace: dora-metrics
data:
  config.yaml: |
    collectors:
      - type: argocd
        webhook_path: /webhooks/argocd
        metrics:
          - deployment_frequency
          - lead_time_for_changes
      - type: jenkins
        webhook_path: /webhooks/jenkins
        metrics:
          - build_time
          - pipeline_success_rate
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dora-collector
  namespace: dora-metrics
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dora-collector
  template:
    metadata:
      labels:
        app: dora-collector
    spec:
      containers:
        - name: collector
          image: fawkes/dora-collector:v1.0.0
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: config
              mountPath: /etc/dora
      volumes:
        - name: config
          configMap:
            name: dora-collector-config
---
apiVersion: v1
kind: Service
metadata:
  name: dora-collector
  namespace: dora-metrics
spec:
  selector:
    app: dora-collector
  ports:
    - port: 8080
      targetPort: 8080
```

3. Apply the configuration:

```bash
kubectl apply -f dora-deployment-collector.yaml
```

**Verification**: Check that the collector pod is running:

```bash
kubectl get pods -n dora-metrics -l app=dora-collector
```

??? example "Expected Output"
`     NAME                              READY   STATUS    RESTARTS   AGE
    dora-collector-7d9f8b6c4f-x2k9j   1/1     Running   0          30s
    `

### Step 2: Configure ArgoCD Webhooks

**Objective**: Connect ArgoCD deployment events to the DORA collector.

**Estimated Time**: 30 minutes

1. Get the DORA collector service endpoint:

```bash
kubectl get svc dora-collector -n dora-metrics -o jsonpath='{.spec.clusterIP}'
```

2. Configure ArgoCD notifications to send deployment events:

```yaml
# argocd-notifications-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.webhook.dora: |
    url: http://dora-collector.dora-metrics:8080/webhooks/argocd
    headers:
    - name: Content-Type
      value: application/json
  template.deployment-event: |
    webhook:
      dora:
        method: POST
        body: |
          {
            "application": "{{.app.metadata.name}}",
            "status": "{{.app.status.sync.status}}",
            "revision": "{{.app.status.sync.revision}}",
            "timestamp": "{{.app.status.operationState.finishedAt}}"
          }
  trigger.on-sync-succeeded: |
    - when: app.status.sync.status == 'Synced'
      send: [deployment-event]
```

3. Apply the notification configuration:

```bash
kubectl apply -f argocd-notifications-cm.yaml
```

**Verification**: Trigger a deployment and check for webhook delivery.

### Step 3: Configure Jenkins Pipeline Metrics

**Objective**: Capture build and pipeline metrics from Jenkins.

**Estimated Time**: 45 minutes

1. Install the Prometheus metrics plugin in Jenkins:

```groovy
// In Jenkins shared library
// vars/doraMetrics.groovy
def recordDeployment(Map config) {
    def startTime = config.startTime ?: currentBuild.startTimeInMillis
    def endTime = System.currentTimeMillis()
    def leadTime = endTime - startTime

    sh """
        curl -X POST http://dora-collector.dora-metrics:8080/metrics/deployment \\
            -H 'Content-Type: application/json' \\
            -d '{
                "service": "${config.service}",
                "environment": "${config.environment}",
                "commit_sha": "${config.commitSha}",
                "lead_time_ms": ${leadTime},
                "status": "${currentBuild.result ?: 'SUCCESS'}"
            }'
    """
}

def recordFailure(Map config) {
    sh """
        curl -X POST http://dora-collector.dora-metrics:8080/metrics/failure \\
            -H 'Content-Type: application/json' \\
            -d '{
                "service": "${config.service}",
                "environment": "${config.environment}",
                "type": "${config.type}",
                "detected_at": "${new Date().toInstant()}"
            }'
    """
}
```

2. Update pipelines to emit DORA metrics:

```groovy
// Example Jenkinsfile integration
@Library('fawkes-shared-library') _

pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                script {
                    // Deployment logic here
                    sh 'kubectl apply -f manifests/'

                    // Record deployment for DORA metrics
                    doraMetrics.recordDeployment(
                        service: 'my-service',
                        environment: 'production',
                        commitSha: env.GIT_COMMIT
                    )
                }
            }
        }
    }
    post {
        failure {
            script {
                doraMetrics.recordFailure(
                    service: 'my-service',
                    environment: 'production',
                    type: 'deployment_failure'
                )
            }
        }
    }
}
```

**Verification**: Run a pipeline and verify metrics are being collected.

!!! warning "Common Pitfall"
Ensure the Jenkins service account has network access to the dora-collector service. If using network policies, create appropriate rules.

### Step 4: Configure Incident Tracking for MTTR

**Objective**: Track incident detection and resolution for Mean Time to Restore measurement.

**Estimated Time**: 30 minutes

1. Configure Prometheus alerting to record incidents:

```yaml
# prometheus-dora-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: dora-incident-rules
  namespace: monitoring
spec:
  groups:
    - name: dora-incidents
      rules:
        - alert: ServiceDown
          expr: up{job=~".*production.*"} == 0
          for: 1m
          labels:
            severity: critical
            dora_incident: "true"
          annotations:
            summary: "Service {{ $labels.job }} is down"

        - alert: HighErrorRate
          expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
          for: 2m
          labels:
            severity: warning
            dora_incident: "true"
          annotations:
            summary: "High error rate for {{ $labels.service }}"
```

2. Configure Alertmanager to notify DORA collector:

```yaml
# alertmanager-dora-config.yaml
receivers:
  - name: dora-collector
    webhook_configs:
      - url: "http://dora-collector.dora-metrics:8080/webhooks/alertmanager"
        send_resolved: true

route:
  receiver: dora-collector
  routes:
    - match:
        dora_incident: "true"
      receiver: dora-collector
```

**Verification**: Trigger a test alert and verify it's recorded.

### Step 5: Deploy DORA Metrics Dashboard

**Objective**: Create visualization dashboards for all four DORA metrics.

**Estimated Time**: 30 minutes

1. Deploy the DORA Grafana dashboard:

```yaml
# dora-dashboard-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dora-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "true"
data:
  dora-metrics.json: |
    {
      "title": "DORA Metrics Dashboard",
      "panels": [
        {
          "title": "Deployment Frequency",
          "type": "stat",
          "targets": [{
            "expr": "sum(increase(dora_deployments_total[7d]))"
          }]
        },
        {
          "title": "Lead Time for Changes",
          "type": "gauge",
          "targets": [{
            "expr": "avg(dora_lead_time_seconds)"
          }]
        },
        {
          "title": "Change Failure Rate",
          "type": "gauge",
          "targets": [{
            "expr": "sum(dora_deployment_failures_total) / sum(dora_deployments_total) * 100"
          }]
        },
        {
          "title": "Mean Time to Restore",
          "type": "gauge",
          "targets": [{
            "expr": "avg(dora_mttr_seconds)"
          }]
        }
      ]
    }
```

2. Apply the dashboard:

```bash
kubectl apply -f dora-dashboard-configmap.yaml
```

**Verification**: Access Grafana and verify the DORA dashboard is visible.

---

## IV. Validation & Success Metrics

!!! check "Diátaxis: How-to Guide / Reference"
Instructions for verifying the implementation and measuring success.

### Functional Validation

#### Test 1: Deployment Frequency Collection

```bash
# Trigger a test deployment
kubectl set image deployment/test-app app=nginx:latest -n test

# Check metrics endpoint
kubectl exec -n dora-metrics deploy/dora-collector -- \
  curl -s localhost:8080/metrics | grep dora_deployments_total
```

**Expected Result**: Metric should show at least 1 deployment recorded.

#### Test 2: Lead Time Calculation

```bash
# Query Prometheus for lead time
kubectl exec -n monitoring deploy/prometheus -- \
  promtool query instant 'avg(dora_lead_time_seconds)'
```

**Expected Result**: Returns a valid duration in seconds.

#### Test 3: MTTR Recording

```bash
# Simulate an incident resolution
curl -X POST http://dora-collector.dora-metrics:8080/incidents/resolve \
  -d '{"incident_id": "test-123", "resolved_at": "'$(date -Iseconds)'"}'

# Verify MTTR metric
kubectl exec -n monitoring deploy/prometheus -- \
  promtool query instant 'dora_mttr_seconds'
```

**Expected Result**: MTTR metric is populated.

### Success Metrics

| Metric          | How to Measure               | Target Value          | Dashboard Link |
| --------------- | ---------------------------- | --------------------- | -------------- |
| Data Collection | Check `dora_*` metrics exist | All 4 metrics present | /grafana/dora  |
| Dashboard Load  | Grafana dashboard loads      | < 3 seconds           | /grafana/dora  |
| Historical Data | Query 7-day data             | Data available        | /grafana/dora  |

### Verification Checklist

- [ ] All four DORA metrics are being collected
- [ ] Grafana dashboard displays correctly
- [ ] Team-level filtering works
- [ ] Historical trend data is accumulating
- [ ] Alerts trigger correctly for metric degradation

### DORA Metrics Impact

This playbook establishes the foundation for measuring DORA metrics. After 2-4 weeks of data collection, you'll be able to:

| DORA Metric           | Initial Baseline | Typical Elite Target |
| --------------------- | ---------------- | -------------------- |
| Deployment Frequency  | Measured         | Multiple per day     |
| Lead Time for Changes | Measured         | < 1 hour             |
| Change Failure Rate   | Measured         | 0-15%                |
| Time to Restore       | Measured         | < 1 hour             |

---

## V. Client Presentation Talking Points

!!! quote "Diátaxis: Explanation / Conceptual"
Ready-to-use business language for communicating success to client executives.

### Executive Summary

> We've implemented automated measurement of software delivery performance using the industry-standard DORA metrics framework. Your organization now has real-time visibility into deployment frequency, lead time, change failure rate, and recovery time—the four metrics that DORA research proves correlate with business performance. This data-driven foundation enables targeted improvements and demonstrates engineering progress to stakeholders.

### Key Messages for Stakeholders

#### For Technical Leaders (CTO, VP Engineering)

- "We've implemented automated DORA metrics collection that tracks all four key performance indicators across your delivery pipeline"
- "This positions your organization to identify bottlenecks with data rather than intuition—teams can now see exactly where time is spent in the delivery process"
- "Elite performers in the DORA research deploy on-demand, have lead times under one hour, fail less than 15% of the time, and recover in under one hour. You now have the data to benchmark and improve toward these targets."

#### For Business Leaders (CEO, CFO)

- "This investment gives you visibility into engineering productivity for the first time—you'll see exactly how fast features move from idea to customer"
- "DORA research proves that organizations with elite software delivery performance are 2x more likely to exceed their business goals. These metrics are your leading indicator."
- "Faster, more reliable software delivery translates directly to faster time-to-market and reduced risk of outages that impact customers and revenue"

### Demonstration Script

1. **Open**: "Let me show you the DORA Metrics Dashboard in Grafana. This gives us real-time visibility into four key performance indicators..."

2. **Show Deployment Frequency**: "This shows how often we're deploying to production. Elite performers deploy on-demand, multiple times per day. Our current rate is [X]..."

3. **Show Lead Time**: "Lead time measures the time from when a developer commits code to when it's running in production. Elite performers achieve this in under one hour. We're currently at [X]..."

4. **Show Change Failure Rate**: "This shows what percentage of our deployments cause problems. Elite teams are below 15%. We're at [X%]..."

5. **Show MTTR**: "When something does go wrong, how quickly do we recover? Elite teams restore service in under an hour. Our current mean time to restore is [X]..."

6. **Connect to value**: "By tracking these metrics, we can identify exactly where to focus improvement efforts and demonstrate progress to the business."

### Common Executive Questions & Answers

??? question "How does this compare to industry benchmarks?"
According to the 2023 State of DevOps Report from DORA, elite performers deploy on demand (often multiple times per day), have lead times under one hour, a change failure rate of 0-15%, and recover from failures in under one hour. Your current metrics place you in the [Elite/High/Medium/Low] performance category, which aligns with approximately [X%] of organizations studied.

??? question "What's the ROI on this implementation?"
The primary ROI is in enabling data-driven improvement. Organizations that improve from Medium to Elite performance see 2x improvement in organizational performance goals according to DORA research. Additionally, by identifying bottlenecks, we typically see 20-30% improvement in developer productivity within the first quarter.

??? question "What's the risk if we don't maintain this?"
Without continued attention, metrics data quality may degrade as systems change. We recommend quarterly reviews of data collection configuration as part of normal platform maintenance. The cost of maintenance is minimal compared to the value of continued visibility.

??? question "What's the next step after implementing metrics?"
With baseline metrics established, the next step is to identify your primary bottleneck. Typically, this is either deployment frequency (solved by automation) or lead time (solved by pipeline optimization). We can run a focused improvement sprint targeting your biggest constraint.

### Follow-Up Actions

| Action                                   | Owner            | Timeline |
| ---------------------------------------- | ---------------- | -------- |
| Review baseline metrics after 2 weeks    | Engineering Lead | +2 weeks |
| Identify primary improvement opportunity | Platform Team    | +3 weeks |
| Begin targeted improvement playbook      | Consultant/Team  | +4 weeks |
| Schedule stakeholder review              | Consultant       | +6 weeks |

---

## Appendix

### Related Resources

- [Module 2: DORA Metrics](../dojo/modules/white-belt/module-02-dora-metrics.md) - Conceptual background on the four key metrics
- [Prometheus Tool Reference](../tools/prometheus.md) - Metrics collection details
- [DORA Metrics Guide](../observability/dora-metrics-guide.md) - Detailed DORA implementation guide

### Troubleshooting

| Issue                 | Possible Cause          | Resolution                                    |
| --------------------- | ----------------------- | --------------------------------------------- |
| Metrics not appearing | Webhook not configured  | Verify ArgoCD/Jenkins webhook settings        |
| Dashboard empty       | Prometheus not scraping | Check Prometheus targets and scrape config    |
| Incorrect lead time   | Clock skew              | Ensure NTP sync across nodes                  |
| Missing deployments   | Network policy blocking | Add network policy for dora-metrics namespace |

### Change Log

| Date       | Version | Changes         |
| ---------- | ------- | --------------- |
| 2024-01-15 | 1.0     | Initial release |
