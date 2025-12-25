# Design System Storybook Deployment Guide

This guide provides instructions for deploying the Fawkes Design System Storybook to Kubernetes.

## Overview

The Design System Storybook provides interactive documentation for all 42+ components in the Fawkes Design System. It includes:

- Interactive component examples
- Design tokens documentation
- Accessibility testing with a11y addon
- Component API documentation
- Integration with Backstage

## Prerequisites

- Kubernetes cluster (local or cloud)
- kubectl configured with cluster access
- Docker for building images
- Node.js 18+ and npm (for local development)
- ArgoCD (for GitOps deployment)

## Architecture

The Storybook deployment consists of:

1. **Static Site**: Pre-built Storybook site served by nginx
2. **Deployment**: 2 replicas for high availability
3. **Service**: ClusterIP service exposing port 80
4. **Ingress**: NGINX ingress with TLS support
5. **ArgoCD Application**: Automated sync from Git repository

## Local Development

### Install Dependencies

```bash
cd design-system
npm install
```

### Run Storybook Locally

```bash
npm run storybook
```

This starts Storybook at http://localhost:6006

### Build Storybook

```bash
npm run build-storybook
```

This creates a static site in `storybook-static/` directory.

## Building the Docker Image

### Option 1: Build from Pre-built Storybook (Recommended)

This method uses a pre-built Storybook to avoid npm install issues in Docker:

```bash
cd design-system
npm run build-storybook
docker build -f Dockerfile.prebuilt -t fawkes/design-system-storybook:latest .
```

### Option 2: Build Everything in Docker

This method builds Storybook inside Docker (requires npm registry access):

```bash
cd design-system
docker build -t fawkes/design-system-storybook:latest .
```

## Deploying to Kubernetes

### Manual Deployment

```bash
# Apply the manifests directly
kubectl apply -f platform/apps/design-system/deployment.yaml

# Check the deployment status
kubectl get pods -n fawkes -l app=design-system-storybook

# Check the service
kubectl get svc -n fawkes design-system-storybook

# Check the ingress
kubectl get ingress -n fawkes design-system-storybook
```

### GitOps Deployment with ArgoCD

```bash
# Apply the ArgoCD application
kubectl apply -f platform/apps/design-system-application.yaml

# Check ArgoCD sync status
argocd app get design-system

# Sync manually if needed
argocd app sync design-system
```

### Local Kubernetes (minikube/kind)

```bash
# Add entry to /etc/hosts
echo "127.0.0.1 design-system.fawkes.local" | sudo tee -a /etc/hosts

# If using minikube, setup ingress
minikube addons enable ingress

# If using minikube, get the tunnel running
minikube tunnel
```

## Accessing Storybook

### Local Access

- http://design-system.fawkes.local (HTTP)
- https://design-system.fawkes.local (HTTPS with self-signed cert)

### Port Forwarding (Alternative)

```bash
kubectl port-forward -n fawkes svc/design-system-storybook 6006:80
```

Then access at http://localhost:6006

## Verifying the Deployment

### Check All Resources

```bash
# Check namespace
kubectl get namespace fawkes

# Check deployment
kubectl get deployment -n fawkes design-system-storybook

# Check pods
kubectl get pods -n fawkes -l app=design-system-storybook

# Check service
kubectl get svc -n fawkes design-system-storybook

# Check ingress
kubectl get ingress -n fawkes design-system-storybook

# View pod logs
kubectl logs -n fawkes -l app=design-system-storybook
```

### Health Checks

```bash
# Check pod health
kubectl describe pod -n fawkes -l app=design-system-storybook

# The deployment includes:
# - Liveness probe: HTTP GET / on port 6006
# - Readiness probe: HTTP GET / on port 6006
```

### Test Accessibility

1. Open Storybook in browser
2. Navigate to any component story
3. Click on "Accessibility" tab in the addon panel
4. Verify a11y checks pass (no violations)

## Backstage Integration

The Design System is automatically registered in Backstage:

1. Open Backstage at your Backstage URL
2. Search for "design-system"
3. Click on the component
4. Find the "Storybook Documentation" link
5. Click to open Storybook

## Troubleshooting

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod -n fawkes -l app=design-system-storybook

# Check pod logs
kubectl logs -n fawkes -l app=design-system-storybook

