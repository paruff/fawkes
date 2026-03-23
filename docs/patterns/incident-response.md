# Incident Response Pattern

Effective incident response minimises Mean Time to Restore (MTTR) — the time from
when a production incident starts until normal service is restored. DORA identifies
MTTR as one of the four key metrics of software delivery performance. Elite teams
restore service in less than one hour.

## Incident Severity Levels

| Severity | Definition | Response Time | Examples |
|----------|-----------|---------------|---------|
| **P1 (Critical)** | Complete service outage, data loss | Immediate | Cluster down, database corruption |
| **P2 (High)** | Major feature unavailable | 15 minutes | Login broken, payments failing |
| **P3 (Medium)** | Degraded performance | 1 hour | Slow responses, partial outage |
| **P4 (Low)** | Minor issue | Next business day | UI glitch, non-critical error |

## Response Process

### 1. Detect

Grafana alerts fire when SLO thresholds are breached. The alert routes to the on-call
engineer via Alertmanager → PagerDuty → Mattermost.

### 2. Declare

The on-call engineer declares an incident in the `#incidents` Mattermost channel with
severity, impact scope, and initial hypothesis.

### 3. Diagnose

Use the runbook linked in the alert annotation. Check:
- Grafana dashboards — error rate, latency, saturation
- Loki logs — filter to the affected service and time window
- Tempo traces — identify which service call is failing

### 4. Mitigate

Prioritise restoring service over finding root cause:
- Rollback recent deployment (`argocd app rollback <app>`)
- Scale up replicas to absorb load
- Enable a feature flag to disable the failing feature

### 5. Resolve and Learn

After service is restored, write a blameless post-mortem within 48 hours. Document:
- Timeline of events
- Root cause
- Contributing factors
- Action items with owners and due dates

Post-mortems are stored in `docs/runbooks/post-mortems/` and shared with the team.

## Runbooks

Every P1/P2 alert must link to a runbook in `docs/runbooks/`. Runbooks are tested
quarterly — an untested runbook is unreliable under pressure.

## See Also

- [Runbooks](../runbooks/index.md)
- [Monitoring Pattern](monitoring.md)
- [MTTR Tutorial](../tutorials/6-measure-dora-metrics.md)
