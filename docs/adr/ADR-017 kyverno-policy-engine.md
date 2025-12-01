# ADR-017: Kyverno Policy Engine for Policy-as-Code

## Status

Accepted

## Context

The Fawkes platform requires a policy enforcement mechanism to ensure:

- **Security Standards**: All workloads comply with Pod Security Standards
- **Platform Standardization**: Consistent labels, annotations, and configurations
- **Governance**: Resource quotas, network policies, and compliance requirements
- **Runtime Enforcement**: Policies enforced at admission time, not just CI

### Current State

Security and standardization are enforced primarily by CI pipeline checks
(pre-deployment). Post-deployment compliance relies on manual cluster
administrator oversight, leading to:

1. **Inconsistent Enforcement**: Different teams may bypass CI checks
2. **No Runtime Protection**: Malicious or accidental misconfigurations can
   be applied directly via kubectl
3. **Manual Overhead**: Administrators must manually review and correct
   non-compliant resources
4. **No Automatic Standardization**: Platform labels and configurations
   require manual addition

### Requirements from Issue

1. Deploy Kyverno as the Kubernetes-native policy engine
2. Implement validation policies for security (Pod Security Standards)
3. Implement mutation policies for automatic standardization
4. Implement generation policies for namespace defaults
5. Enable policy reporting for audit and compliance
6. Avoid duplication with CI security scans (SonarQube)

## Decision

We will deploy **Kyverno** as the policy-as-code engine for the Fawkes platform,
providing validation, mutation, and generation capabilities through native
Kubernetes admission control.

### Why Kyverno over OPA/Gatekeeper

| Criteria | Kyverno | OPA/Gatekeeper |
|----------|---------|----------------|
| Learning Curve | YAML-based, familiar | Rego language, steep |
| Mutation Support | Native | Limited |
| Generation Support | Native | Not supported |
| Kubernetes Native | Yes, CRDs | Abstraction layer |
| Policy Testing | kyverno CLI | opa test |
| Community | Growing rapidly | Established |

We chose Kyverno because:

1. **Lower barrier to entry**: Platform teams can write policies in YAML
2. **Mutation capabilities**: Critical for automatic Vault integration
3. **Generation capabilities**: Essential for namespace standardization
4. **Kubernetes-native**: Better integration with ArgoCD and GitOps workflows

### Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Kyverno Policy Engine                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    Admission Controllers                              │   │
│  │                                                                        │   │
│  │  ValidatingWebhook ──► Validate ──► Allow/Deny                        │   │
│  │  MutatingWebhook ──► Mutate ──► Modified Resource                     │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    Background Controllers                             │   │
│  │                                                                        │   │
│  │  GenerateController ──► Watch Resources ──► Create Generated          │   │
│  │  ReportsController ──► Collect Results ──► PolicyReport               │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────┬────────────────────────────────────────────┐   │
│  │   ClusterPolicy         │   Policy (Namespace-scoped)                │   │
│  │   • Security            │   • Team-specific                          │   │
│  │   • Platform standards  │   • Application exceptions                 │   │
│  └─────────────────────────┴────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Policy Categories

#### 1. Mandatory Security Policies (Enforce Mode)

These policies DENY non-compliant resources:

| Policy | Description | Enforcement |
|--------|-------------|-------------|
| `require-run-as-non-root` | Containers must run as non-root | Enforce |
| `disallow-privileged-containers` | No privileged containers | Enforce |
| `restrict-host-namespaces` | No hostNetwork/hostPID/hostIPC | Enforce |
| `disallow-host-ports` | No host port bindings | Enforce |
| `disallow-capabilities` | Must drop ALL capabilities | Enforce |
| `require-resource-limits` | CPU/memory limits required | Enforce |

#### 2. Standardization Policies (Mutate Mode)

These policies automatically modify resources:

| Policy | Mutation | Purpose |
|--------|----------|---------|
| `add-platform-labels` | Add `app.fawkes.idp/*` labels | Consistent labeling |
| `add-vault-annotations` | Add Vault Agent annotations | Secret injection |
| `set-ingress-class` | Set `ingressClassName: nginx` | Traffic routing |
| `set-default-security-context` | Add secure defaults | Security baseline |
| `add-default-resources` | Add default requests | Scheduling |

