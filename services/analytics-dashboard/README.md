# Analytics Dashboard Service

## Overview

The Analytics Dashboard Service provides comprehensive analytics dashboards that aggregate data from multiple sources including Plausible Analytics, Experimentation Service, and Feedback Service. It offers real-time insights into usage trends, feature adoption, experiment results, and user segments.

## Features

### 1. Usage Trends
- Total and active user counts
- Page view analytics
- Session duration tracking
- Bounce rate monitoring
- Time series visualization
- Top pages and traffic sources

### 2. Feature Adoption
- Feature usage tracking
- Adoption rate calculations
- Unique user counts per feature
- Trend analysis (up/down/stable)
- Historical adoption trends

### 3. Experiment Results
- A/B test results with statistical analysis
- Variant performance metrics
- Confidence intervals
- P-value calculations
- Statistical significance determination
- Automated recommendations

### 4. User Segments
- Behavioral segmentation
- Segment-specific metrics
- Engagement scoring
- At-risk user identification
- Power user analysis

### 5. Funnel Visualization
- Multi-step conversion funnels
- Step-by-step completion rates
- Drop-off analysis
- Time-to-complete metrics
- Standard funnels:
  - Onboarding flow
  - Deployment workflow
  - Service creation

### 6. Export Capabilities
- JSON export
- CSV export (planned)
- Real-time data access via API

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│           Analytics Dashboard Service                        │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │         FastAPI Application                            │ │
│  │  • REST API endpoints                                  │ │
│  │  • Real-time data aggregation                          │ │
│  │  • Prometheus metrics export                           │ │
│  └────────────────────────────────────────────────────────┘ │
│                           │                                  │
│  ┌────────────────────────┼────────────────────────────────┐│
│  │         Data Aggregator                                 ││
│  │  • Multi-source data fetching                           ││
│  │  • Data caching (5-minute TTL)                          ││
│  │  • Background refresh (5-minute interval)               ││
│  └──────────────┬──────────┬──────────┬───────────────────┘│
└─────────────────┼──────────┼──────────┼─────────────────────┘
                  │          │          │
        ┌─────────┴───┐  ┌──┴────┐  ┌──┴─────────┐
        │  Plausible  │  │ Exper.│  │  Feedback  │
        │  Analytics  │  │Service│  │  Service   │
        └─────────────┘  └───────┘  └────────────┘
```

## API Endpoints

### Health Check
```
GET /health
```

### Complete Dashboard
```
GET /api/v1/dashboard?time_range=7d
```
Returns all analytics data in a single response.

### Usage Trends
```
GET /api/v1/usage-trends?time_range=7d
```

### Feature Adoption
```
GET /api/v1/feature-adoption?time_range=30d
```

### Experiment Results
```
GET /api/v1/experiment-results?status=running
```

### User Segments
```
GET /api/v1/user-segments?time_range=30d
```

### Funnel Data
```
GET /api/v1/funnel/{funnel_name}?time_range=30d
```
Available funnels: `onboarding`, `deployment`, `service_creation`

### Refresh Metrics
```
POST /api/v1/metrics/refresh
```

### Export Data
```
GET /api/v1/export/{format}?time_range=30d
```
Formats: `json`, `csv`

## Prometheus Metrics

The service exposes the following metrics on `/metrics`:

### Usage Metrics
- `analytics_total_users` - Total unique users
- `analytics_active_users` - Active users in time range
- `analytics_page_views_total` - Total page views
- `analytics_unique_visitors` - Unique visitors
- `analytics_avg_session_duration_seconds` - Average session duration
- `analytics_bounce_rate_percentage` - Bounce rate

### Feature Metrics
- `analytics_feature_adoption_rate{feature_name}` - Adoption rate per feature
- `analytics_feature_usage_total{feature_name}` - Total usage count per feature
- `analytics_feature_unique_users{feature_name}` - Unique users per feature

### Experiment Metrics
- `analytics_active_experiments` - Number of active experiments
- `analytics_experiment_conversions{experiment_id,variant}` - Conversions per variant
- `analytics_experiment_conversion_rate{experiment_id,variant}` - Conversion rate per variant
- `analytics_significant_results_total` - Number of significant results

### Segment Metrics
- `analytics_segment_size{segment_name}` - Users per segment
- `analytics_segment_engagement{segment_name}` - Engagement score per segment

### Funnel Metrics
- `analytics_funnel_conversion_rate{funnel_name}` - Overall conversion rate
- `analytics_funnel_step_completion_rate{funnel_name,step}` - Step completion rate
- `analytics_funnel_drop_off_rate{funnel_name,step}` - Step drop-off rate

## Configuration

Environment variables:

- `PLAUSIBLE_URL` - Plausible Analytics URL (default: `http://plausible.fawkes.svc:8000`)
- `EXPERIMENTATION_URL` - Experimentation Service URL (default: `http://experimentation.fawkes.svc:8000`)
- `FEEDBACK_URL` - Feedback Service URL (default: `http://feedback-service.fawkes.svc:8000`)
- `REFRESH_INTERVAL` - Background refresh interval in seconds (default: `300`)
- `CORS_ALLOWED_ORIGINS` - Comma-separated allowed origins

