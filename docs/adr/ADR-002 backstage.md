# ADR-002: Backstage for Developer Portal

## Status
**Accepted** - October 8, 2025

## Context

Fawkes is an Internal Product Delivery Platform that needs a unified interface—a "single pane of glass"—where developers and platform engineers can discover services, provision infrastructure, launch applications, access documentation, track learning progress, and monitor platform health.

### The Need for a Developer Portal

**Current Challenges Without a Portal**:
- **Tool Sprawl**: Developers jump between GitHub, Jenkins, ArgoCD, Grafana, Mattermost, documentation sites
- **Service Discovery**: No central catalog of services, APIs, dependencies, ownership
- **Self-Service Barriers**: Provisioning requires knowing where to go, what to do, who to ask
- **Documentation Fragmentation**: Scattered across wikis, README files, Confluence, tribal knowledge
- **Onboarding Complexity**: New team members overwhelmed by tools and processes
- **Cognitive Load**: Mental model of the system exists only in developers' heads
- **Dojo Integration**: Learning content needs a central hub accessible alongside work

**What Teams Need**:
1. **Service Catalog**: Comprehensive view of all services, APIs, libraries, and resources
2. **Software Templates**: Self-service scaffolding for new services ("golden paths")
3. **Documentation Hub**: Centralized, searchable, always up-to-date technical docs
4. **Status Dashboard**: Real-time health, deployment status, metrics for all services
5. **Dojo Learning Hub**: Browse curriculum, launch labs, track progress
6. **Plugin Ecosystem**: Extensibility to integrate with all platform tools
7. **Search**: Find anything (services, docs, people, runbooks) instantly
8. **Developer Experience**: Beautiful, intuitive interface that developers love

### Requirements for Developer Portal

**Technical Requirements**:
- **Open Source**: Aligns with Fawkes values, no vendor lock-in
- **Extensible**: Plugin architecture to integrate all platform components
- **Kubernetes-Native**: Designed for cloud-native environments
- **API-First**: Programmatic access to all functionality
- **Self-Hosted**: Deploy in our infrastructure, control our data
- **Active Development**: Regular releases, growing community
- **Enterprise-Grade**: Production-ready, scalable, secure

**User Experience Requirements**:
- **Intuitive UI**: Developers can use without extensive training
- **Fast**: Page loads <2 seconds, search instant
- **Mobile-Friendly**: Accessible on phones/tablets
- **Customizable**: Branding, themes, layout configurable
- **Accessible**: WCAG compliance, keyboard navigation

**Integration Requirements**:
- **GitHub**: Repository discovery, authentication
- **Jenkins/CI**: Pipeline status, trigger builds
- **ArgoCD**: Deployment status, sync applications
- **Kubernetes**: Resource visibility, pod logs
- **Grafana**: Embed dashboards, show metrics
- **Mattermost**: Chat integration, notifications
- **Focalboard**: Embed boards, show progress
- **DORA Metrics**: Display team performance
- **Dojo System**: Learning hub, lab launcher

### Forces at Play

**Technical Forces**:
- Need to integrate with dozens of tools (existing and future)
- Developer portal is mission-critical (high availability required)
- Must scale from 10 to 1000+ services
- Security critical (access to sensitive information)

**User Experience Forces**:
- Developers resist using clunky, slow tools
- Cognitive load already high; portal must reduce, not increase
- Mobile access increasingly important
- Dark mode preference widespread among developers

**Business Forces**:
- Developer productivity directly impacts business outcomes
- Portal adoption critical for platform success
- Open source preference to avoid vendor lock-in
- Total cost of ownership matters (licensing, maintenance)

**Community Forces**:
- Backstage has largest, most active community in this space
- CNCF incubating status provides credibility
- Spotify's success story is compelling
- Growing ecosystem of plugins and integrations

## Decision

**We will use Backstage as the developer portal and dojo learning hub for Fawkes.**

Specifically:
- **Backstage Core** (latest stable version)
- **PostgreSQL backend** for catalog storage
- **Custom Fawkes theme** with branding
- **Curated plugin ecosystem** (Jenkins, ArgoCD, Kubernetes, Grafana, Mattermost, Focalboard)
- **Custom dojo plugin** (`@fawkes/plugin-dojo`) for learning hub
- **TechDocs** for documentation-as-code
- **Software Templates** for golden paths

### Rationale

