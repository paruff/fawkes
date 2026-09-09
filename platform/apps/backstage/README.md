# Backstage - Developer Portal

## Purpose

Backstage is the central developer portal for the Fawkes platform, providing a unified interface for service catalog, software templates, documentation, and platform integrations.

## Key Features

- **Service Catalog**: Centralized inventory of all services, APIs, and resources
- **Software Templates**: Golden path templates for creating new services
- **TechDocs**: Documentation as code with MkDocs
- **Plugin Ecosystem**: CI/CD status, Kubernetes, ArgoCD, metrics
- **Search**: Unified search across all platform resources
- **Authentication**: GitHub OAuth integration

## Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                     Backstage Frontend (React)                   │
│  ├─ Service Catalog                                             │
│  ├─ Software Templates                                          │
│  ├─ TechDocs                                                    │
│  └─ Plugins (Kubernetes, ArgoCD, Jenkins)                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Backstage Backend (Node.js)                  │
│  ├─ Catalog API                                                 │
│  ├─ Scaffolder                                                  │
│  ├─ TechDocs                                                    │
│  ├─ Proxy Endpoints                                             │
│  └─ Authentication Provider                                      │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PostgreSQL Database                          │
│  ├─ Catalog entities                                            │
│  ├─ User sessions                                               │
│  └─ TechDocs index                                              │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Kubernetes cluster running
- PostgreSQL database deployed (via CloudNativePG)
- GitHub OAuth app configured (see below)

### Configure GitHub OAuth

Before deploying Backstage, you need to set up GitHub OAuth for authentication:

1. **Create GitHub OAuth App**:

   - Go to https://github.com/settings/developers (personal) or
   - Go to https://github.com/organizations/YOUR_ORG/settings/applications (organization)
   - Click "New OAuth App"
   - Fill in:
     - Application name: `Fawkes Backstage - Development`
     - Homepage URL: `https://backstage.fawkes.idp`
     - Authorization callback URL: `https://backstage.fawkes.idp/api/auth/github/handler/frame`
   - Note the Client ID and generate a Client Secret

2. **Update Kubernetes Secrets**:

   ```bash
   # Edit secrets file
   vim platform/apps/backstage/secrets.yaml

   # Update github-client-id and github-client-secret
   # Then apply:
   kubectl apply -f platform/apps/backstage/secrets.yaml
   ```

3. **Deploy Backstage**:

   ```bash
   # Apply via ArgoCD
   kubectl apply -f platform/apps/backstage-application.yaml

   # Or deploy directly with Helm
   helm install backstage backstage/backstage \
     -f platform/apps/backstage/values.yaml \
     -n fawkes
   ```

**For detailed OAuth setup instructions, see**: [GitHub OAuth Setup Guide](../../docs/how-to/security/github-oauth-setup.md)

### Accessing Backstage

Local development:

```bash
# Access UI
http://backstage.127.0.0.1.nip.io
```

Login with your GitHub account (OAuth configured).

## Service Catalog

### Registering a Component

Add a `catalog-info.yaml` to your repository:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-service
  description: My awesome service
  annotations:
    github.com/project-slug: paruff/my-service
    argocd/app-name: my-service
    backstage.io/kubernetes-id: my-service
  tags:
    - java
    - spring-boot
spec:
  type: service
  owner: team-a
  lifecycle: production
  providesApis:
    - my-api
  consumesApis:
    - user-api
```

Register in Backstage:

1. Go to "Create" → "Register Existing Component"
2. Enter repository URL
3. Click "Analyze" and "Import"

## Software Templates

Create new services using golden path templates:

```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: java-service
  title: Java Microservice
  description: Create a new Java Spring Boot microservice
spec:
  owner: platform-team
  type: service
  parameters:
    - title: Service Information
      required:
        - name
        - owner
      properties:
        name:
          title: Name
          type: string
        owner:
          title: Owner
          type: string
  steps:
    - id: fetch
      name: Fetch Template
      action: fetch:template
      input:
        url: ./skeleton
    - id: publish
      name: Publish to GitHub
      action: publish:github
      input:
        repoUrl: github.com?repo=${{ parameters.name }}
```

## Plugins

### Kubernetes Plugin

View pod status and logs:

```yaml
# In catalog-info.yaml
metadata:
  annotations:
    backstage.io/kubernetes-id: my-service
    backstage.io/kubernetes-namespace: production
```

### ArgoCD Plugin

Monitor deployment status:

```yaml
# In catalog-info.yaml
metadata:
  annotations:
    argocd/app-name: my-service
```

### Jenkins Plugin

View build status:

```yaml
# In catalog-info.yaml
metadata:
  annotations:
    jenkins.io/job-full-name: folder/my-service
```

## TechDocs

Documentation as code using MkDocs:

```yaml
# mkdocs.yml in your repository
site_name: My Service Documentation
docs_dir: docs
nav:
  - Home: index.md
  - API: api.md
  - Development: development.md

# In catalog-info.yaml
metadata:
  annotations:
    backstage.io/techdocs-ref: dir:.
```

Build and publish:

```bash
# Build locally
npx @techdocs/cli generate --source-dir . --output-dir ./site

# Auto-published by Backstage when catalog refreshes
```

## Eclipse Che Integration

Launch cloud development environments:

```yaml
# In catalog-info.yaml
metadata:
  annotations:
    che.eclipse.org/devfile: .devfile.yaml
```

Users can click "Open in Eclipse Che" to launch a pre-configured workspace.

## Customization

### Adding Custom Plugins

```typescript
// packages/app/src/plugins.ts
export { plugin as chePlugin } from '@paruff/backstage-plugin-che';

// packages/app/src/components/catalog/EntityPage.tsx
import { EntityCheCard } from '@paruff/backstage-plugin-che';

const serviceEntityPage = (
  <EntityLayout>
    <EntityLayout.Route path="/che" title="Che">
      <EntityCheCard />
    </EntityLayout.Route>
  </EntityLayout>
);
```

### Custom Theme

```typescript
// packages/app/src/theme/fawkesTheme.ts
import { createTheme } from "@backstage/theme";

export const fawkesTheme = createTheme({
  palette: {
    primary: {
      main: "#1976d2",
    },
    secondary: {
      main: "#dc004e",
    },
  },
});
```

## Monitoring

Backstage exposes metrics:

```yaml
# ServiceMonitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: backstage
spec:
  selector:
    matchLabels:
      app: backstage
```

Key metrics:

- `backstage_catalog_entities_count` - Total catalog entities
- `backstage_http_request_duration_seconds` - Request latency
- `backstage_catalog_processing_duration` - Catalog processing time

## Troubleshooting

### Catalog Not Updating

```bash
# Force catalog refresh
kubectl exec -n fawkes deployment/backstage -- \
  curl -X POST http://localhost:7007/api/catalog/refresh
```

### Plugin Not Loading

```bash
# Check backend logs
kubectl logs -n fawkes deployment/backstage -c backstage-backend -f

# Check frontend logs
kubectl logs -n fawkes deployment/backstage -c backstage-frontend -f
```

## Related Documentation

- [ADR-002: Backstage for Developer Portal](../../../docs/adr/002-backstage.md)
- [Backstage Documentation](https://backstage.io/docs/overview/what-is-backstage)
- [Software Templates Guide](../../../docs/how-to/create-software-template.md)
