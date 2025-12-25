---
title: Zero Trust Security Model - Vault, Kyverno, and Ingress Integration
description: How Vault, Kyverno, and Istio/Ingress work together to implement defense in depth
---

# Zero Trust Security Model: Never Trust, Always Verify

## Context

Traditional security models operate on the **perimeter defense** principle: hard outer shell (firewall), soft interior (trusted network). Once you're inside the network, you're trusted. This worked when datacenters had literal walls and employees sat in offices.

But modern cloud-native applications break these assumptions:

- **No perimeter** - Services span multiple clouds, regions, networks
- **Ephemeral workloads** - Containers are created and destroyed constantly
- **Lateral movement** - A compromised pod can talk to others on the same network
- **Supply chain attacks** - Third-party dependencies could be malicious

The solution is **Zero Trust Architecture**: assume breach, verify everything, and grant least-privilege access at every layer.

Fawkes implements Zero Trust through the integration of three key components:

- **HashiCorp Vault** - Secrets management and identity
- **Kyverno** - Policy-as-Code enforcement
- **Istio/Ingress** - Network policy and mTLS

This document explains how these pieces work together to create defense in depth.

## The Problem: Trust-Based Security Fails in Kubernetes

### The Traditional "Trust the Network" Approach

In legacy architectures:

```
Internet → Firewall → Internal Network (Trusted Zone)
```

**Inside the firewall:**

- Services communicate over HTTP (no encryption)
- Authentication is often "source IP" or "same VLAN"
- Secrets stored in environment variables or config files
- Policies enforced at deploy time (if at all)

**What Could Go Wrong?**

```mermaid
graph TB
    A[Compromised App Pod] -->|No network policy| B[Database Pod]
    A -->|No network policy| C[Secret Store]
    A -->|No network policy| D[Other App Pods]

    style A fill:#ff6b6b
```

1. **Lateral Movement**: Compromised pod accesses database directly
2. **Secret Sprawl**: Environment variables visible in `kubectl describe pod`
3. **No Audit Trail**: Who accessed what secret? Unknown.
4. **Static Credentials**: Secrets rotate manually (if ever)
5. **Policy Drift**: Deployed configuration diverges from security requirements

### Real-World Attack Scenario

**Day 1**: Developer deploys app with a vulnerable dependency (Log4Shell, typo-squatting, etc.)

**Day 2**: Attacker exploits vulnerability, gains remote code execution in pod

**Day 3**: Attacker pivots:

```bash
# From inside compromised pod
curl http://database:5432  # No network policy blocks this
env | grep DB_PASSWORD     # Secrets in environment variables
kubectl get secrets -n prod  # Service account has excessive permissions
```

**Day 4**: Attacker exfiltrates customer data, deploys cryptominer, pivots to other clusters

**Time to Detect**: Days to weeks
**Blast Radius**: Entire cluster potentially compromised

## The Solution: Layered Zero Trust Defense

Fawkes implements **defense in depth** with multiple verification layers:

```mermaid
graph TB
    A[Incoming Request] -->|1. TLS Termination| B[Ingress/Istio]
    B -->|2. Identity Verification| C[mTLS Between Services]
    C -->|3. Policy Check| D[Kyverno Admission]
    D -->|4. Secret Injection| E[Vault Agent]
    E -->|5. Application| F[Pod]

    style B fill:#2196F3
    style D fill:#FF9800
    style E fill:#4CAF50
```

### Layer 1: Network Security with Istio/Ingress

**Principle**: Encrypted transport, verified identity

#### Ingress Controller (External Traffic)

**Purpose**: TLS termination for traffic entering the cluster

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - api.fawkes.io
      secretName: api-tls
  rules:
    - host: api.fawkes.io
      http:
        paths:
          - path: /
            backend:
              service:
                name: api-service
                port:
                  number: 8080