1. **Industry Leading**: Backstage is the de facto standard for developer portals, originated at Spotify, now CNCF Incubating project with 100+ adopters including American Airlines, Netflix, Expedia

2. **Purpose-Built for IDPs**: Specifically designed for internal developer platforms, not retrofitted from another use case. Core features align perfectly with Fawkes needs:
   - Service catalog with relationships and ownership
   - Software templates for scaffolding
   - TechDocs for documentation
   - Plugin architecture for extensibility

3. **Massive Plugin Ecosystem**: 100+ plugins available, covering most tools:
   - CI/CD: Jenkins, GitHub Actions, CircleCI, GitLab
   - Deployment: ArgoCD, Flux, Spinnaker, Kubernetes
   - Monitoring: Grafana, Prometheus, Datadog, PagerDuty
   - Cloud: AWS, Azure, GCP
   - And many more

4. **CNCF Incubating Status**: Under Cloud Native Computing Foundation governance:
   - Long-term sustainability assured
   - Neutral governance (not single-vendor controlled)
   - Rigorous security and quality standards
   - Growing adoption and contribution

5. **Active Development & Community**: 
   - 1,000+ contributors
   - Monthly releases
   - 27,000+ GitHub stars
   - Active Discord community (5,000+ members)
   - Excellent documentation

6. **Open Source & Self-Hosted**: 
   - Apache 2.0 license
   - Complete control over data and deployment
   - No per-user licensing fees
   - Customizable to exact needs

7. **Perfect for Dojo Integration**: 
   - Can build custom plugin for learning hub
   - TechDocs perfect for module content
   - Catalog can track learner progress
   - Plugins can integrate with lab environment

8. **Developer Experience**: 
   - Beautiful, modern UI (React-based)
   - Fast, responsive
   - Intuitive navigation
   - Developers actually enjoy using it

9. **Extensibility**: 
   - Plugin architecture allows infinite customization
   - Frontend and backend plugins
   - Can build exactly what we need
   - TypeScript/React (popular, easy to find contributors)

10. **Enterprise Adoption**: Used by major enterprises proves production-readiness, scalability, security

11. **Software Templates**: Golden paths built-in, can create custom templates for:
    - Microservices (Java, Python, Node.js, Go)
    - Infrastructure (Terraform modules)
    - Dojo labs (pre-configured learning environments)

12. **Search & Discovery**: 
    - Full-text search across services, docs, people
    - Advanced filtering and faceting
    - GraphQL API for programmatic access

## Consequences

### Positive

✅ **Unified Developer Experience**: Single interface for all platform interactions, dramatically reduces cognitive load

✅ **Self-Service Enablement**: Software templates empower developers to provision without platform team tickets

✅ **Service Visibility**: Catalog provides system-wide visibility—every service, owner, dependencies visible

✅ **Documentation Centralization**: TechDocs brings all documentation into one searchable place

✅ **Onboarding Acceleration**: New developers have guided path to understand systems and get productive

✅ **Dojo Integration**: Custom plugin creates perfect hub for learning (course browser, lab launcher, progress tracking)

✅ **Extensibility**: Can integrate any tool via plugins, future-proof for new technologies

✅ **Community Support**: Large community means help available, plugins exist for most needs

✅ **Developer Satisfaction**: Beautiful UI developers enjoy using improves engagement and platform adoption

✅ **Open Source Alignment**: Demonstrates commitment to open source, avoids vendor lock-in

✅ **Cost Effective**: No licensing fees, only infrastructure and development time

✅ **CNCF Backing**: Long-term sustainability, neutral governance, security audits

✅ **Golden Paths**: Software templates codify best practices, improve consistency

### Negative

⚠️ **Learning Curve**: Platform team needs to learn Backstage architecture, plugin development (TypeScript/React)

⚠️ **Initial Setup Complexity**: Getting Backstage configured with all plugins takes time (2-4 weeks)

⚠️ **Resource Requirements**: Backstage + PostgreSQL requires ~1-2GB RAM, 1-2 CPU cores

⚠️ **Plugin Quality Variance**: Community plugins vary in quality, some need customization

⚠️ **Version Management**: Keeping Backstage and plugins updated requires ongoing effort

⚠️ **Custom Plugin Development**: Building custom dojo plugin requires TypeScript/React expertise (20-40 hours)

⚠️ **Performance at Scale**: Large catalogs (1000+ entities) can slow search/filtering (mitigated with indexing)

⚠️ **Authentication Complexity**: Integrating with multiple auth providers can be tricky

