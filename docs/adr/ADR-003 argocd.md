# ADR-003: ArgoCD for GitOps

## Status
**Accepted** - October 8, 2025

## Context

Fawkes requires a GitOps continuous delivery solution to manage application deployments and platform infrastructure declaratively. GitOps—where Git is the single source of truth for desired system state—is a core principle of modern platform engineering and directly supports DORA best practices.

### The Need for GitOps

**Current Challenges Without GitOps**:
- **Manual Deployments**: Error-prone, not repeatable, tribal knowledge
- **Configuration Drift**: Production state diverges from declared state
- **Audit Trail Gaps**: Hard to track who changed what and when
- **Rollback Complexity**: No easy way to revert to previous working state
- **Multi-Environment Management**: Promoting changes across dev/staging/prod is manual
- **No Self-Healing**: Systems don't automatically recover from drift

**What GitOps Provides**:
1. **Declarative Configuration**: Everything defined in Git (applications, infrastructure, configs)
2. **Automated Sync**: System automatically converges to desired state
3. **Version Control**: Complete history of all changes with Git commits
4. **Easy Rollback**: Revert Git commit to roll back to previous state
5. **Audit Trail**: Who, what, when, why all tracked in Git
6. **Self-Healing**: Automatic drift detection and correction
7. **Multi-Cluster Management**: Manage multiple Kubernetes clusters from single control plane

### Requirements for GitOps Tool

**Core Requirements**:
- **Kubernetes-Native**: Designed specifically for Kubernetes deployments
- **Git Integration**: Supports GitHub, GitLab, Bitbucket, etc.
- **Automated Sync**: Watches Git, applies changes automatically
- **Drift Detection**: Detects and corrects configuration drift
- **Multi-Cluster**: Manages multiple clusters (dev, staging, prod)
- **Progressive Delivery**: Supports canary, blue-green deployments
- **Rollback**: Easy revert to previous version
- **RBAC**: Fine-grained access control for teams
- **SSO Integration**: OIDC/SAML for authentication

**DORA Alignment**:
- **Deployment Frequency**: Automated deployments increase frequency
- **Lead Time**: Git commit to deployment is fast and automated
- **Change Failure Rate**: Declarative state reduces misconfigurations
- **Time to Restore**: Git revert enables fast rollback

**Integration Requirements**:
- **Backstage**: Show deployment status in developer portal
- **Jenkins**: Trigger deployments after successful builds
- **Mattermost**: Send deployment notifications to team channels
- **DORA Metrics**: Report deployment events for metrics calculation
- **Kubernetes**: Native integration, no abstraction layer

### Forces at Play

**Technical Forces**:
- Need declarative configuration for reliability
- Drift detection critical for production stability
- Multi-environment promotion needs automation
- Self-healing reduces operational toil

**Operational Forces**:
- Platform team can't manually deploy everything
- Need audit trail for compliance
- Rollback must be fast and reliable
- Want to reduce deployment-related incidents

**Developer Experience Forces**:
- Developers want to see deployment status
- Need confidence deployments will succeed
- Want easy rollback if issues arise
- Prefer GitOps "merge to deploy" workflow

**DORA Forces**:
- Deployment frequency depends on automation
- Lead time includes deployment time
- GitOps reduces change failure rate
- Fast rollback improves time to restore

## Decision

**We will use ArgoCD as the GitOps continuous delivery platform for Fawkes.**

Specifically:
- **ArgoCD Core** (latest stable version, currently 2.9+)
- **Multi-cluster deployment** (manage dev, staging, prod from single ArgoCD)
- **ApplicationSets** for managing multiple applications with templates
- **Argo Rollouts** for progressive delivery (canary, blue-green)
- **Argo Notifications** for Mattermost integration
- **Argo Image Updater** for automated image updates (optional, evaluate after MVP)
- **SSO integration** via OIDC (Phase 2)

### Rationale

1. **Kubernetes-Native Leader**: ArgoCD is the most popular GitOps tool for Kubernetes, with 15,000+ GitHub stars, CNCF Graduated status, and massive adoption

2. **CNCF Graduated Project**: Highest maturity level in CNCF, indicating:
   - Production-ready and battle-tested
   - Strong governance and security
   - Long-term sustainability
   - Regular security audits

3. **Best-in-Class GitOps**: Purpose-built for GitOps on Kubernetes:
   - Declarative Git-based deployments
   - Automated sync with configurable policies
   - Drift detection with auto-heal option
   - Multi-cluster management from single UI
   - Application health assessment

