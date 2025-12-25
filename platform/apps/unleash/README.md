# Unleash Feature Flags Platform

## Overview

Unleash is an open-source feature flag management platform deployed on Fawkes to enable:

- **Gradual Rollouts**: Progressive deployment with percentage-based rollouts
- **A/B Testing**: Experiment with different feature variants
- **Kill Switches**: Quickly disable features without redeployment
- **Targeting**: User-based, team-based, or environment-based feature flags
- **Audit Trail**: Complete history of flag changes

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Unleash Feature Flags                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Unleash Frontend (UI)                     │ │
│  │         https://unleash.fawkes.idp                     │ │
│  └─────────────────────┬──────────────────────────────────┘ │
│                        │                                     │
│                        ▼                                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │             Unleash Server (2 replicas)                │ │
│  │  • Feature flag management API                         │ │
│  │  • OpenFeature provider backend                        │ │
│  │  • Rollout strategies & targeting                      │ │
│  └─────────────────────┬──────────────────────────────────┘ │
│                        │                                     │
│                        ▼                                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │        PostgreSQL (CloudNativePG, 3 replicas)          │ │
│  │  • Feature flags metadata                              │ │
│  │  • Strategies and constraints                          │ │
│  │  • User preferences and audit logs                     │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## OpenFeature Integration

Unleash serves as the backend provider for **OpenFeature**, a CNCF standard for vendor-agnostic feature flag APIs. This architecture provides:

- **Vendor Independence**: Swap providers without code changes
- **Standardized API**: Consistent interface across languages
- **Future-Proof**: Easy migration to other providers if needed

### Using OpenFeature with Unleash

#### TypeScript/JavaScript (Backstage)

```typescript
import { OpenFeature } from "@openfeature/server-sdk";
import { UnleashProvider } from "@openfeature/unleash-provider";

// Configure OpenFeature with Unleash provider
await OpenFeature.setProviderAndWait(
  new UnleashProvider({
    url: "https://unleash.fawkes.idp/api",
    appName: "backstage",
    apiToken: process.env.UNLEASH_API_TOKEN,
  })
);

// Use feature flags
const client = OpenFeature.getClient();
const showNewUI = await client.getBooleanValue("new-ui-enabled", false);
```

#### Python

```python
from openfeature import api
from openfeature.contrib.provider.unleash import UnleashProvider

# Set Unleash as the provider
api.set_provider(UnleashProvider(
    url="https://unleash.fawkes.idp/api",
    app_name="python-service",
    api_token=os.getenv("UNLEASH_API_TOKEN")
))

# Use feature flags
client = api.get_client()
show_new_ui = client.get_boolean_value("new-ui-enabled", False)
```

#### Go

```go
import (
    "github.com/open-feature/go-sdk/openfeature"
    unleash "github.com/open-feature/go-sdk-contrib/providers/unleash/pkg"
)

// Set Unleash as the provider
openfeature.SetProvider(unleash.NewProvider(
    unleash.WithURL("https://unleash.fawkes.idp/api"),
    unleash.WithAppName("go-service"),
    unleash.WithAPIToken(os.Getenv("UNLEASH_API_TOKEN")),
))

// Use feature flags
client := openfeature.NewClient("my-app")
showNewUI, _ := client.BooleanValue(context.Background(), "new-ui-enabled", false, openfeature.EvaluationContext{})
```

## Deployment

### Prerequisites

- Kubernetes cluster with ArgoCD installed
- PostgreSQL operator (CloudNativePG) deployed
- Ingress controller (nginx-ingress) configured
- cert-manager for TLS certificates

### Deploy

```bash
# Deploy Unleash via ArgoCD
kubectl apply -f platform/apps/unleash-application.yaml

# Wait for deployment
kubectl wait --for=condition=ready pod -l app=unleash -n fawkes --timeout=300s

# Get admin credentials
kubectl get secret unleash-secret -n fawkes -o jsonpath='{.data.ADMIN_PASSWORD}' | base64 -d
```

### Access

- **UI**: https://unleash.fawkes.idp
- **API**: https://unleash.fawkes.idp/api
- **Admin User**: admin@fawkes.local
- **Admin Password**: Retrieved from secret (see above)

### ⚠️ Security Warning - Production Deployment

**IMPORTANT**: The deployment manifests contain default development credentials that **MUST** be changed before production use:

1. **Generate secure passwords** and API tokens:

```bash
# Generate admin password
openssl rand -base64 32

# Generate API tokens
openssl rand -hex 32
```

2. **Update secrets** before deploying:

```bash
kubectl create secret generic unleash-secret \
  --from-literal=ADMIN_PASSWORD="$(openssl rand -base64 32)" \
  --from-literal=INIT_ADMIN_API_TOKENS="*:*.$(openssl rand -hex 32)" \
  --from-literal=INIT_CLIENT_API_TOKENS="*:development.$(openssl rand -hex 32)" \
  --namespace fawkes \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic db-unleash-credentials \
  --from-literal=username="unleash_user" \
  --from-literal=password="$(openssl rand -base64 32)" \
  --from-literal=database="unleash" \
  --namespace fawkes \
  --dry-run=client -o yaml | kubectl apply -f -
```