⚠️ **Breaking Changes**: Major Backstage updates sometimes introduce breaking changes in plugins

### Neutral

◽ **TypeScript/React Stack**: Modern stack but requires specific skills (widely available)

◽ **Plugin Approval Process**: Not all community plugins are official; need evaluation

◽ **Theming Flexibility**: Can fully customize but requires CSS/design skills

### Mitigation Strategies

1. **Learning Curve**:
   - Allocate 1 week for Backstage training (official docs, tutorials)
   - Start with core features, add plugins incrementally
   - Leverage community Discord for questions
   - Consider Backstage training from Spotify (if available)

2. **Initial Setup**:
   - Use official Helm charts for deployment
   - Start with minimal plugin set, expand over time
   - Document configuration as Infrastructure as Code
   - Create runbooks for common operations

3. **Custom Plugin Development**:
   - Hire contractor if TypeScript/React skills lacking
   - Use plugin templates and examples from community
   - Contribute plugin back to community (get feedback, maintenance help)
   - Budget 40 hours for dojo plugin development

4. **Performance**:
   - Implement PostgreSQL optimization (indexing, connection pooling)
   - Use caching for expensive queries
   - Consider read replicas for large deployments
   - Monitor performance, optimize bottlenecks

5. **Plugin Quality**:
   - Vet plugins before adoption (GitHub stars, maintainer responsiveness, recent commits)
   - Fork and customize plugins if needed
   - Contribute improvements back to community
   - Build custom plugins for critical features

6. **Version Management**:
   - Establish update cadence (monthly review, quarterly updates)
   - Test updates in staging before production
   - Pin plugin versions in package.json
   - Subscribe to Backstage release notes

## Alternatives Considered

### Alternative 1: Port.io (SaaS)

**Pros**:
- Purpose-built for developer portals
- Beautiful, modern UI
- SaaS (no operational overhead)
- Growing quickly, good momentum
- Strong visualization capabilities
- AI-powered search

**Cons**:
- **SaaS Only**: No self-hosted option, data on Port's servers
- **Cost**: $20-50/developer/month depending on tier (expensive at scale)
- **Vendor Lock-In**: Proprietary platform, hard to migrate off
- **Not Open Source**: Closed source, can't customize deeply
- **Smaller Ecosystem**: Newer, fewer integrations than Backstage
- **Less Proven**: Fewer large enterprise adoptions
- **Misaligned Values**: SaaS commercial conflicts with open source platform values

**Reason for Rejection**: SaaS-only model and proprietary nature conflict with Fawkes' self-hosted, open source values. Cost prohibitive for open source community (at 500 developers: $120,000-$300,000/year). Cannot build deep customizations like dojo plugin.

### Alternative 2: Humanitec (SaaS)

**Pros**:
- Complete IDP platform (more than just portal)
- Score-based environment management
- Strong GitOps integration
- Good enterprise features
- Active development

**Cons**:
- **SaaS Only**: No self-hosted option
- **Very Expensive**: Enterprise pricing ($50-100k+ annually)
- **Opinionated**: Prescriptive workflows, less flexible
- **Not Just Portal**: Full platform, we're building our own
- **Closed Source**: Proprietary, can't customize
- **Vendor Lock-In**: Migrating off would be extremely difficult

**Reason for Rejection**: Humanitec is a complete platform, not just a portal. We're building Fawkes as the platform, only need portal component. SaaS-only and cost prohibitive. Closed source conflicts with values.

### Alternative 3: Cortex (SaaS)

**Pros**:
- Service catalog with scorecards
- On-call integration
- Incident management
- Resource management
- Growing adoption

**Cons**:
- **SaaS Only**: No self-hosted option
- **Cost**: $15-30/service/month (expensive at scale)
- **Narrow Focus**: More focused on service management than full portal
- **Proprietary**: Closed source
- **Smaller Community**: Less proven than Backstage
- **Limited Extensibility**: Cannot build custom plugins like dojo

**Reason for Rejection**: SaaS-only, closed source, cost at scale. More focused on service management than comprehensive developer portal. Cannot integrate deeply customized dojo learning system.

### Alternative 4: OpsLevel (SaaS)

**Pros**:
- Service maturity scoring
- Good for service ownership tracking
- Integrations with common tools
- Nice UI

