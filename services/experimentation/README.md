# Experimentation Service

A/B testing framework with statistical analysis, variant assignment, and results dashboards for the Fawkes platform.

## Features

- **Experiment Management**: Create, start, stop, and manage A/B tests
- **Variant Assignment**: Consistent hash-based assignment with traffic allocation control
- **Statistical Analysis**: Automated two-proportion z-tests with confidence intervals
- **Event Tracking**: Track conversion events and custom metrics
- **Results Dashboard**: Real-time experiment metrics via Prometheus and Grafana
- **Integration**: Works with Unleash (feature flags) and Plausible (analytics)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Experimentation Service                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │               FastAPI Application                       │ │
│  │  • Experiment CRUD operations                          │ │
│  │  • Variant assignment (consistent hashing)             │ │
│  │  • Event tracking and analytics                        │ │
│  │  • Statistical analysis engine                         │ │
│  └────────────────────┬───────────────────────────────────┘ │
│                       │                                      │
│                       ▼                                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │        PostgreSQL Database (CloudNativePG)             │ │
│  │  • Experiments metadata                                │ │
│  │  • Variant assignments                                 │ │
│  │  • Event tracking data                                 │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Prometheus Metrics                         │ │
│  │  • Experiment counts and status                        │ │
│  │  • Variant assignment rates                            │ │
│  │  • Event tracking metrics                              │ │
│  │  • Statistical significance indicators                 │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            │                               │
            ▼                               ▼
    ┌──────────────┐              ┌──────────────┐
    │   Unleash    │              │  Plausible   │
    │(Feature Flags│              │  (Analytics) │
    └──────────────┘              └──────────────┘
```

## API Endpoints

### Experiment Management

- `POST /api/v1/experiments` - Create new experiment
- `GET /api/v1/experiments` - List all experiments
- `GET /api/v1/experiments/{id}` - Get experiment details
- `PUT /api/v1/experiments/{id}` - Update experiment
- `DELETE /api/v1/experiments/{id}` - Delete experiment
- `POST /api/v1/experiments/{id}/start` - Start experiment
- `POST /api/v1/experiments/{id}/stop` - Stop experiment

### Variant Assignment & Tracking

- `POST /api/v1/experiments/{id}/assign` - Assign variant to user
- `POST /api/v1/experiments/{id}/track` - Track event
- `GET /api/v1/experiments/{id}/stats` - Get statistical analysis

### Monitoring

- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics

## Quick Start

### Create an Experiment

```bash
curl -X POST https://experimentation.fawkes.idp/api/v1/experiments \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Feature Test",
    "description": "Testing new feature vs. control",
    "hypothesis": "New feature will increase conversion by 10%",
    "variants": [
      {"name": "control", "allocation": 0.5, "config": {}},
      {"name": "new-feature", "allocation": 0.5, "config": {"feature_enabled": true}}
    ],
    "metrics": ["conversion", "signup"],
    "target_sample_size": 1000,
    "significance_level": 0.05,
    "traffic_allocation": 1.0
  }'
```

### Start Experiment

```bash
curl -X POST https://experimentation.fawkes.idp/api/v1/experiments/{id}/start \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"
```

### Assign Variant

```bash
curl -X POST https://experimentation.fawkes.idp/api/v1/experiments/{id}/assign \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "context": {"source": "web"}
  }'
```

### Track Event

```bash
curl -X POST https://experimentation.fawkes.idp/api/v1/experiments/{id}/track \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "event_name": "conversion",
    "value": 1.0
  }'
```

### Get Statistics

```bash
curl https://experimentation.fawkes.idp/api/v1/experiments/{id}/stats
```

## Statistical Analysis

The service performs automated statistical analysis using:

- **Two-Proportion Z-Test**: Compares conversion rates between variants
- **Confidence Intervals**: 95% CI for each variant's performance
- **P-Value Calculation**: Tests statistical significance
- **Effect Size**: Measures practical significance
- **Recommendations**: Automated decision support

### Example Stats Response

```json
{
  "experiment_id": "abc-123",
  "experiment_name": "New Feature Test",
  "status": "running",
  "variants": [
    {
      "variant": "control",
      "sample_size": 523,
      "conversions": 47,
      "conversion_rate": 0.0899,
      "mean_value": 1.0,
      "std_dev": 0.0,
      "confidence_interval": [0.067, 0.113]
    },
    {
      "variant": "new-feature",
      "sample_size": 511,
      "conversions": 62,
      "conversion_rate": 0.1213,
      "mean_value": 1.0,
      "std_dev": 0.0,
      "confidence_interval": [0.094, 0.148]
    }
  ],
  "control_variant": "control",
  "winner": "new-feature",
  "statistical_significance": true,
  "p_value": 0.0234,
  "confidence_level": 0.95,
  "effect_size": 0.349,
  "recommendation": "✅ Winner: new-feature shows 34.9% improvement over control (p=0.0234). Recommend rolling out new-feature to 100% traffic.",
  "sample_size_per_variant": 517,
  "total_conversions": 109
}
```

## Integration with Platform

### Unleash Feature Flags

Use Unleash to control experiment traffic:

```typescript
// In your application
const isInExperiment = await client.getBooleanValue('experiment-new-feature', false);

