---
title: DORA Metrics Service Deployment Checklist
description: Step-by-step checklist for deploying and validating the DORA metrics collection service
---

# DORA Metrics Service Deployment Checklist

## Overview

This checklist ensures the DORA Metrics Service (DevLake) is properly deployed and functional in the Fawkes platform.

**Estimated Time**: 30-45 minutes
**Prerequisites**: Kubernetes cluster, ArgoCD, External Secrets Operator

---

## Pre-Deployment Checklist

### Infrastructure Requirements

- [ ] Kubernetes cluster running (1.28+)
- [ ] At least 3 worker nodes available
- [ ] 20Gi of storage available for MySQL
- [ ] Ingress controller deployed (nginx recommended)
- [ ] cert-manager deployed (for TLS)

### Dependencies

- [ ] ArgoCD deployed and healthy
- [ ] External Secrets Operator deployed
- [ ] Prometheus and Grafana stack deployed
- [ ] Vault or cloud secrets manager configured

### Access Requirements

- [ ] Cluster admin kubectl access
- [ ] GitHub personal access token (for data collection)
- [ ] Jenkins API token (optional, for CI metrics)
- [ ] ArgoCD API access configured

---

## Deployment Steps

### 1. Create Secrets

**External Secrets Method (Recommended)**:

- [ ] Create secret in Vault/AWS Secrets Manager:

  ```bash
  # Example for Vault
  vault kv put secret/fawkes/devlake \
    encryption-secret=$(openssl rand -base64 32) \
    mysql-root-password=$(openssl rand -base64 32) \
    mysql-password=$(openssl rand -base64 32) \
    grafana-admin-password=$(openssl rand -base64 32) \
    github-token=ghp_your_token_here \
    api-token=$(openssl rand -base64 32)
  ```

- [ ] Verify ExternalSecret exists:

  ```bash
  kubectl get externalsecret -n fawkes devlake-secrets
  kubectl get externalsecret -n fawkes devlake-db
  kubectl get externalsecret -n fawkes devlake-grafana-secrets
  ```

- [ ] Verify secrets are synced:
  ```bash
  kubectl get secret -n fawkes devlake-secrets
  kubectl get secret -n fawkes devlake-db
  kubectl get secret -n fawkes devlake-grafana-secrets
  ```

**Manual Secrets Method (Development Only)**:

- [ ] Create DevLake secrets manually:

  ```bash
  kubectl create secret generic devlake-secrets -n fawkes \
    --from-literal=encryption-secret=$(openssl rand -base64 32) \
    --from-literal=api-token=$(openssl rand -base64 32)

  kubectl create secret generic devlake-db -n fawkes \
    --from-literal=mysql-root-password=$(openssl rand -base64 32) \
    --from-literal=mysql-password=$(openssl rand -base64 32)

  kubectl create secret generic devlake-grafana-secrets -n fawkes \
    --from-literal=admin-password=$(openssl rand -base64 32)
  ```

### 2. Deploy DevLake via ArgoCD

- [ ] Apply ArgoCD Application:

  ```bash
  kubectl apply -f platform/apps/devlake/devlake-application.yaml
  ```

- [ ] Verify Application is created:

  ```bash
  kubectl get application devlake -n fawkes
  ```

- [ ] Check Application status:

  ```bash
  argocd app get devlake
  # Expected: Health Status: Healthy, Sync Status: Synced
  ```

- [ ] If not synced, manually sync:
  ```bash
  argocd app sync devlake
  ```

### 3. Verify Pod Deployment

- [ ] Check all pods are running:

  ```bash
  kubectl get pods -n fawkes -l app.kubernetes.io/name=devlake
  ```

  Expected pods:

  - devlake-lake-0 (Running)
  - devlake-ui-0 (Running)
  - devlake-grafana-0 (Running)
  - devlake-mysql-0 (Running)

- [ ] Check pod logs for errors:

  ```bash
  kubectl logs -n fawkes -l app.kubernetes.io/component=lake --tail=50
  kubectl logs -n fawkes -l app.kubernetes.io/component=mysql --tail=50
  ```

- [ ] Verify no CrashLoopBackOff or Error states:
  ```bash
  kubectl get pods -n fawkes -l app.kubernetes.io/name=devlake -o jsonpath='{.items[*].status.phase}'
  # Expected: All "Running"
  ```

