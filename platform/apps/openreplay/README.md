# OpenReplay Session Recording

This directory contains the deployment configuration for OpenReplay, an open-source session replay and analytics platform used for usability testing.

## Overview

OpenReplay provides:

- Session replay with DOM recording
- Console logs and network traffic capture
- Performance monitoring
- Privacy controls and data sanitization
- Search and filtering capabilities

## Deployment

### Prerequisites

- Kubernetes cluster with at least 8GB RAM available
- Storage class for persistent volumes
- Ingress controller configured (nginx-ingress)
- DNS configured for openreplay.fawkes.local

### Deploy with ArgoCD

```bash
# Apply the ArgoCD application
kubectl apply -f openreplay-application.yaml

# Check deployment status
argocd app get openreplay --namespace fawkes
kubectl get pods -n openreplay
```

### Local Deployment (for testing)

```bash
# Deploy using Helm values
helm install openreplay openreplay/openreplay \
  --namespace openreplay --create-namespace \
  --values values.yaml

# Or use kustomize
kubectl apply -k .
```

## Configuration

### Access

Once deployed:

- **URL**: https://openreplay.fawkes.local
- **Default credentials**: Set during initial setup

### Environment Variables

Key configuration options in `values.yaml`:

- `DOMAIN_NAME`: openreplay.fawkes.local
- `ENABLE_SSL`: true
- `STORAGE_SIZE`: 50Gi (adjust based on needs)
- `RETENTION_DAYS`: 90 (auto-delete old sessions)

### Integration

See [Session Recording Setup Guide](../../docs/how-to/session-recording-setup.md) for:

- Installing tracker in applications
- Configuring privacy and sanitization
- Using metadata and tagging
- Best practices

## Maintenance

### Storage Management

```bash
# Check storage usage
kubectl get pvc -n openreplay

# Adjust retention in OpenReplay UI
# Settings → Storage → Retention
```

### Backup

```bash
# Backup PostgreSQL metadata
kubectl exec -n openreplay deploy/openreplay-postgresql -- \
  pg_dump -U postgres openreplay > backup.sql
```

### Monitoring

```bash
# Check health
kubectl get pods -n openreplay
kubectl logs -n openreplay deploy/openreplay-api
```

## Resources

- [OpenReplay Documentation](https://docs.openreplay.com/)
- [Usability Testing Guide](../../docs/how-to/usability-testing-guide.md)
- [Session Recording Setup](../../docs/how-to/session-recording-setup.md)
- [Research Repository](../../docs/research/README.md)

## Support

- **Technical Issues**: #platform-support on Mattermost
- **Research Questions**: #product-research on Mattermost
- **Product Team**: product-team@fawkes.local
