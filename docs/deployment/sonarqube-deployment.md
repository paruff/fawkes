# SonarQube Deployment Guide

## Overview

This guide covers the deployment and configuration of SonarQube for code quality and security analysis on the Fawkes platform.

## Prerequisites

Before deploying SonarQube, ensure the following components are running:

- [x] Kubernetes cluster with at least 4GB RAM and 2 CPU cores available
- [x] ArgoCD installed and configured
- [x] PostgreSQL operator (CloudNativePG) deployed
- [x] Ingress NGINX controller installed
- [x] Cert-manager for TLS (optional but recommended)
- [x] Persistent storage provisioner

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Developer Workflow                           │
│                                                                   │
│  Git Commit → Jenkins Pipeline → SonarQube Analysis → Quality Gate
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                     SonarQube Platform                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Web UI     │  │   Compute    │  │   Search     │          │
│  │   (Java)     │  │   Engine     │  │   (ES)       │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                           │                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    PostgreSQL                             │  │
│  │              (db-sonarqube-dev cluster)                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Deployment Steps

### Step 1: Deploy PostgreSQL Database

The PostgreSQL database cluster for SonarQube is already defined in the repository.

**Files**:
- `platform/apps/postgresql/db-sonarqube-cluster.yaml` - PostgreSQL cluster definition
- `platform/apps/postgresql/db-sonarqube-credentials.yaml` - Database credentials

**Verify PostgreSQL Deployment**:
```bash
# Check if PostgreSQL operator is running
kubectl get pods -n cloudnativepg-system

# Check if SonarQube database cluster is deployed
kubectl get cluster -n fawkes db-sonarqube-dev

# Verify cluster is ready
kubectl get cluster -n fawkes db-sonarqube-dev -o jsonpath='{.status.phase}'
# Expected output: Cluster in healthy state
```

**Database Details**:
- **Cluster Name**: `db-sonarqube-dev`
- **Namespace**: `fawkes`
- **Database**: `sonarqube`
- **User**: `sonarqube_user`
- **Instances**: 3 (1 primary + 2 replicas)
- **Storage**: 20Gi per instance
- **Connection String**: `jdbc:postgresql://db-sonarqube-dev-rw.fawkes.svc.cluster.local:5432/sonarqube`

**⚠️ Security Note**: Change the default password in `db-sonarqube-credentials.yaml` before deploying to production!

### Step 2: Deploy SonarQube via ArgoCD

The SonarQube application is defined as an ArgoCD Application manifest.

**File**: `platform/apps/sonarqube-application.yaml`

**Apply the ArgoCD Application**:
```bash
# Apply the SonarQube application
kubectl apply -f platform/apps/sonarqube-application.yaml

# Verify ArgoCD application is created
kubectl get application -n fawkes sonarqube

# Watch the synchronization
kubectl get application -n fawkes sonarqube -w
```

**Alternative: Deploy via ArgoCD UI**:
1. Open ArgoCD UI
2. Click **+ New App**
3. Application Name: `sonarqube`
4. Project: `default`
5. Sync Policy: `Automatic`
6. Repository URL: `https://charts.sonarsource.com`
7. Chart: `sonarqube`
8. Target Revision: `2025.1.0`
9. Cluster: `https://kubernetes.default.svc`
10. Namespace: `fawkes`
11. Values: Copy from `sonarqube-application.yaml`

### Step 3: Verify Deployment

**Check Pod Status**:
```bash
# Wait for SonarQube pod to be ready (can take 2-3 minutes)
kubectl get pods -n fawkes -l app=sonarqube

# Check pod logs
kubectl logs -n fawkes -l app=sonarqube --tail=50 -f

# Expected in logs:
# "SonarQube is operational"
# "Process[web] is up"
```

**Check Service**:
```bash
# Verify service is created
kubectl get svc -n fawkes -l app=sonarqube

# Expected output:
# NAME        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
# sonarqube   ClusterIP   10.x.x.x        <none>        9000/TCP   xm
```

**Check Ingress**:
```bash
# Verify ingress is created
kubectl get ingress -n fawkes -l app=sonarqube

# Check ingress details
kubectl describe ingress -n fawkes sonarqube
```

### Step 4: Access SonarQube UI

**Local Development**:
```bash
# Access via ingress
http://sonarqube.127.0.0.1.nip.io

# Or port-forward if ingress is not working
kubectl port-forward -n fawkes svc/sonarqube 9000:9000

# Then access at http://localhost:9000
```

**Production**:
```
https://sonarqube.fawkes.idp
```