# Common issues:
# - Image pull errors: Check image name and availability
# - Port conflicts: Check if port 6006 is already in use
# - Resource limits: Check if cluster has enough resources
```

### Ingress Not Working

```bash
# Check ingress status
kubectl describe ingress -n fawkes design-system-storybook

# Check nginx ingress controller
kubectl get pods -n ingress-nginx

# Check ingress class
kubectl get ingressclass

# Test service directly
kubectl port-forward -n fawkes svc/design-system-storybook 6006:80
curl http://localhost:6006
```

### ArgoCD Sync Issues

```bash
# Check application status
argocd app get design-system

# View diff
argocd app diff design-system

# Force sync
argocd app sync design-system --force

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Certificate Issues

If you see TLS/certificate errors:

```bash
# Check cert-manager
kubectl get pods -n cert-manager

# Check certificate
kubectl get certificate -n fawkes design-system-tls

# Check certificate status
kubectl describe certificate -n fawkes design-system-tls
```

## Resource Requirements

### Current Configuration

- **CPU Request**: 100m
- **CPU Limit**: 500m
- **Memory Request**: 128Mi
- **Memory Limit**: 512Mi
- **Replicas**: 2

### Scaling

To scale the deployment:

```bash
# Scale up
kubectl scale deployment -n fawkes design-system-storybook --replicas=3

# Scale down
kubectl scale deployment -n fawkes design-system-storybook --replicas=1
```

### Resource Monitoring

```bash
# Check resource usage
kubectl top pods -n fawkes -l app=design-system-storybook

# Check resource quotas
kubectl describe resourcequota -n fawkes
```

## Updating Storybook

### Update Process

1. Make changes to components or stories in `design-system/src`
2. Build Storybook: `npm run build-storybook`
3. Build new Docker image with updated tag
4. Update image tag in `platform/apps/design-system/deployment.yaml`
5. Commit and push changes
6. ArgoCD will automatically sync (if automated sync is enabled)

### Manual Update

```bash
# Build new image
cd design-system
npm run build-storybook
docker build -f Dockerfile.prebuilt -t fawkes/design-system-storybook:v2.0.0 .

# Push to registry (if using registry)
docker push fawkes/design-system-storybook:v2.0.0

# Update deployment
kubectl set image deployment/design-system-storybook -n fawkes \
  storybook=fawkes/design-system-storybook:v2.0.0

# Or edit the deployment directly
kubectl edit deployment -n fawkes design-system-storybook
```

## Monitoring and Logging

### View Logs

```bash
# Real-time logs
kubectl logs -f -n fawkes -l app=design-system-storybook

# Logs from specific pod
kubectl logs -n fawkes <pod-name>

# Previous container logs (if restarted)
kubectl logs -n fawkes <pod-name> --previous
```

### Prometheus Metrics

If Prometheus is installed, nginx metrics are available:

- `nginx_http_requests_total`
- `nginx_http_request_duration_seconds`
- `nginx_connections_active`

### Grafana Dashboards

Import nginx dashboard for visualization of:

- Request rate
- Response times
- Error rates
- Connection metrics

## Security Considerations

### HTTPS/TLS

- TLS is automatically provisioned by cert-manager
- Certificate is stored in `design-system-tls` secret
- Auto-renewal is handled by cert-manager

### Network Policies

Consider adding network policies to restrict traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: design-system-storybook-policy
  namespace: fawkes
spec:
  podSelector:
    matchLabels:
      app: design-system-storybook
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 6006
```

### RBAC

Ensure proper RBAC is configured for ArgoCD service account.

## Best Practices

1. **Version Tags**: Use semantic versioning for Docker images
2. **Resource Limits**: Set appropriate resource requests and limits
3. **Health Checks**: Keep liveness and readiness probes configured
4. **Multiple Replicas**: Run at least 2 replicas for high availability
5. **Monitoring**: Set up alerts for pod failures and high resource usage
6. **Backups**: Keep GitOps configuration in version control
7. **Documentation**: Update stories when components change
8. **Accessibility**: Run a11y tests regularly
9. **Performance**: Monitor page load times and optimize bundle size
10. **Security**: Keep dependencies updated and scan for vulnerabilities

## Additional Resources

- [Storybook Documentation](https://storybook.js.org/)
- [Design System README](../../design-system/README.md)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [NGINX Ingress Documentation](https://kubernetes.github.io/ingress-nginx/)
