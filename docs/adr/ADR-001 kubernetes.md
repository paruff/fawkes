# ADR-001: Kubernetes as Container Orchestration Platform

## Status
**Accepted** - October 4, 2025

## Context

Fawkes requires a container orchestration platform to run the Internal Delivery Platform components (Backstage, Jenkins, ArgoCD, Prometheus, etc.) and to host application workloads for teams using the platform. The orchestration platform must support:

- **Multi-tenancy**: Isolated environments for different teams
- **Scalability**: From small teams (5 services) to large enterprises (100+ services)
- **Observability**: Rich metrics, logging, and monitoring capabilities
- **Security**: RBAC, network policies, secrets management
- **Ecosystem**: Strong ecosystem of tools and integrations
- **Multi-cloud**: Ability to run on AWS, Azure, GCP, and on-premises
- **GitOps**: Declarative configuration and reconciliation
- **Developer Experience**: Self-service capabilities, easy local development

The platform must be production-ready, with a mature community, extensive documentation, and enterprise adoption.

### Forces at Play

**Technical Forces**:
- Need for container orchestration is non-negotiable for modern platforms
- Team familiarity with orchestration platforms varies
- Learning curve vs. time to value tradeoff
- Platform stability and maturity critical for production use

**Business Forces**:
- Open-source preference to avoid vendor lock-in
- Enterprise adoption important for credibility
- Community size affects long-term sustainability
- Multi-cloud support required for diverse adoption

**Organizational Forces**:
- Platform engineering skills growing but not universal
- Kubernetes increasingly becoming industry standard
- CNCF ecosystem alignment provides future-proofing

## Decision

**We will use Kubernetes as the container orchestration platform for Fawkes.**

Specifically:
- **Managed Kubernetes services** for MVP: AWS EKS, with Azure AKS and GCP GKE following
- **Kubernetes version**: 1.28+ (stay within N-2 of latest stable)
- **Distribution agnostic**: Design for standard Kubernetes, test on managed services
- **Cluster API** for cluster lifecycle management (roadmap)

### Rationale

1. **Industry Standard**: Kubernetes is the de facto standard for container orchestration, with 88% of organizations using or evaluating it (CNCF Survey 2023)

2. **CNCF Ecosystem**: Kubernetes is the foundation of the CNCF landscape, providing access to hundreds of complementary tools (ArgoCD, Prometheus, Istio, etc.)

3. **Multi-Cloud Native**: All major cloud providers offer managed Kubernetes (EKS, AKS, GKE), enabling true multi-cloud portability

4. **GitOps Alignment**: Kubernetes' declarative API makes it ideal for GitOps workflows, a core Fawkes principle

5. **Platform Engineering Fit**: Kubernetes provides the right abstractions for platform teams to create developer self-service capabilities

6. **Talent Availability**: Growing pool of Kubernetes-skilled engineers makes hiring and onboarding easier

7. **Enterprise Adoption**: Used by 67% of Fortune 100 companies, providing credibility for enterprise adoption

8. **Security Features**: Built-in RBAC, network policies, pod security standards, and secrets management

9. **Observability**: Rich metrics exposure, established patterns for monitoring and logging

10. **Community & Support**: Massive community, extensive documentation, commercial support available

## Consequences

### Positive

✅ **Broad Adoption**: Using Kubernetes makes Fawkes accessible to the largest possible audience
✅ **Ecosystem Integration**: Can leverage hundreds of CNCF tools designed for Kubernetes
✅ **Multi-Cloud Support**: Same APIs work across AWS, Azure, GCP, and on-premises
✅ **Developer Self-Service**: Kubernetes primitives (Namespaces, RBAC) enable multi-tenancy
✅ **Future-Proof**: Kubernetes is backed by major tech companies and shows no signs of decline
✅ **GitOps Native**: Declarative configuration aligns perfectly with GitOps principles
✅ **Skills Transfer**: Learning Fawkes teaches transferable Kubernetes skills
✅ **Extensibility**: Custom Resource Definitions (CRDs) enable platform extension
✅ **Production Ready**: Battle-tested at scale by thousands of organizations

