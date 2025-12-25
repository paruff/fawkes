# DataHub Ingestion Configuration

This directory contains DataHub metadata ingestion recipes and automated ingestion jobs for the Fawkes platform.

## Overview

Automated metadata ingestion is configured for:
- **PostgreSQL databases** (Backstage, Harbor, SonarQube) - Daily at 2 AM UTC
- **Kubernetes resources** (Deployments, Services, ConfigMaps, etc.) - Hourly
- **GitHub repositories** and **Jenkins jobs** - Every 6 hours

## Files

### Ingestion Recipes

- `postgres.yaml` - PostgreSQL database ingestion recipe
  - Backstage developer portal database
  - Harbor container registry database
  - SonarQube code quality database

- `kubernetes.yaml` - Kubernetes resources ingestion recipe
  - Deployments, StatefulSets, Services
  - ConfigMaps, Secrets, Ingresses
  - Links to Backstage components via annotations

- `github-jenkins.yaml` - Git and CI/CD ingestion recipe
  - GitHub repositories, branches, commits, PRs
  - Jenkins jobs, builds, pipelines
  - Pipeline lineage tracking

### Automated Ingestion (CronJobs)

- `cronjob-postgres-ingestion.yaml` - Daily PostgreSQL ingestion
- `cronjob-kubernetes-ingestion.yaml` - Hourly Kubernetes ingestion
- `cronjob-git-ci-ingestion.yaml` - 6-hourly Git/CI ingestion

## Prerequisites

1. **DataHub deployed and running**
   ```bash
   kubectl get pods -n fawkes -l app.kubernetes.io/name=datahub
   ```

2. **DataHub CLI installed** (for manual ingestion)
   ```bash
   pip install 'acryl-datahub[all]'
   ```

3. **Credentials configured**
   - PostgreSQL credentials in Kubernetes Secrets
   - GitHub personal access token (for GitHub ingestion)
   - Jenkins API token (for Jenkins ingestion)

## Manual Ingestion

To manually run ingestion (useful for testing):

### PostgreSQL Ingestion

```bash
# Set environment variables for credentials
export POSTGRES_BACKSTAGE_USER="backstage_user"
export POSTGRES_BACKSTAGE_PASSWORD="your-password"

# Run ingestion
datahub ingest -c platform/apps/datahub/ingestion/postgres.yaml
```

### Kubernetes Ingestion

```bash
# Ensure kubectl is configured
kubectl cluster-info

# Run ingestion
datahub ingest -c platform/apps/datahub/ingestion/kubernetes.yaml
```

### GitHub and Jenkins Ingestion

```bash
# Set environment variables
export GITHUB_TOKEN="your-github-token"
export JENKINS_USER="admin"
export JENKINS_TOKEN="your-jenkins-token"

# Run ingestion
datahub ingest -c platform/apps/datahub/ingestion/github-jenkins.yaml
```

## Automated Ingestion (CronJobs)

CronJobs are automatically deployed via ArgoCD and run on the following schedules:

| Source | Schedule | Description |
|--------|----------|-------------|
| PostgreSQL | Daily at 2 AM UTC | Ingest database schemas and metadata |
| Kubernetes | Every hour at :15 | Ingest cluster resources |
| Git/CI | Every 6 hours at :30 | Ingest repos and pipelines |

### Check CronJob Status

```bash
# List all ingestion CronJobs
kubectl get cronjobs -n fawkes -l component=ingestion

# View recent job runs
kubectl get jobs -n fawkes -l component=ingestion --sort-by=.metadata.creationTimestamp

# Check logs of most recent job
LATEST_JOB=$(kubectl get jobs -n fawkes -l component=ingestion,source=postgres --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
kubectl logs -n fawkes job/$LATEST_JOB
```

### Manually Trigger a CronJob

```bash
# Trigger PostgreSQL ingestion
kubectl create job --from=cronjob/datahub-postgres-ingestion -n fawkes manual-postgres-$(date +%s)

# Trigger Kubernetes ingestion
kubectl create job --from=cronjob/datahub-kubernetes-ingestion -n fawkes manual-k8s-$(date +%s)

# Trigger Git/CI ingestion
kubectl create job --from=cronjob/datahub-git-ci-ingestion -n fawkes manual-git-ci-$(date +%s)
```

## Configuration

### Update Database Credentials

Edit the Secret in `cronjob-postgres-ingestion.yaml`:

```bash
kubectl edit secret datahub-postgres-ingestion-credentials -n fawkes
```

