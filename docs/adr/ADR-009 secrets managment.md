# ADR-009: Secrets Management for Platform Services

## Status

Accepted

## Context

The Fawkes platform integrates numerous services that require secure storage and management of sensitive credentials:

**Service Credentials Required**:

- **ArgoCD**: Admin password, GitHub/GitLab tokens, webhook secrets, cluster credentials
- **Jenkins**: Admin password, GitHub tokens, Docker registry credentials, cloud provider credentials, SSH keys
- **PostgreSQL**: Root password, application user passwords (Backstage, Mattermost, SonarQube, Harbor)
- **Mattermost**: Database password, SMTP credentials, OAuth2 client secrets, encryption keys
- **Harbor**: Admin password, database password, Redis password, registry storage credentials
- **SonarQube**: Admin password, database password, authentication tokens
- **Grafana**: Admin password, database password, OAuth2 secrets, data source credentials
- **Backstage**: Database password, GitHub tokens, catalog integration tokens, OAuth2 secrets
- **Prometheus**: Basic auth credentials, remote write credentials, alertmanager credentials
- **External Secrets Operator**: Cloud provider credentials (AWS, Azure, GCP service accounts)

**Security Requirements**:

- Secrets must never be stored in Git repositories (even encrypted)
- Secrets must be encrypted at rest in the Kubernetes cluster
- Secrets must be encrypted in transit
- Secrets must support rotation without service downtime
- Secrets must have audit logging for access and changes
- Secrets must support multi-tenancy (namespace isolation)
- Secrets must work across cloud providers and on-premises
- Secrets must integrate with external secret stores (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager, HashiCorp Vault)

**Operational Requirements**:

- Automatic secret injection into pods (no manual mounting)
- Secret synchronization from external stores
- Automatic rotation support
- Disaster recovery (backup/restore)
- GitOps compatibility (declarative, version-controlled configuration without exposing secrets)
- Easy troubleshooting (visibility without exposing plaintext)
- Low operational overhead for platform team
- Clear separation between secret metadata (who/what/where) and secret values

**Developer Experience Requirements**:

- Simple secret consumption (environment variables or file mounts)
- No custom code required in applications
- Clear documentation and examples
- Minimal learning curve for dojo students
- Self-service secret creation (with RBAC controls)

**Dojo Learning Requirements**:

- Students need isolated secret environments per learner
- Must support rapid provisioning/teardown
- Should demonstrate enterprise-grade practices
- Must work in local/development environments (Minikube, Kind)

## Decision

We will use **External Secrets Operator (ESO)** as the primary secrets management solution for the Fawkes platform, with support for multiple backend secret stores.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  External Secret Stores (Backends)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ AWS Secrets  │  │ Azure Key    │  │  HashiCorp   │     │
│  │   Manager    │  │    Vault     │  │    Vault     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                 │                  │              │
└─────────┼─────────────────┼──────────────────┼──────────────┘
          │                 │                  │
          └─────────────────┴──────────────────┘
                            │
                            v
          ┌─────────────────────────────────────┐
          │  External Secrets Operator (ESO)    │
          │  - Secret synchronization           │
          │  - Automatic rotation               │
          │  - Multi-backend support            │
          └─────────────────────────────────────┘
                            │
                            v
          ┌─────────────────────────────────────┐
          │  Kubernetes Secrets (Encrypted)     │
          │  - namespace: fawkes-core           │
          │  - namespace: fawkes-collaboration  │
          │  - namespace: fawkes-observability  │
          │  - namespace: learner-*             │
          └─────────────────────────────────────┘
                            │
          ┌─────────────────┴─────────────────┐
          │                                    │
          v                                    v
    ┌──────────┐                        ┌──────────┐
    │ ArgoCD   │                        │ Jenkins  │
    │ Pod      │                        │ Pod      │
    │          │                        │          │
    │ ENV vars │                        │ Files in │
    │ from     │                        │ /secrets │
    │ secrets  │                        │          │
    └──────────┘                        └──────────┘
```

### Backend Strategy

**Multi-Backend Support** (Choose based on environment):

1. **AWS Secrets Manager** (AWS deployments)
2. **Azure Key Vault** (Azure deployments)
3. **GCP Secret Manager** (GCP deployments)
4. **HashiCorp Vault** (On-premises, multi-cloud, advanced use cases)
5. **Kubernetes Secrets** (Development, learning environments)

**Default Recommendation by Environment**:

- **Production**: Cloud provider secret store (AWS/Azure/GCP)
- **Staging**: Cloud provider secret store
- **Development**: Kubernetes secrets (ESO optional)
- **Dojo/Learning**: Kubernetes secrets with ESO synchronization from templates

### Core Components

**1. External Secrets Operator**

- Deployed in `fawkes-system` namespace
- Monitors `ExternalSecret` and `SecretStore` resources
- Synchronizes secrets from external stores to Kubernetes
- Automatic refresh interval (configurable, default 1 hour)

**2. SecretStore Resources**
Define connections to external secret backends per namespace:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsmanager
  namespace: fawkes-core
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
```