**Default Credentials**:
- Username: `admin`
- Password: `admin`

**⚠️ Important**: Change the admin password immediately after first login!

### Step 5: Initial Configuration

#### 5.1 Change Admin Password

1. Login with default credentials
2. Click on **Administrator** avatar (top right)
3. Go to **My Account** → **Security**
4. Enter new password
5. Save changes

#### 5.2 Generate Authentication Token for Jenkins

```bash
# Via UI:
# 1. Go to My Account → Security → Generate Tokens
# 2. Name: "jenkins-scanner"
# 3. Type: "Project Analysis Token" or "Global Analysis Token"
# 4. Click "Generate"
# 5. Copy the token (you won't see it again!)

# Via API:
SONAR_PASSWORD="your-new-admin-password"
curl -u admin:${SONAR_PASSWORD} \
  -X POST \
  "http://sonarqube.fawkes.svc:9000/api/user_tokens/generate?name=jenkins-scanner"

# Save the token output for Jenkins configuration
```

#### 5.3 Configure Jenkins Integration

**Add Token to Jenkins**:
```bash
# Via Jenkins UI:
# 1. Jenkins → Manage Jenkins → Manage Credentials
# 2. Select domain: (global)
# 3. Add Credentials → Secret text
# 4. Secret: <paste token>
# 5. ID: "sonarqube-token"
# 6. Description: "SonarQube Scanner Token"

# Via Jenkins Configuration as Code (JCasC):
# Already configured in jenkins-casc-configmap.yaml
```

**Configure SonarQube Server in Jenkins**:
```groovy
// Already configured in Jenkins Shared Library
withSonarQubeEnv('SonarQube') {
    // SonarQube server URL: http://sonarqube.fawkes.svc:9000
    // Scanner authentication via token
}
```

#### 5.4 Create Quality Profiles

See [quality-profiles.md](../../platform/apps/sonarqube/quality-profiles.md) for detailed instructions.

**Quick Setup**:
1. Navigate to **Quality Profiles** in SonarQube UI
2. Create custom profiles for each language:
   - `Fawkes Java` (parent: Sonar way)
   - `Fawkes Python` (parent: Sonar way)
   - `Fawkes JavaScript` (parent: Sonar way)
3. Activate additional security and quality rules
4. Set each as default for its language

#### 5.5 Configure Quality Gate

The default Quality Gate "Sonar way" is sufficient, but you can customize:

```bash
# Create custom Quality Gate via API
curl -u admin:${SONAR_PASSWORD} \
  -X POST \
  "http://sonarqube.fawkes.svc:9000/api/qualitygates/create?name=Fawkes%20Gate"

# Add conditions (example: no new bugs)
curl -u admin:${SONAR_PASSWORD} \
  -X POST \
  "http://sonarqube.fawkes.svc:9000/api/qualitygates/create_condition?gateName=Fawkes%20Gate&metric=new_bugs&op=GT&error=0"

# Set as default
curl -u admin:${SONAR_PASSWORD} \
  -X POST \
  "http://sonarqube.fawkes.svc:9000/api/qualitygates/set_as_default?name=Fawkes%20Gate"
```

Or configure via UI:
1. Navigate to **Quality Gates**
2. Click **Create**
3. Name: `Fawkes Gate`
4. Add conditions as per [ADR-014](../adr/ADR-014%20sonarqube%20quality%20gates.md)
5. Set as default

### Step 6: Test Integration with Jenkins

**Create Test Project**:
```bash
# Use a golden path template to create a test service
# From Backstage UI:
# 1. Create Component → Select Java/Python/Node.js template
# 2. Fill in details
# 3. Create

# Or manually create a simple project with Jenkinsfile
```

**Trigger Jenkins Build**:
```bash
# Push code to trigger Jenkins pipeline
git commit -m "Test SonarQube integration"
git push

# Monitor Jenkins build
# Should see "SonarQube Analysis" stage execute successfully
# Should see "Quality Gate" stage check results
```

**Verify in SonarQube**:
```bash
# Check project appears in SonarQube UI
# Navigate to Projects
# Should see your test project listed with analysis results
```

## Configuration Details

### Resource Limits

**SonarQube Pod**:
- Requests: 500m CPU, 2Gi memory
- Limits: 2 CPU, 4Gi memory

**PostgreSQL Cluster**:
- Requests: 500m CPU, 512Mi memory per instance
- Limits: 2 CPU, 2Gi memory per instance
- Storage: 20Gi per instance (total 60Gi for 3 instances)

### Persistence