**Cons**:
- **SaaS Only**: No self-hosted
- **Cost**: $15-25/service/month
- **Narrow Focus**: Primarily service catalog, not full portal
- **Proprietary**: Closed source
- **Limited Developer Experience**: More for tracking than daily use

**Reason for Rejection**: Too narrow in focus (service catalog only). SaaS-only, closed source, expensive. Not designed for developer portal use case. Lacks documentation, templates, extensibility features needed.

### Alternative 5: Build Custom Portal from Scratch

**Pros**:
- Complete control and customization
- Exact features we want
- No external dependencies
- Can optimize for our exact use case
- Learning opportunity for team

**Cons**:
- **Massive Time Investment**: 6-12 months full-time development for MVP
- **Opportunity Cost**: Time not spent on platform features
- **Maintenance Burden**: Ongoing development, security patches, features
- **Reinventing Wheel**: Building solved problems (catalog, templates, plugins)
- **No Community**: No plugins, no shared knowledge
- **Talent**: Requires frontend expertise (React/TypeScript)
- **Risk**: May not match quality of established solutions

**Reason for Rejection**: Building custom portal is 6-12 months of work, delaying platform delivery. Backstage solves 80%+ of needs out-of-box. Better to invest time in dojo content and platform features than rebuilding existing solutions. Can always build custom features as Backstage plugins.

### Alternative 6: Compass by Atlassian (SaaS)

**Pros**:
- From Atlassian (established company)
- Service catalog with health scores
- Integrates with Jira, Confluence, Bitbucket
- Good for Atlassian shops

**Cons**:
- **SaaS Only**: No self-hosted
- **Cost**: Part of Atlassian Cloud, pricing unclear
- **Atlassian Ecosystem**: Designed for Atlassian tools (Jira, Confluence)
- **New Product**: Launched 2022, less mature
- **Proprietary**: Closed source
- **Limited Extensibility**: Cannot build custom plugins
- **Not Developer Portal**: More service management than portal

**Reason for Rejection**: SaaS-only, proprietary, Atlassian ecosystem lock-in. Not designed as comprehensive developer portal. Cannot build custom dojo integration. Newer and less proven than Backstage.

### Alternative 7: GitLab (Self-Hosted or SaaS)

**Pros**:
- All-in-one DevOps platform
- Self-hosted option available
- Service catalog feature
- Strong CI/CD integration
- Open source core (Community Edition)

**Cons**:
- **CI/CD Centric**: Designed around GitLab CI/CD, we use Jenkins
- **Heavy**: GitLab is massive, resource-intensive
- **Portal Secondary**: Developer portal is add-on, not core feature
- **Limited Templates**: Software templates less mature than Backstage
- **Plugin Ecosystem**: Smaller ecosystem for portal features
- **Complexity**: GitLab has steep learning curve
- **Cost**: Premium/Ultimate tiers expensive for portal features

**Reason for Rejection**: GitLab excellent for GitLab-centric workflows, but we're using Jenkins, ArgoCD, and other tools. Portal features are add-on, not core competency. Too heavyweight for just portal use case. Backstage better fit for our multi-tool environment.

## Related Decisions

- **ADR-007**: Mattermost for Team Collaboration (will integrate via iframe/plugin)
- **ADR-008**: Focalboard for Project Management (will embed boards in Backstage)
- **ADR-004**: Jenkins for CI/CD (Jenkins plugin will show pipeline status)
- **ADR-003**: ArgoCD for GitOps (ArgoCD plugin will show deployment status)
- **Future ADR**: Backstage Dojo Plugin Architecture

## Implementation Notes

### Deployment Architecture

```yaml
# Backstage Deployment
backstage:
  namespace: fawkes-platform
  
  components:
    - backstage-frontend:
        image: fawkes/backstage:latest
        replicas: 2 (HA)
        resources:
          cpu: 1 core
          memory: 1Gi
        
    - backstage-backend:
        image: fawkes/backstage:latest
        replicas: 2 (HA)
        resources:
          cpu: 1 core
          memory: 1Gi
    
    - postgresql:
        replicas: 1 (consider HA for production)
        resources:
          cpu: 500m
          memory: 512Mi
        storage: 20Gi
        
  integrations:
    - github (OAuth, repository discovery)
    - jenkins (pipeline plugin)
    - argocd (deployment plugin)
    - kubernetes (resources plugin)
    - grafana (iframe embed)
    - mattermost (chat integration)
    - focalboard (board embed)
    - dojo-labs (custom plugin)
```

### Initial Plugin Set

