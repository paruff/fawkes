# Hasura GraphQL API Quick Start Guide

This guide will help you get started with the unified GraphQL API powered by Hasura.

## Prerequisites

- Kubernetes cluster with the Fawkes platform deployed
- `kubectl` configured to access the cluster
- PostgreSQL databases deployed (VSM, Backstage, DevLake)

## Deployment

### 1. Deploy Hasura via ArgoCD

```bash
# Apply the ArgoCD Application
kubectl apply -f platform/apps/hasura-application.yaml

# Check deployment status
kubectl get application hasura -n fawkes

# Watch pods come up
kubectl get pods -n fawkes -l app=hasura -w
```

### 2. Access the GraphQL Console

```bash
# Forward Hasura service to localhost
kubectl port-forward -n fawkes svc/hasura 8080:8080

# Open browser to http://localhost:8080/console
```

## Resources

- [Full README](../../../platform/apps/hasura/README.md)
- [RBAC Guide](../../../services/data-api/rbac/README.md)
- [Schema Guide](../../../services/data-api/schema/README.md)
