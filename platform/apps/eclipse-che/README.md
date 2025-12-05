# Eclipse Che Cloud Development Environment

This directory contains the deployment configuration for Eclipse Che, providing
Cloud Development Environments (CDEs) for the Fawkes platform.

## Overview

Eclipse Che enables developers to instantly provision standardized, pre-configured,
and AI-enabled development environments linked directly to their repositories,
eliminating local environment setup friction.

## Components

| Component | Description |
|-----------|-------------|
| `eclipse-che-application.yaml` | ArgoCD Application for Eclipse Che Operator |
| `workspace-quota.yaml` | ResourceQuota and LimitRange for workspaces |
| `network-policies.yaml` | Network policies for workspace isolation |
| `kustomization.yaml` | Kustomize configuration |

## Architecture

```text
                    ┌─────────────────────────────────┐
                    │         Backstage Portal        │
                    │     (CDE Launcher Component)    │
                    └────────────────┬────────────────┘
                                     │
                                     ▼
                    ┌─────────────────────────────────┐
                    │       Eclipse Che Server        │
                    │   (eclipse-che namespace)       │
                    │                                 │
                    │  • Dashboard                    │
                    │  • Devfile Registry             │
                    │  • Plugin Registry              │
                    │  • Workspace Controller         │
                    └────────────────┬────────────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
              ▼                      ▼                      ▼
┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐
│ che-user-developer1  │ │ che-user-developer2  │ │ che-user-developer3  │
│                      │ │                      │ │                      │
│  ┌────────────────┐  │ │  ┌────────────────┐  │ │  ┌────────────────┐  │
│  │  IDE Container │  │ │  │  IDE Container │  │ │  │  IDE Container │  │
│  │  (VS Code)     │  │ │  │  (VS Code)     │  │ │  │  (VS Code)     │  │
│  └────────────────┘  │ │  └────────────────┘  │ │  └────────────────┘  │
│  ┌────────────────┐  │ │  ┌────────────────┐  │ │  ┌────────────────┐  │
│  │  Dev Container │  │ │  │  AI Container  │  │ │  │  Dev Container │  │
│  │  (Python)      │  │ │  │  (TensorFlow)  │  │ │  │  (Node.js)     │  │
│  └────────────────┘  │ │  └────────────────┘  │ │  └────────────────┘  │
│  ┌────────────────┐  │ │  ┌────────────────┐  │ │  ┌────────────────┐  │
│  │  Vault Agent   │  │ │  │  Vault Agent   │  │ │  │  Vault Agent   │  │
│  └────────────────┘  │ │  └────────────────┘  │ │  └────────────────┘  │
└──────────────────────┘ └──────────────────────┘ └──────────────────────┘
```

## Access URLs

| Endpoint | URL | Purpose |
|----------|-----|---------|
| Che Dashboard | `https://che.fawkes.idp` | Workspace management UI |
| Devfile Registry | `https://che.fawkes.idp/devfile-registry` | Golden Path templates |
| Workspace IDE | `https://che.fawkes.idp/<workspace-id>` | Individual workspace access |

## Golden Path Devfiles

Available workspace templates in `/platform/devfiles/`:

| Template | Description | Resources |
|----------|-------------|-----------|
| `goldenpath-python` | Python development environment | 2 CPU, 4Gi Memory |
| `goldenpath-ai` | AI/ML development with GPU support | 8 CPU, 16Gi Memory, GPU |

## Resource Limits

Default workspace limits are enforced via `workspace-quota.yaml`:

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 500m | 2 |
| Memory | 1Gi | 4Gi |
| Storage | - | 20Gi |

## SSO Integration

Eclipse Che integrates with the platform's SSO provider:

1. User accesses Che Dashboard or Backstage CDE Launcher
2. Redirected to SSO login (same as Backstage)
3. Upon successful authentication, workspace access granted
4. SSO token used for Git operations within workspace

## Vault Integration

Workspaces access secrets via Vault Agent Sidecar:

```yaml
# Workspace annotations for Vault integration
vault.hashicorp.com/agent-inject: "true"
vault.hashicorp.com/role: "che-workspace"
vault.hashicorp.com/agent-inject-secret-db-creds: "secret/data/dev/database"
```

Secrets are mounted at `/vault/secrets/` within the workspace container.

## Operations

### View Active Workspaces

```bash
kubectl get pods -n eclipse-che -l app.kubernetes.io/component=workspace
```

### Check Resource Usage

```bash
kubectl describe resourcequota che-workspace-quota -n eclipse-che
```

### Stop Idle Workspaces

Workspaces automatically stop after 30 minutes of inactivity. To manually stop:

```bash
# Via Che CLI
chectl workspace:stop <workspace-id>

# Via kubectl
kubectl delete pod <workspace-pod> -n che-user-<username>
```

### Scale Che Server

```bash
kubectl scale deployment che-server -n eclipse-che --replicas=2
```

## Troubleshooting

### Workspace Won't Start

1. Check namespace quota: `kubectl describe resourcequota -n che-user-<username>`
2. Check events: `kubectl get events -n che-user-<username> --sort-by=.lastTimestamp`
3. Check Che Server logs: `kubectl logs -n eclipse-che deploy/che-server`

### IDE Connection Issues

1. Verify ingress: `kubectl get ingress -n eclipse-che`
2. Check TLS certificate: `kubectl describe certificate -n eclipse-che`
3. Test gateway: `curl -I https://che.fawkes.idp`

### Secrets Not Injected

1. Verify Vault Agent annotation on workspace pod
2. Check Vault role permissions: `vault read auth/kubernetes/role/che-workspace`
3. Check Agent logs: `kubectl logs <workspace-pod> -c vault-agent -n che-user-<username>`

## References

- [Eclipse Che Documentation](https://www.eclipse.org/che/docs/)
- [Devfile Specification](https://devfile.io/)
- [ADR-021: Eclipse Che CDE Strategy](../../../docs/adr/ADR-021%20eclipse-che-cde-strategy.md)