**Core Plugins** (included with Backstage):
- **catalog**: Service catalog with relationships
- **scaffolder**: Software templates
- **techdocs**: Documentation as code
- **search**: Full-text search
- **kubernetes**: Pod logs, resource status

**Community Plugins** (install via npm):
- `@backstage/plugin-jenkins`: CI/CD pipeline status
- `@backstage/plugin-argo-cd`: Deployment status
- `@backstage/plugin-grafana`: Embed dashboards
- `@roadiehq/backstage-plugin-github-insights`: Repository insights
- `@backstage/plugin-tech-radar`: Technology adoption tracking

**Custom Plugins** (build ourselves):
- `@fawkes/plugin-dojo`: Learning hub, lab launcher, progress tracking
- `@fawkes/plugin-dora-metrics`: DORA dashboards and insights
- `@fawkes/plugin-mattermost`: Chat integration and notifications
- `@fawkes/plugin-focalboard`: Embed project boards

### Software Templates

**Initial Templates**:
1. **Microservice - Java Spring Boot**
   - Spring Boot starter with best practices
   - Dockerfile, Jenkinsfile, K8s manifests
   - Tests, logging, metrics instrumentation
   - README with runbook

2. **Microservice - Python FastAPI**
   - FastAPI with async support
   - pytest, coverage, linting
   - Container, pipeline, manifests
   - Documentation template

3. **Microservice - Node.js Express**
   - Express.js with TypeScript
   - Jest tests, ESLint, Prettier
   - CI/CD and deployment configs
   - OpenAPI specification

4. **Terraform Module**
   - Terraform module structure
   - Testing with Terratest
   - Documentation and examples
   - CI/CD for validation

5. **Dojo Lab Environment**
   - Pre-configured namespace
   - Sample application
   - Lab instructions
   - Validation scripts

### TechDocs Structure

```
docs/
├── index.md (homepage)
├── getting-started/
│   ├── overview.md
│   ├── quickstart.md
│   └── concepts.md
├── architecture/
│   ├── overview.md
│   ├── components.md
│   └── decisions.md (ADRs)
├── dojo/
│   ├── overview.md
│   ├── white-belt/
│   ├── yellow-belt/
│   ├── green-belt/
│   ├── brown-belt/
│   └── black-belt/
├── operations/
│   ├── runbooks/
│   ├── troubleshooting.md
│   └── monitoring.md
└── contributing/
    ├── code.md
    ├── docs.md
    └── dojo-content.md
```

### Catalog Structure

**Entity Types**:
- **Component**: Microservices, libraries, websites
- **API**: REST, GraphQL, gRPC interfaces
- **Resource**: Databases, queues, storage buckets
- **System**: Groups of components working together
- **Domain**: Business domains or product areas
- **User**: People using the platform
- **Group**: Teams, departments
- **Template**: Software templates for scaffolding

**Example Component**:
```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: sample-app
  title: Sample Application
  description: Demo application for Fawkes dojo
  annotations:
    github.com/project-slug: paruff/fawkes
    backstage.io/techdocs-ref: dir:.
    jenkins.io/job-full-name: fawkes/sample-app
    argocd/app-name: sample-app
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: dojo-learning
  providesApis:
    - sample-api
  consumesApis:
    - auth-api
  dependsOn:
    - resource:postgres-db
```

### Authentication Strategy

**Phase 1** (MVP): GitHub OAuth
- Simple setup
- Most developers have GitHub accounts
- Scopes: read:user, read:org

**Phase 2** (Month 2): Add providers
- Google OAuth (Gmail accounts)
- GitLab OAuth (if using GitLab)
- LDAP/AD (for enterprise)

**Phase 3** (Month 4): Full SSO
- SAML 2.0 support
- OIDC support
- Integration with Keycloak (if deployed)

### Customization & Branding

**Theme Configuration**:
```typescript
// app-config.yaml
app:
  title: Fawkes Platform
  branding:
    theme:
      light:
        primary: '#326CE5'    # Kubernetes blue
        secondary: '#FF6D00'  # Fawkes orange
      dark:
        primary: '#7DA3FF'
        secondary: '#FFB74D'
    logo: './logo.svg'
    favicon: './favicon.ico'
```

**Custom Homepage**:
- Welcome message and quick links
- Recent deployments
- DORA metrics summary
- Dojo progress widget
- Mattermost activity feed
- Platform status indicators

### Performance Optimization

