---
title: View DORA Metrics in DevLake
description: Access and interpret DORA metrics dashboards for your team
---

# View DORA Metrics in DevLake

## Goal

Access and analyze DORA (DevOps Research and Assessment) metrics for your team to measure deployment frequency, lead time for changes, change failure rate, and mean time to recovery.

## Prerequisites

Before you begin, ensure you have:

- [ ] DevLake deployed and configured (see [DORA Metrics Implementation](../../playbooks/dora-metrics-implementation.md))
- [ ] Your project connected to DevLake data sources (Git, Jenkins, ArgoCD)
- [ ] Access to Grafana UI (`https://grafana.127.0.0.1.nip.io`)
- [ ] At least 7 days of deployment data for meaningful metrics

## Steps

### 1. Access Grafana Dashboards

#### Open Grafana

Navigate to Grafana:

```bash
# Get Grafana URL
echo "https://grafana.127.0.0.1.nip.io"

# Get admin password (if needed)
kubectl -n monitoring get secret grafana-admin \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

Log in with your credentials.

### 2. Locate DORA Metrics Dashboard

#### Navigate to DORA Dashboard

1. In Grafana, click **Dashboards** (four squares icon) in the left sidebar
2. Search for **"DORA Metrics"** or **"DevLake"**
3. Click on the **"DORA Metrics Overview"** dashboard

Common DORA dashboards:

- **DORA Metrics Overview**: All four metrics in one view
- **Deployment Frequency**: Detailed deployment trends
- **Lead Time Analysis**: Commit to deployment timeline
- **Change Failure Rate**: Failed vs. successful deployments
- **MTTR Dashboard**: Incident response times

### 3. Select Your Team/Project

#### Filter by Team

Most DORA dashboards include filters at the top:

1. **Team/Project Dropdown**: Select your team or project
2. **Time Range**: Choose the period to analyze (default: Last 90 days)
3. **Environment**: Filter by dev/staging/production

Example filters:

```text
Team: Payment Squad
Project: payment-service
Environment: production
Time Range: Last 90 days
```

### 4. Analyze the Four DORA Metrics

#### Metric 1: Deployment Frequency

**What it measures**: How often your team deploys code to production.

**Dashboard panels**:

- **Deployments per Day/Week**: Bar chart showing deployment count over time
- **Deployment Trend**: Line graph showing frequency trend
- **Team Comparison**: Compare your team's frequency to organization average

**Interpretation**:

| Performance Level | Deployment Frequency |
|-------------------|---------------------|
| Elite | Multiple deploys per day |
| High | Between once per day and once per week |
| Medium | Between once per week and once per month |
| Low | Fewer than once per month |

**Example view**:

```text
┌─────────────────────────────────────────────────────┐
│ Deployment Frequency                                │
│                                                     │
│ This Week: 23 deployments (3.3 per day)           │
│ Last Week: 19 deployments (2.7 per day)           │
│                                                     │
│ Performance Level: Elite ⭐                        │
│                                                     │
│ [Bar Chart: Deployments by Day]                   │
│  Mon  Tue  Wed  Thu  Fri  Sat  Sun                │
│   ▓▓   ▓▓▓  ▓▓▓  ▓▓   ▓▓   ▓    ▓                │
│    4    5    5    4    4    1    0                │
└─────────────────────────────────────────────────────┘
```

#### Metric 2: Lead Time for Changes

**What it measures**: Time from code commit to production deployment.

**Dashboard panels**:

- **Average Lead Time**: Single stat showing mean lead time
- **Lead Time Distribution**: Histogram showing lead time spread
- **Lead Time Trend**: Line graph showing trend over time
- **Lead Time by Stage**: Breakdown by commit→build→test→deploy

**Interpretation**:

| Performance Level | Lead Time for Changes |
|-------------------|----------------------|
| Elite | Less than one hour |
| High | Between one day and one week |
| Medium | Between one week and one month |
| Low | More than one month |

**Example view**:

```text
┌─────────────────────────────────────────────────────┐
│ Lead Time for Changes                               │
│                                                     │
│ Average: 45 minutes                                │
│ P50 (Median): 32 minutes                           │
│ P95: 2 hours 15 minutes                            │
│                                                     │
│ Performance Level: Elite ⭐                        │
│                                                     │
│ Breakdown by Stage:                                │
│  Commit → Build:    8 min  ▓▓                     │
│  Build → Test:     12 min  ▓▓▓                    │
│  Test → Deploy:    15 min  ▓▓▓▓                   │
│  Deploy → Verify:  10 min  ▓▓▓                    │
└─────────────────────────────────────────────────────┘
```

#### Metric 3: Change Failure Rate

**What it measures**: Percentage of deployments that result in failure requiring remediation.

**Dashboard panels**:

- **Change Failure Rate %**: Single stat showing failure percentage
- **Failed vs. Successful Deployments**: Pie chart
- **Failure Trend**: Line graph showing failure rate over time
- **Top Failure Causes**: Table of most common failure reasons

**Interpretation**:

| Performance Level | Change Failure Rate |
|-------------------|-------------------|
| Elite | 0-15% |
| High | 16-30% |
| Medium | 31-45% |
| Low | More than 45% |

**Example view**:

```text
┌─────────────────────────────────────────────────────┐
│ Change Failure Rate                                 │
│                                                     │
│ Last 30 days: 8.5%                                 │
│                                                     │
│ Performance Level: Elite ⭐                        │
│                                                     │
│ Failed:     7 deployments  ▓                       │
│ Successful: 75 deployments ▓▓▓▓▓▓▓▓▓▓▓            │
│                                                     │
│ Top Failure Causes:                                │
│  1. Database migration error     (3)              │
│  2. Configuration missing        (2)              │
│  3. Image pull error             (2)              │
└─────────────────────────────────────────────────────┘
```

#### Metric 4: Mean Time to Recovery (MTTR)

**What it measures**: Time to restore service after a production incident.

**Dashboard panels**:

- **Average MTTR**: Single stat showing mean recovery time
- **MTTR Distribution**: Histogram showing recovery time spread
- **MTTR Trend**: Line graph showing trend over time
- **Recent Incidents**: Table of recent incidents with recovery times

**Interpretation**:

| Performance Level | Mean Time to Recovery |
|-------------------|---------------------|
| Elite | Less than one hour |
| High | Less than one day |
| Medium | Between one day and one week |
| Low | More than one week |

**Example view**:

```text
┌─────────────────────────────────────────────────────┐
│ Mean Time to Recovery (MTTR)                        │
│                                                     │
│ Average: 28 minutes                                │
│ P50 (Median): 18 minutes                           │
│ P95: 1 hour 45 minutes                             │
│                                                     │
│ Performance Level: Elite ⭐                        │
│                                                     │
│ Recent Incidents:                                  │
│  Dec 5: API timeout         MTTR: 15 min          │
│  Dec 3: Database connection MTTR: 42 min          │
│  Dec 1: Memory leak         MTTR: 1h 30min        │
└─────────────────────────────────────────────────────┘
```

### 5. Drill Down into Specific Metrics

#### View Deployment Details

Click on any data point in the charts to drill down:

1. Click on a deployment bar in the Deployment Frequency chart
2. View deployment details:
   - Commit SHA and message
   - Author and timestamp
   - Build duration
   - Deploy duration
   - Success/failure status

#### Trace Lead Time Breakdown

Click on a lead time data point to see:

- Commit timestamp
- Build start/end time
- Test execution time
- Deployment start/end time
- Link to ArgoCD application
- Link to Jenkins pipeline

#### Investigate Failed Deployments

Click on a failed deployment to view:

- Error message and logs
- Failed stage (build/test/deploy)
- Rollback timestamp
- Time to detection
- Time to resolution
- Link to incident ticket

### 6. Compare Team Performance

#### View Team Comparison Dashboard

Navigate to the **Team Comparison** dashboard:

1. Click **Dashboards** → **DORA Team Comparison**
2. View metrics across all teams:
   - Deployment frequency by team
   - Lead time comparison
   - Failure rate comparison
   - MTTR comparison

#### Identify Best Practices

Look for high-performing teams and investigate:

- What tools do they use?
- What practices enable fast deployment?
- How do they maintain low failure rates?
- What's their secret to fast recovery?

### 7. Export and Share Metrics

#### Share Dashboard

1. Click the **Share** icon (arrow) at the top of the dashboard
2. Choose sharing option:
   - **Link**: Copy URL to share with team
   - **Snapshot**: Create a public snapshot
   - **Export**: Download as JSON
   - **Email**: Schedule email report

#### Generate Report

Create a PDF report:

1. Set the desired time range and filters
2. Click **Share** → **Render PDF**
3. Download and share with stakeholders

#### Schedule Weekly Report

Configure automated reports:

1. Click **Dashboards** → **Dashboard Settings**
2. Select **Reporting** tab
3. Click **Schedule Report**
4. Configure:
   - Frequency: Weekly (Monday 9 AM)
   - Recipients: team@example.com
   - Format: PDF
   - Time range: Last 7 days

## Verification

### 1. Verify Data Accuracy

Check that metrics reflect recent deployments:

```bash
# List recent deployments from ArgoCD
kubectl get applications -n argocd \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.sync.revision}{"\t"}{.status.operationState.finishedAt}{"\n"}{end}'