**SonarQube Data**:
- Volume: PersistentVolumeClaim
- Storage Class: `standard`
- Size: 10Gi
- Access Mode: ReadWriteOnce

**PostgreSQL Data**:
- Managed by CloudNativePG operator
- Automated backups (configure in production)
- Point-in-time recovery capability

### Security

**Pod Security Context**:
- Non-root user: UID/GID 1000
- fsGroup: 1000
- Read-only root filesystem: false (SonarQube writes to temp dirs)
- Capabilities dropped: ALL
- Seccomp profile: RuntimeDefault

**Network**:
- Internal service: ClusterIP
- External access: Via Ingress with TLS
- Database connection: Internal service, TLS optional

**Secrets Management**:
- Database credentials: Kubernetes secrets (dev/local)
- Admin credentials: Manual change required
- Scanner tokens: Jenkins credentials store
- Production: Use External Secrets Operator with Vault

### Plugins

The following plugins are pre-installed:
- sonar-scm-git-plugin (Git integration)
- sonar-jacoco-plugin (Java code coverage)
- sonar-findbugs-plugin (SpotBugs integration)
- checkstyle-sonar-plugin (Java code style)
- sonar-yaml-plugin (Infrastructure as Code analysis)

See `sonarqube-application.yaml` for plugin URLs and versions.

## Monitoring

### Prometheus Integration

**ServiceMonitor**:
```yaml
# Already configured in sonarqube-application.yaml
prometheusMonitoring:
  podMonitor:
    enabled: true
    namespace: fawkes
    interval: 30s
```

**Key Metrics**:
- `sonarqube_health_status` - Overall health
- `sonarqube_compute_engine_tasks` - Background task queue
- `sonarqube_database_pool_active_connections` - DB connections

**View Metrics**:
```bash
# Port-forward to SonarQube
kubectl port-forward -n fawkes svc/sonarqube 9000:9000

# Access metrics endpoint
curl http://localhost:9000/api/monitoring/metrics
```

### Health Checks

**Liveness Probe**:
- Path: `/api/system/liveness`
- Initial Delay: 90 seconds
- Period: 30 seconds

**Readiness Probe**:
- Path: `/api/system/health`
- Initial Delay: 90 seconds
- Period: 30 seconds

**Check Health**:
```bash
# Via API
curl http://sonarqube.fawkes.svc:9000/api/system/health

# Expected response: {"health":"GREEN","causes":[]}
```

## Troubleshooting

### Pod Not Starting

**Symptoms**: Pod stuck in `CrashLoopBackOff` or `Pending`

**Solutions**:
```bash
# Check pod events
kubectl describe pod -n fawkes -l app=sonarqube

# Check logs
kubectl logs -n fawkes -l app=sonarqube --previous

# Common issues:
# 1. Insufficient memory - increase resources
# 2. PostgreSQL not ready - wait for DB cluster to be healthy
# 3. PVC not bound - check storage provisioner
```

### Database Connection Failed

**Symptoms**: Logs show "Can't connect to database"

**Solutions**:
```bash
# Verify PostgreSQL cluster is healthy
kubectl get cluster -n fawkes db-sonarqube-dev

# Check PostgreSQL logs
kubectl logs -n fawkes db-sonarqube-dev-1

# Test database connection
kubectl exec -it -n fawkes db-sonarqube-dev-1 -- psql -U sonarqube_user -d sonarqube -c "SELECT version();"

# Verify credentials match
kubectl get secret -n fawkes db-sonarqube-credentials -o yaml
```

### Ingress Not Working

**Symptoms**: Can't access SonarQube UI via ingress

**Solutions**:
```bash
# Check ingress status
kubectl get ingress -n fawkes sonarqube

# Verify ingress controller is running
kubectl get pods -n ingress-nginx

# Test service directly
kubectl port-forward -n fawkes svc/sonarqube 9000:9000
# Access http://localhost:9000

# Check ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### Quality Gate Timeout

**Symptoms**: Jenkins pipeline times out waiting for Quality Gate

**Solutions**:
```bash
# Increase timeout in Jenkinsfile
timeout(time: 10, unit: 'MINUTES') {
    waitForQualityGate abortPipeline: true
}

# Check SonarQube compute engine
curl -u admin:${SONAR_PASSWORD} \
  "http://sonarqube.fawkes.svc:9000/api/ce/activity"

# Restart SonarQube pod if compute engine is stuck
kubectl rollout restart deployment -n fawkes sonarqube
```

### High Memory Usage

**Symptoms**: Pod using more memory than allocated

**Solutions**:
```bash
# Check current usage
kubectl top pod -n fawkes -l app=sonarqube