4. **Argo Ecosystem Integration**: Part of larger Argo ecosystem:
   - **Argo Rollouts**: Advanced deployment strategies (canary, blue-green)
   - **Argo Workflows**: Complex workflow orchestration
   - **Argo Events**: Event-driven workflow automation
   - **Argo CD Image Updater**: Automated image updates
   - All integrate seamlessly

5. **Progressive Delivery Support**: Via Argo Rollouts:
   - Canary deployments with automated analysis
   - Blue-green deployments
   - Traffic splitting (with service mesh)
   - Automated rollback on metrics threshold
   - Critical for reducing change failure rate

6. **Excellent UI**: Beautiful web interface showing:
   - Application topology (visual graph)
   - Real-time sync status
   - Resource health
   - Git commit history
   - Diff view (Git vs. cluster)

7. **CLI and API**: Full control via CLI and REST API:
   - Automate operations
   - Integrate with CI/CD
   - Custom tooling and scripts

8. **ApplicationSets**: Powerful templating for multiple applications:
   - Deploy multiple apps with single manifest
   - Git generator (monorepo support)
   - Cluster generator (multi-cluster)
   - Matrix generator (combinations)

9. **RBAC and Security**:
   - Fine-grained RBAC for teams
   - SSO integration (OIDC, SAML, LDAP)
   - Git credentials management
   - Audit logging

10. **Backstage Integration**: Official Backstage plugin shows:
    - Application sync status
    - Deployment history
    - Health status
    - Direct links to ArgoCD UI

11. **Large Community**:
    - 300+ contributors
    - Active Slack community (10,000+ members)
    - Monthly releases
    - Extensive documentation

12. **Production Proven**: Used by thousands of organizations including Intuit, IBM, Red Hat, Adobe

## Consequences

### Positive

✅ **True GitOps**: Git becomes single source of truth, all changes tracked and auditable

✅ **Automated Deployments**: Merge to Git → automatic deployment, increasing deployment frequency

✅ **Drift Correction**: Self-healing keeps cluster in sync with Git, reducing incidents

✅ **Fast Rollback**: Git revert + automatic sync = sub-minute rollback time

✅ **Multi-Environment**: Promote changes across environments with Git merges/branches

✅ **Developer Self-Service**: Developers deploy by merging PRs, no platform team tickets

✅ **Audit Trail**: Complete history of who deployed what, when, and why (Git commits)

✅ **Progressive Delivery**: Canary and blue-green reduce blast radius of bad deployments

✅ **Reduced MTTR**: Fast rollback and self-healing improve time to restore service

✅ **Visual Topology**: Application graph helps understand dependencies and health

✅ **Multi-Cluster**: Single pane of glass for dev, staging, prod clusters

✅ **CNCF Backing**: Graduated status ensures long-term sustainability and security

✅ **DORA Improvement**: GitOps directly improves all four key metrics

### Negative

⚠️ **Learning Curve**: Platform team needs to learn ArgoCD concepts (Applications, ApplicationSets, Sync policies)

⚠️ **Git as Bottleneck**: All changes must go through Git (could slow emergency fixes)

⚠️ **Initial Setup Complexity**: Configuring multi-cluster, RBAC, and integrations takes time

⚠️ **Resource Overhead**: ArgoCD consumes ~500MB RAM, additional for controllers

⚠️ **Sync Delays**: 3-minute default sync interval (configurable, can use webhooks)

⚠️ **Secret Management**: Secrets in Git require encryption (Sealed Secrets, SOPS, Vault)

⚠️ **ApplicationSet Complexity**: Advanced ApplicationSets can become complex to debug

⚠️ **UI Performance**: Large deployments (100+ apps) can slow UI

⚠️ **Version Compatibility**: Must ensure ArgoCD version compatible with Kubernetes version

### Neutral

◽ **GitOps Philosophy**: Requires team buy-in to GitOps methodology

◽ **Repository Structure**: Requires thoughtful Git repository organization

◽ **Sync Policies**: Choosing auto vs. manual sync requires consideration per application

### Mitigation Strategies

1. **Learning Curve**:
   - Allocate 1 week for ArgoCD training
   - Start with simple applications, progress to complex
   - Leverage official documentation and tutorials
   - Join ArgoCD Slack community for support

