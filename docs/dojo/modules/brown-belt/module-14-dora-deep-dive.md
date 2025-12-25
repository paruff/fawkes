# Fawkes Dojo Module 14: DORA Metrics Deep Dive

## 🎯 Module Overview

**Belt Level**: 🟤 Brown Belt - Observability & SRE
**Module**: 2 of 4 (Brown Belt)
**Duration**: 60 minutes
**Difficulty**: Advanced
**Prerequisites**:

- Module 2: DORA Metrics (White Belt) review recommended
- Module 13: Observability complete
- Understanding of Prometheus and Grafana
- Familiarity with GitOps workflows

---

## 📚 Learning Objectives

By the end of this module, you will:

1. ✅ Calculate and track all four DORA metrics automatically
2. ✅ Build comprehensive DORA dashboards in Grafana
3. ✅ Implement metric collection across the entire delivery pipeline
4. ✅ Analyze trends and identify improvement opportunities
5. ✅ Benchmark against industry standards
6. ✅ Use metrics to drive platform improvements
7. ✅ Present DORA metrics to leadership effectively

**DORA Capabilities Addressed**:

- ✓ All 4 Key Metrics (Deployment Frequency, Lead Time, MTTR, Change Failure Rate)
- ✓ Monitoring and Observability
- ✓ Data-Driven Decision Making

---

## 📖 Part 1: DORA Metrics Review & Advanced Concepts

### The Four Key Metrics (Refresher)

| Metric                    | What It Measures                  | Elite Performance |
| ------------------------- | --------------------------------- | ----------------- |
| **Deployment Frequency**  | How often you deploy              | Multiple per day  |
| **Lead Time for Changes** | Commit → Production time          | < 1 hour          |
| **Change Failure Rate**   | % of deployments causing failures | 0-15%             |
| **Mean Time to Restore**  | Time to recover from failure      | < 1 hour          |

### Why These Four?

Research shows these metrics are:

- **Predictive** of organizational performance
- **Balanced** between speed (DF, LT) and stability (CFR, MTTR)
- **Actionable** - teams can directly improve them
- **Universal** - apply across industries and tech stacks

### Advanced DORA Concepts

**1. Metric Correlation**

Metrics don't exist in isolation:

```
High Deployment Frequency
    ↓
Smaller batch sizes
    ↓
Lower Change Failure Rate
    ↓
Faster Lead Time (less code per deploy)
    ↓
Better MTTR (easier to identify issues)
```

**2. Team-Level vs Organization-Level**

- **Team-level**: Track individual team performance
- **Organization-level**: Aggregate across all teams
- **Service-level**: Track per microservice/application

**3. Metric Distributions Matter**

Don't just track averages:

- **P50 (Median)**: Typical case
- **P95**: Worst 5% of cases
- **P99**: Outliers that hurt user experience

**Example**:

```
Lead Time:
- Average: 2 hours
- P50: 30 minutes ✅ (Most deploys are fast)
- P95: 8 hours ❌ (5% take too long - investigate why)
```

---

## 🔢 Part 2: Calculating DORA Metrics

### Metric 1: Deployment Frequency

**Definition**: Number of deployments per time period

**Calculation**:

```
Deployment Frequency = Total Deployments / Time Period

Example:
- 150 deployments in 30 days
- DF = 150 / 30 = 5 deployments per day ✅ Elite
```

**Data Sources**:

- ArgoCD sync events
- GitOps repository commits
- CI/CD pipeline completions
- Kubernetes deployment events

**Prometheus Query**:

```promql
# Count deployments per day
sum(increase(argocd_app_sync_total{phase="Succeeded"}[1d]))

# Deployment frequency by application
sum(rate(argocd_app_sync_total{phase="Succeeded"}[7d])) by (name) * 86400
```

### Metric 2: Lead Time for Changes

**Definition**: Time from code commit to running in production

**Calculation**:

```
Lead Time = Production Deployment Time - Commit Time

Example:
- Commit: 2025-10-10 14:00:00
- Production: 2025-10-10 14:25:00
- Lead Time: 25 minutes ✅ Elite
```

