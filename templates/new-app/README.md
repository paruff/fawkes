# Application Templates

This directory contains templates for creating new platform applications in Fawkes.

## Available Templates

### New Application Template

Location: `new-app/`

Contains templates for creating a new platform application component:

- **README.template.md**: Documentation template following platform standards
- **argocd-application.template.yaml**: ArgoCD Application manifest template
- **kubernetes-manifests.template.yaml**: Complete Kubernetes manifest templates
- **values.template.yaml**: Helm values file template

## Using Templates

### Step 1: Copy Template

```bash
# Copy the new-app template to your component directory
cp -r templates/new-app platform/apps/my-component

# Navigate to the new directory
cd platform/apps/my-component
```

### Step 2: Customize Files

Replace placeholders in all files:

- `component-name` → Your component name (lowercase, hyphenated)
- `component-namespace` → Kubernetes namespace
- `[Component Name]` → Human-readable component name
- `[Brief Description]` → Short description of component

### Step 3: Update Content

Edit each file to match your component's needs:

1. **README.md**: 
   - Fill in purpose, features, architecture
   - Add component-specific configuration
   - Document integration points
   - Add troubleshooting steps

2. **ArgoCD Application**:
   - Update source path
   - Set correct namespace
   - Configure sync policy
   - Choose source type (Helm/Kustomize/Plain)

3. **Kubernetes Manifests**:
   - Update image reference
   - Configure resource limits
   - Add component-specific volumes
   - Adjust health check endpoints
   - Customize environment variables

4. **Helm Values** (if using Helm):
   - Set default values
   - Configure ingress hostname
   - Set resource limits
   - Add component-specific configuration

### Step 4: Remove Unused Files

```bash
# If not using Helm, remove values file
rm values.template.yaml

# If not using plain manifests, remove manifests file
rm kubernetes-manifests.template.yaml

# Rename template files
mv README.template.md README.md
mv argocd-application.template.yaml ../my-component-application.yaml
```

### Step 5: Deploy

```bash
# Test locally first
kubectl apply -f platform/apps/my-component-application.yaml

# Check ArgoCD sync status
kubectl get application my-component -n argocd

# View component status
kubectl get all -n my-component-namespace
```

## Template Features

All templates include:

### Security Best Practices

- ✅ Non-root containers
- ✅ Read-only root filesystem
- ✅ Pod Security Standards enforcement
- ✅ Network policies
- ✅ Security contexts
- ✅ Dropped capabilities

### Observability

- ✅ Prometheus metrics endpoint
- ✅ ServiceMonitor for automatic scraping
- ✅ Health check endpoints
- ✅ Structured logging support

### High Availability

- ✅ Multiple replicas (default: 2)
- ✅ Pod anti-affinity
- ✅ Pod Disruption Budget
- ✅ Resource requests/limits
- ✅ Health probes

### Scalability

- ✅ Horizontal Pod Autoscaler
- ✅ Resource-based scaling
- ✅ Configurable min/max replicas

### GitOps Ready

- ✅ ArgoCD Application manifest
- ✅ Automated sync
- ✅ Self-healing
- ✅ Pruning of deleted resources

## Component Structure

After customization, your component directory should look like:

```text
platform/apps/my-component/
├── README.md                           # Component documentation
├── kustomization.yaml                  # Kustomize overlay (optional)
├── values.yaml                         # Helm values (if using Helm)
├── deployment.yaml                     # Kubernetes manifests
├── service.yaml                        # (or single combined file)
├── ingress.yaml
├── configmap.yaml
└── configs/                            # Additional config files
    └── app-config.yaml

platform/apps/my-component-application.yaml  # ArgoCD Application
```

## Quick Reference

### Minimal Component

For a minimal component, you only need:

1. **ArgoCD Application** (`my-component-application.yaml`)
2. **Kubernetes Deployment** (basic deployment.yaml)
3. **Kubernetes Service** (basic service.yaml)
4. **README.md** (documentation)

### Full-Featured Component

For a production-ready component, include:

1. ArgoCD Application
2. Deployment with security contexts
3. Service
4. Ingress with TLS
5. ConfigMap
6. ServiceAccount
7. ServiceMonitor
8. HorizontalPodAutoscaler
9. PodDisruptionBudget
10. NetworkPolicy
11. README.md

## Common Customizations

### Adding Persistent Storage

```yaml
# In deployment
volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-component-pvc

# Add PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-component-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

### Adding Database Connection

```yaml
# In deployment env
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: database-credentials
      key: url
```

### Adding Vault Integration

```yaml
# In deployment pod template
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "my-component"
  vault.hashicorp.com/agent-inject-secret-config: "secret/data/fawkes/my-component"
```

### Adding Init Container

```yaml
# In deployment spec
initContainers:
  - name: init-db
    image: busybox:1.28
    command: ['sh', '-c', 'until nc -z database 5432; do sleep 1; done']
```

## Validation

Before committing, validate your manifests:

```bash
# Validate Kubernetes manifests
kubectl apply --dry-run=client -f platform/apps/my-component/

# Validate with kubeval
kubeval platform/apps/my-component/*.yaml

# Validate with kube-linter
kube-linter lint platform/apps/my-component/
```

## Examples

See existing components for reference:

- **Simple Component**: [cert-manager](../platform/apps/cert-manager/)
- **Medium Complexity**: [grafana](../platform/apps/grafana/)
- **Complex Component**: [backstage](../platform/apps/backstage/)

## Best Practices

1. **Naming**: Use lowercase with hyphens (my-component)
2. **Labels**: Include app.kubernetes.io/* labels
3. **Resources**: Always set requests and limits
4. **Health Checks**: Define liveness and readiness probes
5. **Security**: Follow Pod Security Standards
6. **Monitoring**: Expose Prometheus metrics
7. **Documentation**: Keep README.md up to date
8. **Secrets**: Use Vault or External Secrets, never commit secrets
9. **Images**: Use specific tags, not `latest`
10. **Testing**: Test in local environment before production

## Troubleshooting

### Template Placeholder Not Replaced

Search for remaining placeholders:

```bash
grep -r "component-name" platform/apps/my-component/
grep -r "\[Component" platform/apps/my-component/
```

### ArgoCD Sync Fails

Check ArgoCD application logs:

```bash
kubectl logs -n argocd deployment/argocd-application-controller | grep my-component
```

### Pod Won't Start

Check events and logs:

```bash
kubectl describe pod -n my-component-namespace -l app.kubernetes.io/name=my-component
kubectl logs -n my-component-namespace -l app.kubernetes.io/name=my-component
```

## Contributing

To improve these templates:

1. Test changes with a new component
2. Update documentation
3. Submit pull request with examples

## Related Documentation

- [Platform Apps Directory](../platform/apps/README.md)
- [Architecture Overview](../docs/architecture.md)
- [Contributing Guide](../docs/contributing.md)
- [GitOps Workflow](../docs/how-to/gitops-workflow.md)
