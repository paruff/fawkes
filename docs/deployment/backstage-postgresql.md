# Backstage Deployment Guide

## Overview

This guide covers deploying Backstage Developer Portal with PostgreSQL backend to the Fawkes platform using GitOps with ArgoCD.

## Prerequisites

- Kubernetes cluster (1.28+) running
- ArgoCD installed and configured
- kubectl configured with cluster access
- CloudNativePG operator will be deployed automatically

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Backstage Frontend                        │
│                   (React SPA + Node.js)                       │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│                    Backstage Backend API                      │
│                  (Node.js + TypeScript)                       │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│              PostgreSQL HA Cluster (3 replicas)               │
│                   (CloudNativePG Operator)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │
│  │ Primary  │  │ Standby  │  │ Standby  │                   │
│  │  (RW)    │  │  (RO)    │  │  (RO)    │                   │
│  └──────────┘  └──────────┘  └──────────┘                   │
└──────────────────────────────────────────────────────────────┘
```

## Deployment Components

### 1. PostgreSQL Database (CloudNativePG)

**Manifests:**
- `platform/apps/postgresql/cloudnativepg-operator-application.yaml` - CloudNativePG operator
- `platform/apps/postgresql/db-backstage-credentials.yaml` - Database credentials
- `platform/apps/postgresql/db-backstage-cluster.yaml` - HA PostgreSQL cluster (3 replicas)

**Resources:**
- Database: `backstage_db`
- User: `backstage_user`
- Storage: 20Gi per instance
- CPU: 500m request, 2 CPU limit
- Memory: 512Mi request, 2Gi limit

**High Availability:**
- 3 instances (1 primary, 2 standby replicas)
- Automated failover (30 second delay)
- Pod anti-affinity across nodes
- Read-write service: `db-backstage-dev-rw.fawkes.svc.cluster.local:5432`
- Read-only service: `db-backstage-dev-ro.fawkes.svc.cluster.local:5432`

### 2. Backstage Application

**Manifests:**
- `platform/apps/backstage-application.yaml` - ArgoCD Application
- `platform/apps/backstage/app-config.yaml` - Backstage configuration (ConfigMap)
- `platform/apps/backstage/secrets.yaml` - OAuth and integration secrets

**Resources:**
- Replicas: 2 (HA configuration)
- CPU: 500m request, 2 CPU limit
- Memory: 512Mi request, 2Gi limit
- Ingress: `https://backstage.fawkes.idp`

**Integrations:**
- GitHub OAuth for authentication
- GitHub API for repository discovery
- Jenkins for CI/CD status
- ArgoCD for deployment status
- Kubernetes for resource monitoring
- Prometheus for metrics

### 3. Initial Catalog

**Manifests:**
- `catalog-info.yaml` - Root platform catalog

**Catalog Contents:**
- Platform system and domain definitions
- Platform team group
- Core components (Backstage, ArgoCD, Jenkins, Prometheus, Grafana, SonarQube)
- PostgreSQL database resource
- Software template locations

### 4. Software Templates

**Templates:**
- `templates/python-service/template.yaml` - Python FastAPI microservice
- `templates/java-service/template.yaml` - Java Spring Boot microservice
- `templates/nodejs-service/template.yaml` - Node.js Express microservice

Each template includes:
- Service scaffolding with best practices
- Dockerfile and Kubernetes manifests
- CI/CD pipeline configuration
- Automatic catalog registration
- Documentation templates

## Deployment Steps

### Step 0: Prerequisites - Configure GitHub OAuth (REQUIRED)

Before deploying Backstage, you must configure GitHub OAuth authentication. Without this, users won't be able to login.

**Quick Setup:**

1. Create a GitHub OAuth App:
   - Go to: https://github.com/settings/developers (personal) or
   - Go to: https://github.com/organizations/YOUR_ORG/settings/applications (organization)
   - Click "New OAuth App"
   - Fill in:
     - **Application name**: `Fawkes Backstage - Development` (or Production)
     - **Homepage URL**: `https://backstage.fawkes.idp`
     - **Authorization callback URL**: `https://backstage.fawkes.idp/api/auth/github/handler/frame`
   - Copy the **Client ID**
   - Generate and copy the **Client Secret**