3. **For production**, use External Secrets Operator to sync from Vault:
   - See `platform/apps/postgresql/externalsecret-db-*` for examples
   - Configure Vault paths for Unleash secrets
   - Enable ExternalSecret resources in kustomization

## Feature Flag Strategies

Unleash supports multiple rollout strategies:

### 1. Standard Strategy

Default on/off toggle for all users.

### 2. Gradual Rollout

Progressive rollout based on percentage (0-100%).

### 3. User IDs

Target specific users by ID or email.

### 4. Flexible Rollout

Combine multiple constraints (user ID, environment, team).

### 5. Custom Strategy

Define custom targeting logic via API.

## Backstage Plugin

To integrate Unleash UI into Backstage:

1. Install the Backstage plugin:

```bash
cd platform/apps/backstage
yarn add @unleash/backstage-plugin
```

2. Add to `packages/app/src/App.tsx`:

```typescript
import { UnleashPage } from '@unleash/backstage-plugin';

// In your routes
<Route path="/unleash" element={<UnleashPage />} />
```

3. Configure in `app-config.yaml`:

```yaml
unleash:
  url: https://unleash.fawkes.idp
  apiToken: ${UNLEASH_API_TOKEN}
```

## SDK Integration Examples

See [examples/](./examples/) directory for complete integration examples:

- `examples/backstage-integration.ts` - Backstage frontend plugin
- `examples/python-service.py` - Python microservice
- `examples/go-service.go` - Go microservice
- `examples/jenkins-pipeline.groovy` - Jenkins pipeline feature gating

## Monitoring

Unleash exposes Prometheus metrics at `/internal-backstage/prometheus`:

- `unleash_feature_toggles_total` - Total feature flags
- `unleash_client_requests_total` - API request count
- `unleash_db_pool_*` - Database connection pool metrics

View metrics in Grafana: https://grafana.fawkes.idp/d/unleash

## Security

### Authentication

- **Admin UI**: Username/password (stored in Kubernetes secret)
- **API**: API tokens (scoped per environment/team)
- **SSO**: OIDC/SAML support (roadmap)

### Secrets Management

- Default: Kubernetes secrets (dev/local only)
- Production: External Secrets Operator syncing from Vault

### Network Security

- TLS termination at ingress
- Internal communication: ClusterIP services
- Network policies: Restrict egress to PostgreSQL only

## Resource Usage

Target: <70% CPU/Memory utilization

| Component      | Requests               | Limits                   | Replicas |
| -------------- | ---------------------- | ------------------------ | -------- |
| Unleash Server | 200m CPU, 256Mi RAM    | 1 CPU, 1Gi RAM           | 2        |
| PostgreSQL     | 200m CPU, 256Mi RAM    | 500m CPU, 512Mi RAM      | 3        |
| **Total**      | **~1 CPU, ~1.5Gi RAM** | **~3.5 CPU, ~3.5Gi RAM** | -        |

## Troubleshooting

### Unleash pods not starting

```bash
# Check pod logs
kubectl logs -l app=unleash -n fawkes

# Check database connectivity
kubectl exec -it deployment/unleash -n fawkes -- wget -O- http://db-unleash-dev-rw:5432
```

### Database connection issues

```bash
# Verify PostgreSQL cluster is healthy
kubectl get cluster db-unleash-dev -n fawkes

# Check database credentials
kubectl get secret db-unleash-credentials -n fawkes -o yaml
```

### Feature flags not syncing

```bash
# Check Unleash logs
kubectl logs -l app=unleash -n fawkes --tail=100

# Verify API token is valid
curl -H "Authorization: ${UNLEASH_API_TOKEN}" https://unleash.fawkes.idp/api/admin/features
```

## Backup & Recovery

CloudNativePG automatically manages backups:

```bash
# Trigger manual backup
kubectl create -f backup-unleash.yaml

# List backups
kubectl get backups -n fawkes

# Restore from backup
kubectl create -f restore-unleash.yaml
```

## References

- [Unleash Documentation](https://docs.getunleash.io/)
- [OpenFeature Documentation](https://openfeature.dev/)
- [OpenFeature Unleash Provider](https://github.com/open-feature/js-sdk-contrib/tree/main/libs/providers/unleash)
- [Issue #99: Deploy Feature Flags Platform](https://github.com/paruff/fawkes/issues/99)
- [ADR-032: Product Analytics Platform Selection](../../docs/adr/ADR-032%20Product%20Analytics%20Platform%20Selection.md)

## Support

- **Platform Team**: #fawkes-platform (Mattermost)
- **Documentation**: https://docs.fawkes.idp/unleash
- **Issues**: https://github.com/paruff/fawkes/issues