```

**What This Provides:**

- ✅ **Encryption in transit** - HTTPS for all external traffic
- ✅ **Certificate management** - Cert-manager automates TLS renewal
- ✅ **SNI routing** - Multiple services, one load balancer
- ✅ **DDoS mitigation** - Rate limiting, WAF integration (if enabled)

#### Istio Service Mesh (Internal Traffic)

**Purpose**: Mutual TLS (mTLS) for pod-to-pod communication

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT # Require mTLS for all traffic
```

**What This Provides:**

- ✅ **Zero trust networking** - Pods authenticate to each other via certificates
- ✅ **Encrypted service mesh** - Even inside the cluster, traffic is encrypted
- ✅ **Identity-based access** - Authorization based on service identity, not IP
- ✅ **Observability** - Istio traces every request (distributed tracing)

**Example AuthorizationPolicy:**

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: api-to-database
  namespace: production
spec:
  selector:
    matchLabels:
      app: postgres
  action: ALLOW
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/production/sa/api-service"]
      to:
        - operation:
            ports: ["5432"]
```

**Translation**: Only the `api-service` service account can connect to Postgres port 5432. Everything else denied.

### Layer 2: Policy Enforcement with Kyverno

**Principle**: Prevent bad configurations from ever being deployed

Kyverno is a **Kubernetes-native policy engine** that validates, mutates, and generates resources based on policy rules.

#### Policy Types

**1. Validation Policies (Block Bad Configs)**

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-non-root
spec:
  validationFailureAction: Enforce # Block deployment if violated
  rules:
    - name: check-containers-non-root
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Containers must not run as root"
        pattern:
          spec:
            containers:
              - securityContext:
                  runAsNonRoot: true
```

**Effect**: Pods running as root are **rejected at admission time**.

**2. Mutation Policies (Auto-Fix Configs)**

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-security-context
spec:
  rules:
    - name: add-safe-security-context
      match:
        any:
          - resources:
              kinds:
                - Pod
      mutate:
        patchStrategicMerge:
          spec:
            securityContext:
              runAsNonRoot: true
              runAsUser: 1000
              fsGroup: 2000
              seccompProfile:
                type: RuntimeDefault
```

**Effect**: Even if developer forgets, security context is **automatically added**.

**3. Generation Policies (Auto-Create Resources)**

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: generate-network-policy
spec:
  rules:
    - name: default-deny-ingress
      match:
        any:
          - resources:
              kinds:
                - Namespace
      generate:
        kind: NetworkPolicy
        name: default-deny-ingress
        namespace: "{{request.object.metadata.name}}"
        data:
          spec:
            podSelector: {}
            policyTypes:
              - Ingress
```

**Effect**: Every new namespace automatically gets a **default-deny network policy**.

#### Audit vs. Enforce Modes

Kyverno supports two enforcement modes:

| Mode        | Behavior                      | Use Case                                   |
| ----------- | ----------------------------- | ------------------------------------------ |
| **Enforce** | Block non-compliant resources | Production environments, critical policies |
| **Audit**   | Allow but log violations      | Testing new policies, gradual rollout      |

**Fawkes Approach:**

1. **Phase 1 (Audit)**: Deploy policy in audit mode, observe violations
2. **Phase 2 (Remediation)**: Work with teams to fix violations
3. **Phase 3 (Enforce)**: Switch to enforce mode, block new violations

**Example Policy Report:**

```yaml
apiVersion: wgpolicyk8s.io/v1alpha2
kind: PolicyReport
metadata:
  name: polr-ns-production
  namespace: production
results:
  - policy: require-non-root
    rule: check-containers-non-root
    result: fail
    resources:
      - apiVersion: v1
        kind: Pod
        name: legacy-app-pod-123
        namespace: production
    message: "Container 'app' runs as root user"
```

**Visibility**: Platform team sees violations, can track compliance over time.

### Layer 3: Secrets Management with Vault

**Principle**: Secrets are ephemeral, dynamically generated, and audited

#### The Problem with Kubernetes Secrets

Native Kubernetes Secrets are **not secret**:

- Stored **base64-encoded** (not encrypted) in etcd
- Visible to anyone with `get secrets` permission
- Static (no automatic rotation)
- No audit trail (who read the secret?)

#### Vault's Solution

**HashiCorp Vault** is a secrets management platform that provides:

- **Encryption at rest** - Secrets encrypted in storage backend
- **Dynamic secrets** - Generated on-demand, short-lived
- **Audit logging** - Every secret access logged
- **Access policies** - Fine-grained RBAC
- **Automatic rotation** - Secrets rotated automatically

#### Integration Pattern: Vault Agent Sidecar

**Option 1: Vault Agent Injector (Recommended)**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: api-pod
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "api-service"
    vault.hashicorp.com/agent-inject-secret-database: "secret/data/database"
    vault.hashicorp.com/agent-inject-template-database: |
      {{- with secret "secret/data/database" -}}
      DB_HOST={{ .Data.data.host }}
      DB_USER={{ .Data.data.username }}
      DB_PASS={{ .Data.data.password }}
      {{- end }}
spec:
  serviceAccountName: api-service
  containers:
    - name: api
      image: fawkes/api:v1.2.3
      # Secrets injected at /vault/secrets/database
```

**What Happens:**

1. **Vault Agent sidecar injected** - Runs alongside app container
2. **Kubernetes auth** - Vault verifies pod's service account
3. **Secret retrieval** - Agent fetches secrets from Vault
4. **File injection** - Secrets written to shared volume at `/vault/secrets/`
5. **Automatic renewal** - Agent refreshes secrets before expiration

**Benefits:**

- ✅ **No secrets in environment variables** - Hidden from `kubectl describe`
- ✅ **No code changes** - App reads from file like config
- ✅ **Automatic rotation** - Agent handles renewal
- ✅ **Audit trail** - Vault logs every access

**Option 2: External Secrets Operator**

For teams preferring Kubernetes-native pattern:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-secret
  namespace: production
spec:
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: database-secret
  data:
    - secretKey: username
      remoteRef:
        key: secret/data/database
        property: username
    - secretKey: password
      remoteRef:
        key: secret/data/database
        property: password
```

**Effect**: Kubernetes Secret created/updated automatically from Vault.

#### Dynamic Database Credentials

**The Ultimate Secret Management:**

```yaml
# Vault configuration
vault write database/config/postgres \
plugin_name=postgresql-database-plugin \
allowed_roles="api-role" \
connection_url="postgresql://{{username}}:{{password}}@postgres:5432/production"

vault write database/roles/api-role \
db_name=postgres \
creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
default_ttl="1h" \
max_ttl="24h"
```

**What This Enables:**

- Vault **generates unique database credentials** per application
- Credentials **expire after 1 hour** (auto-rotated by Vault Agent)
- If pod compromised, credentials useless after 1 hour
- **No shared passwords** - Each pod gets unique creds
- **Audit trail** - Know which pod accessed database at what time

**Time-Limited Blast Radius**: Compromised credentials valid for max 1 hour, not indefinitely.

## How the Layers Work Together

### Scenario: Deploying a New API Service

**Step 1: Developer creates manifest**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: production
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "api"
    spec:
      serviceAccountName: api
      containers:
        - name: api
          image: fawkes/api:v2.0.0
          ports:
            - containerPort: 8080
