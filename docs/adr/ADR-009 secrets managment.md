# ADR-009: External Secrets Operator for Secrets Management

## Status
**Accepted** - December 2024

## Context

Fawkes integrates multiple services that require secure credential storage and management:

- **ArgoCD**: Git repository credentials, cluster credentials, SSO configuration
- **Jenkins**: Cloud provider credentials, Git tokens, artifact registry credentials, SonarQube tokens
- **Prometheus/Grafana**: Database passwords, OAuth client secrets, webhook tokens
- **Mattermost**: Database passwords, SMTP credentials, OAuth applications
- **Focalboard**: Database passwords, API tokens
- **Harbor**: Database passwords, S3/cloud storage credentials, registry tokens
- **PostgreSQL**: Database passwords for all services
- **Backstage**: GitHub tokens, cloud provider credentials, plugin API keys

### Security Requirements

1. **Secrets Rotation**: Ability to rotate credentials without application redeployment
2. **Encryption at Rest**: Secrets must be encrypted when stored
3. **Encryption in Transit**: Secrets must be encrypted during transmission
4. **Audit Logging**: Track who accessed which secrets and when
5. **Least Privilege**: Services should only access secrets they need
6. **Cloud Provider Integration**: Work with AWS, Azure, GCP secret stores
7. **GitOps Compatibility**: Secrets management must work with ArgoCD workflows
8. **Multi-Tenancy**: Isolate secrets between teams/namespaces
9. **Developer Experience**: Simple for platform engineers to use
10. **Cost**: Minimize operational costs for self-hosted deployment

### Current State Challenges

Without proper secrets management:
- **Kubernetes Secrets** are base64 encoded (not encrypted) and stored in etcd
- Credentials in Git repositories create security vulnerabilities
- Manual secret updates require kubectl commands and context switching
- No centralized audit trail for secret access
- Difficult to implement rotation without downtime
- Secrets sprawl across multiple systems

### Forces in Tension

- **Security** vs **Simplicity**: More secure solutions are often more complex
- **Self-Hosted** vs **Cloud-Managed**: Fawkes targets self-hosted, but many users run on cloud
- **GitOps-Native** vs **External Systems**: Should secrets be in Git (encrypted) or external stores?
- **Operator Complexity** vs **Manual Management**: Operators add abstraction but require learning
- **Cost** vs **Features**: Commercial solutions offer more features but add cost

## Decision

**We will use External Secrets Operator (ESO) as the primary secrets management solution for Fawkes.**

External Secrets Operator is a Kubernetes operator that integrates external secret management systems (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager, HashiCorp Vault, etc.) with Kubernetes. It synchronizes secrets from external stores into Kubernetes Secrets automatically.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Fawkes Platform                        │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   ArgoCD     │  │   Jenkins    │  │  Mattermost  │     │
│  │              │  │              │  │              │     │
│  │  consumes    │  │  consumes    │  │  consumes    │     │
│  │  K8s Secrets │  │  K8s Secrets │  │  K8s Secrets │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            │                                │
│                   ┌────────▼─────────┐                      │
│                   │  Kubernetes      │                      │
│                   │  Secrets         │                      │
│                   │  (synced)        │                      │
│                   └────────▲─────────┘                      │
│                            │                                │
│                   ┌────────┴─────────┐                      │
│                   │ External Secrets │                      │
│                   │    Operator      │                      │
│                   │                  │                      │
│                   │  - SecretStore   │                      │
│                   │  - ExternalSecret│                      │
│                   └────────▲─────────┘                      │
│                            │                                │
└────────────────────────────┼────────────────────────────────┘
                             │
                             │ Pulls secrets
                             │ (encrypted connection)
                             │
              ┌──────────────┴──────────────┐
              │                             │
        ┌─────▼──────┐              ┌──────▼──────┐
        │   AWS      │              │ HashiCorp   │
        │  Secrets   │              │   Vault     │
        │  Manager   │              │ (optional)  │
        └────────────┘              └─────────────┘
        
        OR Azure Key Vault, GCP Secret Manager, etc.
