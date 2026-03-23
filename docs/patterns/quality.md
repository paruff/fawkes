# Change Failure Rate Reduction Pattern

Change Failure Rate (CFR) is one of the four DORA metrics: the percentage of changes
to production that result in degraded service or require a hotfix, rollback, or patch.
Elite teams maintain a CFR of 0–15%. High-performing teams achieve 16–30%. Anything
above 45% indicates a systemic quality problem.

## Why CFR Matters

A high CFR is a lagging indicator of poor engineering practices. It means:
- Developers are spending significant time fixing production issues instead of building
- Incidents erode user trust
- Fear of failures reduces deployment frequency, which increases batch sizes, which
  increases CFR — a vicious cycle

## Root Causes

Common causes of elevated CFR:
1. **Insufficient automated testing** — Issues that should be caught in CI reach production
2. **Large batch sizes** — Large changes are harder to test and harder to roll back
3. **Missing quality gates** — No SonarQube, no coverage threshold, no security scan
4. **Flaky tests ignored** — Flaky tests get disabled, creating blind spots
5. **No canary deployments** — Changes go directly to 100% of traffic

## Reduction Strategies

### Testing Investment

Maintain a healthy testing pyramid: many unit tests (fast, cheap), fewer integration
tests, minimal E2E tests. Each layer catches different failure modes.

### Quality Gates

SonarQube enforces: no new HIGH/CRITICAL vulnerabilities, ≥ 80% test coverage on new
code, no new blocker code smells. Merge is blocked until the Quality Gate passes.

### Deployment Strategies

**Canary releases** — Route 5–10% of traffic to the new version. Monitor error rates
and latency for 10 minutes. Promote or rollback automatically.

**Feature flags** — Decouple deployment from release. Code is deployed dark and
enabled for a subset of users first.

### Automated Rollback

ArgoCD's sync policy includes `selfHeal: true`. If a deployment causes SLO violations
detected by Prometheus alerts, a runbook-triggered rollback restores the previous image
within minutes.

## Measuring CFR in Fawkes

DevLake correlates deployment events with incident records to calculate CFR per team
per sprint. View the DORA dashboard in Grafana.

## See Also

- [DORA Metrics Tutorial](../tutorials/6-measure-dora-metrics.md)
- [SonarQube](../tools/sonarqube.md)
- [Quality Gates Configuration](../how-to/security/quality-gates-configuration.md)