```

**Step 2: Kyverno validates**

- ✅ **Non-root user** - `runAsNonRoot: true` (mutated if missing)
- ✅ **Resource limits** - Memory/CPU limits set (mutated if missing)
- ✅ **No privileged escalation** - `allowPrivilegeEscalation: false` enforced
- ✅ **Image from approved registry** - Not from Docker Hub public repos
- ✅ **Service account exists** - `api` service account present
- ⛔ **Violations rejected** - If any policy fails, deployment blocked

**Step 3: Pod created with Vault injection**

- Vault Agent sidecar automatically injected
- Agent authenticates to Vault using service account token
- Secrets fetched from Vault and written to `/vault/secrets/`

**Step 4: Network policy enforced**

- Istio injects Envoy sidecar
- mTLS established between api pod and dependencies
- AuthorizationPolicy enforces "api can only talk to postgres and redis"

**Step 5: Ingress exposes service**

- TLS certificate issued by cert-manager (Let's Encrypt)
- External traffic encrypted via HTTPS
- Internal traffic encrypted via mTLS

**Security Layers Active:**

1. ✅ **Ingress** - TLS encryption for external traffic
2. ✅ **Istio** - mTLS for internal service-to-service
3. ✅ **Kyverno** - Policy validation (non-root, resource limits, etc.)
4. ✅ **Vault** - Dynamic secrets with audit trail
5. ✅ **Network Policy** - Least privilege network access

### Scenario: Compromised Pod (Defense in Depth)

**Attacker gains code execution in `api` pod:**

**Attack 1: Lateral movement to database**

```bash
curl http://postgres:5432
```

**❌ Blocked**: Istio AuthorizationPolicy requires mTLS with `api` service identity. Attacker can't forge certificate.

**Attack 2: Steal secrets from environment**

```bash
env | grep PASSWORD
```

**❌ Mitigated**: No secrets in environment variables. Secrets in `/vault/secrets/` (but still accessible if pod compromised).

**Attack 3: Read secrets from Vault directly**

```bash
export VAULT_ADDR=http://vault:8200
vault read secret/data/database
```

**❌ Blocked**: Vault requires service account token. Attacker's manual `vault` CLI doesn't have token (Vault Agent does, but Agent is separate container).

**Attack 4: Pivot to other namespaces**

```bash
kubectl get pods -n other-namespace
```

**❌ Blocked**: Service account has RBAC limited to own namespace. No cross-namespace access.

**Attack 5: Deploy malicious pod**

```bash
kubectl run evil-pod --image=attacker/cryptominer
```

**❌ Blocked**: Kyverno policy rejects images from unapproved registries. Admission denied.

**Attack 6: Exfiltrate data from accessible database**

```bash
# Assume attacker accesses DB using app's connection
SELECT * FROM customers;
```

**✅ Possible**: If app has database access, attacker can read data the app can read.

**Mitigation**:

- Least privilege DB credentials (Vault dynamic secrets give minimal permissions)
- Audit logging (Vault logs all secret access; know which pod at what time)
- Incident response (Revoke Vault credentials for compromised pod, rotate dynamic secrets)

**Blast Radius**: Limited to what the `api` service legitimately needs. Can't pivot to other services or namespaces.

## Trade-Offs: Security vs. Complexity

### What Zero Trust Gives You

| Benefit                    | Explanation                                                     |
| -------------------------- | --------------------------------------------------------------- |
| **Minimized Blast Radius** | Compromised pod can't pivot to other services                   |
| **Audit Trail**            | Vault logs every secret access; Istio logs every request        |
| **Defense in Depth**       | Multiple layers must fail for breach to succeed                 |
| **Compliance**             | Encryption, RBAC, audit logs satisfy SOC2, PCI-DSS, HIPAA       |
| **Time-Limited Exposure**  | Dynamic secrets expire; compromised creds short-lived           |
| **Policy Enforcement**     | Security policies enforced automatically, not via docs/training |

### What Zero Trust Costs You

| Challenge                | Mitigation                                                                                                                                                                                                |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Complexity**           | More components (Vault, Kyverno, Istio) to learn and maintain. **Mitigation**: Fawkes Dojo has [Zero Trust module](../../dojo/modules/black-belt/module-19-security-zerotrust.md)                         |
| **Operational Overhead** | Vault HA, secret rotation, policy management. **Mitigation**: Automated via GitOps; platform team handles                                                                                                 |
| **Debugging Difficulty** | mTLS/network policies can block legitimate traffic during troubleshooting. **Mitigation**: [Troubleshooting guides](../../how-to/policy/troubleshoot-kyverno-violation.md) and `istioctl` debugging tools |
| **Performance Impact**   | mTLS encryption adds latency (~1-5ms per hop). **Mitigation**: Acceptable for security gain; not noticeable in most apps                                                                                  |
| **Policy Authoring**     | Writing Kyverno policies requires Kubernetes knowledge. **Mitigation**: Fawkes provides library of common policies                                                                                        |

### When to Relax Zero Trust

**Not every environment needs fortress-level security:**

| Environment               | Security Posture        | Rationale                                    |
| ------------------------- | ----------------------- | -------------------------------------------- |
| **Production**            | ✅ Full Zero Trust      | Customer data, compliance requirements       |
| **Staging**               | ⚠️ Relaxed (audit mode) | Test policies before enforcing               |
| **Development**           | ⚠️ Minimal              | Developer velocity > security (no real data) |
| **Local (Kind/Minikube)** | ❌ Disabled             | Avoid complexity on laptop                   |

**Fawkes Approach**: Security policies applied per environment via Kustomize overlays.

## Governance: Audit vs. Enforce Tiers

Kyverno's audit mode enables **gradual security adoption**:

### Tier 1: Critical (Enforce)

Policies that prevent immediate security incidents:

- ❌ **No privileged containers** - Block root access, privilege escalation
- ❌ **No host network/PID namespaces** - Prevent container breakout
- ❌ **Images from approved registries** - Block public Docker Hub
- ❌ **Required security contexts** - Non-root user, read-only filesystem

**Effect**: Deployment blocked if violated.

### Tier 2: Important (Audit → Enforce)

Policies that improve security posture but allow migration time:

- ⚠️ **Resource limits required** - Prevent resource exhaustion
- ⚠️ **Liveness/readiness probes** - Improve reliability
- ⚠️ **No latest tag** - Require specific version tags
- ⚠️ **Secrets via Vault** - Not Kubernetes Secrets

**Rollout**:

1. **Month 1**: Audit mode (log violations, don't block)
2. **Month 2**: Notify teams of violations, provide guidance
3. **Month 3**: Enforce mode (block non-compliant deployments)

### Tier 3: Best Practice (Audit Only)

Policies that encourage good practices but don't block:

- ℹ️ **Recommended labels** - team, component, version labels
- ℹ️ **Cost allocation tags** - For chargeback
- ℹ️ **Deployment strategy** - RollingUpdate preferred

**Effect**: Logged for visibility, never enforced.

**Policy Report Dashboard**: Grafana shows compliance trends over time.

## Related Reading

- **ADR**: [ADR-015: Vault Deployment](../../adr/ADR-015%20vault%20deployment.md)
- **ADR**: [ADR-017: Kyverno Policy Engine](../../adr/ADR-017%20kyverno-policy-engine.md)
- **ADR**: [ADR-010: Ingress Controller](../../adr/ADR-010%3A%20Ingress%20Controller%20for%20Service%20Access.md)
- **How-To**: [Rotate Vault Secrets](../../how-to/security/rotate-vault-secrets.md)
- **How-To**: [Troubleshoot Kyverno Violations](../../how-to/policy/troubleshoot-kyverno-violation.md)
- **Tutorial**: [Module 19: Zero Trust Security](../../dojo/modules/black-belt/module-19-security-zerotrust.md)

## Conclusion

Zero Trust is not a product—it's an **architectural philosophy**. No single tool provides Zero Trust; it emerges from the integration of complementary security layers.

Fawkes implements Zero Trust through:

- **Vault** - Identity-based secrets with audit trail
- **Kyverno** - Policy enforcement at admission time
- **Istio/Ingress** - Encrypted transport and identity verification

Together, these create **defense in depth**: multiple security layers that must all fail for a breach to succeed.

**The Goal**: Make attacks expensive. Even if an attacker compromises one pod, they can't pivot laterally, can't exfiltrate secrets, can't deploy malicious workloads. The blast radius is minimized, and the audit trail is complete.

**This is Zero Trust**: Never trust, always verify, and limit the damage when (not if) something goes wrong.
