# ADR-021: Eclipse Che Cloud Development Environment (CDE) Strategy

## Status

Accepted

## Context

The Fawkes platform requires a Cloud Development Environment (CDE) solution to
eliminate local environment setup friction, ensure consistent development
toolchains, and enable AI-ready development workspaces with appropriate resources.

### Current State

Product developers rely on local machines for development, leading to:

- "Works on my machine" issues due to inconsistent toolchains
- Significant setup time for new projects
- AI development requiring substantial local resources (GPU/high-CPU)
- Security concerns with local development of sensitive codebases
- Difficulty onboarding new team members

### Requirements

1. **Standardized Environments**: Pre-configured workspaces with correct runtime,
   tools, and language servers
2. **AI-Ready Workspaces**: Support for GPU/high-CPU resource allocation for AI/ML
   development
3. **Git Integration**: Automatic repository cloning and access configuration
4. **SSO Integration**: Seamless authentication via platform's central SSO provider
5. **Secrets Access**: Secure credential injection via Vault Agent pattern
6. **Resource Management**: Kubernetes ResourceQuota enforcement to prevent
   cluster overload
7. **Workspace Isolation**: Dedicated namespaces per user/team for security
   separation

### Evaluation Criteria

- Open source with active community
- Kubernetes-native deployment
- Devfile standard support
- SSO/OIDC integration capability
- IDE flexibility (VS Code, IntelliJ, etc.)
- Backstage integration potential

## Decision

We will deploy **Eclipse Che** as the Cloud Development Environment platform for
Fawkes.

### Why Eclipse Che

**Advantages**:

1. **Kubernetes-Native**: Built for Kubernetes with Operator-based deployment
2. **Devfile Standard**: Uses CNCF Devfile specification for workspace definitions
3. **IDE Flexibility**: Supports VS Code, Che-Theia, and JetBrains IDEs
4. **SSO Support**: Native OIDC integration for SSO authentication
5. **Open Source**: Apache 2.0 license, CNCF project (incubating)
6. **Per-User Workspaces**: Automatic namespace isolation per developer
7. **Resource Control**: Kubernetes-native resource limits and quotas

**Trade-offs**:

1. **Resource Intensive**: Workspaces consume significant cluster resources
2. **Complexity**: Operator deployment requires careful configuration
3. **Learning Curve**: Teams need to understand Devfile structure

### Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Eclipse Che CDE Architecture                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                        Access Layer                                      │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐          │ │
│  │  │   Backstage     │  │   Che Dashboard │  │   Direct IDE    │          │ │
│  │  │   CDE Launcher  │  │                 │  │   Access        │          │ │
│  │  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘          │ │
│  └───────────┼────────────────────┼────────────────────┼────────────────────┘ │
│              │                    │                    │                      │
│              └────────────────────┴────────────────────┘                      │
│                                   │                                           │
│                                   ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                   Eclipse Che Operator (eclipse-che namespace)          │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐          │ │
│  │  │  Che Server     │  │  Devfile        │  │  Workspace      │          │ │
│  │  │  (API/Gateway)  │  │  Registry       │  │  Controller     │          │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘          │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    OIDC/SSO Integration                              │ │ │
│  │  │           (Platform SSO → Eclipse Che Authentication)               │ │ │
│  │  └─────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                   │                                           │
│                                   ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                   Developer Workspaces (user namespaces)                 │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐ │ │
│  │  │ Namespace: che-user-developer1                                       │ │ │
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │ │ │
│  │  │  │  IDE Container  │  │  Dev Container  │  │  Vault Agent    │     │ │ │
│  │  │  │  (VS Code)      │  │  (Python/Node)  │  │  Sidecar        │     │ │ │
│  │  │  └─────────────────┘  └─────────────────┘  └─────────────────┘     │ │ │
│  │  │        │ ResourceQuota: 4 CPU, 8Gi Memory                           │ │ │
│  │  └─────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐ │ │
│  │  │ Namespace: che-user-developer2 (AI Workspace)                        │ │ │
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │ │ │
│  │  │  │  IDE Container  │  │  AI Container   │  │  Vault Agent    │     │ │ │
│  │  │  │  (VS Code)      │  │  (TensorFlow)   │  │  Sidecar        │     │ │ │
│  │  │  └─────────────────┘  └─────────────────┘  └─────────────────┘     │ │ │
│  │  │        │ ResourceQuota: 8 CPU, 16Gi Memory, GPU: 1                  │ │ │
│  │  │        │ Node Selector: gpu-enabled=true                            │ │ │
│  │  └─────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Devfile Standardization

Eclipse Che uses Devfiles to define development environments. We will provide
two initial Golden Path Devfiles:

| Devfile             | Purpose                    | Resources               | Tools                              |
| ------------------- | -------------------------- | ----------------------- | ---------------------------------- |
| `goldenpath-python` | General Python development | 2 CPU, 4Gi Memory       | Python 3.11, pip, Language Server  |
| `goldenpath-ai`     | AI/ML development          | 8 CPU, 16Gi Memory, GPU | TensorFlow, PyTorch, Jupyter, CUDA |

### Deployment Configuration

**Namespace**: `eclipse-che`

**Components**:

- Eclipse Che Operator (via OperatorHub or Helm)
- Che Server (API gateway, workspace management)
- Devfile Registry (Golden Path templates)
- PostgreSQL (workspace metadata storage)

**Resource Requirements**:

```yaml
che-operator:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

che-server:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2
    memory: 2Gi

devfile-registry:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### SSO Integration

Eclipse Che will integrate with the platform's central SSO provider:

```yaml
spec:
  auth:
    oAuthClientName: eclipse-che
    oAuthSecret: che-oauth-secret
    identityProviderURL: https://sso.fawkes.idp/realms/fawkes
```

For GitHub OAuth (matching Backstage):

- Che uses the same OAuth provider configured for Backstage
- User identity is consistent across portal and CDEs
- Token refresh handled automatically

### Secrets Access via Vault

Workspaces will access secrets via the Vault Agent Sidecar pattern:

1. Workspace pod annotations trigger Vault Agent injection
2. Secrets mounted at `/vault/secrets/` in workspace container
3. Developers use secrets without managing credentials locally

```yaml
# Workspace template annotation
vault.hashicorp.com/agent-inject: "true"
vault.hashicorp.com/role: "che-workspace"
vault.hashicorp.com/agent-inject-secret-db-creds: "secret/data/dev/database"
```

### Resource Quota Enforcement

Each team has a cluster-wide quota for CDE consumption:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: che-workspace-quota
  namespace: che-user-team-a
spec:
  hard:
    requests.cpu: "16"
    requests.memory: 32Gi
    limits.cpu: "32"
    limits.memory: 64Gi
    pods: "10"
```

When quota is exceeded:

- New workspace launches are denied with clear error message
- Users see quota status in Che Dashboard
- Alerting configured for approaching quota limits

### Backstage Integration

Eclipse Che integrates with Backstage via:

1. **Che Launcher Plugin**: Component to launch CDEs from Service Catalog
2. **Entity Annotation**: Link services to Devfile templates
3. **Status Widget**: Show active workspaces for each service

Example catalog annotation:

```yaml
metadata:
  annotations:
    eclipse.org/che-devfile: goldenpath-python
    eclipse.org/che-url: https://che.fawkes.idp
```

### Edge Cases

| Scenario               | Behavior                                      |
| ---------------------- | --------------------------------------------- |
| Quota exceeded         | Clear error message, workspace launch blocked |
| Git access denied      | Prompt for credentials, SSO token refresh     |
| Workspace idle timeout | Auto-stop after 30 minutes, state preserved   |
| Devfile not found      | Fallback to Universal Developer Image         |
| GPU unavailable        | Queue workspace, notify when resources free   |

## Consequences

### Positive

1. **Consistent Environments**: All developers use identical, reproducible setups
2. **Fast Onboarding**: New team members productive within minutes
3. **AI-Ready Infrastructure**: GPU resources available on-demand
4. **Security**: No sensitive code on local machines
5. **Reduced Support**: Fewer "works on my machine" issues

### Negative

1. **Resource Cost**: Significant cluster resources per active workspace
2. **Network Dependency**: Requires stable internet connection
3. **Learning Curve**: Devfile authoring requires training
4. **Complexity**: Additional platform component to maintain

### Risks and Mitigations

| Risk               | Mitigation                                   |
| ------------------ | -------------------------------------------- |
| Workspace sprawl   | Auto-stop idle workspaces, quota enforcement |
| Performance issues | Node affinity, SSD storage for workspaces    |
| Security exposure  | Network policies, namespace isolation, RBAC  |
| Vendor lock-in     | Devfile is CNCF standard, portable           |

## Alternatives Considered

### 1. GitHub Codespaces (Commercial)

**Description**: GitHub's cloud development environment

**Rejected because**:

- Vendor lock-in to GitHub ecosystem
- Per-user licensing costs
- Limited customization for enterprise requirements

### 2. Gitpod (Open Source/Commercial)

**Description**: Alternative CDE platform

**Rejected because**:

- Less mature Kubernetes Operator
- Smaller community than Eclipse Che
- Commercial licensing for enterprise features

### 3. VS Code Dev Containers (Local)

**Description**: Containerized development environments running locally

**Rejected because**:

- Still requires local resources
- Not suitable for AI/ML workloads
- No centralized management

### 4. Custom Solution

**Description**: Build bespoke CDE platform

**Rejected because**:

- Significant development effort
- Maintenance burden
- Reinventing existing solutions

## Implementation Plan

### Phase 1: Core Deployment (Week 1)

- [x] Create ADR-021 for Eclipse Che CDE strategy
- [ ] Deploy Eclipse Che Operator via ArgoCD
- [ ] Configure SSO integration
- [ ] Set up ingress for Che endpoints

### Phase 2: Devfile Templates (Week 2)

- [ ] Create `goldenpath-python` Devfile
- [ ] Create `goldenpath-ai` Devfile
- [ ] Configure Devfile Registry
- [ ] Test workspace launch with templates

### Phase 3: Integration (Week 3)

- [ ] Develop Backstage Che Launcher plugin
- [ ] Configure Vault Agent integration
- [ ] Set up ResourceQuota policies
- [ ] Create team namespaces

### Phase 4: Documentation & Training (Week 4)

- [ ] Update architecture documentation
- [ ] Create Devfile authoring guide
- [ ] Add Dojo learning module for CDEs
- [ ] Create operational runbooks

## References

- [Eclipse Che Documentation](https://www.eclipse.org/che/docs/)
- [CNCF Devfile Specification](https://devfile.io/)
- [Eclipse Che Operator](https://github.com/eclipse-che/che-operator)
- [ADR-002: Backstage for Developer Portal](ADR-002%20backstage.md)
- [ADR-015: HashiCorp Vault Deployment](ADR-015%20vault%20deployment.md)
