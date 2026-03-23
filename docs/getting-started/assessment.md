# Assess Your Current Capabilities

Before adopting Fawkes, take stock of where your teams stand today. This self-assessment
guides you to the right implementation path and helps you set realistic improvement targets.

## DORA Performance Tiers

The DORA State of DevOps research classifies teams into four performance tiers based on
their delivery metrics. Use the table below to identify your current tier:

| Metric | Elite | High | Medium | Low |
|--------|-------|------|--------|-----|
| **Deployment Frequency** | Multiple/day | Weekly | Monthly | Quarterly |
| **Lead Time for Changes** | < 1 hour | 1 day–1 week | 1–6 months | > 6 months |
| **Change Failure Rate** | 0–15% | 16–30% | 16–30% | 46–60%+ |
| **MTTR** | < 1 hour | < 1 day | 1 day–1 week | > 1 week |

## Capability Checklist

Answer yes/no for your team today:

### Version Control
- [ ] All code (including infrastructure) is in version control
- [ ] Branch protection is enforced on `main`
- [ ] Small, frequent commits (at least daily)

### Continuous Integration
- [ ] Automated tests run on every pull request
- [ ] Builds complete in < 10 minutes
- [ ] Coverage is tracked and reported

### Deployment
- [ ] Deployments are automated (no manual steps)
- [ ] Deployments can be rolled back within 1 hour
- [ ] Multiple deployments per week are possible

### Observability
- [ ] Error rates and latency are monitored for all services
- [ ] Alerts exist for user-impacting SLO breaches
- [ ] Logs are centralised and searchable

### Security
- [ ] Dependency vulnerabilities are scanned automatically
- [ ] Secrets are managed in a vault (not in config files or Git)
- [ ] Container images are scanned before deployment

## Interpreting Your Score

**0–5 checked**: Start with the [Quick Wins](quick-wins.md) path. Focus on getting
basic CI and monitoring in place before anything else.

**6–10 checked**: You are ready for the [Incremental Adoption](implementation-paths.md)
path. Tackle deployment automation and security scanning next.

**11–15 checked**: You are performing at the High tier. Explore the full Fawkes
platform to reach Elite. Focus on reducing lead time and MTTR.

## Next Steps

Once you have your baseline, move to:

1. [Choose Your Implementation Path](implementation-paths.md)
2. [Quick Wins You Can Implement This Sprint](quick-wins.md)

## See Also

- [DORA Metrics Tutorial](../tutorials/6-measure-dora-metrics.md)
- [Dojo Getting Started](../dojo/getting-started.md)
- [Getting Started Guide](../getting-started.md)