**Components**:

```
Total Lead Time =
    Code Review Time +
    CI Build Time +
    Test Execution Time +
    Security Scanning Time +
    Artifact Creation Time +
    Deployment Time +
    Validation Time
```

**Data Collection**:

```python
# Webhook receiver for Git commits
@app.route('/webhook/commit', methods=['POST'])
def record_commit():
    commit_sha = request.json['after']
    commit_time = request.json['head_commit']['timestamp']

    # Store in database
    db.store_commit(commit_sha, commit_time)

    return '', 200

# Webhook receiver for deployments
@app.route('/webhook/deploy', methods=['POST'])
def record_deployment():
    commit_sha = request.json['revision']
    deploy_time = datetime.utcnow()

    # Calculate lead time
    commit_time = db.get_commit_time(commit_sha)
    lead_time = (deploy_time - commit_time).total_seconds()

    # Send to Prometheus
    lead_time_histogram.labels(app=app_name).observe(lead_time)

    return '', 200
```

**Prometheus Query**:

```promql
# Average lead time (seconds)
avg(deployment_lead_time_seconds)

# P95 lead time
histogram_quantile(0.95, sum(rate(deployment_lead_time_seconds_bucket[7d])) by (le))

# Lead time by team
avg(deployment_lead_time_seconds) by (team)
```

### Metric 3: Change Failure Rate

**Definition**: Percentage of deployments that result in failure

**Calculation**:

```
CFR = (Failed Deployments / Total Deployments) × 100

Example:
- Total deployments: 100
- Failed deployments: 8
- CFR = (8 / 100) × 100 = 8% ✅ Elite
```

**Defining "Failure"**:

- Deployment rollback within 24 hours
- Incident created within 24 hours of deployment
- Deployment marked as failed in ArgoCD
- Health checks fail post-deployment

**Data Collection**:

```python
def calculate_change_failure_rate(timeframe_hours=24):
    """
    Calculate CFR by correlating deployments with incidents
    """
    deployments = get_deployments(since=timeframe_hours)
    failures = 0

    for deployment in deployments:
        deploy_time = deployment['timestamp']

        # Check for incidents within 24h
        incidents = get_incidents(
            since=deploy_time,
            until=deploy_time + timedelta(hours=24)
        )

        # Check for rollbacks
        rollback = get_rollback(
            deployment_id=deployment['id'],
            since=deploy_time,
            until=deploy_time + timedelta(hours=24)
        )

        if incidents or rollback:
            failures += 1

    cfr = (failures / len(deployments)) * 100 if deployments else 0
    return cfr
```

**Prometheus Query**:

```promql
# Change Failure Rate (%)
sum(deployment_result{status="failed"}) / sum(deployment_result) * 100

# CFR by application
(sum(deployment_result{status="failed"}) by (app) / sum(deployment_result) by (app)) * 100

# CFR trend over time
sum(rate(deployment_result{status="failed"}[7d])) / sum(rate(deployment_result[7d])) * 100
```

### Metric 4: Mean Time to Restore (MTTR)

**Definition**: Average time to recover from a production failure

**Calculation**:

```
MTTR = Total Downtime / Number of Incidents

Example:
- 5 incidents in a month
- Total downtime: 125 minutes
- MTTR = 125 / 5 = 25 minutes ✅ Elite
```

**Data Collection**:

```python
# Incident lifecycle tracking
class Incident:
    def __init__(self, id, severity):
        self.id = id
        self.severity = severity
        self.detected_at = datetime.utcnow()
        self.mitigated_at = None
        self.resolved_at = None

    def mitigate(self):
        """Service restored, but root cause not fixed"""
        self.mitigated_at = datetime.utcnow()
        ttm = (self.mitigated_at - self.detected_at).total_seconds()

        # Time to Mitigate (what we really care about for MTTR)
        mttr_histogram.labels(severity=self.severity).observe(ttm)

    def resolve(self):
        """Root cause fixed, incident closed"""
        self.resolved_at = datetime.utcnow()
        ttr = (self.resolved_at - self.detected_at).total_seconds()

        # Time to Resolve (total incident duration)
        incident_duration_histogram.labels(severity=self.severity).observe(ttr)
```

