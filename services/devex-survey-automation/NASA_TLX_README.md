# NASA-TLX Cognitive Load Assessment Tool

## Overview

The NASA-TLX (Task Load Index) Cognitive Load Assessment Tool is an adaptation of the well-established NASA Task Load Index for measuring developer cognitive load when performing platform tasks in Fawkes.

## What is NASA-TLX?

NASA-TLX is a widely-used, subjective workload assessment tool that provides an overall workload score based on six dimensions:

1. **Mental Demand**: How mentally demanding was the task?
2. **Physical Demand**: How physically demanding was the task? (typing, clicking, etc.)
3. **Temporal Demand**: How hurried or rushed was the pace of the task?
4. **Performance**: How successful were you in accomplishing the task? (0=failure, 100=perfect)
5. **Effort**: How hard did you have to work to accomplish your level of performance?
6. **Frustration**: How insecure, discouraged, irritated, stressed, and annoyed were you?

Each dimension is rated on a scale from 0 to 100, and an overall workload score is calculated.

## Why NASA-TLX for Developer Experience?

Traditional developer productivity metrics focus on outputs (commits, PRs, deployments) but fail to capture the **experience** of doing the work. High cognitive load leads to:

- Burnout and fatigue
- Increased errors and rework
- Lower job satisfaction
- Reduced innovation and creativity
- Developer attrition

By systematically measuring cognitive load, we can:

- Identify which platform tasks are most demanding
- Track the impact of platform improvements
- Prioritize UX enhancements based on real data
- Understand which dimensions (mental, temporal, frustration) need the most attention

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Platform Task Completion                      │
│  (Deployment, PR Review, Incident Response, Build, etc.)        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              NASA-TLX Assessment Prompt                          │
│  - Post-task trigger (optional)                                 │
│  - Backstage link                                               │
│  - Mattermost bot command                                       │
│  - Direct URL access                                            │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│          NASA-TLX Assessment Form (Web UI)                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Rate each dimension (0-100 scale):                         │ │
│  │ - Mental Demand         [slider]                           │ │
│  │ - Physical Demand       [slider]                           │ │
│  │ - Temporal Demand       [slider]                           │ │
│  │ - Performance           [slider]                           │ │
│  │ - Effort                [slider]                           │ │
│  │ - Frustration           [slider]                           │ │
│  │                                                            │ │
│  │ Duration: [___] minutes (optional)                         │ │
│  │ Comment: [text area] (optional)                            │ │
│  │                                                            │ │
│  │ [Submit Assessment]                                        │ │
│  └────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│             DevEx Survey Automation Service                      │
│  - Store assessment in PostgreSQL                               │
│  - Calculate overall workload score                             │
│  - Update Prometheus metrics                                    │
│  - Generate aggregates by task type and time period             │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
┌────────────────────────┐  ┌──────────────────────────┐
│  Prometheus Metrics    │  │  PostgreSQL Database     │
│  - Overall workload    │  │  - Individual responses  │
│  - By dimension        │  │  - Aggregates by week    │
│  - By task type        │  │  - Privacy-compliant     │
└────────┬───────────────┘  └──────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│              Grafana DevEx Dashboard                             │
│  - Overall cognitive workload gauge                             │
│  - Workload by task type                                        │
│  - Dimension breakdowns (which is most demanding?)              │
│  - Trends over time                                             │
│  - Alerts when workload exceeds thresholds                      │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

### Submit Assessment via Web Form

Access the NASA-TLX assessment page:

```
https://surveys.fawkes.idp/nasa-tlx?task_type=deployment&user_id=your_user_id
```

Query parameters:
- `task_type`: Type of platform task (deployment, pr_review, incident_response, build, etc.)
- `task_id` (optional): Specific identifier for the task
- `user_id`: Your user identifier (for privacy-preserving analytics)

### Submit Assessment via API