**Caching**:
- Enable backend caching for catalog
- Redis for session storage
- CDN for static assets (logo, theme)

**Database**:
- PostgreSQL connection pooling
- Read replicas for queries
- Regular vacuum and analyze
- Index optimization

**Search**:
- Elasticsearch for full-text search (optional, improves performance)
- Incremental indexing
- Faceted search for filtering

### Monitoring & Observability

**Metrics** (Prometheus):
- HTTP request duration
- Catalog entity count
- Plugin load times
- Database query performance
- Authentication success/failure

**Dashboards** (Grafana):
- Backstage performance dashboard
- User activity dashboard
- Plugin health dashboard
- Database metrics dashboard

**Alerts**:
- Backstage down (>2 min)
- High error rate (>5% in 5 min)
- Slow response times (>2s P95)
- Database connection issues

### Backup & Disaster Recovery

**Backups**:
- PostgreSQL daily backups
- Catalog snapshots to Git (optional)
- Configuration stored in Git (Infrastructure as Code)

**Recovery**:
- Restore from PostgreSQL backup
- Redeploy from Git configuration
- RTO: <4 hours
- RPO: <24 hours

### Security Considerations

**Authentication**:
- OAuth 2.0 for external providers
- JWT tokens with expiration
- Session management with secure cookies

**Authorization**:
- RBAC for catalog entities
- Team-based access control
- Read-only public catalog (optional)

**Network Security**:
- TLS/HTTPS only
- Network policies to restrict access
- Rate limiting on APIs
- CORS configuration

**Secrets Management**:
- Never store secrets in Backstage config
- Use Kubernetes secrets or Vault
- Rotate credentials regularly
- Audit access logs

## Monitoring This Decision

We will revisit this ADR if:
- Backstage becomes unmaintained or development slows significantly
- A superior open source alternative emerges with better fit
- Performance issues arise that cannot be resolved
- Plugin ecosystem fails to meet our needs
- Community adoption of Backstage declines significantly
- Total cost of ownership (operational) exceeds commercial alternatives

**Next Review Date**: April 8, 2026 (6 months)

## References

- [Backstage Official Documentation](https://backstage.io/docs/)
- [Backstage GitHub Repository](https://github.com/backstage/backstage)
- [Backstage Plugin Marketplace](https://backstage.io/plugins)
- [CNCF Backstage Project](https://www.cncf.io/projects/backstage/)
- [Spotify Engineering Blog - Backstage](https://engineering.atspotify.com/2020/04/21/how-we-use-backstage-at-spotify/)
- [Backstage Community Discord](https://discord.gg/backstage)

## Notes

### Why Backstage Over Building Custom?

The most common question: "Why not build our own portal?"

**Build vs. Buy (Open Source) Calculation**:

**Build Custom**:
- Development: 6-12 months × 2 engineers = $200k-$400k
- Maintenance: Ongoing 0.5 FTE = $60k/year
- Features: Limited to what we build
- Community: Zero
- Risk: May not match quality

**Use Backstage**:
- Setup: 2-4 weeks × 1 engineer = $10k-$20k
- Custom plugin (dojo): 40 hours = $5k
- Maintenance: 0.1 FTE (mostly updates) = $12k/year
- Features: 100+ plugins available immediately
- Community: 1,000+ contributors, constant improvements
- Risk: Proven at scale

**ROI**: Backstage saves $200k-$400k upfront, $48k/year ongoing. Gets 100+ plugins and battle-tested features immediately.

### Backstage at Spotify Scale

Spotify's experience (from their blog):
- **1,300+ services** in catalog
- **200+ software templates**
- **200 custom plugins**
- **2,000+ engineers** using daily
- **Improved onboarding**: New engineers productive in days, not weeks
- **Reduced cognitive load**: 80% reduction in "where do I find X" questions

While Fawkes won't reach Spotify scale immediately, proves Backstage can scale to our needs and beyond.

### Plugin Development Learning Curve

Building custom plugins requires TypeScript and React knowledge. However:
- Official plugin templates speed development
- Extensive documentation and examples
- Active community for questions
- Can hire contractors if needed
- ROI positive even with learning curve

Budget 40 hours for first plugin (dojo learning hub), 20 hours for subsequent plugins.

---

**Decision Made By**: Platform Architecture Team  
**Approved By**: Project Lead  
**Date**: October 8, 2025  
**Author**: [Platform Architect Name]  
**Last Updated**: October 8, 2025