### Negative

⚠️ **Complexity**: Kubernetes has a steep learning curve for beginners
⚠️ **Resource Overhead**: Control plane and system components require 2-4GB RAM minimum
⚠️ **Operational Burden**: Requires expertise to operate reliably (mitigated by managed services)
⚠️ **Over-Engineering for Small Teams**: May be overkill for teams with < 5 services
⚠️ **Version Management**: Frequent releases require upgrade planning and testing
⚠️ **Configuration Complexity**: YAML configuration can be verbose and error-prone
⚠️ **Local Development**: Running Kubernetes locally (minikube, kind) adds complexity

### Neutral

◽ **Cost**: Managed Kubernetes has base costs ($70-150/month for control plane) but provides value at scale
◽ **Security**: Powerful security features exist but require configuration and expertise
◽ **Networking**: Kubernetes networking is flexible but requires understanding of concepts

### Mitigation Strategies

For the negative consequences, we will:

1. **Complexity**: Provide comprehensive documentation, dojo learning modules, and golden paths that abstract complexity
2. **Resource Overhead**: Start with managed services (EKS) to reduce operational burden
3. **Operational Burden**: Include monitoring, alerting, and runbooks; leverage managed services
4. **Over-Engineering**: Document when Kubernetes is appropriate; provide alternative architectures for very small teams
5. **Version Management**: Establish clear upgrade policies and automated testing
6. **Configuration Complexity**: Use Helm charts and Kustomize for templating; provide validated templates
7. **Local Development**: Provide remote development options (Eclipse Che); document local setup thoroughly

## Alternatives Considered

### Alternative 1: Docker Swarm

**Pros**:
- Simpler learning curve than Kubernetes
- Integrated with Docker ecosystem
- Lower resource overhead
- Faster initial setup

**Cons**:
- Smaller ecosystem (limited tooling compared to K8s)
- Declining adoption and community activity
- Limited multi-cloud support
- Fewer enterprise features (RBAC, network policies less mature)
- Less relevant skill for users to learn

**Reason for Rejection**: While simpler, Docker Swarm's declining adoption and limited ecosystem make it a poor foundation for a platform meant to last 5+ years. The simplicity advantage doesn't outweigh the ecosystem and future-proofing benefits of Kubernetes.

### Alternative 2: HashiCorp Nomad

**Pros**:
- Simpler than Kubernetes (easier to learn and operate)
- Good performance and resource efficiency
- Multi-cloud support
- Strong HashiCorp ecosystem integration (Vault, Consul)
- Supports non-containerized workloads

**Cons**:
- Much smaller ecosystem than Kubernetes
- Fewer integrations with CNCF tools
- Smaller community and talent pool
- Less enterprise adoption
- Would require custom integrations for many tools

**Reason for Rejection**: Nomad is excellent for specific use cases, but the CNCF ecosystem is centered on Kubernetes. Building Fawkes on Nomad would require reimplementing many integrations and would limit the potential contributor and user base.

### Alternative 3: AWS ECS/Fargate

**Pros**:
- Simpler than Kubernetes for basic use cases
- Fully managed (no control plane management)
- Deep AWS integration
- Lower operational overhead
- Cost-effective for certain workloads

**Cons**:
- AWS-only (locks into single cloud vendor)
- Limited ecosystem (no CNCF tools work natively)
- Proprietary API (not transferable skills)
- Multi-tenancy requires more custom work
- GitOps support less mature

**Reason for Rejection**: ECS lock-in to AWS contradicts Fawkes' multi-cloud goals. While simpler for AWS-only users, it would fragment the platform (need separate solutions for Azure, GCP) and limit adoption by multi-cloud organizations.

### Alternative 4: Platform.sh / Heroku-style PaaS

**Pros**:
- Extremely simple developer experience
- Minimal configuration required
- Fast time-to-value
- Handles all infrastructure concerns