**3. ClusterSecretStore**
Cluster-wide secret store for shared secrets:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.fawkes.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "fawkes-platform"
```

**4. ExternalSecret Resources**
Define which secrets to sync and how:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: argocd-credentials
  namespace: fawkes-core
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: argocd-secret
    creationPolicy: Owner
  data:
    - secretKey: admin.password
      remoteRef:
        key: fawkes/argocd/admin
        property: password
    - secretKey: github.token
      remoteRef:
        key: fawkes/github/integration
        property: token
```

### Secret Naming Convention

**Path Structure in External Stores**:

```
fawkes/
  ├── core/
  │   ├── argocd/
  │   │   ├── admin-password
  │   │   ├── github-token
  │   │   └── webhook-secret
  │   ├── backstage/
  │   │   ├── postgres-password
  │   │   ├── github-token
  │   │   └── oauth2-client-secret
  │   └── postgres/
  │       ├── root-password
  │       └── replication-password
  ├── collaboration/
  │   ├── mattermost/
  │   │   ├── postgres-password
  │   │   ├── smtp-password
  │   │   └── encryption-key
  │   └── focalboard/
  │       └── session-secret
  ├── cicd/
  │   ├── jenkins/
  │   │   ├── admin-password
  │   │   ├── github-token
  │   │   ├── docker-registry-password
  │   │   └── aws-credentials
  │   └── harbor/
  │       ├── admin-password
  │       ├── postgres-password
  │       └── s3-credentials
  └── observability/
      ├── grafana/
      │   ├── admin-password
      │   └── oauth2-client-secret
      └── prometheus/
          └── remote-write-password
```

### Example Configurations

**ArgoCD Admin Password**:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: argocd-secret
  namespace: fawkes-core
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: argocd-secret
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        admin.password: "{{ .adminPassword | bcrypt }}"
        server.secretkey: "{{ .serverSecretKey }}"
  dataFrom:
    - extract:
        key: fawkes/core/argocd/credentials
```

**Jenkins Credentials (Multiple Secrets)**:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: jenkins-credentials
  namespace: fawkes-cicd
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: jenkins-credentials
    creationPolicy: Owner
  data:
    - secretKey: admin-user
      remoteRef:
        key: fawkes/cicd/jenkins/admin
        property: username
    - secretKey: admin-password
      remoteRef:
        key: fawkes/cicd/jenkins/admin
        property: password
    - secretKey: github-token
      remoteRef:
        key: fawkes/github/integration
        property: token
    - secretKey: docker-config.json
      remoteRef:
        key: fawkes/cicd/docker-registry
        property: config
```

**PostgreSQL Passwords (Templated)**:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: postgres-credentials
  namespace: fawkes-core
spec:
  refreshInterval: 24h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: postgres-credentials
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        postgres-password: "{{ .rootPassword }}"
        backstage-password: "{{ .backstagePassword }}"
        argocd-password: "{{ .argocdPassword }}"
        connection-string: "postgresql://postgres:{{ .rootPassword }}@postgres.fawkes-core.svc.cluster.local:5432/postgres"
  dataFrom:
    - extract:
        key: fawkes/core/postgres/passwords
```

### Secret Rotation Strategy

**Automatic Rotation**:

1. Update secret in external store (AWS Secrets Manager, Vault, etc.)
2. ESO detects change on next refresh interval (default 1 hour)
3. ESO updates Kubernetes secret
4. Pods with secret volumes automatically get updated files
5. Pods with environment variables require restart (handled by Reloader)

**Reloader Integration**:
Deploy Reloader to automatically restart pods when secrets change:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: jenkins-config
  namespace: fawkes-cicd
  annotations:
    reloader.stakater.com/match: "true"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: fawkes-cicd
  annotations:
    reloader.stakater.com/auto: "true"
spec:
  template:
    spec:
      containers:
        - name: jenkins
          env:
            - name: ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: jenkins-credentials
                  key: admin-password
```

### Security Hardening