2. **Git as Bottleneck**:
   - Use webhooks for faster sync (vs. 3-minute poll)
   - Emergency "break glass" procedure documented
   - kubectl still available for true emergencies
   - Consider sync timeout configuration

3. **Secret Management**:
   - Use Sealed Secrets or External Secrets Operator
   - Never commit raw secrets to Git
   - Document secret rotation procedures
   - Consider Vault integration for sensitive data

4. **Initial Setup**:
   - Use official Helm chart for deployment
   - Start with single cluster, add multi-cluster later
   - Use Infrastructure as Code for ArgoCD configuration
   - Create runbooks for common operations

5. **Sync Performance**:
   - Use webhooks instead of polling where possible
   - Configure appropriate sync intervals per application
   - Use ApplicationSets for large-scale deployments
   - Monitor ArgoCD performance metrics

6. **Repository Structure**:
   - Design clear repository structure upfront
   - Separate application code from deployment manifests
   - Use Kustomize or Helm for configuration management
   - Document repository conventions

## Alternatives Considered

### Alternative 1: Flux CD

**Pros**:
- CNCF Graduated (alongside ArgoCD)
- GitOps Toolkit approach (modular)
- Native Helm support
- Excellent multi-tenancy
- Lower resource usage than ArgoCD
- Strong automation capabilities
- Good for Infrastructure as Code

**Cons**:
- **No Built-In UI**: CLI-only, requires separate UI (Weave GitOps)
- **Less Visual**: No application topology graph like ArgoCD
- **Smaller Community**: Fewer contributors and users than ArgoCD
- **Learning Curve**: GitOps Toolkit concepts more abstract
- **Progressive Delivery**: Requires Flagger (separate project)
- **Less Mature Backstage Plugin**: ArgoCD plugin more feature-complete

**Reason for Rejection**: Flux is excellent, but ArgoCD's UI is significant advantage for developer experience and troubleshooting. Visual application topology helps developers understand system. ArgoCD's larger community and more mature Backstage integration better fit Fawkes needs. However, Flux is valid choice and could be reconsidered for infrastructure GitOps.

### Alternative 2: Jenkins X

**Pros**:
- Complete CI/CD platform (not just CD)
- GitOps-based
- Automated preview environments
- Integrated pipeline and deployment
- Good for Jenkins users

**Cons**:
- **Opinionated**: Prescriptive workflows, less flexible
- **Complexity**: Full platform, not just GitOps
- **Jenkins Dependency**: Tied to Jenkins ecosystem
- **Smaller Adoption**: Less proven than ArgoCD/Flux
- **Maintenance Concerns**: Development pace slowed
- **Overkill**: We already have Jenkins for CI

**Reason for Rejection**: Jenkins X is full CI/CD platform, but we're using Jenkins (ADR-004) for CI and only need GitOps for CD. Jenkins X too opinionated and complex. ArgoCD's separation of concerns (CI vs CD) cleaner architecture.

### Alternative 3: Spinnaker

**Pros**:
- Multi-cloud native (not just Kubernetes)
- Advanced deployment strategies
- Proven at Netflix scale
- Strong pipeline orchestration
- Multi-cluster management
- Extensive integrations

**Cons**:
- **Heavy and Complex**: Difficult to deploy and maintain
- **Resource Intensive**: Requires 8+ microservices, significant resources
- **Steep Learning Curve**: Complex concepts and UI
- **Not GitOps-First**: Push-based, not GitOps pull model
- **Maintenance Burden**: High operational overhead
- **Overkill**: More than we need for Kubernetes deployments

**Reason for Rejection**: Spinnaker powerful but extremely complex. High resource usage (10+ pods) and maintenance burden unjustified for our Kubernetes-focused needs. Not GitOps-native (push model). ArgoCD provides 80% of benefits with 20% of complexity. May revisit Spinnaker if we need multi-cloud deployment orchestration beyond Kubernetes.

### Alternative 4: Helm Only (No GitOps Tool)

**Pros**:
- Simple, no additional tool to learn
- Direct control with helm upgrade commands
- Low resource overhead
- Familiar to most Kubernetes users
- Fast deployments

**Cons**:
- **No GitOps**: No automatic sync, drift detection, or self-healing
- **Manual Process**: Engineers must run helm commands
- **No Audit Trail**: History only in Helm releases, not Git
- **No Rollback Automation**: Manual helm rollback required
- **No Multi-Cluster**: Managing multiple clusters complex
- **High Error Potential**: Human mistakes likely
- **No Developer Self-Service**: Requires platform team access