**Cons**:
- Not infrastructure we control (SaaS, not self-hosted platform)
- Contradicts Fawkes' goal of providing an IDP
- Limited customization and extensibility
- Doesn't teach platform engineering skills
- Vendor lock-in and cost at scale

**Reason for Rejection**: Fawkes is about building an Internal Developer Platform, not consuming a PaaS. While these platforms provide great developer experience, they don't align with the goal of creating a self-hosted, customizable platform.

### Alternative 5: "Cloud Native" with Managed Services Only

**Pros**:
- Use cloud provider's managed services directly (Lambda, Cloud Run, etc.)
- No container orchestration complexity
- Pay only for usage
- Serverless scaling

**Cons**:
- Completely different approach per cloud (no portability)
- Limited long-running workload support
- Stateful applications challenging
- Platform components (Jenkins, Backstage) need orchestration anyway
- Contradicts unified platform goal

**Reason for Rejection**: While serverless has its place, Fawkes needs a consistent foundation across clouds and for long-running platform components. We may use managed services alongside Kubernetes, but can't build the entire platform on serverless.

## Related Decisions

- **ADR-002**: Backstage for Developer Portal (depends on Kubernetes for deployment)
- **ADR-003**: ArgoCD for GitOps (Kubernetes-native GitOps tool)
- **ADR-005**: Terraform for Infrastructure (will provision Kubernetes clusters)
- **Future ADR**: Cluster API for cluster lifecycle management

## Implementation Notes

### Initial Implementation (MVP)
- Start with AWS EKS (most mature managed Kubernetes)
- Single cluster design (platform + applications)
- Use EKS add-ons for AWS integrations
- Kubernetes version 1.28 (N-1 from latest stable at time of writing)

### Future Enhancements
1. **Multi-Cluster** (Month 6-12):
   - Separate platform cluster from application clusters
   - Multi-region deployments
   - Cluster API for lifecycle management

2. **Multi-Cloud** (Month 3-6):
   - Azure AKS support
   - GCP GKE support
   - Unified tooling across clouds

3. **Advanced Features** (Month 12+):
   - Service mesh (Linkerd/Istio)
   - Multi-tenancy with vCluster or Capsule
   - Cost optimization with spot instances

### Learning Resources for Contributors

- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [CKAD Certification](https://www.cncf.io/certification/ckad/)
- Platform Engineering dojo modules will include K8s fundamentals

## Monitoring This Decision

We will revisit this ADR if:
- Kubernetes adoption significantly declines (< 60% of survey respondents)
- A new orchestration platform gains > 30% market share
- Operational complexity consistently causes adoption issues
- Alternative platforms provide compelling advantages

**Next Review Date**: October 4, 2026 (12 months)

## References

- [CNCF Annual Survey 2023](https://www.cncf.io/reports/cncf-annual-survey-2023/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [The Kubernetes Book by Nigel Poulton](https://www.amazon.com/Kubernetes-Book-Nigel-Poulton/dp/1521823634)

## Notes

### Why Not Start Simpler?

We considered starting with Docker Compose or simpler solutions and "graduating" to Kubernetes later. However:
- Migration is costly and disruptive for early adopters
- Learning Kubernetes is a core part of platform engineering
- Starting with K8s forces us to address complexity early
- Better to have a steeper initial curve than force migration later

### Managed vs. Self-Managed

For MVP, we strongly recommend **managed Kubernetes** (EKS, AKS, GKE) because:
- Reduces operational burden for platform teams
- Allows focus on platform features, not cluster management
- Enterprise-grade reliability and SLAs
- Regular updates and security patches

Self-managed Kubernetes (on-premises, bare metal) is supported but not the primary use case for Fawkes.

---

**Decision Made By**: Platform Architecture Team
**Approved By**: Project Lead
**Date**: October 4, 2025
**Author**: [Platform Architect Name]
**Last Updated**: October 4, 2025