**1. Encryption at Rest**:
Enable Kubernetes secret encryption:

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <base64-encoded-32-byte-key>
      - identity: {}
```

**2. RBAC Policies**:
Restrict access to secrets by namespace and role:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: fawkes-core
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list"]
    resourceNames: ["argocd-secret", "postgres-credentials"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: argocd-secret-access
  namespace: fawkes-core
subjects:
  - kind: ServiceAccount
    name: argocd-server
    namespace: fawkes-core
roleRef:
  kind: Role
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

**3. Pod Security Standards**:
Enforce that pods cannot access secrets they don't need:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: jenkins
  namespace: fawkes-cicd
spec:
  serviceAccountName: jenkins
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
    - name: jenkins
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
```

**4. Audit Logging**:
Enable Kubernetes audit logs for secret access:

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: Metadata
    resources:
      - group: ""
        resources: ["secrets"]
    omitStages:
      - RequestReceived
```

### AWS Secrets Manager Integration

**IAM Role for ESO (IRSA)**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789012:secret:fawkes/*"
    }
  ]
}
```

**Service Account Annotation**:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets-sa
  namespace: fawkes-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/fawkes-external-secrets
```

**SecretStore for AWS**:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
            namespace: fawkes-system
```

### HashiCorp Vault Integration (Alternative)

**Vault Setup**:

```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
    kubernetes_host="https://kubernetes.default.svc:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Create policy
vault policy write fawkes-secrets - <<EOF
path "secret/data/fawkes/*" {
  capabilities = ["read"]
}
EOF

# Create Kubernetes role
vault write auth/kubernetes/role/fawkes-platform \
    bound_service_account_names=external-secrets-sa \
    bound_service_account_namespaces=fawkes-system \
    policies=fawkes-secrets \
    ttl=24h
```

**ClusterSecretStore for Vault**:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.fawkes.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "fawkes-platform"
          serviceAccountRef:
            name: external-secrets-sa
            namespace: fawkes-system
```

### Disaster Recovery

**Backup Strategy**:

1. **External Store**: Secrets in AWS/Azure/GCP have built-in backup/versioning
2. **ExternalSecret Manifests**: Version controlled in Git (no secret values)
3. **Emergency Access**: Break-glass procedures documented
4. **Key Rotation Records**: Maintain audit log of all rotations

**Recovery Procedure**:

```bash
# 1. Restore External Secrets Operator
kubectl apply -f manifests/external-secrets-operator/

# 2. Restore SecretStore configurations
kubectl apply -f manifests/secret-stores/

# 3. ESO automatically syncs all ExternalSecret resources
kubectl apply -f manifests/external-secrets/

# 4. Verify secret creation
kubectl get secrets -A | grep fawkes