**Prometheus Query**:

```promql
# Average MTTR (seconds)
avg(incident_duration_seconds)

# MTTR by severity
avg(incident_duration_seconds) by (severity)

# P95 MTTR (captures worst cases)
histogram_quantile(0.95, sum(rate(incident_duration_seconds_bucket[30d])) by (le))

# MTTR trend
avg_over_time(incident_duration_seconds[7d])
```

---

## 📊 Part 3: Building the Ultimate DORA Dashboard

### Dashboard Architecture

```
┌─────────────────────────────────────────────────────────┐
│              DORA Metrics Dashboard                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Executive Summary (Current vs Target)             │ │
│  │  DF: 5/day (Elite) | LT: 45m (Elite)              │ │
│  │  CFR: 8% (Elite)   | MTTR: 25m (Elite)            │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │
│  │ Deployment   │ │ Lead Time    │ │ Change       │   │
│  │ Frequency    │ │ Trend        │ │ Failure Rate │   │
│  │ (Time Series)│ │ (Histogram)  │ │ (Gauge)      │   │
│  └──────────────┘ └──────────────┘ └──────────────┘   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  MTTR Analysis (by Severity & Trend)             │  │
│  │  SEV1: 15m | SEV2: 1.5h | SEV3: 4h              │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Team Comparison (Leaderboard)                    │  │
│  │  Team A: Elite | Team B: High | Team C: Medium  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Improvement Trends (30-day vs 90-day)           │  │
│  │  DF: ↑15% | LT: ↓20% | CFR: ↓10% | MTTR: ↓25% │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Grafana Dashboard JSON

```json
{
  "dashboard": {
    "title": "DORA Metrics - Platform Performance",
    "tags": ["dora", "metrics", "platform"],
    "timezone": "utc",
    "panels": [
      {
        "id": 1,
        "title": "Deployment Frequency (per day)",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(argocd_app_sync_total{phase='Succeeded'}[7d])) * 86400",
            "legendFormat": "Deployments/Day"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "mode": "absolute",
              "steps": [
                { "value": 0, "color": "red" },
                { "value": 0.1, "color": "yellow" },
                { "value": 1, "color": "green" }
              ]
            },
            "mappings": [],
            "unit": "short"
          }
        },
        "gridPos": { "h": 8, "w": 6, "x": 0, "y": 0 }
      },
      {
        "id": 2,
        "title": "Lead Time for Changes (P95)",
        "type": "stat",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(deployment_lead_time_seconds_bucket[7d])) by (le)) / 3600",
            "legendFormat": "P95 Hours"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 1, "color": "yellow" },
                { "value": 24, "color": "red" }
              ]
            },
            "unit": "h"
          }
        },
        "gridPos": { "h": 8, "w": 6, "x": 6, "y": 0 }
      },
      {
        "id": 3,
        "title": "Change Failure Rate",
        "type": "gauge",
        "targets": [
          {
            "expr": "sum(rate(deployment_result{status='failed'}[7d])) / sum(rate(deployment_result[7d])) * 100"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 15, "color": "yellow" },
                { "value": 30, "color": "red" }
              ]
            },
            "max": 100,
            "unit": "percent"
          }
        },
        "gridPos": { "h": 8, "w": 6, "x": 12, "y": 0 }
      },
      {
        "id": 4,
        "title": "Mean Time to Restore",
        "type": "stat",
        "targets": [
          {
            "expr": "avg(incident_duration_seconds) / 60",
            "legendFormat": "Avg Minutes"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 60, "color": "yellow" },
                { "value": 1440, "color": "red" }
              ]
            },
            "unit": "m"
          }
        },
        "gridPos": { "h": 8, "w": 6, "x": 18, "y": 0 }
      },
      {
        "id": 5,
        "title": "Deployment Frequency Trend",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(argocd_app_sync_total{phase='Succeeded'}[1d])) by (name) * 86400",
            "legendFormat": "{{name}}"
          }
        ],
        "gridPos": { "h": 8, "w": 12, "x": 0, "y": 8 }
      },
      {
        "id": 6,
        "title": "Lead Time Distribution",
        "type": "heatmap",
        "targets": [
          {
            "expr": "sum(increase(deployment_lead_time_seconds_bucket[1h])) by (le)",
            "format": "heatmap",
            "legendFormat": "{{le}}"
          }
        ],
        "gridPos": { "h": 8, "w": 12, "x": 12, "y": 8 }
      }
    ]
  }
}
```

---

## 🎯 Part 4: Hands-On Lab - Complete DORA Implementation

### Objective

Implement end-to-end DORA metrics collection and visualization for Fawkes platform.

### Step 1: Deploy DORA Metrics Collector

Create `dora-collector.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dora-collector
  namespace: dojo-metrics
