# SPACE Metrics Implementation Guide

## Overview

This document provides a comprehensive guide to the SPACE Framework metrics collection implementation in Fawkes. The SPACE framework measures Developer Experience across five key dimensions.

## Architecture

The SPACE metrics service is built with:
- **FastAPI**: RESTful API framework
- **PostgreSQL**: Data persistence
- **SQLAlchemy**: ORM for database operations
- **Prometheus**: Metrics exposition
- **Kubernetes**: Container orchestration

## The Five SPACE Dimensions

### 1. Satisfaction (S)

**What it measures**: Developer happiness and fulfillment

**Key Metrics**:
- NPS Score (-100 to 100)
- Platform satisfaction rating (1-5)
- Burnout percentage

**Data Sources**:
- NPS Service (quarterly surveys)
- Pulse surveys (weekly)
- Feedback widget

**Target Values**:
- NPS > 50 (good), > 70 (excellent)
- Satisfaction rating > 4.0/5.0
- Burnout < 20%

**API Endpoint**: `GET /api/v1/metrics/space/satisfaction`

**Example Response**:
```json
{
  "nps_score": 65.0,
  "satisfaction_rating": 4.2,
  "burnout_percentage": 15.0,
  "response_count": 87
}
```

### 2. Performance (P)

**What it measures**: System and process outcomes

**Key Metrics**:
- Deployment frequency (per day)
- Lead time for changes (hours)
- Change failure rate (%)
- MTTR (minutes)
- Build success rate (%)
- Test coverage (%)

**Data Sources**:
- Jenkins API (builds, deployments)
- ArgoCD (deployments)
- GitHub API (PRs, commits)

**Target Values**:
- Deployment frequency > 1/day
- Lead time < 24 hours
- Change failure rate < 15%
- MTTR < 60 minutes
- Build success rate > 95%

**API Endpoint**: `GET /api/v1/metrics/space/performance`

**Example Response**:
```json
{
  "deployment_frequency": 2.3,
  "lead_time_hours": 18.0,
  "change_failure_rate": 12.0,
  "mttr_minutes": 47.0,
  "build_success_rate": 96.5,
  "test_coverage": 82.0
}
```

### 3. Activity (A)

**What it measures**: Developer actions and outputs

**Key Metrics**:
- Commits count
- Pull requests count
- Code reviews count
- Active developers count
- AI tool adoption rate (%)
- Platform usage count

**Data Sources**:
- GitHub API
- Backstage analytics
- AI tool telemetry

**Target Values**:
- 80%+ developers active weekly
- 90%+ PRs reviewed within 24h
- 70%+ AI tool adoption

**API Endpoint**: `GET /api/v1/metrics/space/activity`

**Example Response**:
```json
{
  "commits_count": 523,
  "pull_requests_count": 98,
  "code_reviews_count": 142,
  "active_developers_count": 12,
  "ai_tool_adoption_rate": 75.0,
  "platform_usage_count": 1847
}
```

### 4. Communication (C)

**What it measures**: Team interaction and collaboration quality

**Key Metrics**:
- Average review time (hours)
- PR comments average
- Cross-team PRs
- Mattermost messages
- Constructive feedback rate (%)

**Data Sources**:
- GitHub API (PR reviews)
- Mattermost API

**Target Values**:
- Review time < 12 hours
- PR comments > 2 per review
- Constructive feedback > 80%

**API Endpoint**: `GET /api/v1/metrics/space/communication`

**Example Response**:
```json
{
  "avg_review_time_hours": 8.5,
  "pr_comments_avg": 3.2,
  "cross_team_prs": 18,
  "mattermost_messages": 437,
  "constructive_feedback_rate": 92.0
}
```

### 5. Efficiency (E)

**What it measures**: Ability to complete work with minimal interruption

**Key Metrics**:
- Flow state days (per week)
- Valuable work percentage
- Friction incidents
- Context switches (per day)
- Cognitive load average (1-5)

**Data Sources**:
- Pulse surveys
- Friction logging widget
- Self-reported metrics

**Target Values**:
- Flow state > 3 days/week
- Valuable work > 60%
- Friction < 30 incidents/100 devs/month
- Cognitive load < 3.5

**API Endpoint**: `GET /api/v1/metrics/space/efficiency`