```

### Implementation Strategy

**Phase 1: MVP (AWS Secrets Manager)**
- Deploy External Secrets Operator via Helm
- Configure AWS Secrets Manager as backend
- Create SecretStore resources for each namespace
- Migrate critical secrets (ArgoCD, Jenkins, databases)
- Document secret creation and rotation procedures

**Phase 2: Multi-Backend Support**
- Add HashiCorp Vault support for on-premises deployments
- Support Azure Key Vault and GCP Secret Manager
- Create backend selection guide in documentation
- Provide Terraform modules for secret store provisioning

**Phase 3: Advanced Features**
- Implement secret rotation automation
- Add audit logging with OpenSearch integration
- Create Backstage plugin for secret lifecycle management
- Implement secret versioning and rollback

### Key Components

1. **External Secrets Operator**: Kubernetes operator (CNCF project)
2. **SecretStore**: Defines connection to external secret backend (namespace-scoped)
3. **ClusterSecretStore**: Defines connection to external secret backend (cluster-scoped)
4. **ExternalSecret**: Defines which secrets to sync from external store
5. **Backend**: AWS Secrets Manager (primary), with support for Vault, Azure KV, GCP SM

### Example Configuration

```yaml
# SecretStore for AWS Secrets Manager
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsstore
  namespace: fawkes-platform
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa

---
# ExternalSecret for ArgoCD admin password
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: argocd-secret
  namespace: argocd
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsstore
    kind: SecretStore
  target:
    name: argocd-secret
    creationPolicy: Owner
  data:
  - secretKey: admin.password
    remoteRef:
      key: fawkes/argocd/admin
      property: password
  - secretKey: server.secretkey
    remoteRef:
      key: fawkes/argocd/server
      property: secretkey
```

### Secret Organization Structure

```
AWS Secrets Manager Hierarchy:
fawkes/
├── argocd/
│   ├── admin                    # Admin password
│   ├── git-credentials          # Git repository tokens
│   └── cluster-credentials      # Target cluster credentials
├── jenkins/
│   ├── admin                    # Jenkins admin password
│   ├── github-token             # GitHub API token
│   ├── aws-credentials          # AWS access keys
│   └── sonarqube-token          # SonarQube integration token
├── postgresql/
│   ├── argocd-db               # ArgoCD database password
│   ├── jenkins-db              # Jenkins database password
│   ├── mattermost-db           # Mattermost database password
│   └── backstage-db            # Backstage database password
├── mattermost/
│   ├── admin                    # Initial admin password
│   ├── smtp-credentials         # Email integration
│   └── oauth-gitlab            # GitLab OAuth app
├── backstage/
│   ├── github-token             # GitHub integration
│   ├── cloud-providers         # AWS/Azure/GCP credentials
│   └── plugin-secrets          # Various plugin API keys
└── harbor/
    ├── admin                    # Harbor admin password
    ├── database                 # Harbor database password
    └── s3-credentials          # Object storage credentials