spec:
  replicas: 2
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
          image: fawkes/dora-collector:v1.0
          ports:
            - containerPort: 8080
              name: http
            - containerPort: 9090
              name: metrics
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: dora-db-credentials
                  key: url
            - name: PROMETHEUS_URL
              value: "http://prometheus:9090"
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: dora-collector
  namespace: dojo-metrics
spec:
  selector:
    app: dora-collector
  ports:
    - name: http
      port: 80
      targetPort: 8080
    - name: metrics
      port: 9090
      targetPort: 9090
---
apiVersion: monitoring.coreos.io/v1
kind: ServiceMonitor
metadata:
  name: dora-collector
  namespace: dojo-metrics
spec:
  selector:
    matchLabels:
      app: dora-collector
  endpoints:
    - port: metrics
      interval: 30s
```

### Step 2: Configure Webhooks

**ArgoCD Webhook** (for deployments):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.webhook.dora: |
    url: http://dora-collector.dojo-metrics/webhook/deploy
    headers:
    - name: Content-Type
      value: application/json

  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [dora-deploy-succeeded]
    - when: app.status.operationState.phase in ['Failed']
      send: [dora-deploy-failed]

  template.dora-deploy-succeeded: |
    webhook:
      dora:
        method: POST
        body: |
          {
            "event": "deployment",
            "status": "success",
            "app": "{{.app.metadata.name}}",
            "revision": "{{.app.status.sync.revision}}",
            "timestamp": "{{.app.status.operationState.finishedAt}}"
          }

  template.dora-deploy-failed: |
    webhook:
      dora:
        method: POST
        body: |
          {
            "event": "deployment",
            "status": "failed",
            "app": "{{.app.metadata.name}}",
            "revision": "{{.app.status.sync.revision}}",
            "timestamp": "{{.app.status.operationState.finishedAt}}"
          }
```

**Git Webhook** (for commits):

```bash
# Add webhook to GitHub repository
curl -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Content-Type: application/json" \
  https://api.github.com/repos/myorg/myapp/hooks \
  -d '{
    "name": "web",
    "active": true,
    "events": ["push"],
    "config": {
      "url": "https://dora-collector.fawkes.io/webhook/commit",
      "content_type": "json"
    }
  }'
```

### Step 3: Create Grafana Dashboard

```bash
# Import dashboard via API
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  http://grafana:3000/api/dashboards/db \
  -d @dora-dashboard.json

# Or import via UI:
# Grafana → Dashboards → Import → Upload dora-dashboard.json
```

### Step 4: Validate Data Collection

```bash
# Check if metrics are being collected
kubectl port-forward -n dojo-metrics svc/dora-collector 9090:9090

# Query Prometheus
curl "http://localhost:9090/metrics" | grep deployment

# Expected output:
# deployment_frequency_total{app="myapp"} 150
# deployment_lead_time_seconds_sum{app="myapp"} 450000
# deployment_lead_time_seconds_count{app="myapp"} 150
# deployment_result{app="myapp",status="success"} 142
# deployment_result{app="myapp",status="failed"} 8
```

