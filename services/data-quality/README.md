# Great Expectations Data Quality Service

This service provides automated data quality validation and monitoring for Fawkes platform databases using Great Expectations.

## Overview

The data quality service validates data in the following databases:
- **Backstage**: Developer portal catalog data
- **Harbor**: Container registry metadata
- **DataHub**: Data catalog metadata
- **DORA Metrics**: Deployment and performance metrics
- **SonarQube**: Code quality and analysis data

## Architecture

### Components

1. **Great Expectations Core**: Data validation framework
2. **Expectation Suites**: Validation rules for each database
3. **Checkpoints**: Automated validation runners
4. **Alerting**: Mattermost integration for failure notifications
5. **CronJob**: Scheduled validation runs (every 6 hours)
6. **Prometheus Exporter**: Metrics exporter for monitoring and dashboards

### Directory Structure

```
services/data-quality/
├── gx/                           # Great Expectations configuration
│   ├── great_expectations.yml    # Main config
│   ├── datasources.yml           # Database connections
│   └── uncommitted/              # Runtime files (not in git)
├── expectations/                 # Validation rules
│   ├── backstage_db_suite.json
│   ├── harbor_db_suite.json
│   ├── datahub_db_suite.json
│   ├── dora_metrics_suite.json
│   └── sonarqube_db_suite.json
├── checkpoints/                  # Validation runners
│   ├── backstage_db_checkpoint.yml
│   ├── harbor_db_checkpoint.yml
│   ├── datahub_db_checkpoint.yml
│   ├── dora_metrics_checkpoint.yml
│   ├── sonarqube_db_checkpoint.yml
│   └── all_databases_checkpoint.yml
├── scripts/                      # Helper scripts
│   ├── alert_handler.py          # Mattermost alerting
│   └── run_checkpoint.py         # Checkpoint runner
└── prometheus-exporter.py        # Prometheus metrics exporter
```

## Expectation Suites

### Backstage Database (`backstage_db_suite.json`)
Validates:
- Row counts within expected range
- Required columns exist
- Primary key (entity_id) is not null and unique
- Entity references are not null

### Harbor Database (`harbor_db_suite.json`)
Validates:
- Artifact row counts
- Required columns (id, digest, size, timestamps)
- Primary key uniqueness
- Size values within reasonable range (0-10GB)
- Referential integrity

### DataHub Database (`datahub_db_suite.json`)
Validates:
- Metadata row counts
- Required columns (urn, aspect, version)
- URN format follows DataHub standards
- Aspect and version are not null

### DORA Metrics (`dora_metrics_suite.json`)
Validates:
- Metrics data exists
- Timestamp column exists and is valid
- Data freshness (latest data is recent)
- Completeness of time-series data
- Metric type enumeration (deployment_frequency, lead_time, change_failure_rate, mttr)
- Value type and range validation

### SonarQube Database (`sonarqube_db_suite.json`)
Validates:
- Project row counts
- Required columns (uuid, kee, name, timestamps)
- Primary key uniqueness
- UUID format validation
- Project key (kee) uniqueness
- Timestamp validity
- Data freshness

## Deployment

### Kubernetes Resources

The service is deployed using ArgoCD with the following resources:

```yaml
platform/apps/data-quality/
├── data-quality-application.yaml  # ArgoCD Application
├── configmap.yaml                 # Configuration
├── secret.yaml                    # Credentials
├── serviceaccount.yaml            # RBAC
├── service.yaml                   # Service endpoint
├── cronjob.yaml                   # Scheduled validation
└── kustomization.yaml             # Kustomize config
```

### Environment Variables

From ConfigMap:
- `ALERT_ON_FAILURE`: Enable failure alerts (default: true)
- `ALERT_ON_WARNING`: Enable warning alerts (default: false)
- `SEND_DAILY_SUMMARY`: Enable daily summary (default: true)

From Secrets:
- `POSTGRES_USER`: PostgreSQL username
- `POSTGRES_PASSWORD`: PostgreSQL password
- `BACKSTAGE_DB_CONNECTION_STRING`: Backstage DB connection
- `HARBOR_DB_CONNECTION_STRING`: Harbor DB connection
- `DATAHUB_DB_CONNECTION_STRING`: DataHub DB connection
- `MATTERMOST_WEBHOOK_URL`: Webhook for alerts

## Usage

### Running Checkpoints Manually

To run a specific checkpoint:

```bash
# Run from within the data-quality pod
cd /app
python3 scripts/run_checkpoint.py backstage_db_checkpoint --json
```

To run all database checkpoints:

```bash
python3 scripts/run_checkpoint.py all_databases_checkpoint --json
```

### Viewing Results

Data Docs are generated after each validation run. Access them:

```bash
# Port-forward to the data-quality service
kubectl port-forward -n fawkes svc/data-quality 8080:8080

# Open in browser
open http://localhost:8080
```

### Testing Locally

```bash
cd services/data-quality

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export BACKSTAGE_DB_CONNECTION_STRING="postgresql://user:pass@localhost:5432/backstage"
export HARBOR_DB_CONNECTION_STRING="postgresql://user:pass@localhost:5432/registry"
# ... etc

# Run checkpoint
python3 scripts/run_checkpoint.py backstage_db_checkpoint
```

## Alerting

### Mattermost Integration

The service sends alerts to Mattermost on validation failures:

- **Failure Alert**: Sent when any expectation fails
- **Daily Summary**: Summary of all validations (optional)

Alert format:
```
## 🚨 Data Quality Validation Failed

**Suite:** backstage_db_suite
**Time:** 2024-12-21 18:00:00 UTC
**Status:** ❌ Failed

**Results:**
- Total Expectations: 10
- Successful: ✅ 7
- Failed: ❌ 3

**Details:** [View Data Docs](http://data-docs-url)
```

