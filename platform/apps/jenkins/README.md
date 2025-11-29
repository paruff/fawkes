# Jenkins CI/CD Service

## Purpose

Jenkins provides automated build, test, and deployment pipelines for all Fawkes applications. It integrates with Kubernetes for dynamic agent provisioning and ArgoCD for GitOps-based deployment.

## Quick Start

### Local Development Access

1. **Ensure Jenkins is deployed** (via ArgoCD or Helm):
   ```bash
   # Check if Jenkins is running
   kubectl get pods -n fawkes -l app.kubernetes.io/name=jenkins
   ```

2. **Port-forward to access Jenkins UI**:
   ```bash
   kubectl port-forward -n fawkes svc/jenkins 8080:8080
   ```

3. **Access Jenkins**:
   - URL: http://localhost:8080
   - Username: `admin`
   - Password: `fawkesidp`

### Cloud/Production Access

When ingress is enabled, access Jenkins via:
- URL: `https://jenkins.<your-domain>`
- Credentials managed via External Secrets Operator

## Files

| File | Description |
|------|-------------|
| `values.yaml` | Helm values for standalone deployment |
| `jcasc.yaml` | Jenkins Configuration as Code settings |
| `jenkins-admin-secret.yaml` | Example secret for admin credentials |
| `jenkins-casc-configmap.yaml` | ConfigMap for JCasC configuration |

## Deployment Methods

### Method 1: Via ArgoCD (Recommended)

Jenkins is automatically deployed when ArgoCD syncs the `jenkins-application.yaml`:

```bash
# Verify ArgoCD has synced Jenkins
argocd app get jenkins -n fawkes
```

### Method 2: Direct Helm Installation

```bash
# Add Jenkins Helm repo
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Install with local values
helm upgrade --install jenkins jenkins/jenkins \
  -f values.yaml \
  -n fawkes \
  --create-namespace
```

### Method 3: Using deploy-local.sh

```bash
# Deploy Jenkins to local cluster
./infra/local-dev/deploy-local.sh fawkes jenkins
```

## Configuration

### Kubernetes Plugin

Jenkins uses the Kubernetes plugin for dynamic agent provisioning:
- Agents are created on-demand in the `fawkes` namespace
- Agents are automatically cleaned up after builds
- Multiple agent templates available (default, maven, etc.)

### Plugin List

Pre-installed plugins:
- `kubernetes` - Dynamic agent provisioning
- `workflow-aggregator` - Pipeline support
- `git` - Git integration
- `configuration-as-code` - JCasC support
- `credentials-binding` - Secure credential handling
- `github` - GitHub integration
- `blueocean` - Modern UI
- `pipeline-stage-view` - Pipeline visualization

### JCasC (Configuration as Code)

Jenkins is configured via JCasC. Main configuration in `jcasc.yaml`:
- Security realm (local users)
- Authorization strategy
- Kubernetes cloud configuration
- Agent templates

## Troubleshooting

### Pod not starting

```bash
# Check pod status
kubectl describe pod -n fawkes -l app.kubernetes.io/name=jenkins

# Check logs
kubectl logs -n fawkes -l app.kubernetes.io/name=jenkins
```

### Cannot access UI

```bash
# Verify service is running
kubectl get svc -n fawkes jenkins

# Check port-forward is working
kubectl port-forward -n fawkes svc/jenkins 8080:8080 --address=0.0.0.0
```

### Plugins not installing

Check the init container logs:
```bash
kubectl logs -n fawkes -l app.kubernetes.io/name=jenkins -c init
```

## DORA Metrics

Jenkins integration with DORA metrics:
- Deployment Frequency tracking
- Lead Time for Changes measurement
- Build failure notifications
- Pipeline duration metrics

## Security Considerations

- Admin password should be rotated in production
- Use External Secrets Operator for credential management
- Enable RBAC for Jenkins service account
- Consider using IRSA (AWS) or Workload Identity (GCP) for cloud access

## Related Documentation

- [Jenkins Documentation](../../docs/tools/jenkins.md)
- [ArgoCD Jenkins Application](../jenkins-application.yaml)
- [External Secrets Configuration](../external-secrets/externalsecret-jenkins-admin.yaml)