# Adjust JVM heap settings in sonarqube-application.yaml:
sonarProperties:
  sonar.web.javaAdditionalOpts: "-Xms512m -Xmx2g"
  sonar.ce.javaAdditionalOpts: "-Xms512m -Xmx2g"

# Increase pod limits
resources:
  limits:
    memory: 6Gi  # Increase from 4Gi
```

## Backup and Recovery

### Database Backup

**Automated Backups** (configure in production):
```yaml
# Edit db-sonarqube-cluster.yaml
backup:
  barmanObjectStore:
    destinationPath: s3://fawkes-db-backups/sonarqube/
    s3Credentials:
      accessKeyId:
        name: db-backup-credentials
        key: ACCESS_KEY_ID
      secretAccessKey:
        name: db-backup-credentials
        key: SECRET_ACCESS_KEY
    wal:
      compression: gzip
  retentionPolicy: "30d"
```

**Manual Backup**:
```bash
# Export database
kubectl exec -it -n fawkes db-sonarqube-dev-1 -- \
  pg_dump -U sonarqube_user -d sonarqube > sonarqube-backup.sql

# Backup quality profiles
curl -u admin:${SONAR_PASSWORD} \
  "http://sonarqube.fawkes.svc:9000/api/qualityprofiles/backup?language=java" \
  > fawkes-java-profile.xml
```

### Restore

```bash
# Restore database
cat sonarqube-backup.sql | \
  kubectl exec -i -n fawkes db-sonarqube-dev-1 -- \
  psql -U sonarqube_user -d sonarqube

# Restore quality profiles
curl -u admin:${SONAR_PASSWORD} \
  -X POST \
  -F "backup=@fawkes-java-profile.xml" \
  "http://sonarqube.fawkes.svc:9000/api/qualityprofiles/restore"
```

## Upgrade

### Upgrading SonarQube

```bash
# Update targetRevision in sonarqube-application.yaml
# Example: 2025.1.0 → 2025.2.0

# Apply changes
kubectl apply -f platform/apps/sonarqube-application.yaml

# ArgoCD will sync automatically
# Monitor upgrade
kubectl get pods -n fawkes -l app=sonarqube -w

# Verify new version
curl http://sonarqube.fawkes.svc:9000/api/system/status
```

### Database Migration

SonarQube automatically migrates the database schema on startup if needed.

**Monitor Migration**:
```bash
# Check logs for migration
kubectl logs -n fawkes -l app=sonarqube --tail=100 -f

# Look for:
# "Executing DB migrations..."
# "DB migration | success"
```

## Maintenance

### Housekeeping

**Clean Old Analysis**:
```bash
# Via UI: Administration → Projects → Management → Bulk Deletion

# Or via API (delete analyses older than 90 days)
curl -u admin:${SONAR_PASSWORD} \
  -X POST \
  "http://sonarqube.fawkes.svc:9000/api/projects/bulk_delete?analyzedBefore=2024-09-01"
```

### Reindexing

If search is slow or not working:
```bash
# Trigger reindex
curl -u admin:${SONAR_PASSWORD} \
  -X POST \
  "http://sonarqube.fawkes.svc:9000/api/system/restart"

# Monitor logs
kubectl logs -n fawkes -l app=sonarqube -f
```

## Resources

- [SonarQube Documentation](https://docs.sonarqube.org/)
- [SonarQube Helm Chart](https://artifacthub.io/packages/helm/sonarqube/sonarqube)
- [CloudNativePG Documentation](https://cloudnative-pg.io/)
- [Fawkes ADR-014: SonarQube Quality Gates](../adr/ADR-014%20sonarqube%20quality%20gates.md)
- [Quality Profiles Guide](../../platform/apps/sonarqube/quality-profiles.md)
- [Jenkins Integration](../../platform/apps/jenkins/README.md)

## Next Steps

1. [Configure SSO/OAuth](https://docs.sonarqube.org/latest/instance-administration/authentication/) for developer access
2. [Set up PR decoration](https://docs.sonarqube.org/latest/analysis/pr-decoration/) for inline feedback
3. [Configure webhooks](https://docs.sonarqube.org/latest/project-administration/webhooks/) for external integrations
4. [Enable automated backups](https://cloudnative-pg.io/documentation/1.20/backup/) for PostgreSQL
5. [Configure alerts](https://docs.sonarqube.org/latest/project-administration/project-notifications/) for quality gate failures
