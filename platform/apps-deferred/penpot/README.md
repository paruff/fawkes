# Penpot Design Tool

Penpot is an open-source design and prototyping platform for cross-domain teams.

## Overview

This directory contains the Kubernetes manifests for deploying Penpot to the Fawkes cluster. Penpot provides:

- **Open Source**: Self-hosted design tool with no vendor lock-in
- **Web-based**: No desktop installation required
- **SVG-based**: Native web standards for better integration
- **Real-time Collaboration**: Multiple designers working simultaneously
- **Developer Handoff**: Export designs with code snippets
- **API Access**: Automate design workflows and sync with component library

## Components

- **Penpot Backend**: Main application server
- **Penpot Frontend**: Web UI
- **PostgreSQL**: Database for Penpot data
- **Redis**: Session and cache management

## URLs

- **Design Tool**: https://penpot.fawkes.local
- **API**: https://penpot.fawkes.local/api

## Configuration

### Secrets Management

**IMPORTANT**: The default secrets in the deployment manifests use placeholder values (e.g., `CHANGE_ME_*`).

**Before deploying**:

1. **Local/Dev**: Update secrets in `deployment.yaml` and `db-penpot-credentials.yaml`
2. **Production**: Use External Secrets Operator to pull from vault/secret manager
3. Generate strong passwords (min 16 characters) for:
   - Database password (`penpot-db-credentials`)
   - Penpot secret key (`PENPOT_SECRET_KEY`)

Example using External Secrets Operator:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: penpot-secrets
  namespace: fawkes
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: penpot-secrets
  data:
    - secretKey: PENPOT_DATABASE_URI
      remoteRef:
        key: penpot/database-uri
    - secretKey: PENPOT_SECRET_KEY
      remoteRef:
        key: penpot/secret-key
```

### Environment Variables

Penpot is configured via environment variables in the deployment manifest:

- `PENPOT_PUBLIC_URI`: Public URL for Penpot
- `PENPOT_FLAGS`: Feature flags (enable-registration, etc.)
- `PENPOT_DATABASE_URI`: PostgreSQL connection string
- `PENPOT_REDIS_URI`: Redis connection string

### Storage

- Persistent volume for uploaded assets and media files
- Database storage via PostgreSQL

## Access Control

### Authentication

- Local authentication enabled by default
- OAuth integration with Backstage (planned)
- LDAP/SAML support available

### Authorization

- Team-based permissions
- Project-level access control
- Read-only viewer access for developers

## Integration with Backstage

The Backstage plugin allows viewing designs inline:

1. Navigate to a component in Backstage catalog
2. Add annotation: `penpot.io/design-id: <design-file-id>`
3. View the "Design" tab to see embedded designs

## Design-to-Code Workflow

1. **Design Phase**: Designers create mockups in Penpot
2. **Review**: Team reviews designs via Penpot sharing
3. **Export**: Export design specs and assets
4. **Component Mapping**: Map designs to design system components
5. **Implementation**: Developers reference designs in Backstage
6. **Sync**: Component library automatically synced with designs

## Deployment

```bash
# Deploy via ArgoCD
kubectl apply -f platform/apps/penpot-application.yaml

# Check status
kubectl get pods -n fawkes -l app=penpot

# Access logs
kubectl logs -n fawkes -l app=penpot-backend
```

## Resources

- [Penpot Documentation](https://help.penpot.app/)
- [Penpot API Reference](https://penpot.app/api/doc)
- [Design System Integration](../../docs/design/design-system.md)

## Support

- Issues: [GitHub Issues](https://github.com/paruff/fawkes/issues)
- Slack: #design-tools
