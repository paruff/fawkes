# NASA-TLX Integration Guide

## Quick Start - Deploying NASA-TLX Cognitive Load Assessment

### 1. Database Migration

The new NASA-TLX tables will be automatically created when the DevEx Survey Automation service starts:

- `nasa_tlx_assessments` - Individual cognitive load assessments
- `nasa_tlx_aggregates` - Weekly aggregated metrics by task type

**No manual migration needed** - SQLAlchemy will create tables on startup via `Base.metadata.create_all()`.

### 2. Deploy Updated Service

The service code is ready to deploy. Update the existing `devex-survey-automation` deployment:

```bash
# In the platform/apps/devex-survey-automation directory
kubectl apply -k .

# Or via ArgoCD
argocd app sync devex-survey-automation
```

### 3. Import Grafana Dashboard

Import the new NASA-TLX dashboard into Grafana:

```bash
# Option 1: Via ConfigMap (already in place)
kubectl apply -f platform/apps/grafana/dashboards/nasa-tlx-cognitive-load.json

# Option 2: Via Grafana UI
# - Navigate to Grafana
# - Dashboards > Import
# - Upload platform/apps/grafana/dashboards/nasa-tlx-cognitive-load.json
```

### 4. Verify Prometheus Metrics

Check that the new metrics are being scraped:

```bash
# Query Prometheus
curl -G http://prometheus.fawkes.svc:9090/api/v1/query \
  --data-urlencode 'query=devex_nasa_tlx_submissions_total'
```

### 5. Test the Assessment Form

Access the NASA-TLX assessment page:

```bash
# Port forward to the service
kubectl port-forward svc/devex-survey-automation 8000:8000 -n fawkes

# Open in browser
open http://localhost:8000/nasa-tlx?task_type=deployment&user_id=test_user
```

### 6. Submit a Test Assessment

```bash
curl -X POST http://localhost:8000/api/v1/nasa-tlx/submit?user_id=test_developer \
  -H "Content-Type: application/json" \
  -d '{
    "task_type": "deployment",
    "task_id": "test-deployment-1",
    "mental_demand": 50.0,
    "physical_demand": 20.0,
    "temporal_demand": 60.0,
    "performance": 85.0,
    "effort": 45.0,
    "frustration": 30.0,
    "duration_minutes": 20,
    "comment": "Test assessment"
  }'
```

Expected response:

```json
{
  "success": true,
  "message": "NASA-TLX assessment submitted successfully",
  "assessment_id": 1,
  "overall_workload": 41.67,
  "submitted_at": "2025-12-24T09:30:00Z"
}
```

### 7. Verify Dashboard

Open the Grafana dashboard:

```
https://grafana.fawkes.idp/d/nasa-tlx-cognitive-load
```

You should see:

- Overall workload gauge
- Test assessment counted
- Metrics by task type

## Integration with Platform Workflows

### Option A: Backstage Integration

Add a NASA-TLX link to Backstage's Developer Experience section:

```yaml
# In backstage app-config.yaml
catalog:
  providers:
    custom:
      devex:
        actions:
          - title: "Submit Cognitive Load Assessment"
            description: "Help us improve the platform by sharing your experience"
            url: "${SURVEY_BASE_URL}/nasa-tlx?user_id=${user.name}"
```

### Option B: Post-Deployment Trigger

Add to Jenkins shared library pipeline:

```groovy
// In vars/deployPipeline.groovy
def call(Map config) {
    pipeline {
        // ... existing stages ...

        post {
            success {
                script {
                    if (env.BRANCH_NAME == 'main') {
                        def nasaTlxUrl = "https://surveys.fawkes.idp/nasa-tlx?" +
                            "task_type=deployment&" +
                            "task_id=${env.BUILD_ID}&" +
                            "user_id=${env.BUILD_USER}"

                        echo "✨ Optional: Submit cognitive load assessment: ${nasaTlxUrl}"

                        // Send to Mattermost
                        mattermostSend(
                            channel: "#${config.team}",
                            color: 'good',
                            message: "Deployment successful! [Optional] Help us improve: Submit NASA-TLX assessment: ${nasaTlxUrl}"
                        )
                    }
                }
            }
        }
    }
}
```

### Option C: Mattermost Bot Command

Add to Mattermost bot commands:

```python
# In Mattermost bot integration
@bot.command("/nasa-tlx")
async def nasa_tlx_command(ctx, task_type: str = "general"):
    """Submit a NASA-TLX cognitive load assessment"""
    user_id = ctx.user.username
    assessment_url = (
        f"https://surveys.fawkes.idp/nasa-tlx?"
        f"task_type={task_type}&"
        f"user_id={user_id}"
    )

    await ctx.respond(
        f"📊 **NASA-TLX Cognitive Load Assessment**\n\n"
        f"Help us understand your experience with {task_type} tasks!\n\n"
        f"[Click here to submit assessment]({assessment_url})\n\n"
        f"Takes ~2 minutes. Your feedback helps improve the platform. 🙏"
    )
```

Usage:

```
/nasa-tlx deployment
/nasa-tlx pr_review
/nasa-tlx incident_response
```

## Alerting Configuration

Add to Prometheus alert rules (`platform/apps/prometheus/devex-alerting-rules.yaml`):

