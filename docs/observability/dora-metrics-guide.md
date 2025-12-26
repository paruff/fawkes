# DORA Metrics Definition Guide

## Overview

This guide explains how each of the five DORA metrics is calculated within the
Fawkes platform using Apache DevLake.

DORA (DevOps Research and Assessment) metrics are industry-standard measures of
software delivery performance. They help teams understand their delivery velocity,
stability, and identify areas for improvement.

## GitOps Architecture and Data Sources

In Fawkes, we follow a GitOps pattern where:

- **ArgoCD** performs the actual deployments to Kubernetes
- **Jenkins** handles CI (build, test, scan) and updates the GitOps repository
- **GitHub** provides commit and PR data
- **Observability** provides incident data

This architecture affects where DORA metrics are sourced:

| DORA Metric             | Primary Source             | Why                                     |
| ----------------------- | -------------------------- | --------------------------------------- |
| Deployment Frequency    | **ArgoCD**                 | ArgoCD syncs are the actual deployments |
| Lead Time for Changes   | **Git + ArgoCD**           | Commit time → ArgoCD sync completion    |
| Change Failure Rate     | **ArgoCD + Incidents**     | Failed syncs + production incidents     |
| MTTR                    | **Observability + ArgoCD** | Incident creation → restore deployment  |
| Operational Performance | **Prometheus**             | SLO/SLI adherence metrics               |

**Jenkins provides complementary CI metrics:**

- Build success/failure rates
- Test coverage and flakiness
- Quality gate pass rates
- Rework metrics (retries, repeated failures)

## The Five DORA Metrics

### 1. Deployment Frequency

**Definition**: How often code changes are deployed to production.

**Primary Data Source**: **ArgoCD sync events**

In a GitOps architecture, Jenkins does not deploy directly. Instead:

1. Jenkins builds and tests code
2. Jenkins updates the GitOps repository with new image tags
3. ArgoCD detects the change and syncs to Kubernetes
4. The ArgoCD sync is the actual deployment event

**Calculation**:

```
Deployment Frequency = Number of successful ArgoCD syncs to production / Time period
```

**Performance Levels**:
| Level | Frequency |
|-------|-----------|
| Elite | Multiple times per day |
| High | Once per day to once per week |
| Medium | Once per week to once per month |
| Low | Less than once per month |

**Fawkes Implementation**:

- DevLake ArgoCD plugin collects sync events
- Production environments identified by app name pattern (e.g., `*-prod`)
- Grafana dashboard displays daily/weekly/monthly trends

---

### 2. Lead Time for Changes

**Definition**: Time from code commit to running in production.

**Data Sources**:

- **GitHub**: Commit timestamps
- **ArgoCD**: Sync completion timestamps

**Calculation**:

```
Lead Time = ArgoCD Sync Timestamp - First Commit Timestamp
```

The lead time includes:

1. **Development Time**: Time spent coding
2. **Review Time**: Time in code review/PR process
3. **CI Time**: Jenkins build and test execution
4. **GitOps Sync Time**: ArgoCD reconciliation

**Performance Levels**:
| Level | Lead Time |
|-------|-----------|
| Elite | Less than 1 hour |
| High | 1 hour to 1 day |
| Medium | 1 day to 1 week |
| Low | More than 1 week |

**Fawkes Implementation**:

- DevLake correlates GitHub commits with ArgoCD syncs
- Commit SHA links are used for correlation
- Pipeline stages are tracked for detailed breakdown

---

### 3. Change Failure Rate (CFR)

**Definition**: Percentage of deployments that cause a failure in production.

**Data Sources**:

- **ArgoCD**: Sync status (success/failed/degraded)
- **Observability**: Incident records from Alertmanager
- **Webhooks**: Manual incident creation

**Calculation**:

```
CFR = (Failed ArgoCD Syncs + Production Incidents) / Total ArgoCD Syncs × 100%
```

A deployment is considered a failure if:

- The ArgoCD sync fails or enters degraded state
- An incident is created within a configured time window after sync
- A rollback sync is triggered

**Performance Levels**:
| Level | CFR |
|-------|-----|
| Elite | 0-5% |
| High | 5-10% |
| Medium | 10-15% |
| Low | 15%+ |