### Update GitHub/Jenkins Credentials

Edit the Secret in `cronjob-git-ci-ingestion.yaml`:

```bash
kubectl edit secret datahub-git-ci-ingestion-credentials -n fawkes
```

### Modify Ingestion Schedules

Edit the `schedule` field in the respective CronJob manifest:

```yaml
spec:
  schedule: "0 2 * * *"  # Cron format: minute hour day month weekday
```

Common schedules:
- Daily at 2 AM: `0 2 * * *`
- Every hour: `0 * * * *`
- Every 6 hours: `0 */6 * * *`
- Twice daily: `0 2,14 * * *`

## Verify Ingestion

### Check DataHub UI

1. Open DataHub: http://datahub.127.0.0.1.nip.io
2. Search for ingested entities
3. Verify metadata is present

### Query via GraphQL API

```bash
# Search for PostgreSQL datasets
curl -X POST http://datahub.127.0.0.1.nip.io/api/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ search(input: {type: DATASET, query: \"backstage\", start: 0, count: 10}) { total searchResults { entity { urn ... on Dataset { name description } } } } }"
  }'

# Search for Kubernetes resources
curl -X POST http://datahub.127.0.0.1.nip.io/api/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ search(input: {type: DATASET, query: \"kubernetes\", start: 0, count: 10}) { total } }"
  }'
```

### Check Ingestion Status via CLI

```bash
# List recent ingestion runs
datahub get --urn "urn:li:dataJob:(urn:li:dataFlow:(datahub,postgres-backstage-daily-ingestion,PROD),ingestion)"
```

## Troubleshooting

### Ingestion Job Fails

```bash
# Check job status
kubectl describe job <job-name> -n fawkes

# View pod logs
kubectl logs -n fawkes -l job-name=<job-name>

# Check events
kubectl get events -n fawkes --sort-by='.lastTimestamp' | grep datahub-ingestion
```

### DataHub Not Accessible

```bash
# Check DataHub GMS health
kubectl exec -it -n fawkes deployment/datahub-datahub-gms -- curl -f http://localhost:8080/health

# Check DataHub pods
kubectl get pods -n fawkes -l app.kubernetes.io/name=datahub
```

### Database Connection Issues

```bash
# Test database connectivity from ingestion pod
kubectl run -it --rm debug --image=postgres:16 --restart=Never -n fawkes -- \
  psql -h db-backstage-dev-rw.fawkes.svc.cluster.local -U backstage_user -d backstage_db -c '\dt'
```

### GitHub/Jenkins Authentication Issues

- Verify tokens are valid and not expired
- Check token has required permissions:
  - GitHub: `repo` scope
  - Jenkins: API access enabled
- Update credentials in Secrets

## Metadata Lineage

The ingestion recipes automatically extract and visualize lineage:

1. **Database-to-Service**: Links database tables to services that use them
2. **Repo-to-Pipeline**: Links GitHub repos to Jenkins build jobs
3. **Pipeline-to-Artifact**: Links Jenkins builds to container images
4. **Service-to-K8s**: Links Backstage components to Kubernetes resources

View lineage in DataHub UI by navigating to any entity and clicking the "Lineage" tab.

## DORA Metrics Integration

Jenkins ingestion extracts DORA metrics:
- **Deployment Frequency**: From deployment jobs
- **Lead Time for Changes**: From commit to deployment
- **Change Failure Rate**: From rollback/hotfix jobs
- **Mean Time to Recovery**: From failure to recovery

View DORA metrics in Grafana dashboards or query via DataHub API.

## Best Practices

1. **Start with PostgreSQL** - It's the most stable source
2. **Test manually first** - Run `datahub ingest` manually before relying on CronJobs
3. **Monitor ingestion** - Set up alerts for failed jobs
4. **Keep credentials secure** - Use External Secrets Operator in production
5. **Review lineage** - Regularly check that lineage is accurate
6. **Clean up stale metadata** - Stateful ingestion is enabled to remove old entities

## Resources

- [DataHub Documentation](https://datahubproject.io/docs/)
- [PostgreSQL Source](https://datahubproject.io/docs/metadata-ingestion/integration_docs/postgres)
- [Kubernetes Source](https://datahubproject.io/docs/metadata-ingestion/integration_docs/kubernetes)
- [GitHub Source](https://datahubproject.io/docs/metadata-ingestion/integration_docs/github)
- [Jenkins Source](https://datahubproject.io/docs/metadata-ingestion/integration_docs/jenkins)