**Example Response**:
```json
{
  "flow_state_days": 3.5,
  "valuable_work_percentage": 68.0,
  "friction_incidents": 12,
  "context_switches": 4.2,
  "cognitive_load_avg": 3.1
}
```

## DevEx Health Score

The overall DevEx health score combines all five dimensions into a single metric (0-100).

**Calculation**:
1. Normalize each dimension to 0-100 scale
2. Calculate weighted average
3. Return score with status

**Status Indicators**:
- 80-100: Excellent
- 60-79: Good
- 0-59: Needs Improvement

**API Endpoint**: `GET /api/v1/metrics/space/health`

**Example Response**:
```json
{
  "health_score": 78.3,
  "timestamp": "2025-12-23T20:00:00Z",
  "status": "good"
}
```

## Data Collection

### Automated Collection

The service runs background tasks to automatically collect metrics:

1. **Hourly**: Activity and performance metrics from GitHub/Jenkins
2. **Daily**: Aggregate daily metrics, calculate trends
3. **Weekly**: Process pulse survey responses

### Manual Data Entry

#### Pulse Survey

Developers submit weekly pulse surveys via API:

```bash
POST /api/v1/surveys/pulse/submit
{
  "valuable_work_percentage": 70.0,
  "flow_state_days": 3.0,
  "cognitive_load": 3.0,
  "friction_experienced": false
}
```

#### Friction Logging

Developers log friction incidents in real-time:

```bash
POST /api/v1/friction/log
{
  "title": "Slow CI builds",
  "description": "Jenkins builds taking over 30 minutes",
  "severity": "high",
  "category": "ci"
}
```

## Privacy & Ethics

### Privacy-First Design

1. **No Individual Tracking**: API never exposes individual developer metrics
2. **Aggregation Threshold**: Metrics only shown for teams of 5+ developers
3. **Anonymous Surveys**: Survey responses cannot be linked to individuals
4. **Opt-Out Available**: Developers can opt out of activity tracking
5. **Data Retention**: Raw data deleted after 90 days

### Ethical Use Guidelines

**Never use SPACE metrics for:**
- ❌ Individual performance reviews
- ❌ Ranking developers
- ❌ Firing decisions
- ❌ Bonus calculations

**Always use SPACE metrics for:**
- ✅ Identifying platform improvement opportunities
- ✅ Understanding team-level trends
- ✅ Measuring impact of platform changes
- ✅ Improving developer experience

## Integration

### With Backstage

Add to `app-config.yaml`:

```yaml
proxy:
  endpoints:
    '/space-metrics/api':
      target: http://space-metrics.fawkes-local.svc:8000/
      changeOrigin: true
```

### With Grafana

Import DevEx Dashboard:

```bash
kubectl apply -f platform/apps/grafana/dashboards/devex-dashboard.json
```

### With NPS Service

SPACE metrics service automatically integrates with NPS service when `NPS_SERVICE_URL` is configured.

## Troubleshooting

### Service Not Starting

```bash
# Check pod logs
kubectl logs -n fawkes-local -l app=space-metrics

# Check events
kubectl get events -n fawkes-local --sort-by='.lastTimestamp'
```

### No Metrics Appearing

1. Verify database connection
2. Check data sources are accessible
3. Ensure sufficient data has been collected
4. Verify time range in queries

### Prometheus Not Scraping

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n monitoring space-metrics

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
# Navigate to http://localhost:9090/targets
```

## Best Practices

1. **Regular Review**: Review SPACE metrics weekly in team meetings
2. **Act on Insights**: Always follow up on feedback with action items
3. **Communicate Back**: Share results and improvements with developers
4. **Continuous Improvement**: Treat DevEx as an ongoing practice
5. **Avoid Gaming**: Focus on outcomes, not optimizing metrics

## Related Documentation

- [ADR-018: SPACE Framework](../../docs/adr/ADR-018%20Developer%20Experience%20Measurement%20Framework%20SPACE.md)
- [ADR-025: DevEx Metrics Dashboarding](../../docs/adr/ADR-025%20Developer%20Experience%20Metrics%20Collection%20&%20Dashboarding.md)
- [Service README](../../services/space-metrics/README.md)
- [Deployment Guide](../../platform/apps/space-metrics/README.md)

## Support

For questions or issues:
1. Check troubleshooting section above
2. Review service logs
3. Consult platform documentation
4. Open an issue in GitHub repository
