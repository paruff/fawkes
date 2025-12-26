# ArgoCD Terraform Module

## Overview

This Terraform module deploys ArgoCD to a Kubernetes cluster via Helm. ArgoCD provides GitOps continuous delivery for managing applications declaratively.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              ArgoCD Deployment (argocd namespace)            │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              ArgoCD Server (UI & API)                  │ │
│  │  - Ingress: argocd.127.0.0.1.nip.io                    │ │
│  │  - Service: ClusterIP                                   │ │
│  │  - Insecure mode (HTTP) for local dev                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                          │                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │           ArgoCD Application Controller                │ │
│  │  - Monitors Git repositories                           │ │
│  │  - Syncs application state to cluster                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                          │                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              ArgoCD Repo Server                        │ │
│  │  - Fetches manifests from Git                          │ │
│  │  - Renders Helm charts and Kustomize                   │ │
│  └────────────────────────────────────────────────────────┘ │
│                          │                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                  Redis Cache                           │ │
│  │  - Caches repo metadata and manifests                  │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Files

- **main.tf**: Main Terraform configuration with Helm release
- **variables.tf**: Input variables
- **outputs.tf**: Output values (admin password, release name)
- **values.yaml**: Helm values for ArgoCD configuration
- **README.md**: This file

## Usage

### Prerequisites

- Kubernetes cluster (local or cloud)
- kubectl configured with cluster access
- Terraform >= 1.3.0
- Helm >= 2.7.0

### Via ignite.sh (Recommended)

The `ignite.sh` script handles ArgoCD deployment automatically:

```bash
# Set kubeconfig path
export KUBECONFIG=~/.kube/config

# Deploy ArgoCD (and entire platform)
bash ./scripts/ignite.sh local
```

### Direct Terraform Deployment

```bash
# Navigate to module directory
cd infra/terraform/argocd

# Initialize Terraform
terraform init

# Set kubeconfig path
export TF_VAR_kubeconfig_path=~/.kube/config

# Plan deployment
terraform plan

# Apply deployment
terraform apply

# Get admin password
terraform output -raw argocd_admin_password
```

### With Custom Values

```bash
# Create terraform.tfvars
cat > terraform.tfvars <<EOF
kubeconfig_path = "~/.kube/config"
namespace = "argocd"
chart_version = "7.7.12"
EOF

# Apply
terraform apply
```

## Variables

| Name            | Description                      | Type   | Default                                | Required |
| --------------- | -------------------------------- | ------ | -------------------------------------- | -------- |
| release_name    | Helm release name for ArgoCD     | string | "argocd"                               | no       |
| chart_repo      | Helm chart repository URL        | string | "https://argoproj.github.io/argo-helm" | no       |
| chart_name      | Helm chart name                  | string | "argo-cd"                              | no       |
| chart_version   | Chart version (empty for latest) | string | ""                                     | no       |
| namespace       | Kubernetes namespace             | string | "argocd"                               | no       |
| kubeconfig_path | Path to kubeconfig file          | string | -                                      | yes      |

## Outputs

| Name                      | Description                   | Sensitive |
| ------------------------- | ----------------------------- | --------- |
| argocd_release_name       | Helm release name             | no        |
| argocd_admin_password_b64 | Base64-encoded admin password | yes       |
| argocd_admin_password     | Decoded admin password        | yes       |

## Configuration

### Namespace

ArgoCD is deployed to the `argocd` namespace (ArgoCD convention). This can be changed via the `namespace` variable.

### Ingress

- **Enabled**: Yes
- **IngressClass**: nginx
- **Host**: argocd.127.0.0.1.nip.io (for local development)
- **TLS**: Disabled (insecure mode)
- **Protocol**: HTTP

For production, update `values.yaml` to:

- Enable HTTPS/TLS
- Use real domain name
- Configure certificate management

### Admin Credentials

Initial admin password is auto-generated and stored in:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Or retrieve via Terraform:

```bash
terraform output -raw argocd_admin_password
```

### Resource Limits

| Component   | CPU Request | Memory Request | CPU Limit | Memory Limit |
| ----------- | ----------- | -------------- | --------- | ------------ |
| Server      | 50m         | 128Mi          | 500m      | 512Mi        |
| Controller  | 100m        | 256Mi          | 1000m     | 1Gi          |
| Repo Server | 50m         | 128Mi          | 500m      | 512Mi        |
| Redis       | 50m         | 64Mi           | 200m      | 128Mi        |

