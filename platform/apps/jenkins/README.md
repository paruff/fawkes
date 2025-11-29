# Jenkins CI/CD Service

## Purpose

Jenkins provides automated build, test, and deployment pipelines for all Fawkes applications. It integrates with Kubernetes for dynamic agent provisioning and ArgoCD for GitOps-based deployment.

## Quick Start

### Prerequisites

Before deploying Jenkins, you must create the admin credentials secret:

```bash
# Create the jenkins-admin secret with your own secure password
kubectl create namespace fawkes
kubectl create secret generic jenkins-admin \
  --from-literal=username=admin \
  --from-literal=password=YOUR_SECURE_PASSWORD \
  -n fawkes
```

> ⚠️ **Security Note**: Never commit actual passwords to version control. The secret files in this directory are templates only.

### Local Development Access

1. **Deploy Jenkins** (via ArgoCD or Helm):
   ```bash
   # Check if Jenkins is running
   kubectl get pods -n fawkes -l app.kubernetes.io/name=jenkins
   ```

2. **Port-forward to access Jenkins UI**:
   ```bash
   kubectl port-forward -n fawkes svc/jenkins 8080:8080
   ```

3. **Get your password**:
   ```bash
   kubectl get secret jenkins-admin -n fawkes -o jsonpath='{.data.password}' | base64 -d
   ```

4. **Access Jenkins**:
   - URL: http://localhost:8080
   - Username: `admin`
   - Password: (from step 3)

### Cloud/Production Access

When ingress is enabled, access Jenkins via:
- URL: `https://jenkins.<your-domain>`
- Credentials managed via External Secrets Operator

## Files

| File | Description |
|------|-------------|
| `values.yaml` | Helm values for standalone deployment |
| `jcasc.yaml` | Jenkins Configuration as Code settings |
| `jenkins-admin-secret.yaml` | **Template** - secret structure (use kubectl to create actual secret) |
| `jenkins-casc-configmap.yaml` | ConfigMap for JCasC configuration |
| `secrets.yaml` | **Template** - example secret structure |

## Credential Management

### For Local Development

Create secrets manually before deploying:

```bash
# Generate a secure random password
JENKINS_PASSWORD=$(openssl rand -base64 24)

# Create the secret
kubectl create secret generic jenkins-admin \
  --from-literal=username=admin \
  --from-literal=password="$JENKINS_PASSWORD" \
  -n fawkes

# Save the password securely
echo "Jenkins admin password: $JENKINS_PASSWORD"
```

### For Production

Use External Secrets Operator to sync credentials from a secure vault:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: jenkins-admin
  namespace: fawkes
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: aws-secrets-manager  # or azure-keyvault, vault, etc.
  target:
    name: jenkins-admin
  data:
    - secretKey: username
      remoteRef:
        key: jenkins/admin/username
    - secretKey: password
      remoteRef:
        key: jenkins/admin/password
```

## Deployment Methods

### Method 1: Via ArgoCD (Recommended)

Jenkins is automatically deployed when ArgoCD syncs the `jenkins-application.yaml`:

```bash
# Ensure secret is created first
kubectl create secret generic jenkins-admin --from-literal=username=admin --from-literal=password=YOUR_PASSWORD -n fawkes

# Verify ArgoCD has synced Jenkins
argocd app get jenkins -n fawkes
```

### Method 2: Direct Helm Installation

```bash
# Add Jenkins Helm repo
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Create secret first
kubectl create secret generic jenkins-admin --from-literal=username=admin --from-literal=password=YOUR_PASSWORD -n fawkes

# Install with local values
helm upgrade --install jenkins jenkins/jenkins \
  -f values.yaml \
  -n fawkes \
  --create-namespace
```

### Method 3: Using deploy-local.sh

```bash
# This script will create the secret automatically with a generated password
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

- **Never commit plaintext passwords** - Use Kubernetes secrets or External Secrets Operator
- Admin password should be rotated regularly in production
- Use RBAC for Jenkins service account with least privilege
- Consider using IRSA (AWS) or Workload Identity (GCP) for cloud access

## Related Documentation

- [Jenkins Documentation](../../docs/tools/jenkins.md)
- [ArgoCD Jenkins Application](../jenkins-application.yaml)
- [External Secrets Configuration](../external-secrets/externalsecret-jenkins-admin.yaml)