#### 3. Generation Policies (Generate Mode)

These policies create resources automatically:

| Policy | Generated Resources | Trigger |
|--------|---------------------|---------|
| `generate-namespace-network-policy` | NetworkPolicy | New Namespace |
| `generate-namespace-resource-quota` | ResourceQuota | New Namespace |
| `generate-namespace-limit-range` | LimitRange | New Namespace |
| `generate-namespace-service-account` | ServiceAccount | New Namespace |

### Deployment Configuration

#### High Availability

- **Admission Controller**: 3 replicas with pod anti-affinity
- **Background Controller**: 2 replicas
- **Reports Controller**: 1 replica
- **Cleanup Controller**: 1 replica

#### Excluded Namespaces

System namespaces are excluded from policy enforcement:

- `kube-system`
- `kube-public`
- `kube-node-lease`
- `kyverno`

### CI/CD Integration (Avoiding Duplication)

Kyverno complements rather than duplicates CI security scanning:

| Layer | Tool | Purpose |
|-------|------|---------|
| Source Code | SonarQube | SAST, code quality, security hotspots |
| Dependencies | OWASP Check | Known vulnerabilities in libraries |
| Container Image | Trivy | Image vulnerabilities, SBOM |
| **Admission** | **Kyverno** | Runtime policy enforcement |

SonarQube detects code-level issues; Kyverno enforces deployment configuration.
There is no overlap.

## Consequences

### Positive

1. **Consistent Enforcement**: All resources validated at admission time
2. **Automatic Standardization**: Platform labels and configurations applied
   automatically
3. **Self-Service Namespaces**: Standard resources generated for new namespaces
4. **Audit Trail**: PolicyReports provide compliance evidence
5. **GitOps Compatible**: Policies stored in Git, deployed via ArgoCD
6. **Low Learning Curve**: YAML-based policies familiar to Kubernetes users

### Negative

1. **Webhook Overhead**: Slight latency added to API server requests
2. **Policy Complexity**: Complex policies may be hard to debug
3. **False Positives**: Overly strict policies may block legitimate workloads
4. **Operational Burden**: Kyverno cluster requires monitoring and maintenance

### Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Webhook unavailable blocks deployments | `failurePolicy: Ignore` for non-critical |
| Policy blocks legitimate workload | Start with Audit mode, transition to Enforce |
| Complex policies hard to maintain | Policy testing in CI, clear documentation |
| Performance impact | Adequate resources, caching, excluded namespaces |

## Alternatives Considered

### 1. OPA/Gatekeeper

**Rejected because**: Steeper learning curve (Rego), no native mutation or
generation support, less Kubernetes-native feel.

### 2. Pod Security Admission (PSA)

**Rejected because**: Only provides predefined security levels (baseline,
restricted), no custom policies, no mutation or generation.

### 3. Custom Admission Webhooks

**Rejected because**: High development and maintenance burden, requires custom
code for each policy type.

### 4. CI-Only Enforcement

**Rejected because**: Can be bypassed, no runtime protection, no automatic
standardization.

## Implementation Plan

### Phase 1: Core Deployment (Week 1)

- [x] Deploy Kyverno via ArgoCD Application
- [x] Create mandatory security policies
- [x] Create mutation policies for standardization
- [x] Create generation policies for namespaces

### Phase 2: Testing & Validation (Week 2)

- [ ] Test all policies in development environment
- [ ] Create BDD acceptance tests
- [ ] Document policy exceptions process
- [ ] Set up Grafana dashboard for metrics

### Phase 3: Production Rollout (Week 3)

- [ ] Enable Audit mode in production
- [ ] Review PolicyReports for false positives
- [ ] Transition to Enforce mode
- [ ] Developer documentation and training

## References

- [Kyverno Documentation](https://kyverno.io/docs/)
- [Kyverno Policy Library](https://kyverno.io/policies/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [ADR-014: SonarQube Quality Gates](ADR-014%20sonarqube%20quality%20gates.md)
- [ADR-015: Vault Deployment](ADR-015%20vault%20deployment.md)