```bash
curl -X POST https://surveys.fawkes.idp/api/v1/nasa-tlx/submit?user_id=developer1 \
  -H "Content-Type: application/json" \
  -d '{
    "task_type": "deployment",
    "task_id": "deploy-prod-v1.2.0",
    "mental_demand": 65.0,
    "physical_demand": 25.0,
    "temporal_demand": 80.0,
    "performance": 85.0,
    "effort": 70.0,
    "frustration": 40.0,
    "duration_minutes": 30,
    "comment": "Complex rollback scenario required"
  }'
```

### Via Mattermost Bot

```
/nasa-tlx deployment
```

The bot will respond with a personalized link to the assessment form.

### Via Backstage Portal

1. Navigate to Developer Experience section
2. Click "Submit Cognitive Load Assessment"
3. Fill out the form (user_id pre-populated)

## Task Types

Common platform task types to assess:

- `deployment` - Deploying applications to environments
- `pr_review` - Reviewing pull requests
- `incident_response` - Responding to incidents or outages
- `build` - Running builds and CI pipelines
- `debug` - Debugging issues or failures
- `configuration` - Configuring platform resources
- `onboarding` - Onboarding to new services or tools
- `documentation` - Reading or writing documentation

## Analytics

### View in Grafana Dashboard

Access the NASA-TLX Cognitive Load dashboard:

```
https://grafana.fawkes.idp/d/nasa-tlx-cognitive-load
```

Visualizations include:
- Overall workload gauge (0-100 scale)
- Workload by task type (bar chart)
- Six NASA-TLX dimensions (stat panels)
- Workload trends over time (time series)
- Frustration trends (time series)
- Total assessments submitted

### Query Analytics via API

```bash
# Get NASA-TLX analytics for last 4 weeks
curl https://surveys.fawkes.idp/api/v1/nasa-tlx/analytics?weeks=4

# Get NASA-TLX trends
curl https://surveys.fawkes.idp/api/v1/nasa-tlx/trends?weeks=12

# Get statistics by task type
curl https://surveys.fawkes.idp/api/v1/nasa-tlx/task-types
```

## Interpreting Scores

### Overall Workload Score

The overall workload score is calculated as:

```
Overall Workload = (Mental + Physical + Temporal + (100 - Performance) + Effort + Frustration) / 6
```

Note: Performance is inverted because higher performance is better, while higher scores on other dimensions indicate more demand.

**Interpretation:**
- 0-40: **Healthy** - Task has reasonable cognitive load
- 40-60: **Warning** - Task is moderately demanding, consider improvements
- 60-80: **Critical** - Task is very demanding, prioritize UX improvements
- 80-100: **Severe** - Task is extremely demanding, urgent action needed

### Dimension-Specific Insights

- **High Mental Demand**: Task requires complex thinking, many decisions, or unfamiliar concepts
  - *Improvements*: Better documentation, simplified workflows, guided wizards

- **High Physical Demand**: Task requires excessive typing, clicking, or repetitive actions
  - *Improvements*: Keyboard shortcuts, automation, CLI tools, batch operations

- **High Temporal Demand**: Task is time-pressured or has tight deadlines
  - *Improvements*: Faster build times, parallel execution, progress indicators

- **Low Performance**: Users struggle to complete the task successfully
  - *Improvements*: Better error messages, validation, rollback capabilities

- **High Effort**: Task requires more work than it should
  - *Improvements*: Automation, intelligent defaults, templates, code generation

- **High Frustration**: Task causes annoyance, stress, or discouragement
  - *Improvements*: Fix bugs, improve error handling, reduce complexity, provide alternatives

## Privacy & Ethics

### Privacy-First Design

1. **Anonymization**: Individual responses are never shown in reports or dashboards
2. **Aggregation**: Only team-level or task-type-level data is displayed
3. **Threshold**: Metrics only shown when ≥5 responses exist
4. **Opt-Out**: Developers can opt out of assessments at any time
5. **Data Retention**: Individual responses archived after 90 days, aggregates retained

### Ethical Use

**Never use NASA-TLX data for:**
- ❌ Individual performance reviews
- ❌ Ranking or comparing developers
- ❌ Hiring/firing decisions
- ❌ Bonus or compensation

**Always use NASA-TLX data for:**
- ✅ Identifying platform improvement opportunities
- ✅ Measuring impact of UX changes
- ✅ Prioritizing platform roadmap
- ✅ Understanding developer pain points
- ✅ Celebrating successful improvements