### Step 5: Analyze Your Metrics

Access Grafana dashboard and analyze:

1. **Deployment Frequency**: Are you deploying daily? Multiple times per day?
2. **Lead Time**: What's your P95? Where are the bottlenecks?
3. **CFR**: Which deployments are failing? Common patterns?
4. **MTTR**: How quickly do you recover? Can you automate more?

---

## 📈 Part 5: Advanced Analysis Techniques

### Trend Analysis

**Week-over-week comparison**:

```promql
# Current week deployment frequency
sum(rate(argocd_app_sync_total{phase="Succeeded"}[7d])) * 86400

# Previous week
sum(rate(argocd_app_sync_total{phase="Succeeded"}[7d] offset 7d)) * 86400

# % change
(
  sum(rate(argocd_app_sync_total{phase="Succeeded"}[7d]))
  -
  sum(rate(argocd_app_sync_total{phase="Succeeded"}[7d] offset 7d))
)
/
sum(rate(argocd_app_sync_total{phase="Succeeded"}[7d] offset 7d))
* 100
```

### Correlation Analysis

**Does higher deployment frequency correlate with lower CFR?**

```python
import pandas as pd
from scipy.stats import pearsonr

# Fetch data
df = pd.DataFrame({
    'team': teams,
    'deployment_freq': [get_deployment_freq(t) for t in teams],
    'cfr': [get_cfr(t) for t in teams]
})

# Calculate correlation
correlation, p_value = pearsonr(df['deployment_freq'], df['cfr'])

print(f"Correlation: {correlation:.2f}")
print(f"P-value: {p_value:.4f}")

# Expected: Negative correlation (higher DF → lower CFR)
```

### Identifying Bottlenecks

**Lead time breakdown**:

```promql
# Time in each stage
sum(ci_stage_duration_seconds{stage="build"}) by (app)
sum(ci_stage_duration_seconds{stage="test"}) by (app)
sum(ci_stage_duration_seconds{stage="scan"}) by (app)
sum(ci_stage_duration_seconds{stage="deploy"}) by (app)
```

Create waterfall chart to visualize:

```
Commit → Build (3m) → Test (5m) → Scan (2m) → Deploy (1m) = 11m total
         ████████    ████████████  ████        ██

Bottleneck: Testing takes 45% of lead time
Action: Parallelize tests or optimize slow tests
```

---

## 💪 Part 6: Driving Improvements with Data

### Improvement Framework

**1. Measure Current State**

```
Current Performance (Last 30 days):
- DF: 3 per day (High)
- LT: 2 hours (High)
- CFR: 12% (Elite)
- MTTR: 45 minutes (Elite)

Overall: High Performer
```

**2. Set Targets**

```
3-Month Goals:
- DF: 5 per day (Elite) - ↑67%
- LT: 1 hour (Elite) - ↓50%
- CFR: <10% (Elite) - ↓17%
- MTTR: <30 min (Elite) - ↓33%
```

**3. Identify Bottlenecks**

```
Lead Time Breakdown:
- Code Review: 45 min (38%)
- CI Build: 15 min (13%)
- Testing: 35 min (29%)
- Deployment: 25 min (21%)

Biggest opportunity: Code Review (38% of lead time)
```

**4. Implement Changes**

```
Actions:
1. Reduce PR size (enforce <300 lines)
2. Pair programming for complex changes (faster review)
3. Async code review tools (remove scheduling overhead)
4. Auto-approve trivial changes (docs, formatting)

Expected Impact: Reduce code review time by 50% (22min savings)
New Lead Time: 1h 5min → Target not quite met, but significant progress
```

**5. Measure Impact**

```
After 30 days:
- DF: 4.5 per day ✅ (On track)
- LT: 1h 15min ⚠️ (Close to target)
- CFR: 9% ✅ (Target met!)
- MTTR: 28 min ✅ (Target exceeded!)

Continue iteration...
```

---

## 🎓 Part 7: Knowledge Check

### Quiz Questions

