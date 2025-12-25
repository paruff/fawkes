---
title: Spinnaker Integration (Deprecated)
description: This guide is deprecated - ArgoCD is now the standard deployment tool
status: deprecated
---

# Spinnaker (Deprecated)

!!! warning "Deprecated Tool"
    **Spinnaker is no longer used in Fawkes.** This documentation is retained for historical reference only.

    **Migration Path**: Use [ArgoCD](https://argo-cd.readthedocs.io/) for GitOps-based continuous delivery.

    See the migration guide below for transitioning from Spinnaker to ArgoCD.

---

## Migration from Spinnaker to ArgoCD

Fawkes has migrated from Spinnaker to ArgoCD for the following reasons:

1. **GitOps-First**: ArgoCD provides native GitOps workflows with Git as the single source of truth
2. **Simplicity**: Simpler architecture with lower operational overhead
3. **Kubernetes-Native**: Built specifically for Kubernetes deployments
4. **Integration**: Better integration with Grafana, Prometheus, and the observability stack
5. **Cost**: Lower infrastructure and maintenance costs

### How to Migrate

#### From Spinnaker Pipelines to ArgoCD Applications

**Spinnaker Pipeline (Old):**

```json
{
  "name": "Deploy to Production",
  "stages": [
    {
      "type": "deployManifest",
      "cloudProvider": "kubernetes",
      "manifests": [...]
    }
  ]
}
```

**ArgoCD Application (New):**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/my-app.git
    targetRevision: main
    path: k8s/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### Progressive Delivery with Argo Rollouts

For canary and blue-green deployments (previously done in Spinnaker):

**Argo Rollout:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      - setWeight: 40
      - pause: {duration: 5m}
      - setWeight: 60
      - pause: {duration: 5m}
      - setWeight: 80
      - pause: {duration: 5m}
  template:
    spec:
      containers:
      - name: my-app
        image: my-app:v2.0.0
```

### Migration Steps

1. **Install ArgoCD** (if not already installed)
2. **Create ArgoCD Applications** for existing Spinnaker pipelines
3. **Configure automated sync policies**
4. **Test deployments** in development environment
5. **Migrate production workloads** incrementally
6. **Decommission Spinnaker** after full migration

### Resources

- [Onboard Service to ArgoCD](../how-to/gitops/onboard-service-argocd.md) - **Start here**: Step-by-step migration guide
- [Sync ArgoCD Application](../how-to/gitops/sync-argocd-app.md) - Manual and automated sync workflows
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/) - Official ArgoCD docs
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/) - Progressive delivery

---

## Historical Documentation (Deprecated)

The content below is retained for historical reference only and should not be used for new deployments.

---

![Spinnaker Logo](../assets/images/tools/spinnaker.png){ width="300" }

Spinnaker is an open-source continuous delivery platform that helps you release software changes with high velocity and confidence.

## Overview

Spinnaker provides two core sets of features:
- **Application Management** - Deploy and manage cloud resources
- **Application Deployment** - Construct and manage continuous delivery workflows

## Key Features

| Feature | Description |
|---------|-------------|
| ![](../assets/images/icons/multi-cloud.png){ width="24" } Multi-Cloud | Deploy to multiple cloud providers |
| ![](../assets/images/icons/pipelines.png){ width="24" } Pipeline Management | Create complex deployment workflows |
| ![](../assets/images/icons/canary.png){ width="24" } Automated Canary Analysis | Automated testing in production |
| ![](../assets/images/icons/rollback.png){ width="24" } Easy Rollbacks | Quick recovery from failed deployments |

## Integration with Fawkes

### Prerequisites
- Kubernetes cluster
- Helm v3
- kubectl configured with cluster access

### Installation

```bash
# Add Spinnaker Helm repository
helm repo add spinnaker https://helmcharts.opsmx.com/
helm repo update

# Install Spinnaker
helm install spinnaker spinnaker/spinnaker \
  --namespace spinnaker \
  --create-namespace \
  --values values.yaml
```

Example `values.yaml`:
```yaml
spinnakerConfig:
  profiles:
    clouddriver:
      kubernetes:
        enabled: true
        accounts:
        - name: fawkes-cluster
          requiredGroupMembership: []
          providerVersion: V2
          permissions: {}
          dockerRegistries: []
          configureImagePullSecrets: true
          cacheThreads: 1
          namespaces: []
          omitNamespaces: []
          kinds: []
          omitKinds: []
          customResources: []
```

## Using Spinnaker with Fawkes

### Creating a Deployment Pipeline

1. Navigate to Spinnaker UI
2. Create a new application:
   - Name: `fawkes-app`
   - Owner Email: `team@fawkes.io`
   - Cloud Providers: `Kubernetes V2`

3. Create a deployment pipeline:
   ```json
   {
     "name": "Deploy to Production",
     "stages": [
       {
         "type": "deployManifest",
         "name": "Deploy Application",
         "cloudProvider": "kubernetes",
         "account": "fawkes-cluster",
         "source": "text",
         "manifests": [
           {
             "apiVersion": "apps/v1",
             "kind": "Deployment",
             "metadata": {
               "name": "fawkes-app"
             },
             "spec": {
               "replicas": 3
             }
           }
         ]
       }
     ]
   }
   ```

## Best Practices

1. **Pipeline Templates**
   - Use pipeline templates for consistency
   - Version control your templates
   - Share common deployment patterns

2. **Security**
   - Enable RBAC
   - Use service accounts
   - Implement least privilege access

3. **Monitoring**
   - Configure pipeline notifications
   - Monitor pipeline executions
   - Set up alerting for failures

## Troubleshooting

Common issues and solutions:

| Issue | Solution |
|-------|----------|
| Pipeline fails to start | Check Spinnaker service account permissions |
| Manifest deployment fails | Verify Kubernetes cluster connectivity |
| Images not found | Confirm container registry configuration |

## Additional Resources

- [Spinnaker Documentation](https://spinnaker.io/docs/)
- [GitHub Repository](https://github.com/spinnaker/spinnaker)
- [Community Slack](https://join.spinnaker.io/)

[Configure Spinnaker :octicons-gear-16:](../configuration.md#spinnaker){ .md-button .md-button--primary }
[View Examples :octicons-code-16:](../examples/spinnaker.md){ .md-button }