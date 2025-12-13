# Kubernetes Dashboard - Web UI for Cluster Management

## Purpose

Kubernetes Dashboard provides a web-based user interface for managing and troubleshooting Kubernetes cluster resources.

## Key Features

- **Resource Viewing**: View all Kubernetes resources
- **Resource Management**: Create, edit, delete resources
- **Log Viewing**: View pod logs
- **Shell Access**: Execute commands in containers
- **Metrics**: Resource utilization graphs
- **RBAC**: Role-based access control

## Quick Start

### Accessing the Dashboard

```bash
# Get access token
kubectl -n kubernetes-dashboard create token admin-user

# Access UI
http://dashboard.127.0.0.1.nip.io

# Login with token from above
```

## Features

### View Resources

- Workloads (Deployments, StatefulSets, Pods)
- Services and Ingresses
- ConfigMaps and Secrets
- Storage (PVs, PVCs)
- RBAC (Roles, RoleBindings)

### Troubleshooting

- View pod logs
- Execute shell commands
- View events
- Check resource metrics

### Resource Management

- Scale deployments
- Edit resource YAML
- Delete resources
- Restart pods

## Security

### Create Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: admin-user
    namespace: kubernetes-dashboard
```

## Related Documentation

- [Kubernetes Dashboard Documentation](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