1. **What does P95 lead time represent?**

   - [ ] Average lead time
   - [ ] Fastest lead time
   - [x] 95% of deployments complete within this time
   - [ ] Slowest lead time

2. **How do you calculate Change Failure Rate?**

   - [ ] Failed deployments × 100
   - [x] (Failed deployments / Total deployments) × 100
   - [ ] Total deployments / Failed deployments
   - [ ] Failed deployments / Successful deployments

3. **What's the Elite benchmark for Deployment Frequency?**

   - [ ] Once per week
   - [ ] Once per day
   - [x] Multiple times per day
   - [ ] Continuous deployment

4. **What should MTTR measure?**

   - [ ] Time to write code
   - [ ] Time to test
   - [x] Time to restore service after incident
   - [ ] Time to deploy

5. **Why track team-level DORA metrics separately?**

   - [ ] To rank teams
   - [x] To identify improvement opportunities specific to each team
   - [ ] To punish low performers
   - [ ] It's not necessary

6. **What does high DF + low CFR indicate?**

   - [ ] Luck
   - [x] Mature CI/CD with good quality gates
   - [ ] Metrics are broken
   - [ ] Too much testing

7. **How often should you review DORA metrics?**

   - [ ] Annually
   - [ ] When problems occur
   - [x] Weekly or monthly for trends
   - [ ] Once after implementation

8. **What's a good first step to improve lead time?**
   - [ ] Skip testing
   - [ ] Deploy less frequently
   - [x] Identify and optimize the slowest stage
   - [ ] Hire more people

**Answers**: 1-C, 2-B, 3-C, 4-C, 5-B, 6-B, 7-C, 8-C

---

## 🎯 Part 8: Module Summary & Next Steps

### What You Learned

✅ **Advanced Calculation**: All 4 metrics with distributions
✅ **Data Collection**: Webhooks, Prometheus, automation
✅ **Dashboards**: Comprehensive Grafana visualizations
✅ **Analysis**: Trends, correlations, bottlenecks
✅ **Improvement**: Data-driven optimization framework
✅ **Presentation**: Communicate metrics to leadership

### DORA Capabilities Achieved

- ✅ **All 4 Key Metrics**: Automated collection and tracking
- ✅ **Monitoring**: Real-time visibility into delivery performance
- ✅ **Data-Driven**: Metrics inform platform improvements

### Key Takeaways

1. **Metrics must be actionable** - If you can't improve it, don't measure it
2. **Track distributions, not just averages** - P95/P99 reveal user experience
3. **Compare teams carefully** - Context matters (legacy vs greenfield)
4. **Automate collection** - Manual tracking doesn't scale
5. **Review regularly** - Weekly trends reveal improvement opportunities

### Real-World Impact

"After implementing comprehensive DORA tracking:

- **Identified bottleneck**: Code review was 40% of lead time
- **Action**: Reduced PR size, added auto-approval for trivial changes
- **Result**: Lead time decreased 35% in 60 days
- **Visibility**: Leadership now tracks metrics quarterly
- **Culture**: Teams compete (healthily) to improve metrics

Metrics transformed from vanity to value."

- _Engineering Director, Tech Company_

---

## 📚 Additional Resources

### Tools

- [Four Keys](https://github.com/dora-team/fourkeys) - DORA metrics collection
- [Sleuth](https://www.sleuth.io/) - DORA tracking SaaS
- [LinearB](https://linearb.io/) - Engineering intelligence

### Reading

- [DORA State of DevOps Reports](https://dora.dev/research/)
- [Accelerate](https://itrevolution.com/accelerate-book/) - The research behind DORA
- [DORA Metrics Guide](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance)

---

## 🏅 Module Completion

### Assessment Checklist

- [ ] **Conceptual Understanding**

  - [ ] Calculate all 4 metrics correctly
  - [ ] Understand P50/P95/P99 distributions
  - [ ] Explain metric correlations

- [ ] **Practical Skills**
  - [ ] Deploy DORA collector
  - [ ] Configure webhooks
  - [ ] Build Grafana dashboard
  - [ ] Analyze trends
  -