```

### Benefits

1. **Security**
   - Secrets encrypted at rest in AWS/Vault/etc.
   - Secrets encrypted in transit (TLS)
   - Kubernetes Secrets created just-in-time
   - Secret rotation without pod restarts (with reloader)

2. **GitOps-Friendly**
   - ExternalSecret manifests committed to Git (no sensitive data)
   - ArgoCD can manage ExternalSecret resources
   - Secret definitions are declarative
   - No credentials in Git repositories

3. **Cloud-Agnostic**
   - Support for AWS, Azure, GCP, Vault
   - Easy to switch backends
   - Works for on-premises (Vault) and cloud deployments

4. **Operational Simplicity**
   - Single operator to learn and maintain
   - Standard Kubernetes resources
   - Good documentation and community support
   - Helm chart for easy deployment

5. **Cost-Effective**
   - Open source (CNCF project)
   - No per-secret charges for Vault
   - AWS Secrets Manager: $0.40/secret/month + $0.05/10k API calls
   - Minimal infrastructure overhead

6. **Audit & Compliance**
   - Cloud provider audit logs (CloudTrail, etc.)
   - Kubernetes events for secret sync operations
   - Integration with monitoring stack

## Alternatives Considered

### Alternative 1: HashiCorp Vault (Standalone)

**Approach**: Deploy Vault cluster, use Vault Agent sidecar injection or Vault CSI provider.

**Pros**:
- Industry-standard secrets management
- Advanced features: dynamic secrets, PKI, encryption as a service
- Self-hosted option (no cloud dependency)
- Strong audit logging
- Secret versioning and leasing

**Cons**:
- **Complexity**: Requires separate Vault cluster management
- **Operational Overhead**: HA setup, unsealing, backup/restore
- **Learning Curve**: Vault concepts (policies, auth methods, engines)
- **Infrastructure Cost**: Minimum 3 nodes for HA, plus Consul/Raft backend
- **Sidecar Tax**: Vault Agent sidecars add memory/CPU overhead per pod

**Why Rejected**: 
Too complex for MVP. Vault is excellent but requires dedicated operations expertise. External Secrets Operator can use Vault as a backend when needed, giving us flexibility without forcing complexity on all users.

---

### Alternative 2: Sealed Secrets

**Approach**: Encrypt secrets into SealedSecret resources that can be committed to Git.

**Pros**:
- GitOps-native (secrets in Git, encrypted)
- No external dependencies
- Simple concept (encrypt/decrypt)
- Low operational overhead
- Free and open source

**Cons**:
- **Key Management Risk**: Sealing key stored in cluster; loss means all secrets unrecoverable
- **Rotation Difficulty**: Changing secrets requires re-encrypting and committing
- **No Centralized Audit**: Secret access not logged centrally
- **Limited Scope**: Only solves Git storage problem, not broader secret management
- **Breaking GitOps**: Secret updates require kubectl seal commands, then Git commit

**Why Rejected**: 
While simpler, Sealed Secrets don't solve secret rotation, centralized audit logging, or integration with cloud provider secret stores. For enterprise adoption, Fawkes needs proper external secret management.

---

### Alternative 3: Cloud Provider Secret Stores (Direct Integration)

**Approach**: Each application directly integrates with AWS Secrets Manager/Azure KV/GCP SM using CSI driver or SDKs.

**Pros**:
- No operator/middleware required
- Direct cloud provider integration
- Native IAM/RBAC support
- Managed service (no cluster overhead)
- Built-in rotation and auditing

**Cons**:
- **Vendor Lock-In**: Each cloud requires different integration approach
- **Application Changes**: Apps must be modified to read from secret stores
- **Inconsistent Experience**: Different APIs for AWS/Azure/GCP
- **No On-Premises Option**: Doesn't work with self-hosted Vault
- **CSI Limitations**: CSI Secret Store driver mounts secrets as files, not environment variables

**Why Rejected**: 
Breaks cloud-agnosticity and requires application changes. Fawkes should abstract the secret backend so users can choose AWS, Azure, GCP, or Vault without changing application manifests.

---

### Alternative 4: Kubernetes Secrets with etcd Encryption

**Approach**: Enable etcd encryption at rest, use Kubernetes Secrets directly.

**Pros**:
- No additional components
- Native Kubernetes
- Simple for developers
- No external dependencies

**Cons**:
- **No Rotation**: Changing secrets requires manual kubectl commands
- **No Audit Trail**: Limited visibility into secret access
- **Static Secrets**: Can't generate dynamic credentials
- **Git Risk**: Secrets in manifests (even base64) is security anti-pattern
- **No Centralization**: Secrets scattered across clusters

**Why Rejected**: 
Doesn't meet enterprise security requirements. While etcd encryption helps, it doesn't solve rotation, auditing, or GitOps-friendly secret management.

---

### Alternative 5: SOPS (Secrets OPerationS)

**Approach**: Encrypt secrets in Git using AWS KMS/GCP KMS/Azure Key Vault/PGP keys.

**Pros**:
- GitO
