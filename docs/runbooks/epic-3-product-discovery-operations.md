# Epic 3: Product Discovery & UX Operations Runbook

**Version**: 1.0
**Last Updated**: December 2024
**Status**: Production Ready
**Target Audience**: Platform Engineers, Product Teams, UX Researchers, DevEx Engineers

---

## Table of Contents

1. [Overview](#overview)
2. [Component Status Checks](#component-status-checks)
3. [Common Operations](#common-operations)
4. [Troubleshooting](#troubleshooting)
5. [Maintenance Procedures](#maintenance-procedures)
6. [Emergency Response](#emergency-response)
7. [Health Checks](#health-checks)

---

## Overview

This runbook provides operational procedures for the Epic 3 Product Discovery & UX components, including:

- **User Research Infrastructure**: Research repository, personas, journey maps, insights database
- **DevEx Measurement**: SPACE metrics collection, surveys, friction logging, cognitive load assessment
- **Feedback System**: Multi-channel feedback (Backstage widget, CLI tool, Mattermost bot)
- **Design System**: Component library with Storybook, design tokens, accessibility testing
- **Product Analytics**: Event tracking, analytics dashboards, discovery metrics
- **Experimentation**: Feature flags (Unleash), A/B testing framework
- **Continuous Discovery**: Research workflows, usability testing, advisory board
- **Supporting Services**: PostgreSQL databases, NPS surveys, feedback automation

---

## Component Status Checks

### Quick Health Check (All Components)

```bash
# Check all Epic 3 namespaces
kubectl get namespaces | grep -E 'fawkes|fawkes-local'

# Check pod status across all Epic 3 components
kubectl get pods -n fawkes -l epic=3
kubectl get pods -n fawkes-local -l epic=3

# Check all Epic 3 services
kubectl get svc -n fawkes | grep -E 'space-metrics|feedback|unleash'
kubectl get svc -n fawkes-local | grep -E 'space-metrics|feedback'
```

### Individual Component Checks

#### 1. SPACE Metrics Service

```bash
# Check SPACE metrics deployment
kubectl get deployment space-metrics -n fawkes-local
kubectl get pods -n fawkes-local -l app=space-metrics
kubectl get svc space-metrics -n fawkes-local

# Verify database connectivity
kubectl get cluster space-metrics-pg -n fawkes-local

# Check metrics endpoint
kubectl port-forward -n fawkes-local svc/space-metrics 8000:8000 &
curl http://localhost:8000/health
curl http://localhost:8000/api/v1/metrics/space
```

**Expected State**:
- Deployment: 2/2 replicas ready
- Pods: Running
- Service: ClusterIP accessible
- Database: PostgreSQL cluster healthy
- API: Health endpoint returns `{"status": "healthy"}`

#### 2. Feedback Service

```bash
# Check feedback service deployment
kubectl get deployment feedback-service -n fawkes
kubectl get pods -n fawkes -l app=feedback-service
kubectl get svc feedback-service -n fawkes

# Verify database connectivity
kubectl get cluster feedback-db -n fawkes

# Check feedback API endpoints
kubectl port-forward -n fawkes svc/feedback-service 8080:8080 &
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/feedback
```

**Expected State**:
- Deployment: 2/2 replicas ready
- Pods: Running
- Service: ClusterIP accessible
- Database: CloudNativePG cluster healthy
- API: Health endpoint returns `200 OK`

#### 3. Feedback Bot (Mattermost)

```bash
# Check feedback bot deployment
kubectl get deployment feedback-bot -n fawkes
kubectl get pods -n fawkes -l app=feedback-bot
kubectl get configmap feedback-bot-config -n fawkes
kubectl get secret feedback-bot-secret -n fawkes

# Check bot logs
kubectl logs -n fawkes -l app=feedback-bot --tail=50
```

**Expected State**:
- Deployment: 1/1 replicas ready
- Pods: Running
- ConfigMap and Secret: Present
- Logs: No errors, bot connected to Mattermost

#### 4. Feedback Automation (CronJob)

```bash
# Check feedback automation CronJob
kubectl get cronjob feedback-automation -n fawkes
kubectl get jobs -n fawkes -l cronjob=feedback-automation

# View recent job logs
LATEST_JOB=$(kubectl get jobs -n fawkes -l cronjob=feedback-automation --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
kubectl logs -n fawkes job/$LATEST_JOB
```

**Expected State**:
- CronJob: Active, runs hourly
- Jobs: Completed successfully
- Logs: Feedback items processed, GitHub issues created

#### 5. Unleash (Feature Flags)

```bash
# Check Unleash deployment
kubectl get deployment unleash -n fawkes
kubectl get pods -n fawkes -l app=unleash
kubectl get svc unleash -n fawkes

# Verify database
kubectl get cluster db-unleash -n fawkes

# Check Unleash UI
kubectl port-forward -n fawkes svc/unleash 4242:4242 &
curl http://localhost:4242/health
```

**Expected State**:
- Deployment: 2/2 replicas ready
- Pods: Running
- Service: ClusterIP accessible
- Database: PostgreSQL cluster healthy
- UI: Accessible at http://localhost:4242

#### 6. Design System (Storybook)

```bash
# Check Storybook deployment
kubectl get deployment storybook -n fawkes
kubectl get pods -n fawkes -l app=storybook
kubectl get svc storybook -n fawkes
kubectl get ingress storybook -n fawkes

# Check Storybook is serving
kubectl port-forward -n fawkes svc/storybook 6006:80 &
curl http://localhost:6006
```

**Expected State**:
- Deployment: 1/1 replicas ready
- Pods: Running
- Service: ClusterIP accessible
- Ingress: Configured with TLS
- UI: Storybook accessible

#### 7. Product Analytics Platform

```bash
# Check if PostHog/analytics platform is deployed
kubectl get deployment -n fawkes | grep -E 'posthog|analytics'
kubectl get pods -n fawkes -l app.kubernetes.io/name=posthog

# Check analytics ingress
kubectl get ingress -n fawkes | grep -E 'analytics|posthog'
```

**Expected State**:
- Deployment: Running
- Pods: All containers ready
- Ingress: Configured
- UI: Analytics dashboard accessible

---

## Common Operations

### Starting/Stopping Components

#### Scale Down for Maintenance

```bash
# Scale down SPACE metrics service
kubectl scale deployment space-metrics -n fawkes-local --replicas=0

# Scale down feedback service
kubectl scale deployment feedback-service -n fawkes --replicas=0

# Scale down Unleash
kubectl scale deployment unleash -n fawkes --replicas=0
```

#### Scale Up After Maintenance

```bash
# Scale up SPACE metrics service
kubectl scale deployment space-metrics -n fawkes-local --replicas=2

# Scale up feedback service
kubectl scale deployment feedback-service -n fawkes --replicas=2

# Scale up Unleash
kubectl scale deployment unleash -n fawkes --replicas=2
```

### Database Operations

#### Backup SPACE Metrics Database

```bash
# Create backup using CloudNativePG
kubectl cnpg backup space-metrics-pg -n fawkes-local
kubectl get backup -n fawkes-local
```

#### Backup Feedback Database

```bash
# Create backup using CloudNativePG
kubectl cnpg backup feedback-db -n fawkes
kubectl get backup -n fawkes
```

#### Backup Unleash Database

```bash
# Create backup
kubectl cnpg backup db-unleash -n fawkes
kubectl get backup -n fawkes
```

### Configuration Updates

#### Update SPACE Metrics Configuration

```bash
# Edit ConfigMap
kubectl edit configmap space-metrics-config -n fawkes-local

# Restart pods to apply changes
kubectl rollout restart deployment space-metrics -n fawkes-local
```

#### Update Feedback Service Configuration

```bash
# Edit ConfigMap
kubectl edit configmap feedback-service-config -n fawkes

# Restart pods to apply changes
kubectl rollout restart deployment feedback-service -n fawkes
```

#### Update Unleash Configuration

```bash
# Edit ConfigMap
kubectl edit configmap unleash-config -n fawkes

# Restart pods to apply changes
kubectl rollout restart deployment unleash -n fawkes
```

### Monitoring and Metrics

#### View SPACE Metrics Data

```bash
# Port forward to SPACE metrics service
kubectl port-forward -n fawkes-local svc/space-metrics 8000:8000

# Query all SPACE dimensions
curl http://localhost:8000/api/v1/metrics/space | jq .

# Query specific dimensions
curl http://localhost:8000/api/v1/metrics/space/satisfaction | jq .
curl http://localhost:8000/api/v1/metrics/space/performance | jq .
curl http://localhost:8000/api/v1/metrics/space/activity | jq .
curl http://localhost:8000/api/v1/metrics/space/communication | jq .
curl http://localhost:8000/api/v1/metrics/space/efficiency | jq .
```

#### View Feedback Submissions

```bash
# Port forward to feedback service
kubectl port-forward -n fawkes svc/feedback-service 8080:8080

# List all feedback
curl http://localhost:8080/api/v1/feedback | jq .

# Get feedback statistics
curl http://localhost:8080/api/v1/feedback/stats | jq .

# Filter feedback by status
curl 'http://localhost:8080/api/v1/feedback?status=validated' | jq .
```

#### View Prometheus Metrics

```bash
# SPACE metrics Prometheus endpoint
kubectl port-forward -n fawkes-local svc/space-metrics 8000:8000
curl http://localhost:8000/metrics

# Feedback service Prometheus endpoint
kubectl port-forward -n fawkes svc/feedback-service 8080:8080
curl http://localhost:8080/metrics

# Query Prometheus for Epic 3 metrics
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090 and query:
# - space_metrics_*
# - feedback_*
# - unleash_*
```

---

## Troubleshooting

### SPACE Metrics Issues

#### Issue: SPACE metrics service not starting

**Symptoms**: Pods in CrashLoopBackOff

**Diagnosis**:
```bash
kubectl describe pod -n fawkes-local -l app=space-metrics
kubectl logs -n fawkes-local -l app=space-metrics
```

**Common Causes**:
1. Database connection failure
2. Missing environment variables
3. Configuration errors

**Resolution**:
```bash
# Check database status
kubectl get cluster space-metrics-pg -n fawkes-local
kubectl get pods -n fawkes-local -l cnpg.io/cluster=space-metrics-pg

# Check secrets
kubectl get secret space-metrics-db-credentials -n fawkes-local

# Verify ConfigMap
kubectl get configmap space-metrics-config -n fawkes-local -o yaml

# Restart deployment
kubectl rollout restart deployment space-metrics -n fawkes-local
```

#### Issue: No SPACE metrics data being collected

**Symptoms**: API returns empty results

**Diagnosis**:
```bash
kubectl logs -n fawkes-local -l app=space-metrics | grep -i "collect\|error"
```

**Resolution**:
```bash
# Check if data collection jobs are running
kubectl get pods -n fawkes-local -l job=space-metrics-collector

# Verify Prometheus connectivity
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Test connectivity from SPACE metrics pod

# Manually trigger collection
kubectl exec -n fawkes-local -it deployment/space-metrics -- python -c "from app.collectors import collect_all; collect_all()"
```

### Feedback System Issues

#### Issue: Feedback submissions failing

**Symptoms**: 500 errors on POST /api/v1/feedback

**Diagnosis**:
```bash
kubectl logs -n fawkes -l app=feedback-service --tail=100
```

**Common Causes**:
1. Database connection issues
2. Schema migration pending
3. Resource constraints

**Resolution**:
```bash
# Check database
kubectl get cluster feedback-db -n fawkes
kubectl logs -n fawkes -l cnpg.io/cluster=feedback-db

# Run migrations
kubectl exec -n fawkes -it deployment/feedback-service -- flask db upgrade

# Check resource usage
kubectl top pods -n fawkes -l app=feedback-service
```

#### Issue: Feedback bot not responding in Mattermost

**Symptoms**: Bot appears offline or doesn't respond

**Diagnosis**:
```bash
kubectl logs -n fawkes -l app=feedback-bot --tail=50
kubectl describe pod -n fawkes -l app=feedback-bot
```

**Resolution**:
```bash
# Check bot token secret
kubectl get secret feedback-bot-secret -n fawkes -o jsonpath='{.data.MATTERMOST_TOKEN}' | base64 -d

# Verify Mattermost connectivity
kubectl exec -n fawkes -it deployment/feedback-bot -- curl -v https://mattermost.fawkes.local/api/v4/users/me

# Restart bot
kubectl rollout restart deployment feedback-bot -n fawkes
```

#### Issue: Feedback automation not creating GitHub issues

**Symptoms**: CronJob runs but no issues created

**Diagnosis**:
```bash
LATEST_JOB=$(kubectl get jobs -n fawkes -l cronjob=feedback-automation --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
kubectl logs -n fawkes job/$LATEST_JOB
```

**Resolution**:
```bash
# Check GitHub token
kubectl get secret feedback-automation-github -n fawkes -o jsonpath='{.data.GITHUB_TOKEN}' | base64 -d | wc -c

# Verify GitHub API connectivity
kubectl exec -n fawkes -it deployment/feedback-service -- curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user

# Manually trigger job
kubectl create job --from=cronjob/feedback-automation manual-run-$(date +%s) -n fawkes
```

### Unleash (Feature Flags) Issues

#### Issue: Unleash UI not accessible

**Symptoms**: Cannot access Unleash dashboard

**Diagnosis**:
```bash
kubectl get deployment unleash -n fawkes
kubectl get ingress unleash -n fawkes
kubectl logs -n fawkes -l app=unleash
```

**Resolution**:
```bash
# Check ingress configuration
kubectl describe ingress unleash -n fawkes

# Port forward directly to service
kubectl port-forward -n fawkes svc/unleash 4242:4242

# Check database connectivity
kubectl get cluster db-unleash -n fawkes
kubectl logs -n fawkes -l cnpg.io/cluster=db-unleash
```

#### Issue: Feature flags not updating

**Symptoms**: Flag changes in UI not reflected in applications

**Diagnosis**:
```bash
# Check Unleash logs
kubectl logs -n fawkes -l app=unleash

# Check client SDK connectivity
# (from application pod)
curl http://unleash.fawkes.svc.cluster.local:4242/api/client/features
```

**Resolution**:
```bash
# Restart Unleash to clear cache
kubectl rollout restart deployment unleash -n fawkes

# Verify database integrity
kubectl cnpg psql db-unleash -n fawkes -- -c "SELECT * FROM features;"
```

### Design System (Storybook) Issues

#### Issue: Storybook not loading

**Symptoms**: 404 or blank page

**Diagnosis**:
```bash
kubectl logs -n fawkes -l app=storybook
kubectl get ingress storybook -n fawkes
```

**Resolution**:
```bash
# Check if build succeeded
kubectl describe deployment storybook -n fawkes

# Rebuild and redeploy
cd design-system
npm run build-storybook
docker build -f Dockerfile.prebuilt -t storybook:latest .
kubectl rollout restart deployment storybook -n fawkes
```

---

## Maintenance Procedures

### Monthly Maintenance Tasks

#### 1. Database Cleanup (First Monday of Month)

```bash
# Clean up old feedback entries (older than 1 year)
kubectl exec -n fawkes -it deployment/feedback-service -- \
  psql -c "DELETE FROM feedback WHERE created_at < NOW() - INTERVAL '1 year';"

# Vacuum databases
kubectl cnpg psql space-metrics-pg -n fawkes-local -- -c "VACUUM ANALYZE;"
kubectl cnpg psql feedback-db -n fawkes -- -c "VACUUM ANALYZE;"
kubectl cnpg psql db-unleash -n fawkes -- -c "VACUUM ANALYZE;"
```

#### 2. Backup Verification (Second Monday of Month)

```bash
# Verify recent backups exist
kubectl get backup -n fawkes-local | grep space-metrics-pg
kubectl get backup -n fawkes | grep feedback-db
kubectl get backup -n fawkes | grep db-unleash

# Test restore on non-production cluster
# (follow restore procedures in disaster recovery section)
```

#### 3. Security Updates (Third Monday of Month)

```bash
# Check for image vulnerabilities with Trivy
trivy image $(kubectl get deployment space-metrics -n fawkes-local -o jsonpath='{.spec.template.spec.containers[0].image}')
trivy image $(kubectl get deployment feedback-service -n fawkes -o jsonpath='{.spec.template.spec.containers[0].image}')
trivy image $(kubectl get deployment unleash -n fawkes -o jsonpath='{.spec.template.spec.containers[0].image}')

# Update images if vulnerabilities found
# (rebuild images, push to Harbor, update manifests via ArgoCD)
```

#### 4. Metrics Review (Fourth Monday of Month)

```bash
# Review SPACE metrics trends
kubectl port-forward -n fawkes-local svc/space-metrics 8000:8000
curl http://localhost:8000/api/v1/metrics/space | jq .

# Review feedback statistics
kubectl port-forward -n fawkes svc/feedback-service 8080:8080
curl http://localhost:8080/api/v1/feedback/stats | jq .

# Generate monthly report
python scripts/generate-epic3-report.py --month=$(date +%Y-%m)
```

### Quarterly Maintenance Tasks

#### 1. Capacity Planning Review

```bash
# Check resource usage trends
kubectl top pods -n fawkes | grep -E 'space-metrics|feedback|unleash'
kubectl top pods -n fawkes-local | grep space-metrics

# Review Grafana dashboards for capacity metrics
# - Epic 3 Resource Usage
# - SPACE Metrics Performance
# - Feedback System Load
```

#### 2. Journey Map Updates

```bash
# Review and update journey maps based on new insights
cd docs/research/journey-maps

# Update summary with latest pain points
vim 00-SUMMARY.md

# Update individual journey maps as needed
vim 01-developer-onboarding.md
vim 02-deploying-first-app.md
vim 03-debugging-production-issue.md
vim 04-requesting-platform-feature.md
vim 05-contributing-to-platform.md
```

#### 3. Design System Release

```bash
# Update design system version
cd design-system
npm version minor

# Build and publish
npm run build
npm publish

# Update Backstage documentation
npm run build-storybook
kubectl rollout restart deployment storybook -n fawkes
```

---

## Emergency Response

### Incident Response Procedures

#### Severity Definitions

- **SEV-1**: Complete outage of critical feedback system or SPACE metrics
- **SEV-2**: Degraded performance or partial outage
- **SEV-3**: Minor issues not affecting core functionality

#### SEV-1: Critical Outage Response

1. **Initial Response** (0-5 minutes)
   ```bash
   # Check overall cluster health
   kubectl get nodes
   kubectl get pods -A | grep -v Running

   # Identify affected Epic 3 components
   kubectl get pods -n fawkes -l epic=3
   kubectl get pods -n fawkes-local -l epic=3
   ```

2. **Diagnosis** (5-15 minutes)
   ```bash
   # Check recent events
   kubectl get events -n fawkes --sort-by='.lastTimestamp' | tail -20
   kubectl get events -n fawkes-local --sort-by='.lastTimestamp' | tail -20

   # Review logs
   kubectl logs -n fawkes -l epic=3 --tail=100
   kubectl logs -n fawkes-local -l epic=3 --tail=100
   ```

3. **Immediate Mitigation** (15-30 minutes)
   ```bash
   # Rollback to last known good version
   kubectl rollout undo deployment/<component-name> -n fawkes

   # Scale up if resource constraints
   kubectl scale deployment/<component-name> -n fawkes --replicas=3

   # Restart if necessary
   kubectl rollout restart deployment/<component-name> -n fawkes
   ```

4. **Communication**
   - Post incident in #platform-status Mattermost channel
   - Update status page
   - Notify stakeholders

5. **Post-Incident** (After resolution)
   - Document incident in `docs/incidents/`
   - Schedule post-mortem meeting
   - Create remediation action items

### Disaster Recovery

#### Database Restore Procedures

**Restore SPACE Metrics Database**:
```bash
# Stop application to prevent writes
kubectl scale deployment space-metrics -n fawkes-local --replicas=0

# Restore from backup
kubectl cnpg restore space-metrics-pg-restored \
  --backup space-metrics-pg-backup-YYYYMMDD \
  -n fawkes-local

# Verify restore
kubectl cnpg psql space-metrics-pg-restored -n fawkes-local -- -c "SELECT COUNT(*) FROM metrics;"

# Update application to use restored database
kubectl set env deployment/space-metrics -n fawkes-local \
  DATABASE_HOST=space-metrics-pg-restored-rw.fawkes-local.svc.cluster.local

# Scale application back up
kubectl scale deployment space-metrics -n fawkes-local --replicas=2
```

**Restore Feedback Database**:
```bash
# Stop application
kubectl scale deployment feedback-service -n fawkes --replicas=0

# Restore from backup
kubectl cnpg restore feedback-db-restored \
  --backup feedback-db-backup-YYYYMMDD \
  -n fawkes

# Verify and reconnect
kubectl cnpg psql feedback-db-restored -n fawkes -- -c "SELECT COUNT(*) FROM feedback;"
kubectl set env deployment/feedback-service -n fawkes \
  DATABASE_HOST=feedback-db-restored-rw.fawkes.svc.cluster.local

# Scale back up
kubectl scale deployment feedback-service -n fawkes --replicas=2
```

---

## Health Checks

### Automated Health Check Script

Save as `scripts/health-check-epic3.sh`:

```bash
#!/bin/bash
set -e

echo "=== Epic 3 Health Check ==="
echo ""

# SPACE Metrics
echo "1. SPACE Metrics Service"
kubectl get deployment space-metrics -n fawkes-local -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' && echo " replicas ready"
kubectl port-forward -n fawkes-local svc/space-metrics 8000:8000 >/dev/null 2>&1 &
PF_PID=$!
sleep 2
curl -s http://localhost:8000/health | jq -r '.status' && echo " - Health: OK"
kill $PF_PID
echo ""

# Feedback Service
echo "2. Feedback Service"
kubectl get deployment feedback-service -n fawkes -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' && echo " replicas ready"
kubectl port-forward -n fawkes svc/feedback-service 8080:8080 >/dev/null 2>&1 &
PF_PID=$!
sleep 2
curl -s http://localhost:8080/health && echo " - Health: OK"
kill $PF_PID
echo ""

# Feedback Bot
echo "3. Feedback Bot"
kubectl get deployment feedback-bot -n fawkes -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' && echo " replicas ready"
echo ""

# Unleash
echo "4. Unleash (Feature Flags)"
kubectl get deployment unleash -n fawkes -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' && echo " replicas ready"
echo ""

# Storybook
echo "5. Storybook (Design System)"
kubectl get deployment storybook -n fawkes -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' 2>/dev/null && echo " replicas ready" || echo "Not deployed"
echo ""

# Databases
echo "6. Databases"
kubectl get cluster -n fawkes-local space-metrics-pg -o jsonpath='{.status.phase}' && echo " - space-metrics-pg"
kubectl get cluster -n fawkes feedback-db -o jsonpath='{.status.phase}' && echo " - feedback-db"
kubectl get cluster -n fawkes db-unleash -o jsonpath='{.status.phase}' && echo " - db-unleash"
echo ""

echo "=== Health Check Complete ==="
```

Usage:
```bash
chmod +x scripts/health-check-epic3.sh
./scripts/health-check-epic3.sh
```

---

## Appendix

### Related Documentation

- [Epic 3 Architecture Diagrams](epic-3-architecture-diagrams.md)
- [Epic 3 API Reference](../reference/api/epic-3-product-discovery-apis.md)
- [AT-E3-002 SPACE Framework Validation](../validation/AT-E3-002-IMPLEMENTATION.md)
- [AT-E3-003 Feedback System Validation](../validation/AT-E3-003-IMPLEMENTATION.md)
- [AT-E3-004/005/009 Design System Validation](../validation/AT-E3-004-005-009-IMPLEMENTATION.md)

### Contact Information

- **Platform Team**: #platform-team on Mattermost
- **On-Call**: PagerDuty rotation
- **Product Team**: #product-team on Mattermost
- **UX Team**: #ux-research on Mattermost

### Useful Links

- [SPACE Metrics Dashboard](https://grafana.fawkes.local/d/space-metrics)
- [Feedback Analytics Dashboard](https://grafana.fawkes.local/d/feedback-analytics)
- [Unleash UI](https://unleash.fawkes.local)
- [Storybook](https://storybook.fawkes.local)
- [Product Analytics](https://analytics.fawkes.local)
