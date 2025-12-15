# Sample Applications ArgoCD Configurations

This directory contains ArgoCD Application manifests for deploying the three sample applications.

## Applications

- **sample-java-app-application.yaml**: Java Spring Boot application
- **sample-python-app-application.yaml**: Python FastAPI application
- **sample-nodejs-app-application.yaml**: Node.js Express application

## Deployment

To deploy all sample applications:

```bash
kubectl apply -f platform/apps/samples/
```

To deploy individual applications:

```bash
kubectl apply -f platform/apps/samples/sample-java-app-application.yaml
kubectl apply -f platform/apps/samples/sample-python-app-application.yaml
kubectl apply -f platform/apps/samples/sample-nodejs-app-application.yaml
```

## Verify Deployment

```bash
# Check ArgoCD applications
kubectl get applications -n fawkes | grep sample

# Check application pods
kubectl get pods -n fawkes-samples

# Check application services
kubectl get services -n fawkes-samples

# Check application ingress
kubectl get ingress -n fawkes-samples
```

## DORA Metrics

All sample applications are configured with DORA metrics collection enabled:

```yaml
annotations:
  dora.fawkes.io/collect-metrics: "true"
  dora.fawkes.io/environment: "dev"
```

This enables automatic tracking of:
- Deployment Frequency
- Lead Time for Changes
- Change Failure Rate
- Mean Time to Restore

Metrics can be viewed in:
- DevLake: https://devlake.fawkes.idp
- Grafana: https://grafana.fawkes.idp/d/dora-metrics

## Configuration

Each ArgoCD Application is configured with:

- **Repository**: https://github.com/paruff/fawkes.git
- **Path**: services/samples/{app-name}/k8s
- **Target Revision**: HEAD (main branch)
- **Destination Namespace**: fawkes-samples
- **Sync Policy**: Automated with prune and self-heal
- **Sync Options**: CreateNamespace, ServerSideApply

## GitOps Workflow

1. Code changes are committed to the repository
2. CI/CD pipeline builds and tests the application
3. Docker image is built and pushed to Harbor registry
4. Kubernetes manifests are updated (if needed)
5. ArgoCD detects changes and syncs automatically
6. DORA metrics are collected and reported

## Troubleshooting

### Application Out of Sync

```bash
# Check sync status
argocd app get sample-java-app

# Force sync
argocd app sync sample-java-app
```

### Application Health Issues

```bash
# Check application details
kubectl get application sample-java-app -n fawkes -o yaml

# Check pods in target namespace
kubectl get pods -n fawkes-samples -l app=sample-java-app

# View logs
kubectl logs -n fawkes-samples -l app=sample-java-app
```

### Metrics Not Collected

Verify the annotations are present:

```bash
kubectl get application sample-java-app -n fawkes -o jsonpath='{.metadata.annotations}'
```

Check DevLake connection configuration in the DevLake UI.