# Compare with dashboard deployment count
# Numbers should match
```

### 2. Verify Lead Time Calculation

Manually verify a recent deployment:

```bash
# Get commit timestamp
git log -1 --format="%ai" <commit-sha>

# Get deployment timestamp from ArgoCD
argocd app get my-service-prod | grep "Sync Status"

# Calculate lead time manually
# Should match DevLake dashboard
```

### 3. Check Data Freshness

Ensure metrics are up to date:

1. Check **Last Update** timestamp in dashboard header
2. Should be within the last 5-15 minutes
3. If stale, check DevLake data collection:

```bash
# Check DevLake pods
kubectl get pods -n devlake

# Check data collection logs
kubectl logs -n devlake -l app=devlake-collector --tail=50
```

## Understanding Performance Levels

### DORA Performance Tiers

Based on the State of DevOps Report, teams are categorized as:

| Tier | Deployment Frequency | Lead Time | Change Failure Rate | MTTR |
|------|---------------------|-----------|-------------------|------|
| **Elite** | Multiple/day | < 1 hour | 0-15% | < 1 hour |
| **High** | 1/day - 1/week | 1 day - 1 week | 16-30% | < 1 day |
| **Medium** | 1/week - 1/month | 1 week - 1 month | 31-45% | 1 day - 1 week |
| **Low** | < 1/month | > 1 month | > 45% | > 1 week |

### Improvement Recommendations

If your team is not at Elite level, focus on:

**To improve Deployment Frequency:**

- Reduce batch size (smaller, more frequent deploys)
- Automate deployment pipeline
- Enable feature flags for gradual rollout
- Remove manual approval gates

**To reduce Lead Time:**

- Parallelize build and test stages
- Optimize test suite (remove slow/flaky tests)
- Use trunk-based development
- Automate code review checks

**To reduce Change Failure Rate:**

- Increase test coverage (unit, integration, E2E)
- Implement canary deployments
- Add smoke tests after deployment
- Improve monitoring and alerting

**To reduce MTTR:**

- Improve observability (logs, metrics, traces)
- Automate rollback procedures
- Practice incident response drills
- Maintain runbooks for common issues

## Troubleshooting

### Dashboard Shows No Data

**Cause**: DevLake not connected to data sources or no deployments in time range.

**Solution**:

```bash
# Check DevLake data source connections
kubectl get configmap -n devlake devlake-config -o yaml