## Accessing ArgoCD

### Web UI

Access the ArgoCD UI at:

- **URL**: http://argocd.127.0.0.1.nip.io
- **Username**: admin
- **Password**: Retrieved via output or kubectl

### Port Forwarding

If ingress is not working:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:80
# Access at http://localhost:8080
```

### CLI Access

Install ArgoCD CLI:

```bash
# macOS
brew install argocd

# Linux
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/
```

Login:

```bash
# Get password
PASSWORD=$(terraform output -raw argocd_admin_password)

# Login
argocd login argocd.127.0.0.1.nip.io \
  --username admin \
  --password "$PASSWORD" \
  --insecure
```

## Validation

### Check Deployment

```bash
# Check namespace
kubectl get namespace argocd

# Check pods
kubectl get pods -n argocd

# Check services
kubectl get svc -n argocd

# Check ingress
kubectl get ingress -n argocd

# Check CRDs
kubectl get crd | grep argoproj
```

### Run BDD Tests

```bash
# Run all ArgoCD deployment tests
behave tests/bdd/features/argocd-deployment.feature

# Run specific scenario
behave tests/bdd/features/argocd-deployment.feature --name "ArgoCD deployed in argocd namespace"
```

### Verify Health

```bash
# Check all components are ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/part-of=argocd \
  -n argocd --timeout=300s

# Check server health
kubectl -n argocd get deployment argocd-server
```

## Troubleshooting

### Pods Not Starting

Check pod status and logs:

```bash
kubectl get pods -n argocd
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
kubectl describe pod -n argocd <pod-name>
```

### UI Not Accessible

1. Check ingress:

```bash
kubectl describe ingress -n argocd argocd-server
```

2. Check ingress-nginx controller:

```bash
kubectl get svc -n ingress-nginx
```

3. Test with port-forward:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:80
curl http://localhost:8080
```

### Cannot Login

Reset admin password:

```bash
# Delete existing secret
kubectl -n argocd delete secret argocd-initial-admin-secret

# Restart server to regenerate
kubectl -n argocd rollout restart deployment argocd-server

# Wait for restart
kubectl -n argocd rollout status deployment argocd-server

# Get new password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Terraform State Issues

If Terraform state is out of sync:

```bash
# Refresh state
terraform refresh

# Or import existing release
terraform import helm_release.argocd argocd/argocd
```

## Cleanup

### Remove ArgoCD

```bash
# Via Terraform
cd infra/terraform/argocd
terraform destroy

# Or via Helm
helm uninstall argocd -n argocd

# Clean up namespace
kubectl delete namespace argocd
```

## Integration with Fawkes

After ArgoCD is deployed, it manages the rest of the Fawkes platform:

1. **Bootstrap Applications**: Creates root Applications (fawkes-app, fawkes-infra)
2. **App-of-Apps Pattern**: Root Applications deploy child Applications
3. **GitOps Workflow**: All changes via Git → ArgoCD syncs automatically

## Security Considerations

### Production Recommendations

1. **Enable TLS**: Configure proper certificates (Let's Encrypt or corporate CA)
2. **External Secrets**: Use External Secrets Operator for admin credentials
3. **RBAC**: Configure proper RBAC policies for users and applications
4. **SSO**: Enable Dex or OIDC integration for user authentication
5. **Network Policies**: Restrict network access to ArgoCD components
6. **Private Repos**: Configure SSH keys or tokens for private Git repositories

### Local Development

The current configuration uses:

- HTTP (no TLS) for simplicity
- Auto-generated admin password
- No SSO/RBAC
- nip.io for DNS resolution

This is suitable for local development but **NOT for production**.

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Helm Chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)
- [Fawkes Architecture](../../../docs/architecture.md)
- [GitOps Strategy](../../../docs/explanation/architecture/gitops-strategy.md)

## Related Issues

- Issue #5: Deploy ArgoCD via Helm

## Support

For issues or questions:

- Check [Troubleshooting](#troubleshooting) section
- Review [ArgoCD documentation](https://argo-cd.readthedocs.io/)
- Open a GitHub issue in the Fawkes repository