**Fawkes Implementation**:

- ArgoCD sync failures are automatically tracked
- Observability platform sends incident webhooks
- Correlation with recent syncs determines CFR attribution

---

### 4. Mean Time to Restore (MTTR)

**Definition**: Average time to restore service after a production incident.

**Data Sources**:

- **Observability**: Incident creation timestamps (from Alertmanager)
- **ArgoCD**: Restore sync completion timestamps
- **Webhooks**: Manual incident resolution events

**Calculation**:

```
MTTR = Sum(Resolution Time - Creation Time) / Number of Incidents
```

Resolution is detected when:

- A subsequent successful ArgoCD sync occurs
- Alertmanager alert resolves
- Manual resolution via webhook/API

**Performance Levels**:
| Level | MTTR |
|-------|------|
| Elite | Less than 1 hour |
| High | 1 hour to 1 day |
| Medium | 1 day to 1 week |
| Low | More than 1 week |

**Fawkes Implementation**:

- Incidents are created automatically from Alertmanager
- ArgoCD restore syncs are correlated with open incidents
- Grafana dashboard shows MTTR trends by severity

---

### 5. Operational Performance (Reliability)

**Definition**: Measures the reliability and performance of services in production.

**Data Sources**:

- **Prometheus**: Latency, error rate, availability metrics
- **SLO/SLI Definitions**: Target thresholds

**Calculation**:

```
Operational Performance = Actual Uptime / Target Uptime × 100%
```

Or based on SLO adherence:

```
SLO Adherence = Time within SLO / Total Time × 100%
```

**Key Indicators**:

- **Availability**: Percentage of time service is operational
- **Latency P99**: 99th percentile response time
- **Error Rate**: Percentage of failed requests

**Performance Levels**:
| Level | SLO Adherence |
|-------|---------------|
| Elite | 99.99%+ |
| High | 99.9-99.99% |
| Medium | 99-99.9% |
| Low | Below 99% |

---

## Jenkins CI/Rework Metrics

While DORA metrics focus on deployment and production, Jenkins provides valuable
CI quality metrics:

### Build Success Rate

```
Build Success Rate = Successful Builds / Total Builds × 100%
```

Tracks the reliability of the CI pipeline.

### Rework Rate

```
Rework Rate = Retry Builds / Unique Commits × 100%
```

Measures how often builds need to be re-run for the same code.

### Quality Gate Pass Rate

```
QG Pass Rate = Passed Quality Gates / Total Scans × 100%
```

Tracks SonarQube quality gate success over time.

### Test Flakiness

```
Flakiness = Flaky Test Runs / Total Test Runs × 100%
```

Identifies non-deterministic test failures.

### Build Duration Trend

Tracks average and P95 build durations over time.

**Example Jenkins Pipeline Usage**:

```groovy
@Library('fawkes-pipeline-library') _

// Record build metrics
doraMetrics.recordBuild(
    service: 'my-service',
    status: 'success',
    stage: 'build'
)

// Record quality gate results
doraMetrics.recordQualityGate(
    service: 'my-service',
    passed: true,
    coveragePercent: 85,
    vulnerabilities: 0
)

// Record test results for flakiness tracking
doraMetrics.recordTestResults(
    service: 'my-service',
    totalTests: 150,
    passedTests: 148,
    failedTests: 2,
    flakyTests: 1
)

// At pipeline end
doraMetrics.recordPipelineComplete(service: 'my-service')
```

---

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Data Sources                              │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   GitHub     │  │   ArgoCD     │  │   Jenkins    │          │
│  │              │  │  (PRIMARY)   │  │   (CI/QA)    │          │
│  │ • Commits    │  │              │  │              │          │
│  │ • PRs        │  │ • Syncs      │  │ • Builds     │          │
│  │ • Branches   │  │ • Deploys    │  │ • Tests      │          │
│  └──────┬───────┘  │ • Rollbacks  │  │ • Scans      │          │
│         │          └──────┬───────┘  └──────┬───────┘          │
│         │                 │                  │                   │
│  ┌──────────────┐        │                  │                   │
│  │ Observability│        │                  │                   │
│  │              │        │                  │                   │
│  │ • Incidents  │        │                  │                   │
│  │ • Alerts     │        │                  │                   │
│  │ • SLOs       │        │                  │                   │
│  └──────┬───────┘        │                  │                   │
│         │                 │                  │                   │
└─────────┼─────────────────┼──────────────────┼───────────────────┘
          │    API          │    API           │    Webhook
          ▼                 ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DevLake Platform                            │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                     Collectors                              │ │