# Verify Jenkins connection
curl -u admin:password http://jenkins.127.0.0.1.nip.io/api/json

# Verify ArgoCD connection
argocd app list

# Check time range in dashboard (expand to 30 or 90 days)
```

### Metrics Seem Inaccurate

**Cause**: Incorrect deployment detection or missing metadata.

**Solution**:

1. Verify ArgoCD Applications have proper labels:
   ```bash
   kubectl get application -n argocd -o yaml | grep -A 5 labels
   ```
2. Ensure Jenkins pipelines emit DORA events
3. Check DevLake collection logs for errors:
   ```bash
   kubectl logs -n devlake -l app=devlake-collector | grep ERROR
   ```

### Lead Time Shows Extremely High Values

**Cause**: Old commits being deployed or incorrect timestamp parsing.

**Solution**:

- Filter out outliers in dashboard (use percentiles instead of mean)
- Verify commit timestamps match deployment timestamps
- Check for long-lived branches (use trunk-based development)

## Next Steps

After viewing DORA metrics:

- [Trace Requests with Tempo](trace-request-tempo.md) - Debug slow deployments
- [Onboard Service to ArgoCD](../gitops/onboard-service-argocd.md) - Improve deployment frequency
- [Configure Ingress TLS](../networking/configure-ingress-tls.md) - Secure production deployments
- [DORA Metrics Playbook](../../playbooks/dora-metrics-implementation.md) - Deep dive into implementation

## Related Documentation

- [DORA Metrics Implementation Playbook](../../playbooks/dora-metrics-implementation.md) - Setup guide
- [Continuous Delivery Pattern](../../patterns/continuous-delivery.md) - Best practices
- [Architecture Overview](../../architecture.md) - Platform architecture
- [2023 State of DevOps Report](https://dora.dev/) - Research foundation
