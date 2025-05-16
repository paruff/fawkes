---
title: Spinnaker Integration
description: Implementing continuous delivery with Spinnaker in Fawkes
---

# Spinnaker

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