if (isInExperiment) {
  // Call experimentation service to assign variant
  const assignment = await assignVariant(experimentId, userId);

  // Use variant configuration
  if (assignment.variant === 'new-feature') {
    enableNewFeature();
  }
}
```

### Plausible Analytics

Track events in Plausible for additional analytics:

```javascript
// Track event in both systems
plausible('conversion', { props: { experiment: experimentId, variant: variantName } });
await trackEvent(experimentId, userId, 'conversion');
```

### Backstage Integration

Add experiment status to Backstage entity pages:

```yaml
# catalog-info.yaml
metadata:
  annotations:
    fawkes.io/experiments: 'abc-123,def-456'
```

## Prometheus Metrics

The service exposes comprehensive metrics:

### Experiment Metrics
- `experimentation_experiments_total{status}` - Total experiments by status
- `experimentation_experiments_active` - Currently active experiments

### Assignment Metrics
- `experimentation_variant_assignments_total{experiment_id,variant}` - Variant assignments
- `experimentation_events_total{experiment_id,variant,event_name}` - Events tracked

### Analysis Metrics
- `experimentation_significant_results_total{experiment_id}` - Significant results
- `experimentation_analysis_duration_seconds{experiment_id}` - Analysis duration

## Grafana Dashboard

A pre-built dashboard is available at `/grafana/d/experimentation`:

**Panels:**
- Active experiments count
- Variant assignment distribution
- Conversion rates by variant
- Statistical significance indicators
- P-value trends
- Sample size progress

## Configuration

### Environment Variables

- `DATABASE_URL` - PostgreSQL connection string
- `ADMIN_TOKEN` - API admin token
- `UNLEASH_URL` - Unleash API URL (optional)
- `PLAUSIBLE_URL` - Plausible analytics URL (optional)

### Database Schema

Tables:
- `experiments` - Experiment metadata
- `assignments` - Variant assignments
- `events` - Event tracking data

## Development

### Run Locally

```bash
# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Run database migrations (tables created automatically)
# Set DATABASE_URL environment variable

# Run application
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Run Tests

```bash
pytest tests/ -v
```

## Deployment

The service is deployed via ArgoCD:

```bash
# Deploy to cluster
kubectl apply -f platform/apps/experimentation-application.yaml

# Wait for deployment
kubectl wait --for=condition=ready pod -l app=experimentation -n fawkes --timeout=300s

# Check status
kubectl get pods -n fawkes -l app=experimentation
```

## Security

- **Authentication**: Bearer token for admin operations
- **Authorization**: Role-based access control (roadmap)
- **TLS**: All traffic encrypted in transit
- **Secrets**: Managed via Kubernetes secrets / Vault
- **Database**: Connection pooling with SSL

## Best Practices

1. **Sample Size**: Aim for at least 100 users per variant for meaningful results
2. **Significance Level**: Use 0.05 (95% confidence) as default
3. **Traffic Allocation**: Start with 10-20% traffic, scale up after validation
4. **Duration**: Run experiments for at least 1 week to capture behavioral patterns
5. **Metrics**: Choose metrics that align with business goals

## Troubleshooting

### No variant assigned

- Check experiment status (must be "running")
- Verify traffic allocation settings
- Check user_id is consistent

### Low statistical power

- Increase sample size
- Extend experiment duration
- Adjust significance level (with caution)

### Database connection issues

```bash
# Check database status
kubectl get cluster db-experiment-dev -n fawkes

# Test connectivity
kubectl exec -it deployment/experimentation -n fawkes -- \
  psql $DATABASE_URL -c "SELECT 1"
```

## References

- [Two-Proportion Z-Test](https://www.statisticshowto.com/two-proportion-z-test/)
- [A/B Testing Best Practices](https://www.optimizely.com/optimization-glossary/ab-testing/)
- [Statistical Significance Calculator](https://www.evanmiller.org/ab-testing/sample-size.html)

## Support

- **Team**: #fawkes-platform (Mattermost)
- **Documentation**: https://docs.fawkes.idp/experimentation
- **Issues**: https://github.com/paruff/fawkes/issues