**Reason for Rejection**: Helm alone doesn't provide GitOps benefits. Manual deployments don't scale, increase error rate, and limit deployment frequency. GitOps is core principle of modern platform engineering and DORA best practices. Helm excellent as package manager but not replacement for GitOps tool.

### Alternative 5: Rancher Fleet

**Pros**:
- Built into Rancher platform
- GitOps-based
- Multi-cluster management
- Simpler than ArgoCD
- Good for Rancher users

**Cons**:
- **Rancher Dependency**: Requires Rancher platform
- **Smaller Community**: Much smaller than ArgoCD/Flux
- **Less Mature**: Newer project, less battle-tested
- **Limited Features**: Fewer advanced features than ArgoCD
- **No Progressive Delivery**: No built-in canary/blue-green
- **Weaker Ecosystem**: Fewer integrations and plugins

**Reason for Rejection**: Fleet good if using Rancher, but we're not. ArgoCD more mature, larger community, better features. Fleet's simplicity doesn't outweigh ArgoCD's comprehensive capabilities and proven track record.

### Alternative 6: GitLab AutoDevOps

**Pros**:
- Integrated with GitLab
- Auto-configured pipelines
- Built-in deployment
- Good for GitLab-centric shops

**Cons**:
- **GitLab Lock-In**: Only works with GitLab
- **Not GitOps**: Push-based, not declarative
- **Opinionated**: Limited customization
- **GitLab Required**: We use GitHub
- **Less Control**: Abstract away too much
- **Not Best-of-Breed**: GitOps secondary to CI features

**Reason for Rejection**: GitLab AutoDevOps tied to GitLab ecosystem. We use GitHub. Not true GitOps (push-based CI/CD). ArgoCD better fit for our multi-tool, GitOps-first approach.

### Alternative 7: Weave GitOps (Commercial)

**Pros**:
- Built on Flux CD
- Nice UI for Flux
- Enterprise features
- Good for Flux users

**Cons**:
- **Commercial**: Core features open source, but UI and advanced features paid
- **Cost**: Pricing unclear, per-cluster
- **Flux Dependency**: Requires Flux understanding
- **Smaller Adoption**: Newer, less proven
- **Less Features**: Not as comprehensive as ArgoCD

**Reason for Rejection**: Commercial aspects conflict with open source values. ArgoCD provides richer feature set out-of-box with free, open source UI. Weave GitOps good for Flux users wanting UI, but ArgoCD better starting point.

## Related Decisions

- **ADR-001**: Kubernetes (ArgoCD manages Kubernetes deployments)
- **ADR-002**: Backstage (ArgoCD plugin shows deployment status)
- **ADR-004**: Jenkins (Jenkins triggers ArgoCD deployments)
- **ADR-007**: Mattermost (Argo Notifications sends alerts to Mattermost)
- **Future ADR**: Repository Structure for GitOps
- **Future ADR**: Secrets Management Strategy

## Implementation Notes

### Deployment Architecture

```yaml
# ArgoCD Deployment
argocd:
  namespace: argocd

  components:
    - argocd-server:
        replicas: 2 (HA)
        resources:
          cpu: 500m
          memory: 256Mi
        ingress: argocd.fawkes.io

    - argocd-repo-server:
        replicas: 2 (HA)
        resources:
          cpu: 500m
          memory: 512Mi

    - argocd-application-controller:
        replicas: 1 (stateful, uses leader election for HA)
        resources:
          cpu: 1 core
          memory: 1Gi

    - argocd-redis:
        replicas: 3 (HA with sentinel)
        resources:
          cpu: 200m
          memory: 256Mi

    - argocd-dex-server: (for SSO)
        replicas: 1
        resources:
          cpu: 100m
          memory: 128Mi

  integrations:
    - github (repository source)
    - mattermost (notifications)
    - backstage (status plugin)
    - dora-metrics-service (deployment events)
```

### Repository Structure

**Recommended Structure** (monorepo approach):

```
gitops-repo/
├── apps/
│   ├── dev/
│   │   ├── team-a/
│   │   │   ├── service-1/
│   │   │   │   ├── kustomization.yaml
│   │   │   │   └── deployment.yaml
│   │   │   └── service-2/
│   │   └── team-b/
│   ├── staging/
│   └── prod/
├── platform/
│   ├── backstage/
│   ├── jenkins/
│   ├── mattermost/
│   ├── prometheus/
│   └── grafana/
├── infrastructure/
│   ├── namespaces/
│   ├── rbac/
│   ├── network-policies/
│   └── resource-quotas/
├── argocd-apps/
│   ├── dev-apps.yaml (ApplicationSet)
│   ├── staging-apps.yaml
│   └── prod-apps.yaml
└── README.md
```

