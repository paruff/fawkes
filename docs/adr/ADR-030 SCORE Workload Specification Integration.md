# ADR-030: SCORE Workload Specification Integration

## Status

**Accepted** - December 6, 2025

## Context

The Fawkes platform currently generates Kubernetes manifests directly in the Golden Path templates. This approach creates several challenges:

### Current State Problems

1. **Tight Coupling to K8s**: Application definitions are tightly bound to Kubernetes-specific resources (Deployment, Service, Ingress), making them less portable.

2. **Portability Challenges**: Moving workloads between environments (dev, staging, prod) or platforms requires manually editing K8s manifests.

3. **Developer Cognitive Load**: Developers must understand Kubernetes internals to define simple application requirements like "I need a database" or "I need 2GB of memory."

4. **Environment-Specific Duplication**: Similar configurations must be repeated across different environments with minor variations (e.g., different Vault addresses, Ingress hosts).

5. **Infrastructure Abstraction**: The platform should abstract infrastructure details from application developers, allowing them to focus on application logic.

### The SCORE Specification

[SCORE (score.dev)](https://score.dev) is an open-source, platform-agnostic workload specification that provides:

- **Declarative Resource Definitions**: Describe what resources you need (database, cache, secrets) without specifying how they're provisioned.
- **Environment Portability**: Write once, deploy anywhere (K8s, Docker Compose, cloud platforms).
- **Developer-Friendly**: Simple, intuitive YAML syntax focused on application needs, not infrastructure.
- **Industry Adoption**: Created by Humanitec, backed by CNCF ecosystem, growing community adoption.

### Forces at Play

**Technical Forces**:

- Need for platform-agnostic workload definitions
- Balance between abstraction and control
- Integration with existing GitOps workflows (ArgoCD)
- Tooling maturity and ecosystem support

**Business Forces**:

- Reduce time-to-production for application teams
- Improve developer experience and satisfaction
- Enable multi-cloud and hybrid deployments
- Reduce platform lock-in

**Organizational Forces**:

- Varying Kubernetes expertise across teams
- Platform engineering team capacity for supporting multiple deployment patterns
- Need for backwards compatibility with existing applications

## Decision

**We will integrate the SCORE specification into Fawkes Golden Path templates as the primary workload definition format.**

Specifically:

1. **Golden Path Templates** will generate a `score.yaml` file as the authoritative workload definition.

2. **SCORE Transformer Component** will translate `score.yaml` into environment-specific Kubernetes manifests at deployment time.

3. **Kustomize Integration** will be used to apply environment overlays on top of SCORE-generated manifests.

4. **Backwards Compatibility** will be maintained - existing applications without `score.yaml` will continue to work.

5. **SCORE Fields Supported** (Phase 1):
   - Container definitions (image, resources, ports)
   - Resource requirements (database, cache, storage)
   - Service dependencies
   - Environment variables and configuration
   - Basic scaling parameters

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Developer Defines Workload                                  │
│                                                              │
│  score.yaml (Platform-Agnostic)                             │
│  ├── containers:                                            │
│  │   └── web:                                               │
│  │       ├── image: "my-app:1.0.0"                         │
│  │       └── resources: {memory: 512Mi}                    │
│  └── resources:                                             │
│      └── db: {type: postgres}                               │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ GitOps Pipeline
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ SCORE Transformer (Kustomize Generator)                     │
│                                                              │
│  Reads score.yaml + environment config                      │
│  Generates K8s manifests:                                   │
│    - Deployment (from containers)                           │
│    - Service (from ports)                                   │
│    - Ingress (if public endpoint)                           │
│    - ConfigMap (for config)                                 │
│    - ExternalSecret (for secrets)                           │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ Kustomize Build
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Environment-Specific K8s Manifests                          │
│                                                              │
│  Dev: vault.dev.local, 1 replica                            │
│  Prod: vault.prod.local, 3 replicas, HPA                    │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ ArgoCD Sync
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Kubernetes Cluster                                          │
└─────────────────────────────────────────────────────────────┘
```

### Rationale

**Why SCORE?**

1. **Industry Standard**: SCORE is an emerging industry standard, not a proprietary format. This reduces platform lock-in.

2. **Simple for Developers**: Developers describe application needs in business terms ("I need a Postgres DB") rather than infrastructure terms ("I need a StatefulSet with this PVC template...").

3. **Portability**: Applications can theoretically run on different platforms (K8s, Docker Compose, cloud PaaS) with the same `score.yaml`.

4. **GitOps Compatible**: SCORE fits naturally into our GitOps workflow - it's just another declarative YAML file in the repository.

5. **Extensible**: SCORE allows custom resource types, enabling platform-specific extensions while maintaining core portability.

**Why Not Alternatives?**

- **Raw K8s Manifests**: Too verbose, not portable, high cognitive load.
- **Helm Charts**: Templating complexity, over-engineering for simple apps, not platform-agnostic.
- **Docker Compose**: Not designed for production Kubernetes deployments.
- **Custom DSL**: Would create vendor lock-in and require ongoing maintenance.

## Consequences

### Positive

✅ **Improved Developer Experience**: Developers work with simple, declarative workload specs instead of complex K8s YAML.

✅ **Portability**: Applications can be deployed across different environments with minimal changes.

✅ **Reduced Duplication**: Environment differences handled by the platform, not duplicated in app repos.

✅ **Future-Proofing**: SCORE support makes migration to other platforms (cloud PaaS, other orchestrators) easier.

✅ **Clearer Separation of Concerns**: Application teams own `score.yaml`, platform teams own the transformation logic.

### Negative

⚠️ **Additional Abstraction Layer**: Introduces another layer between application definition and K8s resources, potentially complicating debugging.

⚠️ **Tooling Dependency**: Requires SCORE CLI or custom transformer; adds dependency to the deployment pipeline.

⚠️ **Learning Curve**: Teams must learn SCORE specification in addition to (or instead of) Kubernetes.

⚠️ **Limited Adoption**: SCORE is relatively new; community resources and examples are still growing.

⚠️ **Expressiveness Limits**: Very complex K8s configurations may not be fully expressible in SCORE; escape hatches needed.

### Mitigation Strategies

1. **Backwards Compatibility**: Existing apps without `score.yaml` continue to work unchanged.

2. **Escape Hatches**: Allow teams to override/extend generated manifests with custom Kustomize patches.

3. **Documentation & Examples**: Provide comprehensive docs and starter templates for common patterns.

4. **Incremental Rollout**: Start with new applications only; migrate existing apps on a case-by-case basis.

5. **Tooling Simplicity**: Use lightweight SCORE CLI or simple custom generator; avoid over-engineering.

## Implementation Plan

### Phase 1: Foundation (Sprint 1-2)

- [ ] Create ADR (this document)
- [ ] Create `templates/golden-path-service/score.yaml` template
- [ ] Implement basic SCORE transformer (using score-k8s or custom Kustomize generator)
- [ ] Generate Deployment, Service, Ingress from score.yaml
- [ ] Update Golden Path documentation

### Phase 2: Resource Types (Sprint 3-4)

- [ ] Support database resources (Postgres via CloudNativePG)
- [ ] Support cache resources (Redis)
- [ ] Support secrets (External Secrets Operator)
- [ ] Support storage (PVC)
- [ ] Add validation for supported resource types

### Phase 3: Testing & Validation (Sprint 5)

- [ ] BDD tests for SCORE translation
- [ ] BDD tests for environment portability
- [ ] Integration with existing CI/CD pipeline
- [ ] Performance testing (transformation time)

### Phase 4: Migration & Adoption (Sprint 6+)

- [ ] Migrate 2-3 sample applications to SCORE
- [ ] Gather feedback from pilot teams
- [ ] Refine transformer based on real-world usage
- [ ] Create migration guide for existing applications

## Alternatives Considered

### Alternative 1: Continue with Raw K8s Manifests

**Pros**: No new tooling, team familiarity, full K8s expressiveness.

**Cons**: Poor developer experience, low portability, high duplication.

**Decision**: Rejected - doesn't address core problems.

### Alternative 2: Use Helm for Application Templates

**Pros**: Mature ecosystem, broad adoption, powerful templating.

**Cons**: Templating complexity, not platform-agnostic, over-engineering for simple apps.

**Decision**: Rejected - adds complexity without improving portability.

### Alternative 3: Custom Fawkes DSL

**Pros**: Complete control, tailored to Fawkes needs.

**Cons**: Vendor lock-in, maintenance burden, no community support.

**Decision**: Rejected - prefer industry standards over NIH solutions.

### Alternative 4: CUE or Jsonnet

**Pros**: Powerful configuration languages, strong typing.

**Cons**: Steep learning curve, not purpose-built for workload specs.

**Decision**: Rejected - too generic, doesn't solve developer UX problem.

## References

- [SCORE Specification](https://score.dev)
- [score-k8s Implementation](https://github.com/score-spec/score-k8s)
- [Platform Engineering Principles](https://platformengineering.org)
- [ADR-001: Kubernetes](./ADR-001%20kubernetes.md)
- [ADR-003: ArgoCD](./ADR-003%20argocd.md)
- [Golden Path Usage Guide](../golden-path-usage.md)

## Related Decisions

- **ADR-001 (Kubernetes)**: SCORE generates K8s manifests as the target platform.
- **ADR-003 (ArgoCD)**: SCORE transformation happens before ArgoCD sync.
- **ADR-005 (Terraform)**: Infrastructure resources (RDS, S3) provisioned by Terraform, referenced in SCORE.
- **ADR-021 (Eclipse Che)**: Devfiles remain separate from SCORE (different purposes).

## Decision Review

- **Review Date**: March 2026 (3 months after initial implementation)
- **Success Criteria**:
  - 80%+ of new Golden Path applications use score.yaml
  - Developer satisfaction score >4.0/5.0 for SCORE-based deployments
  - <5 minutes average time to deploy a new service using SCORE
  - Zero production incidents caused by SCORE transformation issues