2. Update the secrets file:
   ```bash
   vim platform/apps/backstage/secrets.yaml
   ```
   
   Replace these lines:
   ```yaml
   github-client-id: CHANGE_ME_github_oauth_client_id
   github-client-secret: CHANGE_ME_github_oauth_client_secret
   ```
   
   With your actual values:
   ```yaml
   github-client-id: "your-actual-client-id"
   github-client-secret: "your-actual-client-secret"
   ```

3. Apply the secret:
   ```bash
   kubectl apply -f platform/apps/backstage/secrets.yaml
   ```

**For detailed OAuth setup instructions, see**: [GitHub OAuth Setup Guide](../how-to/security/github-oauth-setup.md)

### Step 1: Update Secrets

### Step 1: Update Additional Secrets

In addition to GitHub OAuth (configured in Step 0), you need to update other integration secrets:

```bash
# Edit PostgreSQL credentials
vim platform/apps/postgresql/db-backstage-credentials.yaml
# Change: CHANGE_ME_backstage_password

# Edit Backstage integration secrets
vim platform/apps/backstage/secrets.yaml
# Update:
# - GitHub personal access token (for repo integration)
# - ArgoCD credentials (optional)
# - Jenkins credentials (optional)
```

**Note**: GitHub OAuth credentials (client-id and client-secret) should already be configured from Step 0.

**Security Note:** For production, use External Secrets Operator with Vault instead of storing secrets in Git.

### Step 2: Deploy via ArgoCD

The platform uses the App-of-Apps pattern. Deploy the root application:

```bash
# Apply the bootstrap application
kubectl apply -f platform/bootstrap/app-of-apps.yaml

# Wait for ArgoCD to sync all applications
argocd app wait platform-bootstrap --sync
```

This will automatically deploy in order:
1. CloudNativePG operator (sync-wave: -5)
2. PostgreSQL clusters (sync-wave: -4)
3. Backstage application (sync-wave: 5)

### Step 3: Monitor Deployment

```bash
# Check ArgoCD applications
argocd app list

# Watch PostgreSQL cluster come up
kubectl get cluster -n fawkes db-backstage-dev -w

# Watch Backstage pods
kubectl get pods -n fawkes -l app.kubernetes.io/name=backstage -w
```

### Step 4: Access Backstage UI

```bash
# For local development with port-forward:
kubectl port-forward -n fawkes svc/backstage 7007:7007

# Access at: http://localhost:7007

# For production with ingress:
# Access at: https://backstage.fawkes.idp
```

### Step 5: Verify Catalog Population

Expected catalog entities:
- System: fawkes-platform
- Domain: platform-engineering
- Group: platform-team
- Components: backstage, argocd, jenkins, prometheus, grafana, sonarqube
- Resource: db-backstage-dev
- Templates: python-service, java-service, nodejs-service

## Verification

### Check Deployment Status

```bash
# ArgoCD application status
argocd app get backstage

# Kubernetes resources
kubectl get all -n fawkes -l app.kubernetes.io/name=backstage

# Health check
curl http://localhost:7007/healthcheck
```

### Run BDD Acceptance Tests

```bash
# Run Backstage deployment tests
behave tests/bdd/features/backstage-deployment.feature
```

## Troubleshooting

### Common Issues

**Issue:** Backstage pods in CrashLoopBackOff

**Solution:** Check database connection. Ensure PostgreSQL cluster is healthy first.

```bash
# Verify database is ready
kubectl wait --for=condition=ready cluster/db-backstage-dev -n fawkes --timeout=300s
```

**Issue:** Catalog not populating

**Solution:** Check GitHub token has correct permissions and repository is accessible.

```bash
# Force catalog refresh
kubectl exec -n fawkes deployment/backstage -- \
  curl -X POST http://localhost:7007/api/catalog/refresh
```

## Related Documentation

- [Backstage Official Documentation](https://backstage.io/docs)
- [CloudNativePG Documentation](https://cloudnative-pg.io/documentation/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