### Configuring Alerts

Update the Mattermost webhook URL in the secret:

```bash
kubectl edit secret data-quality-secrets -n fawkes
```

## Monitoring

### Prometheus Metrics

The data quality service exposes metrics for Prometheus monitoring via a dedicated exporter:

#### Available Metrics

- **`data_quality_validation_success`** (gauge): Success status of last validation (1=success, 0=failure)
  - Labels: datasource, suite, checkpoint
- **`data_quality_validation_duration_seconds`** (histogram): Duration of validation runs
  - Labels: datasource, suite, checkpoint
- **`data_quality_expectation_failures_total`** (counter): Total count of failed expectations
  - Labels: datasource, suite, expectation_type, checkpoint
- **`data_quality_data_freshness_seconds`** (gauge): Seconds since last validation per datasource
  - Labels: datasource, suite
- **`data_quality_validation_runs_total`** (counter): Total number of validation runs
  - Labels: datasource, suite, checkpoint, status
- **`data_quality_expectations_total`** (gauge): Total number of expectations evaluated
  - Labels: datasource, suite, checkpoint
- **`data_quality_expectations_successful`** (gauge): Number of successful expectations
  - Labels: datasource, suite, checkpoint
- **`data_quality_success_rate_percent`** (gauge): Percentage of successful expectations
  - Labels: datasource, suite, checkpoint

#### Accessing Metrics

The Prometheus exporter runs as a separate deployment and exposes metrics on port 9110:

```bash
# Port-forward to the exporter
kubectl port-forward -n fawkes deployment/data-quality-exporter 9110:9110

# View metrics
curl http://localhost:9110/metrics

# Check health
curl http://localhost:9110/health
```

#### ServiceMonitor

Prometheus automatically scrapes metrics via the ServiceMonitor configuration:

```bash
kubectl get servicemonitor data-quality-exporter -n fawkes
```

### Grafana Dashboard

A comprehensive Grafana dashboard is available for visualizing data quality metrics:

**Dashboard Location**: `platform/apps/grafana/dashboards/data-quality.json`

**Dashboard Features**:
- Overall data quality score (% passing)
- Validation pass/fail summary
- Validation status by datasource
- Failed expectations breakdown
- Data freshness by datasource
- Historical trends (7 and 30 day views)
- Alert annotations

**Accessing the Dashboard**:

1. Import the dashboard in Grafana:
   ```bash
   # Via Grafana UI
   # Dashboard > Import > Upload JSON file
   # Select: platform/apps/grafana/dashboards/data-quality.json
   ```

2. Or access via URL (if auto-imported):
   ```
   http://grafana.local/d/data-quality/data-quality-dashboard
   ```

**Dashboard Variables**:
- `datasource`: Filter by specific datasource(s)
- `suite`: Filter by specific expectation suite(s)

### CronJob Schedule

The CronJob runs every 6 hours by default:
```
0 */6 * * *
```

To change the schedule, edit `platform/apps/data-quality/cronjob.yaml`.

### Job History

View recent job runs:

```bash
# List jobs
kubectl get jobs -n fawkes -l app=data-quality

# View job logs
kubectl logs -n fawkes job/data-quality-validation-<timestamp>

# Check job status
kubectl describe job -n fawkes data-quality-validation-<timestamp>
```

## Validation Script (AT-E2-004)

The acceptance test validation is implemented in:
```
scripts/validate-at-e2-004.sh
```

Run the validation:

```bash
make validate-at-e2-004
```

Or directly:

```bash
./scripts/validate-at-e2-004.sh --namespace fawkes
```

## Troubleshooting

### Database Connection Issues

1. **Check secrets are set correctly**:
   ```bash
   kubectl get secret data-quality-secrets -n fawkes -o yaml
   ```

2. **Verify database connectivity**:
   ```bash
   kubectl run -it --rm debug --image=postgres:15 --restart=Never -n fawkes -- \
     psql "postgresql://app:changeme@db-backstage-rw.fawkes.svc.cluster.local:5432/backstage" -c "SELECT 1"
   ```

3. **Check pod logs**:
   ```bash
   kubectl logs -n fawkes -l app=data-quality
   ```

### Checkpoint Failures

1. **Review the specific failure**:
   ```bash
   python3 scripts/run_checkpoint.py backstage_db_checkpoint --json | jq
   ```

2. **Check data docs** for detailed failure information

3. **Verify expectation suite** matches actual database schema

### Alert Issues

1. **Test Mattermost webhook**:
   ```bash
   curl -X POST $MATTERMOST_WEBHOOK_URL \
     -H 'Content-Type: application/json' \
     -d '{"text": "Test alert from data quality service"}'
   ```

2. **Check alert handler logs** in job output

## Adding New Validations

### 1. Create Expectation Suite

```bash
cd services/data-quality
# Create new suite JSON file
vim expectations/new_db_suite.json
```

### 2. Create Checkpoint

```bash
# Create checkpoint YAML
vim checkpoints/new_db_checkpoint.yml
```

### 3. Add to Kustomization

Update `platform/apps/data-quality/kustomization.yaml` to include new files in ConfigMap.

### 4. Update CronJob (Optional)

Add new checkpoint to the validation job or create a separate job.

## References

- [Great Expectations Documentation](https://docs.greatexpectations.io/)
- [Fawkes Architecture](../../docs/architecture.md)
- [AT-E2-004 Acceptance Test](../../docs/implementation-plan/fawkes-handoff-doc.md)
- [Issue #47](https://github.com/paruff/fawkes/issues/47)

## Support

For issues or questions:
- Check troubleshooting section above
- Review Great Expectations docs
- Open an issue in the Fawkes repository