**Alternative** (polyrepo approach):
- Separate repository per team/service
- Pros: Team autonomy, clear ownership
- Cons: Harder to enforce consistency, more repositories to manage

### ApplicationSet Example

**Deploy All Team Applications**:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: team-applications
  namespace: argocd
spec:
  generators:
    - git:
        repoURL: https://github.com/paruff/fawkes-gitops
        revision: HEAD
        directories:
          - path: apps/prod/*/*
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/paruff/fawkes-gitops
        targetRevision: HEAD
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path[1]}}' # team name from path
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

### Sync Policies

**Automated Sync** (recommended for most apps):
```yaml
syncPolicy:
  automated:
    prune: true       # Delete resources removed from Git
    selfHeal: true    # Revert manual changes
  syncOptions:
    - CreateNamespace=true
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

**Manual Sync** (for critical production apps initially):
```yaml
syncPolicy:
  manual: {}  # Require manual approval for sync
```

### Progressive Delivery with Argo Rollouts

**Canary Deployment Example**:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: sample-app
spec:
  replicas: 10
  strategy:
    canary:
      steps:
        - setWeight: 20    # 20% traffic to canary
        - pause: {duration: 5m}
        - setWeight: 40    # 40% traffic
        - pause: {duration: 5m}
        - setWeight: 60    # 60% traffic
        - pause: {duration: 5m}
        - setWeight: 80    # 80% traffic
        - pause: {duration: 5m}
      analysis:
        templates:
          - templateName: error-rate-analysis
        args:
          - name: service-name
            value: sample-app
      trafficRouting:
        istio:
          virtualService:
            name: sample-app
```

### Notifications Configuration

**Mattermost Integration**:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
data:
  service.mattermost: |
    apiURL: https://mattermost.fawkes.io
    token: $mattermost-token

  template.app-deployed: |
    message: |
      Application {{.app.metadata.name}} is now running new version.
      {{if eq .serviceType "slack"}}:white_check_mark:{{end}} Application details: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}.

  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]
```

**Subscribe Application**:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  annotations:
    notifications.argoproj.io/subscribe.on-deployed.mattermost: team-deployments
```

### Multi-Cluster Management

**Add Cluster**:

```bash
# Login to ArgoCD
argocd login argocd.fawkes.io

# Add production cluster
argocd cluster add prod-cluster --name production

# Add staging cluster
argocd cluster add staging-cluster --name staging
```

**Deploy to Multiple Clusters** (ApplicationSet):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: multi-cluster-app
spec:
  generators:
    - list:
        elements:
          - cluster: dev
            url: https://dev-cluster
          - cluster: staging
            url: https://staging-cluster
          - cluster: prod
            url: https://prod-cluster
  template:
    metadata:
      name: 'sample-app-{{cluster}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/paruff/fawkes-gitops
        path: 'apps/{{cluster}}/sample-app'
      destination:
        server: '{{url}}'
        namespace: sample-app
```

### RBAC Configuration

**Project-Based RBAC**:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-a
spec:
  description: Team A applications
  sourceRepos:
    - 'https://github.com/paruff/fawkes-gitops'
  destinations:
    - namespace: 'team-a-*'
      server: https://kubernetes.default.svc
  roles:
    - name: team-a-developer
      policies:
        - p, proj:team-a:team-a-developer, applications, get, team-a/*, allow
        - p, proj:team-a:team-a-developer, applications, sync, team-a/*, allow
```

### Backstage Integration

**Install Plugin**:

```bash
yarn add --cwd packages/app @roadiehq/backstage-plugin-argo-cd
```

**Component Annotation**:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: sample-app
  annotations:
    argocd/app-name: sample-app
    argocd/instance-name: argocd
spec:
  type: service
  lifecycle: production
  owner: team-a
```

### Monitoring & Observability

**Prometheus Metrics**:
- argocd_app_sync_total (sync attempts)
- argocd_app_sync_status (current sync status)
- argocd_app_health_status (application health)
- argocd_git_request_total (Git operations)

**Grafana Dashboard**:
- Official ArgoCD dashboard (ID: 14584)
- Customizations for Fawkes-specific views

**Alerts**:
- Application OutOfSync >30 minutes
- Application Degraded >15 minutes
- Sync Failures (3 consecutive)
- High API latency (>2s)

### Secret Management

**Option 1: Sealed Secrets** (recommended for MVP):

```bash
# Encrypt secret
echo -n 'my-secret-value' | kubectl create secret generic my-secret \
  --dry-run=client --from-file=password=/dev/stdin -o yaml | \
  kubeseal -o yaml > sealed-secret.yaml

# Commit sealed-secret.yaml to Git
# SealedSecret controller decrypts in-cluster
```

**Option 2: External Secrets Operator**:
- Fetch secrets from Vault, AWS Secrets Manager, etc.
- Keep secret references in Git, not actual secrets
- Better for large-scale deployments

**Never**: Commit raw secrets to Git!

### Backup & Disaster Recovery

**Backup Strategy**:
- ArgoCD configuration stored in Git (Infrastructure as Code)
- Application manifests in GitOps repository
- ArgoCD state in Kubernetes (can be recreated)

**Recovery**:
1. Redeploy ArgoCD from Helm chart
2. Re-add clusters
3. Create Applications pointing to Git repository
4. ArgoCD syncs from Git (applications restored)

**RTO**: <2 hours (ArgoCD redeploy + application sync)
**RPO**: 0 (Git is source of truth, no data loss)

### Performance Optimization

**For Large Deployments**:
- Increase application controller replicas
- Tune sync timeouts and retry logic
- Use ApplicationSets instead of individual Applications
- Enable concurrent sync operations
- Optimize Git repository size (use shallow clones)

**Resource Limits**:
```yaml
spec:
  resources:
    limits:
      cpu: 2
      memory: 2Gi
    requests:
      cpu: 500m
      memory: 512Mi
```

## Monitoring This Decision

We will revisit this ADR if:
- ArgoCD project becomes unmaintained or development slows
- Performance issues arise that cannot be resolved
- A superior GitOps tool emerges with better fit
- Flux CD's UI significantly improves (could reconsider)
- Operational burden exceeds benefits
- Community adoption of ArgoCD declines significantly

**Next Review Date**: April 8, 2026 (6 months)

## References

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD GitHub Repository](https://github.com/argoproj/argo-cd)
- [Argo Rollouts Documentation](https://argo-rollouts.readthedocs.io/)
- [CNCF ArgoCD Project](https://www.cncf.io/projects/argo/)
- [GitOps Principles](https://opengitops.dev/)
- [ArgoCD Backstage Plugin](https://github.com/RoadieHQ/roadie-backstage-plugins/tree/main/plugins/frontend/backstage-plugin-argo-cd)

## Notes

### ArgoCD vs. Flux: The Eternal Debate

**When to choose ArgoCD**:
- Want built-in, feature-rich UI
- Prefer visual application topology
- Need strong RBAC out-of-box
- Value large, active community
- Want simpler mental model

**When to choose Flux**:
- Prefer CLI-first workflow
- Want lower resource usage
- Need advanced multi-tenancy
- Comfortable with GitOps Toolkit abstraction
- Strong preference for CNCF's recommended GitOps tool

**For Fawkes**: ArgoCD's UI significant advantage for developer experience and troubleshooting. Both are excellent choices—this decision not deeply philosophical, more pragmatic based on UX priorities.

### GitOps Best Practices

1. **Repository Structure**: Organize thoughtfully upfront (hard to change later)
2. **Separation of Concerns**: Keep application code separate from deployment manifests
3. **Environment Promotion**: Use branches or directories for environments
4. **Secret Management**: Never commit secrets, use Sealed Secrets or Vault
5. **Sync Policies**: Start with manual sync for critical apps, automate once confident
6. **Monitoring**: Watch sync failures, drift detection, and performance metrics
7. **Rollback Plan**: Test rollback procedure before you need it

### Progressive Delivery ROI

Argo Rollouts adds complexity but significantly reduces change failure rate:
- Canary deployments catch issues before full rollout
- Automated rollback based on metrics prevents outages
- Traffic shifting minimizes blast radius
- Aligns with DORA best practices

Worth complexity trade-off for production applications. Can start without Rollouts, add later for critical services.

---

**Decision Made By**: Platform Architecture Team
**Approved By**: Project Lead
**Date**: October 8, 2025
**Author**: [Platform Architect Name]
**Last Updated**: October 8, 2025