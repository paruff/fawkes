# ADR-015: HashiCorp Vault for Centralized Secrets Management

## Status

Accepted

## Context

The Fawkes platform requires a robust, centralized secrets management solution
that provides:

- **High Availability**: Secrets infrastructure must be resilient to failures
- **Kubernetes Integration**: Native authentication for service accounts
- **Dynamic Secrets**: Automatic credential generation and rotation
- **Audit Logging**: Complete trail of secret access for compliance
- **Multi-method Injection**: Support for sidecar and CSI-based secret delivery

### Current State

The platform currently uses External Secrets Operator (ESO) to synchronize
secrets from cloud provider secret stores (AWS Secrets Manager, Azure Key Vault)
into Kubernetes Secrets. While ESO works well for cloud-native deployments, it
has limitations:

1. **Cloud Dependency**: Requires external cloud secret store
2. **No Dynamic Secrets**: Cannot generate credentials on-demand
3. **Limited Rotation**: Relies on external store for rotation logic
4. **On-premises Gap**: Difficult to use in air-gapped environments

### Requirements from Issue

1. Deploy HashiCorp Vault in HA mode (3 replicas)
2. Use Kubernetes Auth Method for service account authentication
3. Implement Vault Agent Sidecar for secret injection
4. Support CSI Secret Store Driver as alternative injection method
5. Enable automatic secret rotation without pod restarts
6. Enforce least-privilege access controls
7. Achieve RTO < 120 seconds for HA failover

## Decision

We will deploy **HashiCorp Vault** as the centralized secrets management
solution for the Fawkes platform, complementing (not replacing) the existing
External Secrets Operator.

### Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Secrets Management Layer                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────┐    ┌────────────────────────────────────┐  │
│  │    HashiCorp Vault (HA)    │    │   External Secrets Operator        │  │
│  │                            │    │                                    │  │
│  │  • Dynamic secrets         │    │  • Cloud provider integration     │  │
│  │  • K8s Auth                │    │  • AWS/Azure/GCP sync             │  │
│  │  • Agent sidecar           │    │  • Legacy secret migration        │  │
│  │  • CSI provider            │    │                                    │  │
│  │  • Audit logging           │    │                                    │  │
│  └────────────────────────────┘    └────────────────────────────────────┘  │
│              │                                    │                          │
│              │ Kubernetes Auth                    │ ClusterSecretStore       │
│              ▼                                    ▼                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                        Kubernetes Secrets                                ││
│  │  (Mounted as volumes or environment variables in application pods)      ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

### Deployment Configuration

#### High Availability

- **Replicas**: 3 (1 active + 2 standby)
- **Storage**: Raft integrated storage (no external database required)
- **Failover**: Automatic leader election via Raft consensus
- **RTO**: < 120 seconds

#### Storage Backend

We chose **Raft integrated storage** over PostgreSQL for:

1. **Simplicity**: No external database dependency
2. **Performance**: Optimized for Vault's access patterns
3. **HA Built-in**: Raft handles replication and failover
4. **Portability**: Works the same in any environment

#### Secret Injection Methods

| Method | Use Case | Pros | Cons |
|--------|----------|------|------|
| Vault Agent Sidecar | Most applications | Auto-rotation, no app changes | Extra container per pod |
| CSI Driver | Stateful apps, legacy | Native volume mount | No auto-rotation in files |
| Direct API | CI/CD pipelines | Full control | Requires Vault SDK/client |

### Kubernetes Auth Configuration

```text
Service Account → Kubernetes Auth → Vault Policy → Secrets Access
       │                 │                │               │
       │     Token JWT   │    Validate    │   Evaluate    │
       └────────────────►│───────────────►│──────────────►│
                         │                │               │
                     K8s API          Vault           KV Store
```

### Access Control Policies

| Role | Service Accounts | Allowed Paths |
|------|-----------------|---------------|
| jenkins | jenkins, jenkins-agent | secret/data/fawkes/cicd/*, apps/*, shared/* |
| backstage | backstage | secret/data/fawkes/core/backstage/*, shared/* |
| platform-service | * in fawkes namespace | secret/data/fawkes/{namespace}/*, shared/* |
| observability | grafana, prometheus | secret/data/fawkes/observability/*, shared/* |

### Integration with Existing ESO

Vault and ESO will coexist:

1. **ESO**: Cloud-native deployments, existing cloud secret stores
2. **Vault**: On-premises, dynamic secrets, advanced use cases

A `ClusterSecretStore` for Vault can be configured in ESO for migration:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "http://vault.vault.svc:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
```

## Consequences

### Positive

1. **Unified Secrets Management**: Single source of truth for platform secrets
2. **Dynamic Secrets**: Database credentials generated on-demand with TTL
3. **Automatic Rotation**: Vault Agent refreshes secrets without pod restart
4. **Audit Compliance**: Complete access log for regulatory requirements
5. **On-premises Ready**: Works in air-gapped and hybrid environments
6. **Kubernetes Native**: Auth via service accounts, no extra credentials

### Negative

1. **Operational Complexity**: Vault cluster requires monitoring and maintenance
2. **Unseal Process**: Manual intervention needed after restarts (mitigate with
   auto-unseal)
3. **Learning Curve**: Teams need to learn Vault policies and injection patterns
4. **Resource Overhead**: Additional pods for Vault cluster and injectors

### Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Vault cluster unavailable | HA with 3 replicas, monitoring alerts |
| Unseal keys lost | Store in secure location, use cloud auto-unseal |
| Policy misconfiguration | Infrastructure as code, policy testing |
| Agent injection failures | Webhook fallback policy, health monitoring |

## Alternatives Considered

### 1. External Secrets Operator Only (Current State)

**Rejected because**: Does not provide dynamic secrets, on-premises support, or
native rotation capabilities.

### 2. AWS Secrets Manager / Azure Key Vault (Direct)

**Rejected because**: Cloud vendor lock-in, no on-premises support, no
Kubernetes-native auth.

### 3. Sealed Secrets

**Rejected because**: Secrets in Git (compliance risk), no dynamic secrets, key
management burden.

### 4. CyberArk Conjur

**Rejected because**: Commercial licensing, more complex than needed, smaller
community.

## Implementation Plan

### Phase 1: Core Deployment (Week 1)

- [ ] Deploy Vault HA cluster via ArgoCD
- [ ] Configure Kubernetes Auth Method
- [ ] Create platform access policies
- [ ] Set up audit logging

### Phase 2: Integration (Week 2)

- [ ] Deploy Vault CSI Driver
- [ ] Configure SecretProviderClasses for services
- [ ] Migrate Jenkins to Vault secrets
- [ ] Update Golden Path pipeline for Vault

### Phase 3: Documentation & Training (Week 3)

- [ ] Developer integration guide
- [ ] Dojo learning module
- [ ] Runbook for operations
- [ ] Grafana dashboards for monitoring

## References

- [HashiCorp Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Vault Agent Injector](https://developer.hashicorp.com/vault/docs/platform/k8s/injector)
- [Kubernetes Auth Method](https://developer.hashicorp.com/vault/docs/auth/kubernetes)
- [CSI Secret Store Driver](https://secrets-store-csi-driver.sigs.k8s.io/)
- [ADR-009: Secrets Management](ADR-009%20secrets%20managment.md)