│  │  GitHub   │  ArgoCD     │  Jenkins   │  Webhook            │ │
│  │  Plugin   │  Plugin     │  Plugin    │  Plugin             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                    │
│                              ▼                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Data Processing                           │ │
│  │  • Commit → ArgoCD Sync Correlation (Lead Time)            │ │
│  │  • ArgoCD Sync Frequency (Deployment Frequency)            │ │
│  │  • Sync Failures + Incidents (CFR)                         │ │
│  │  • Incident → Restore Sync (MTTR)                          │ │
│  │  • Jenkins Build Metrics (Rework)                          │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                    │
│                              ▼                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                      MySQL Database                         │ │
│  │  Raw events, domain models, calculated metrics              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                    │
└──────────────────────────────┼────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Visualization                               │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Grafana    │  │  Backstage   │  │  DevLake UI  │          │
│  │  Dashboards  │  │   Plugin     │  │              │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

## Accessing DORA Metrics

### Grafana Dashboards

Access the DORA metrics dashboards at:

- **URL**: `http://devlake-grafana.127.0.0.1.nip.io`
- **Credentials**: Use the Grafana admin credentials

Available dashboards:

- DORA Overview - All metrics at a glance
- Deployment Frequency - Detailed deploy trends
- Lead Time for Changes - Time breakdown by stage
- Change Failure Rate - Failure analysis
- Mean Time to Restore - Incident resolution trends

### Backstage Developer Portal

DORA metrics are integrated into Backstage service pages:

1. Navigate to your service in the Backstage catalog
2. Click the "DORA Metrics" tab
3. View the five metrics with performance ratings

### DevLake UI

Access the DevLake configuration UI at:

- **URL**: `http://devlake.127.0.0.1.nip.io`
- Configure data sources and projects

### Jenkins Pipeline

View DORA metrics summary in pipeline output:

```groovy
doraMetrics.getMetricsSummary('my-service')
```

## Best Practices

### Improving Deployment Frequency

- Adopt trunk-based development
- Use feature flags for incremental releases
- Automate deployment pipelines
- Reduce batch sizes

### Reducing Lead Time

- Implement fast code review processes
- Use automated testing
- Parallelize CI stages
- Enable self-service deployments

### Lowering Change Failure Rate

- Increase test coverage
- Implement canary deployments
- Use feature flags for gradual rollouts
- Conduct thorough code reviews

### Reducing MTTR

- Implement robust monitoring and alerting
- Create runbooks for common issues
- Use automated rollbacks
- Practice incident response drills

## Troubleshooting

### Missing Metrics

**Problem**: DORA metrics show N/A

**Solutions**:

1. Verify data source connections in DevLake UI
2. Check that Jenkins is sending deployment events
3. Ensure GitHub collector is configured correctly
4. Run a manual data collection in DevLake

### Incorrect Calculations

**Problem**: Metrics don't match expectations

**Solutions**:

1. Verify commit SHAs are being recorded
2. Check time zone configurations
3. Review the deployment pattern regex
4. Validate incident correlation settings

### No Data in Grafana

**Problem**: Grafana dashboards are empty

**Solutions**:

1. Verify DevLake data sync completed
2. Check Grafana data source configuration
3. Adjust time range in dashboard
4. Run DevLake blueprint manually

## References

- [DORA Research](https://dora.dev/)
- [Apache DevLake Documentation](https://devlake.apache.org/docs/)
- [ADR-016: DevLake DORA Strategy](../adr/ADR-016%20devlake-dora-strategy.md)
- [ADR-012: Metrics Monitoring](../adr/ADR-012%20Metrics%20Monitoring%20and%20Management.md)