### 4. Verify Services

- [ ] Check services are created:

  ```bash
  kubectl get svc -n fawkes -l app.kubernetes.io/name=devlake
  ```

  Expected services:

  - devlake-lake (ClusterIP)
  - devlake-ui (ClusterIP)
  - devlake-grafana (ClusterIP)
  - devlake-mysql (ClusterIP)

- [ ] Test internal connectivity:
  ```bash
  kubectl run -it --rm debug --image=alpine --restart=Never -n fawkes -- \
    wget -O- http://devlake-lake:8080/api/ping
  # Expected: {"message":"pong"}
  ```

### 5. Verify Ingress

- [ ] Check ingress resources:

  ```bash
  kubectl get ingress -n fawkes devlake
  kubectl get ingress -n fawkes devlake-grafana
  ```

- [ ] Test external access (if DNS configured):

  ```bash
  curl http://devlake.127.0.0.1.nip.io/api/ping
  curl http://devlake-grafana.127.0.0.1.nip.io/api/health
  ```

- [ ] Or use port-forward for testing:
  ```bash
  kubectl port-forward -n fawkes svc/devlake-lake 8080:8080
  # Test: curl http://localhost:8080/api/ping
  ```

---

## Database Schema Verification

### 6. Verify Database Creation

- [ ] Connect to MySQL:

  ```bash
  # Get root password first
  MYSQL_ROOT_PASSWORD=$(kubectl get secret devlake-db -n fawkes -o jsonpath='{.data.mysql-root-password}' | base64 -d)

  # Connect to MySQL
  kubectl exec -it -n fawkes devlake-mysql-0 -- mysql -u root -p
  # Enter the password when prompted
  ```

- [ ] Verify database exists:

  ```sql
  SHOW DATABASES;
  -- Expected: 'lake' database listed
  ```

- [ ] Verify key tables exist:

  ```sql
  USE lake;
  SHOW TABLES;
  ```

  Expected tables:

  - deployments
  - commits
  - incidents
  - cicd_deployments
  - project_metric_settings
  - dora_benchmarks

- [ ] Check table schemas:

  ```sql
  DESCRIBE deployments;
  DESCRIBE commits;
  DESCRIBE incidents;
  ```

- [ ] Verify indexes:
  ```sql
  SHOW INDEX FROM deployments;
  SHOW INDEX FROM commits;
  ```

---

## API Endpoints Verification

### 7. Test REST API

- [ ] Health check:

  ```bash
  curl http://devlake.127.0.0.1.nip.io/api/ping
  # Expected: {"message":"pong"}
  ```

- [ ] Get API version:

  ```bash
  curl http://devlake.127.0.0.1.nip.io/api/version
  ```

- [ ] Test authenticated endpoint (requires token):
  ```bash
  API_TOKEN=$(kubectl get secret devlake-api-token -n fawkes -o jsonpath='{.data.token}' | base64 -d)
  curl -H "Authorization: Bearer $API_TOKEN" \
    http://devlake.127.0.0.1.nip.io/api/projects
  ```

### 8. Test GraphQL API

- [ ] GraphQL introspection query:

  ```bash
  curl -X POST http://devlake.127.0.0.1.nip.io/api/graphql \
    -H "Content-Type: application/json" \
    -d '{"query":"{ __schema { types { name } } }"}'
  ```

- [ ] Test DORA metrics query (after data collection):
  ```bash
  curl -X POST http://devlake.127.0.0.1.nip.io/api/graphql \
    -H "Content-Type: application/json" \
    -d '{"query":"query { projects { name } }"}'
  ```

### 9. Test Prometheus Metrics Endpoint

- [ ] Verify metrics endpoint:

  ```bash
  curl http://devlake.127.0.0.1.nip.io/metrics
  ```

- [ ] Check for DORA metrics (may be empty initially):

  ```bash
  curl http://devlake.127.0.0.1.nip.io/metrics | grep dora
  ```

  Expected metrics (after data collection):

  - dora_deployment_frequency_total
  - dora_lead_time_seconds
  - dora_change_failure_rate
  - dora_mttr_seconds

---

## Prometheus Integration

### 10. Deploy ServiceMonitor