# 5. Restart pods if needed
kubectl rollout restart deployment -n fawkes-core
```

## Consequences

### Positive

1. **GitOps Compatible**: ExternalSecret manifests can be stored in Git without exposing secrets
2. **Multi-Cloud Support**: Works with AWS, Azure, GCP, Vault, and 20+ providers
3. **Automatic Synchronization**: Secrets updated automatically from external stores
4. **Audit Trail**: All secret access logged in external store (AWS CloudTrail, Vault audit)
5. **Separation of Concerns**: Platform team manages external stores, developers consume via Kubernetes
6. **Rotation Support**: Built-in support for automatic secret rotation
7. **Namespace Isolation**: Secrets scoped to namespaces, preventing cross-namespace access
8. **CNCF Project**: External Secrets Operator is a CNCF sandbox project with active community
9. **Low Operational Overhead**: Minimal maintenance once configured
10. **Developer Friendly**: Secrets consumed as standard Kubernetes secrets (no custom code)

### Negative

1. **Additional Component**: ESO adds operational complexity (another component to monitor)
2. **External Dependency**: Requires external secret store (AWS Secrets Manager, Vault, etc.)
3. **Sync Delay**: Secrets not immediately updated (default 1-hour refresh interval)
4. **Initial Setup Complexity**: Learning curve for ExternalSecret manifests
5. **Cost**: External secret stores have usage costs (AWS Secrets Manager: $0.40/secret/month)
6. **Troubleshooting**: Adds layer between external store and Kubernetes (more places for issues)
7. **IRSA/Workload Identity**: Requires cloud IAM integration (IRSA on AWS, Workload Identity on GCP)

### Neutral

1. **Templating Required**: Complex secret transformations need template syntax
2. **Reloader Dependency**: Pods with env vars need Reloader for automatic updates
3. **Multi-Store Management**: Organizations using multiple clouds need multiple SecretStore configs
4. **Version Pinning**: Need to manage ESO version upgrades carefully

## Alternatives Considered

### Alternative 1: Sealed Secrets

**Pros**:

- Secrets encrypted and stored directly in Git
- No external dependency (secret store)
- Simple mental model (encrypt secret, commit, controller decrypts)
- Good for GitOps workflows
- No cost for external secret store

**Cons**:

- Secrets still in Git (even if encrypted) - compliance/security concerns
- Key management burden (must protect unsealing key)
- No integration with external secret stores (AWS Secrets Manager, Vault)
- Rotation requires re-encrypting and committing
- Limited to Kubernetes secrets (no external source of truth)
- If unsealing key compromised, all secrets exposed

**Reason for Rejection**: Sealed Secrets forces secrets into Git, which violates many compliance frameworks (SOC2, PCI-DSS). Organizations with established secret management (Vault, AWS Secrets Manager) cannot leverage existing infrastructure. The sealed secret key becomes a single point of failure.

### Alternative 2: HashiCorp Vault (Direct Integration)

**Pros**:

- Industry-leading secret management solution
- Advanced features (dynamic secrets, leasing, PKI)
- Superior audit logging and access controls
- Secret engines for databases, clouds, SSH, PKI
- Multi-tenancy and namespace support
- Secret rotation and expiration built-in

**Cons**:

- High operational overhead (Vault cluster management, upgrades, HA)
- Requires Vault expertise on platform team
- Steep learning curve for developers
- Significant infrastructure costs (Vault Enterprise for advanced features)
- Applications need Vault-aware clients or sidecar injectors
- Overkill for basic secret storage needs

**Reason for Rejection**: While Vault is excellent, it requires dedicated operational expertise and introduces significant complexity. ESO provides integration with Vault for organizations that already have it, while also supporting simpler backends (AWS Secrets Manager) for teams without Vault. This gives Fawkes flexibility.

### Alternative 3: Kubernetes Secrets (Native, Encrypted at Rest)

**Pros**:

- No additional components (native Kubernetes)
- Zero operational overhead
- Simple API (kubectl create secret)
- Well understood by developers
- No cost

**Cons**:

- No integration with external secret stores
- Manual rotation (no automation)
- No audit logging (beyond Kubernetes audit logs)
- Secrets must be base64 encoded and put in manifests (risky)
- No centralized secret management
- Difficult to share secrets across clusters
- Limited access controls (namespace-level only)

**Reason for Rejection**: Native Kubernetes secrets are suitable for development but inadequate for production. Lack of integration with external stores means organizations cannot leverage existing secret infrastructure. No rotation support creates operational burden. However, Kubernetes secrets remain the _consumption_ mechanism (ESO creates them), so developers still use the familiar API.

### Alternative 4: Cloud-Specific Solutions (AWS Secrets CSI Driver, Azure Key Vault CSI)

**Pros**:

- Deep cloud integration (native IAM, audit logging)
- No intermediate controller (CSI driver directly mounts secrets)
- Lower latency (secrets mounted on-demand)
- Automatic rotation via CSI driver
- Minimal resource overhead

**Cons**:

- **Cloud vendor lock-in** (different implementation per cloud)
- Cannot work on-premises or in multi-cloud
- Different configuration per cloud (AWS ≠ Azure ≠ GCP)
- Limited to volume mounts (no environment variables without wrapper)
- Learner environments need cloud accounts
- Inconsistent developer experience across environments

**Reason for Rejection**: Violates Fawkes' cloud portability principle. Developers and learners should have consistent experience regardless of deployment target. ESO provides abstraction layer that works with any backend, while CSI drivers lock you into cloud-specific patterns.

### Alternative 5: SOPS (Secrets OPerationS)

**Pros**:

- Encrypt secrets in Git with AWS KMS, GCP KMS, Azure Key Vault, PGP
- GitOps-friendly (encrypted secrets committed)
- Supports multiple formats (YAML, JSON, ENV, INI)
- Integration with FluxCD and ArgoCD
- Partial encryption (encrypt values, leave keys plaintext)

**Cons**:

- Secrets still in Git (compliance concerns)
- Requires KMS key management
- Manual rotation (re-encrypt and commit)
- ArgoCD integration complex (requires custom tooling)
- No runtime secret refresh (static secrets)
- Limited audit trail (Git commits only)

**Reason for Rejection**: Similar issues to Sealed Secrets - storing secrets in Git creates compliance and security challenges. SOPS is excellent for configuration management, but ESO provides better separation between secret storage (external) and consumption (Kubernetes). Organizations prefer secrets in dedicated secret stores, not Git.

### Alternative 6: Kubernetes External Secrets (Older Project)

**Pros**:

- Original external secrets project (inspired ESO)
- Similar concept to ESO
- Works with AWS, GCP, Azure

**Cons**:

- **Deprecated in favor of External Secrets Operator**
- Smaller community and less active development
- Fewer backend integrations
- Less mature API (v1alpha1)
- Not CNCF project

**Reason for Rejection**: External Secrets Operator (ESO) is the successor project with broader community, CNCF sandbox status, and more active development. No reason to use the deprecated version when ESO provides superset of functionality.

## Implementation Plan

### Phase 1: MVP (Week 4 of Sprint 01)

**Day 1-2: External Secrets Operator Deployment** [8 hours]

1. Deploy ESO via Helm chart to `fawkes-system` namespace
2. Configure RBAC for ESO service account
3. Set up AWS IRSA role for ESO (or cloud-specific workload identity)
4. Create ClusterSecretStore for AWS Secrets Manager
5. Verify ESO controller is running and can authenticate

**Day 3: Core Service Secrets** [6 hours] 6. Create secrets in AWS Secrets Manager for:

- PostgreSQL (root password, database passwords)
- ArgoCD (admin password, GitHub token)
- Backstage (database password, GitHub token, OAuth2 secrets)

7. Create ExternalSecret manifests for each
8. Verify Kubernetes secrets created successfully
9. Test secret consumption by deploying test pod

**Day 4: CI/CD Service Secrets** [6 hours] 10. Create secrets in AWS Secrets Manager for: - Jenkins (admin password, GitHub token, Docker credentials) - Harbor (admin password, database password, S3 credentials) 11. Create ExternalSecret manifests 12. Deploy Jenkins and Harbor with external secrets 13. Verify services start successfully with secrets

**Day 5: Documentation & Validation** [4 hours] 14. Document secret naming conventions 15. Create runbook for secret rotation 16. Write troubleshooting guide 17. Create Dojo module outline for secrets management

### Phase 2: Advanced Features (Week 5)

**Secret Rotation** [4 hours]

- Deploy Reloader for automatic pod restarts
- Document rotation procedures for each service
- Test rotation end-to-end for PostgreSQL
- Create Grafana alerts for secret sync failures

**Multi-Environment Setup** [4 hours]

- Create separate secret paths for dev/staging/prod
- Configure namespace-scoped SecretStores
- Implement RBAC for namespace isolation
- Test learner namespace provisioning with secrets

**Backup & Disaster Recovery** [3 hours]

- Document break-glass procedures
- Create backup scripts for ExternalSecret manifests
- Test secret recovery procedures
- Create incident response runbook

### Phase 3: Dojo Integration (Week 6)

**Yellow Belt - Module 3: "Securing Secrets"** [8 hours]

**Learning Objectives**:

- Understand secrets management anti-patterns (secrets in Git, plain text)
- Learn External Secrets Operator concepts
- Create ExternalSecret manifests
- Implement secret rotation
- Troubleshoot secret sync issues

**Hands-On Lab**:

1. Create secret in AWS Secrets Manager (or learner-specific backend)
2. Deploy ExternalSecret manifest to learner namespace
3. Consume secret in test application (environment variables and volume mounts)
4. Rotate secret and observe automatic sync
5. Troubleshoot intentionally broken ExternalSecret

**Assessment**:

- Quiz on secrets best practices (10 questions)
- Practical: Deploy application with database password from external store
- Troubleshoot secret sync failure scenario

**Time**: 2 hours (45 min theory + 75 min hands-on)

### Phase 4: Production Hardening (Week 7)

**Security Hardening** [6 hours]

- Enable Kubernetes secret encryption at rest
- Implement least-privilege RBAC policies
- Configure audit logging for secret access
- Security scan all secret configurations
- Penetration testing for secret access paths

**Monitoring & Alerting** [4 hours]

- Create Prometheus metrics for ESO
- Build Grafana dashboard for secret sync status
- Configure alerts for sync failures
- Set up alert for certificate/secret expiration
- Integrate with PagerDuty/OpsGenie

**Documentation** [4 hours]

- Complete architecture documentation with diagrams
- Write comprehensive troubleshooting guide
- Create secret rotation playbook
- Document disaster recovery procedures
- Create RBAC guidelines

## Monitoring & Observability

### Key Metrics

**External Secrets Operator Metrics**:

```
# Sync success rate
```
