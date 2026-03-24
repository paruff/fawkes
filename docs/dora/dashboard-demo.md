# DORA Metrics Dashboard Demo

This document describes the five DORA (DevOps Research and Assessment) metrics tracked
by the Fawkes platform and how to interpret them in the Grafana dashboard.

## The Five DORA Metrics

The 2025 DORA research identifies five software delivery performance metrics:

| # | Metric | What It Measures | Elite Target |
|---|--------|-----------------|--------------|
| 1 | **Deployment Frequency** | How often code is successfully deployed to production | Multiple times per day |
| 2 | **Lead Time for Changes** | Time from first commit to running in production | Less than one hour |
| 3 | **Change Failure Rate** | Percentage of deployments that cause a production failure | 0–15% |
| 4 | **Time to Restore Service** | Mean time to restore service after a production incident | Less than one hour |
| 5 | **Deployment Rework Rate** | Percentage of deployments that require a follow-up fix deployment within a configurable window (default: 24 h) | < 5% |

---

## Metric Descriptions

### 1. Deployment Frequency

**Definition**: How often an organisation successfully releases to production.

**Why it matters**: High frequency means smaller batches, lower risk, and faster feedback loops.

**Performance Levels**:

| Level | Frequency |
|-------|-----------|
| Elite | Multiple times per day |
| High | Once per day to once per week |
| Medium | Once per week to once per month |
| Low | Less than once per month |

**Grafana panel**: *Deployment Frequency* (stat panel, 7-day window)

---

### 2. Lead Time for Changes

**Definition**: Time from first commit of a change to that change running in production.

**Why it matters**: Short lead time enables rapid iteration and faster customer feedback.

**Performance Levels**:

| Level | Lead Time |
|-------|-----------|
| Elite | Less than 1 hour |
| High | 1 hour to 1 day |
| Medium | 1 day to 1 week |
| Low | More than 1 week |

**Grafana panel**: *Lead Time for Changes* (gauge, P50/P95/P99 breakdown available)

---

### 3. Change Failure Rate

**Definition**: Percentage of deployments that cause a failure in production requiring
a hotfix, rollback, or incident response.

**Why it matters**: A high failure rate indicates quality or process problems in the
delivery pipeline.

**Performance Levels**:

| Level | CFR |
|-------|-----|
| Elite | 0–15% |
| High | 16–30% |
| Medium | 31–45% |
| Low | 46%+ |

**Grafana panel**: *Change Failure Rate* (gauge)

---

### 4. Time to Restore Service

**Definition**: How long it takes to restore service after a production incident.

Also known as Mean Time to Restore (MTTR).

**Why it matters**: Fast recovery limits the blast radius of failures and builds
customer confidence.

**Performance Levels**:

| Level | MTTR |
|-------|------|
| Elite | Less than 1 hour |
| High | 1 hour to 1 day |
| Medium | 1 day to 1 week |
| Low | More than 1 week |

**Grafana panel**: *Mean Time to Restore (MTTR)* (gauge + trend line)

---

### 5. Deployment Rework Rate

**Definition**: The percentage of deployments that require a follow-up deployment to
fix a problem introduced by the original deployment.

A deployment is counted as **rework** when:

- A second deployment to the **same service** occurs within a configurable window
  (default: **24 hours**), **and**
- That follow-up deployment is tagged or flagged as a fix (e.g. commit message
  contains `fix:`, `hotfix:`, or `revert:`, or the deployment is labelled
  `dora.dev/rework=true`).

**Why it matters**: Rework rate distinguishes between deployments that succeed on the
first attempt and those that silently introduce problems requiring rapid follow-up. It
is orthogonal to Change Failure Rate — a high rework rate with a low CFR may indicate
teams are patching quietly rather than raising incidents.

**Performance Levels** (DORA 2025 guidance):

| Level | Rework Rate |
|-------|-------------|
| Elite | < 5% |
| High | 5–10% |
| Medium | 10–20% |
| Low | 20%+ |

**Collection methodology**: See
[docs/playbooks/dora-metrics-implementation.md](../playbooks/dora-metrics-implementation.md#step-6-configure-deployment-rework-rate-collection)
for implementation details.

**Prometheus metric**: `dora_deployment_rework_rate`

**Grafana panel**: *Deployment Rework Rate* (gauge)

---

## Accessing the Dashboard

The DORA metrics dashboard is available in Grafana:

- **Local**: `http://localhost:8080/grafana/d/dora-metrics`
- **Credentials**: `admin` / `fawkes-grafana`

To open directly:

```bash
make dev-status    # prints all service URLs and credentials
```

### Dashboard Sections

1. **Five Key Metrics Overview** — stat/gauge panels for all five metrics side by side
2. **Deployment Trends** — deployment frequency over time, by service
3. **Lead Time Analysis** — trend and P50/P95/P99 distribution
4. **Failure Analysis** — change failure rate over time and by service
5. **Recovery Metrics** — MTTR trend and incident count
6. **Deployment Rework Analysis** — rework rate trend and rework deployments by service
7. **DORA Benchmark Comparison** — your performance vs DORA benchmarks

---

## References

- [DORA 2025 State of DevOps Report](https://dora.dev/)
- [DORA Metrics Definition Guide](../observability/dora-metrics-guide.md)
- [DORA Metrics Implementation Playbook](../playbooks/dora-metrics-implementation.md)
- [DevLake ADR-016](../adr/ADR-016%20devlake-dora-strategy.md)