```yaml
groups:
  - name: nasa_tlx_cognitive_load
    interval: 5m
    rules:
      - alert: HighCognitiveLoad
        expr: avg(devex_nasa_tlx_overall_workload) > 70
        for: 1h
        labels:
          severity: warning
          component: devex
        annotations:
          summary: "High cognitive load detected"
          description: 'Average cognitive workload ({{ $value | printf "%.1f" }}) exceeds 70/100. Developers are experiencing high cognitive load on platform tasks.'
          dashboard: "https://grafana.fawkes.idp/d/nasa-tlx-cognitive-load"

      - alert: HighFrustrationLevels
        expr: avg(devex_nasa_tlx_frustration{task_type=~".+"}) > 75
        for: 30m
        labels:
          severity: critical
          component: devex
        annotations:
          summary: "High frustration levels for {{ $labels.task_type }}"
          description: 'Developers report high frustration ({{ $value | printf "%.1f" }}/100) with {{ $labels.task_type }} tasks. Urgent UX improvements needed.'
          dashboard: "https://grafana.fawkes.idp/d/nasa-tlx-cognitive-load"

      - alert: LowPerformanceScore
        expr: avg(devex_nasa_tlx_performance{task_type=~".+"}) < 50
        for: 1h
        labels:
          severity: warning
          component: devex
        annotations:
          summary: "Low success rate for {{ $labels.task_type }}"
          description: 'Developers struggle to complete {{ $labels.task_type }} tasks ({{ $value | printf "%.1f" }}/100 success rate).'
          dashboard: "https://grafana.fawkes.idp/d/nasa-tlx-cognitive-load"
```

## Environment Variables

Update the DevEx Survey Automation deployment with these environment variables:

```yaml
# platform/apps/devex-survey-automation/deployment.yaml
env:
  - name: SURVEY_BASE_URL
    value: "https://surveys.fawkes.idp"

  # Existing variables...
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: devex-survey-secrets
        key: database-url

  - name: MATTERMOST_URL
    value: "http://mattermost.fawkes.svc:8065"

  - name: MATTERMOST_TOKEN
    valueFrom:
      secretKeyRef:
        name: devex-survey-secrets
        key: mattermost-token
```

## Testing the Integration

### End-to-End Test

1. **Submit an assessment**:

   ```bash
   curl -X POST https://surveys.fawkes.idp/api/v1/nasa-tlx/submit?user_id=e2e_test \
     -H "Content-Type: application/json" \
     -d '{"task_type":"deployment","mental_demand":60,"physical_demand":30,"temporal_demand":70,"performance":80,"effort":55,"frustration":45}'
   ```

2. **Verify in database**:

   ```sql
   SELECT * FROM nasa_tlx_assessments WHERE user_id = 'e2e_test' ORDER BY submitted_at DESC LIMIT 1;
   ```

3. **Check Prometheus metrics**:

   ```bash
   curl -G http://prometheus.fawkes.svc:9090/api/v1/query \
     --data-urlencode 'query=devex_nasa_tlx_overall_workload{task_type="deployment"}'
   ```

4. **View in Grafana**:

   - Navigate to NASA-TLX dashboard
   - Filter by task_type = "deployment"
   - Verify gauge shows workload value

5. **Test analytics endpoint**:
   ```bash
   curl https://surveys.fawkes.idp/api/v1/nasa-tlx/analytics?weeks=4
   ```

### BDD Tests

Run the BDD feature tests:

```bash
cd /home/runner/work/fawkes/fawkes
behave tests/bdd/features/nasa_tlx_cognitive_load.feature --tags=@nasa-tlx
```

## Rollout Plan

### Phase 1: Soft Launch (Week 1)

- Deploy to dev environment
- Platform team submits assessments
- Validate metrics, dashboard, and analytics
- Collect feedback on UX

### Phase 2: Pilot (Week 2-3)

- Deploy to production
- Announce to 2-3 pilot teams
- Add Backstage link
- Monitor response rate and feedback

### Phase 3: General Availability (Week 4+)

- Announce to all developers
- Add Mattermost bot command
- Enable post-deployment triggers (opt-in)
- Weekly review of insights

## Troubleshooting

### Issue: Metrics not showing in Prometheus

**Solution**: Check ServiceMonitor configuration:

```bash
kubectl get servicemonitor devex-survey-automation -n fawkes -o yaml
```

Ensure it has the correct labels and port:

```yaml
spec:
  selector:
    matchLabels:
      app: devex-survey-automation
  endpoints:
    - port: http
      path: /metrics
```

### Issue: Dashboard shows "No Data"

**Cause**: No assessments submitted yet or metrics not scraped.

**Solution**:

1. Submit a test assessment
2. Wait 30 seconds for Prometheus to scrape
3. Refresh Grafana dashboard

### Issue: Database connection errors

**Solution**: Check database credentials:

```bash
kubectl get secret devex-survey-secrets -n fawkes -o yaml
kubectl logs -n fawkes deployment/devex-survey-automation | grep -i database
```

## Success Metrics

Track these KPIs after deployment:

- **Response Rate**: Target >40% of prompted assessments completed
- **Assessment Frequency**: 50-100 assessments per week
- **Actionable Insights**: Identify 2-3 high-workload tasks per month
- **Improvements**: Reduce workload by 20% for targeted tasks within 3 months

## Support

- **Platform Team**: #platform-experience on Mattermost
- **Documentation**: `services/devex-survey-automation/NASA_TLX_README.md`
- **Issues**: https://github.com/paruff/fawkes/issues
- **On-Call**: platform-oncall@fawkes.idp

## References

- [NASA-TLX Overview](https://humansystems.arc.nasa.gov/groups/tlx/)
- [ADR-018: SPACE Framework](/docs/adr/ADR-018%20Developer%20Experience%20Measurement%20Framework%20SPACE.md)
- [Service README](NASA_TLX_README.md)