## Integration with Platform Workflows

### Post-Deployment Assessment

When a deployment completes, optionally prompt for NASA-TLX assessment:

```yaml
# In Jenkins pipeline
post {
  always {
    script {
      if (env.COLLECT_NASA_TLX == 'true') {
        def assessmentUrl = "https://surveys.fawkes.idp/nasa-tlx?task_type=deployment&task_id=${env.BUILD_ID}&user_id=${env.BUILD_USER}"
        echo "Optional: Submit NASA-TLX assessment: ${assessmentUrl}"
        // Could send to Mattermost, Slack, or email
      }
    }
  }
}
```

### Event-Driven Collection

Trigger NASA-TLX prompts based on platform events:

- After merge conflicts resolved
- After incident resolution
- After complex configuration changes
- After first-time tasks (onboarding)

## Prometheus Metrics

### Available Metrics

```promql
# Total assessments submitted by task type
devex_nasa_tlx_submissions_total{task_type="deployment"}

# Average overall workload by task type
devex_nasa_tlx_overall_workload{task_type="deployment"}

# Individual NASA-TLX dimensions
devex_nasa_tlx_mental_demand{task_type="pr_review"}
devex_nasa_tlx_physical_demand{task_type="pr_review"}
devex_nasa_tlx_temporal_demand{task_type="incident_response"}
devex_nasa_tlx_effort{task_type="build"}
devex_nasa_tlx_frustration{task_type="debug"}
devex_nasa_tlx_performance{task_type="configuration"}
```

### Alerting Rules

Example Prometheus alerting rules:

```yaml
groups:
  - name: nasa_tlx_alerts
    rules:
      - alert: HighCognitiveLoad
        expr: devex_nasa_tlx_overall_workload > 70
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "High cognitive load detected for {{ $labels.task_type }}"
          description: "Average workload ({{ $value }}) exceeds 70 for task type {{ $labels.task_type }}"

      - alert: HighFrustration
        expr: devex_nasa_tlx_frustration > 75
        for: 30m
        labels:
          severity: critical
        annotations:
          summary: "High frustration levels for {{ $labels.task_type }}"
          description: "Developers are frustrated ({{ $value }}/100) with {{ $labels.task_type }} tasks"
```

## Best Practices

### When to Prompt for Assessments

- **After task completion**: Immediately after finishing a platform task (within 5 minutes)
- **Optional, not forced**: Never block workflow for assessment
- **Frequency**: Limit to 1-2 assessments per day per developer max
- **Strategic sampling**: Focus on new features or recently changed workflows

### Response Rate Goals

- Target: >40% response rate
- Keep form short (6 sliders + 2 optional fields = ~2 minutes)
- Explain the "why" - how feedback drives improvements
- Share impact: "Thanks to your feedback, we reduced deployment time by 30%"

### Acting on Insights

1. **Weekly Review**: Review NASA-TLX dashboard every week
2. **Identify Outliers**: Which task types have highest workload?
3. **Drill Down**: Which dimensions are driving high workload?
4. **Prioritize**: Focus on tasks with highest frequency × workload
5. **Experiment**: Make improvements and measure before/after
6. **Communicate**: Share improvements back to developers

## References

- [NASA-TLX Original Paper](https://humansystems.arc.nasa.gov/groups/tlx/)
- [SPACE Framework (GitHub Research)](https://queue.acm.org/detail.cfm?id=3454124)
- [ADR-018: Developer Experience Measurement Framework](/docs/adr/ADR-018%20Developer%20Experience%20Measurement%20Framework%20SPACE.md)
- [2025 DORA Report on User-Centric Focus](https://dora.dev/research/)

## Support

For questions or issues with NASA-TLX assessments:

- Platform Team: #platform-experience on Mattermost
- Documentation: [DevEx Measurement Guide](/docs/how-to/devex-measurement.md)
- Report Bugs: [GitHub Issues](https://github.com/paruff/fawkes/issues)

## License

MIT License - See [LICENSE](/LICENSE)
