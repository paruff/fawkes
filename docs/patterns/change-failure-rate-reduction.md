# Change Failure Rate Reduction Pattern

Change Failure Rate (CFR) measures the percentage of production changes that result
in a degraded service or require remediation (rollback, hotfix, patch). Reducing CFR
is about building confidence in every change, not about deploying less often.

## Understanding CFR

CFR is calculated as:

```
CFR = (number of failed deployments) / (total deployments) × 100%
```

DORA benchmarks:
- **Elite**: 0–15%
- **High**: 16–30%
- **Medium**: 16–30% (similar to high)
- **Low**: 46–60%+

## Measuring CFR in Fawkes

DevLake ingests deployment events from ArgoCD and incident/hotfix events from your
incident management system (PagerDuty, Jira). The DORA dashboard in Grafana shows
CFR trending over time per team and service.

## Strategies to Reduce CFR

### Automated Quality Gates

Every change must pass before merge:
- Unit test coverage ≥ 80%
- No new SAST vulnerabilities (SonarQube)
- Container scan clean (Trivy)
- Code review approval

### Smaller Change Batches

Smaller changes have lower CFR because:
- They are easier to reason about
- Testing is more complete and targeted
- Rollback is cheaper
- Root cause identification is faster

The PR size gate in Fawkes (400 lines maximum) enforces this discipline.

### Observability Before Deployment

You cannot detect failures if you cannot observe them. Every service must have:
- Deployment health checks (Kubernetes readiness probe)
- SLO-based alerts in Grafana
- A P1 runbook linked from the alert annotation

### Progressive Delivery

Canary deployments route a small percentage of traffic to new versions. Prometheus
metrics evaluate the canary automatically. Failed canaries are rolled back before
most users are affected, reducing both CFR and MTTR.

## Root Cause Analysis

When a deployment does fail, run a blameless post-mortem. Classify the root cause:
- **Test gap** — Write the missing test
- **Process gap** — Update the deployment checklist
- **Tool gap** — Improve CI/CD pipeline

## See Also

- [Incident Response Pattern](incident-response.md)
- [Deployment Automation Pattern](deployment-automation.md)
- [Quality Pattern](quality.md)