## Deployment

### Kubernetes

```bash
kubectl apply -f platform/apps/analytics-dashboard/
```

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Run service
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Run tests
pytest
```

## Data Flow

1. **Background Refresh**: Service runs background task every 5 minutes to refresh data from all sources
2. **API Request**: When dashboard is accessed, service checks cache first
3. **Cache Hit**: If cache is fresh (<5 minutes), return cached data
4. **Cache Miss**: Fetch data from sources, update cache, return data
5. **Metrics Export**: All metrics continuously exported to Prometheus

## Integration with Grafana

The service exports metrics that can be visualized in Grafana:

```promql
# Example queries
analytics_total_users
analytics_feature_adoption_rate{feature_name="Deploy Application"}
analytics_experiment_conversion_rate{experiment_id="exp-001"}
analytics_funnel_conversion_rate{funnel_name="onboarding"}
```

## Performance

- **Response Time**: <100ms for cached data, <2s for fresh data
- **Cache TTL**: 5 minutes
- **Background Refresh**: Every 5 minutes
- **Concurrent Requests**: Handles 100+ concurrent requests
- **Memory Usage**: ~200MB typical

## Security

- Non-root container execution
- CORS middleware for origin control
- No authentication required for metrics endpoint (Prometheus internal)
- API endpoints accessible from allowed origins only

## Monitoring

### Health Check
```bash
curl http://localhost:8000/health
```

### Metrics
```bash
curl http://localhost:8000/metrics
```

### Logs
```bash
kubectl logs -n fawkes deployment/analytics-dashboard
```

## Troubleshooting

### Service not starting
```bash
# Check logs
kubectl logs -n fawkes deployment/analytics-dashboard

# Check dependencies
kubectl get svc -n fawkes | grep -E "plausible|experimentation|feedback"
```

### No data in dashboard
```bash
# Manually refresh metrics
curl -X POST http://analytics-dashboard.fawkes.svc:8000/api/v1/metrics/refresh

# Check source services
curl http://plausible.fawkes.svc:8000/health
curl http://experimentation.fawkes.svc:8000/health
curl http://feedback-service.fawkes.svc:8000/health
```

### Slow responses
```bash
# Check cache status
# Review Prometheus metrics for data_refresh_duration
```

## Future Enhancements

1. **Real-time Updates**: WebSocket support for live dashboard updates
2. **Custom Dashboards**: User-configurable dashboard layouts
3. **Advanced Filtering**: Complex filtering and drill-down capabilities
4. **Scheduled Reports**: Email reports on schedule
5. **Data Export**: Additional export formats (Excel, PDF)
6. **Alerting**: Threshold-based alerts for key metrics
7. **Predictive Analytics**: ML-based trend predictions
8. **Multi-tenant**: Support for team-specific dashboards

## References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Prometheus Client Python](https://github.com/prometheus/client_python)
- [Plausible Analytics API](https://plausible.io/docs/stats-api)

## License

Part of the Fawkes Internal Delivery Platform