- [ ] Apply ServiceMonitor:

  ```bash
  kubectl apply -f platform/apps/devlake/servicemonitor-devlake.yaml
  ```

- [ ] Verify ServiceMonitor exists:

  ```bash
  kubectl get servicemonitor devlake-metrics -n monitoring
  ```

- [ ] Check Prometheus targets:

  ```bash
  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
  # Open http://localhost:9090/targets
  # Search for "devlake"
  # Expected: Target "devlake-metrics" is UP
  ```

- [ ] Query DORA metrics in Prometheus (after data collection):
  ```promql
  dora_deployment_frequency_total
  dora_lead_time_seconds_bucket
  dora_change_failure_rate
  dora_mttr_seconds_bucket
  ```

---

## Data Source Configuration

### 11. Configure GitHub Data Source

- [ ] Access DevLake UI:

  ```bash
  # Open http://devlake.127.0.0.1.nip.io
  ```

- [ ] Add GitHub connection:

  - Click "Data Connections"
  - Click "Add Connection"
  - Select "GitHub"
  - Enter:
    - Name: "GitHub - Fawkes"
    - Endpoint: https://api.github.com
    - Token: (from secrets)
  - Click "Test Connection"
  - Click "Save"

- [ ] Configure repository scope:
  - Add repository: paruff/fawkes
  - Enable: Commits, Pull Requests, Code Review

### 12. Configure ArgoCD Data Source

- [ ] Add ArgoCD connection:

  - Click "Add Connection"
  - Select "ArgoCD"
  - Enter:
    - Name: "ArgoCD - Fawkes"
    - Endpoint: http://argocd-server.fawkes.svc
    - Token: (ArgoCD API token)
  - Click "Test Connection"
  - Click "Save"

- [ ] Configure application scope:
  - Add all applications or specific projects
  - Enable sync event collection

### 13. Configure Jenkins Data Source (Optional)

- [ ] Add Jenkins connection:
  - Click "Add Connection"
  - Select "Jenkins"
  - Enter:
    - Name: "Jenkins - Fawkes"
    - Endpoint: http://jenkins.fawkes.svc
    - Username: admin
    - Token: (Jenkins API token)
  - Click "Test Connection"
  - Click "Save"

### 14. Configure Webhook for Incidents

- [ ] Enable webhook plugin in DevLake UI

- [ ] Get webhook URL:

  ```bash
  echo "http://devlake.127.0.0.1.nip.io/api/plugins/webhook/1/incidents"
  ```

- [ ] Configure observability platform to send incidents to webhook

---

## Grafana Dashboard Verification

### 15. Access Grafana

- [ ] Get Grafana admin password:

  ```bash
  kubectl get secret devlake-grafana-secrets -n fawkes \
    -o jsonpath='{.data.admin-password}' | base64 -d
  ```

- [ ] Access Grafana UI:
  ```bash
  # Open http://devlake-grafana.127.0.0.1.nip.io
  # Login: admin / <password from above>
  ```

### 16. Verify DORA Dashboards

- [ ] Check pre-installed dashboards:

  - Navigate to Dashboards → Browse
  - Look for "DORA Metrics" dashboards

- [ ] Verify dashboard folders:

  - DORA Metrics Overview
  - Deployment Frequency
  - Lead Time for Changes
  - Change Failure Rate
  - Mean Time to Restore

- [ ] Test dashboard filtering:
  - Select project/team
  - Change time range
  - Verify data loads (may be empty initially)

---

## Automated Verification

### 17. Run Verification Script

- [ ] Execute automated verification:

  ```bash
  ./scripts/verify-dora-metrics-service.sh
  ```

- [ ] Review verification results:

  - All checks should pass
  - Address any failures before proceeding

- [ ] Save verification output:
  ```bash
  ./scripts/verify-dora-metrics-service.sh > /tmp/dora-verification-$(date +%Y%m%d).log
  ```

---

## Post-Deployment Configuration

### 18. Configure DORA Metric Settings

- [ ] Set project-specific configurations in DevLake UI

- [ ] Configure deployment frequency window (default: 7 days)

- [ ] Configure lead time stages:

  - Development
  - Review
  - Production

- [ ] Configure CFR window (default: 30 days)

- [ ] Configure MTTR severity levels

### 19. Test Data Collection

- [ ] Trigger a test deployment via ArgoCD

- [ ] Wait 5-10 minutes for data collection

- [ ] Query deployment via API:

  ```bash
  curl http://devlake.127.0.0.1.nip.io/api/deployments
  ```

- [ ] Check data in database:

  ```sql
  SELECT * FROM deployments ORDER BY created_at DESC LIMIT 5;
  ```

- [ ] Verify metrics update in Grafana

---

## Acceptance Criteria Validation

### 20. Verify Acceptance Criteria

- [ ] **DORA metrics service deployed**: All DevLake pods running
- [ ] **Database schema created**: All tables exist with correct structure
- [ ] **API endpoints functional**: REST, GraphQL, and metrics endpoints respond
- [ ] **Metrics exposed to Prometheus**: ServiceMonitor created, metrics scraped

### 21. Run BDD Tests

- [ ] Execute BDD tests for DORA metrics:

  ```bash
  cd tests/bdd
  pytest features/devlake-dora-metrics.feature
  ```

- [ ] Verify all scenarios pass:
  - Data ingestion from ArgoCD
  - Data ingestion from Jenkins
  - Deployment frequency calculation
  - Lead time calculation
  - Change failure rate calculation
  - MTTR calculation
  - Dashboard access

---

## Documentation Updates

### 22. Update Documentation

- [ ] Update platform architecture documentation with deployment details

- [ ] Document any custom configurations made

- [ ] Add troubleshooting notes if issues encountered

- [ ] Update runbooks with operational procedures

---

## Sign-off

### 23. Final Checklist

- [ ] All pods are running and healthy
- [ ] Database schema is complete
- [ ] All API endpoints are functional
- [ ] Prometheus is scraping metrics
- [ ] Data sources are configured
- [ ] Grafana dashboards are accessible
- [ ] Automated verification passed
- [ ] BDD tests passed
- [ ] Documentation updated

**Deployed by**: **\*\*\*\***\_**\*\*\*\***
**Date**: **\*\*\*\***\_**\*\*\*\***
**Verified by**: **\*\*\*\***\_**\*\*\*\***
**Date**: **\*\*\*\***\_**\*\*\*\***

---

## Troubleshooting

### Common Issues

**Issue**: Pods stuck in Pending state

- **Solution**: Check PVC status, ensure storage class exists
  ```bash
  kubectl get pvc -n fawkes
  kubectl describe pvc devlake-mysql -n fawkes
  ```

**Issue**: Database connection errors

- **Solution**: Verify MySQL pod is running, check credentials
  ```bash
  kubectl logs -n fawkes devlake-lake-0 | grep mysql
  kubectl get secret devlake-db -n fawkes -o yaml
  ```

**Issue**: API endpoints return 404

- **Solution**: Check ingress configuration, verify routes
  ```bash
  kubectl describe ingress devlake -n fawkes
  kubectl get endpoints -n fawkes devlake-lake
  ```

**Issue**: Prometheus not scraping

- **Solution**: Verify ServiceMonitor, check Prometheus logs
  ```bash
  kubectl logs -n monitoring prometheus-kube-prometheus-prometheus-0 | grep devlake
  ```

---

## Rollback Procedure

If deployment fails and needs rollback:

1. Delete ArgoCD Application:

   ```bash
   kubectl delete application devlake -n fawkes
   ```

2. Clean up resources:

   ```bash
   kubectl delete namespace fawkes-devlake
   ```

3. Remove secrets (if manually created):

   ```bash
   kubectl delete secret devlake-secrets -n fawkes
   kubectl delete secret devlake-db -n fawkes
   kubectl delete secret devlake-grafana-secrets -n fawkes
   ```

4. Address issues and retry deployment

---

## Related Documentation

- [DORA Metrics Service README](../platform/apps/devlake/README.md)
- [DORA Metrics API Reference](../docs/reference/dora-metrics-api.md)
- [Database Schema Documentation](../docs/reference/dora-metrics-database-schema.md)
- [ADR-016: DevLake DORA Strategy](../docs/adr/ADR-016%20devlake-dora-strategy.md)
- [Architecture: DORA Metrics Service](../docs/architecture.md#6-dora-metrics-service)
