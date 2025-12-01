# ADR-016: DevLake for DORA Metrics Visualization

## Status

Accepted

## Context

The Fawkes platform requires a unified way to collect, calculate, and display the
five core DORA metrics to enable teams to assess their service performance,
identify bottlenecks, and ensure adherence to Golden Path standards.

### Current State

IDP concepts (CI/CD, secrets, infrastructure provisioning, policy enforcement)
are disconnected, residing across various URLs (Jenkins, Vault UI, Kubernetes CLI).
There is no integrated interface for developers to interact with the platform or
view consolidated DORA metrics.

The existing ADR-012 (Metrics Monitoring and Management) defines a custom DORA
Metrics Service for webhook-based event collection. While this approach provides
flexibility, it requires significant custom development effort.

### Requirements

1. **Deployment Frequency**: Track successful production deployments per day/week
2. **Lead Time for Changes**: Measure commit time to production deployment time
3. **Change Failure Rate (CFR)**: Calculate failed deployments / total deployments
4. **Mean Time to Restore (MTTR)**: Measure incident detection to resolution time
5. **Operational Performance**: Track SLO/SLI adherence for reliability metrics

### Evaluation Criteria

- Open source with active community
- Native DORA metrics calculation
- Integration with Git, Jenkins, and incident management
- Backstage integration capability
- Kubernetes-native deployment
- Minimal operational overhead

## Decision

We will deploy **Apache DevLake** as the DORA metrics collection, calculation,
and visualization platform for Fawkes.

### Why Apache DevLake

**Advantages**:
1. **Purpose-built for DORA**: Native support for all four DORA metrics
2. **Multi-source Integration**: Pre-built collectors for GitHub, GitLab, Jenkins,
   Jira, and more
3. **Open Source**: Apache 2.0 license, active CNCF community
4. **Extensible**: Plugin architecture for custom data sources
5. **Grafana Integration**: Pre-built dashboards for DORA visualization
6. **Low Custom Development**: Reduces need for custom webhook handlers

**Trade-offs**:
1. **Additional Component**: Adds DevLake stack (API, UI, collector workers)
2. **Database Requirement**: Requires MySQL/PostgreSQL for data storage
3. **Learning Curve**: Teams need to understand DevLake configuration

### Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DevLake DORA Metrics Layer                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                       Data Sources (Collectors)                          │ │
│  │                                                                           │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │ │
│  │  │   GitHub    │  │   Jenkins   │  │ Observability│ │   Custom    │    │ │
│  │  │   Plugin    │  │   Plugin    │  │   Webhook   │  │   Webhook   │    │ │
│  │  │             │  │             │  │             │  │             │    │ │
│  │  │ • Commits   │  │ • Builds    │  │ • Incidents │  │ • CFR Events│    │ │
│  │  │ • PRs       │  │ • Deploys   │  │ • Restores  │  │ • MTTR Data │    │ │
│  │  │ • Branches  │  │ • Pipelines │  │ • Alerts    │  │             │    │ │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘    │ │
│  │         │                 │                 │                │          │ │
│  └─────────┼─────────────────┼─────────────────┼────────────────┼──────────┘ │
│            │                 │                 │                │            │
│            └─────────────────┴─────────────────┴────────────────┘            │
│                                      │                                        │
│                                      ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                      DevLake Core Services                               │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         │ │
│  │  │  DevLake API    │  │  DevLake UI     │  │  Lake Workers   │         │ │
│  │  │  (Config/Data)  │  │  (Dashboard)    │  │  (Collectors)   │         │ │
│  │  └────────┬────────┘  └─────────────────┘  └────────┬────────┘         │ │
│  │           │                                          │                  │ │
│  │           └────────────────┬─────────────────────────┘                  │ │
│  │                            │                                             │ │
│  │                            ▼                                             │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐│ │
│  │  │                      MySQL Database                                  ││ │
│  │  │     (Raw data, domain models, DORA calculations)                    ││ │
│  │  └─────────────────────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                        │
│                                      │ Prometheus Metrics Export              │
│                                      ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                      Visualization Layer                                 │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         │ │
│  │  │    Grafana      │  │    Backstage    │  │   DevLake UI    │         │ │
│  │  │  DORA Dashboard │  │  Plugin Widget  │  │  (Native UI)    │         │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘         │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

### DORA Metrics Calculation

DevLake calculates DORA metrics using the appropriate data sources for a GitOps
architecture where ArgoCD handles deployments:

| Metric | Primary Data Source | Secondary Source | Calculation |
|--------|---------------------|------------------|-------------|
| Deployment Frequency | **ArgoCD** sync events | GitHub deployments | Successful production syncs per time period |
| Lead Time for Changes | Git commits + **ArgoCD** | - | Time from first commit to ArgoCD sync completion |
| Change Failure Rate | **ArgoCD** + Incidents | Observability alerts | Failed syncs / Total syncs |
| Mean Time to Restore | Incident records + **ArgoCD** | - | Time from incident to restore sync |
| Operational Performance | Prometheus SLO/SLI data | - | Uptime, latency, error rate adherence |

**Note on Jenkins Role**: In a GitOps architecture, Jenkins handles CI (build,
test, scan) but does **not** perform deployments. Jenkins updates the GitOps
repository, which ArgoCD then reconciles. Therefore:

- **ArgoCD** is the source of truth for deployment events
- **Jenkins** provides build/test metrics and rework tracking (build failures,
  test reruns, quality gate failures)

### Jenkins Rework Metrics

Jenkins contributes to developer productivity metrics beyond core DORA:

| Metric | Description | Calculation |
|--------|-------------|-------------|
| Build Success Rate | Percentage of successful builds | Passed builds / Total builds |
| Test Flakiness | Frequency of non-deterministic test failures | Flaky runs / Total runs |
| Quality Gate Pass Rate | SonarQube gate success | Passed gates / Total scans |
| Rework Rate | Builds triggered by same commit | Rebuilds / Unique commits |
| Build Duration Trend | Average build time over time | Mean/P95 build duration |

### Deployment Configuration

**Namespace Isolation**:
- DevLake deployed in `fawkes-devlake` namespace
- Secrets managed via Vault/External Secrets
- Network policies restrict access to approved sources

**Resource Requirements**:
```yaml
devlake-api:
  requests:
    cpu: 200m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 2Gi

devlake-ui:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

mysql:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 4Gi
```

### Data Source Configuration

**GitHub/Git Integration**:
- OAuth app for repository access
- Webhook receiver for real-time events
- Collect: commits, PRs, branches

**ArgoCD Integration** (Primary deployment source):
- API access for sync event collection
- Deployment frequency from successful syncs
- Lead time correlation with commit timestamps
- Failure detection from sync failures

**Jenkins Integration** (CI and rework metrics):
- API token for build data access
- Build success/failure tracking
- Quality gate results
- **Rework metrics**: build retries, flaky tests, repeated failures

**Observability Integration**:
- Webhook endpoint for incident events
- Alert-to-incident correlation
- Resolution tracking for MTTR

### Backstage Integration

DevLake will integrate with Backstage via:
1. **Iframe Plugin**: Embed DevLake dashboards in Backstage
2. **API Integration**: Fetch DORA metrics for service cards
3. **Entity Annotation**: Link catalog entities to DevLake projects

### Edge Case Handling

| Scenario | Behavior |
|----------|----------|
| No deployments for service | Display "N/A" instead of 0 |
| Partial data (missing incidents) | Calculate available metrics, show warnings |
| High cardinality (many services) | Use pagination and caching |
| Data source unavailable | Show last known values with staleness indicator |

## Consequences

### Positive

1. **Immediate DORA visibility**: Pre-built dashboards reduce time to value
2. **Standardized metrics**: Consistent calculation across all teams
3. **Reduced custom development**: Leverage DevLake's tested collectors
4. **Extensibility**: Plugin architecture for future data sources
5. **Community support**: Active Apache project with regular updates

### Negative

1. **Additional infrastructure**: MySQL database and DevLake services
2. **Configuration complexity**: Multiple data source configurations
3. **Storage requirements**: Historical data requires database capacity

### Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| DevLake version incompatibility | Pin to stable versions, test upgrades |
| Data collection failures | Alerting on collector health, retry logic |
| Dashboard performance | Enable caching, limit historical queries |
| Security exposure | Vault-managed credentials, network policies |

## Alternatives Considered

### 1. Custom DORA Metrics Service (ADR-012 Approach)

**Description**: Build custom Go/Python service with webhook receivers

**Rejected because**:
- Higher development and maintenance cost
- Need to implement all collectors from scratch
- No pre-built visualization

### 2. Sleuth.io (Commercial)

**Description**: SaaS DORA metrics platform

**Rejected because**:
- Commercial licensing costs
- External data residency concerns
- Vendor lock-in

### 3. Faros AI (Commercial)

**Description**: Engineering metrics platform

**Rejected because**:
- Commercial licensing
- More complex than needed
- Over-featured for core DORA requirements

### 4. Haystack (Open Source)

**Description**: Engineering analytics platform

**Rejected because**:
- Smaller community than DevLake
- Less mature DORA implementation
- Limited documentation

## Implementation Plan

### Phase 1: Core Deployment (Week 1)

- [x] Create ADR-016 for DevLake strategy
- [ ] Deploy DevLake Helm chart via ArgoCD
- [ ] Configure MySQL persistence
- [ ] Set up ingress for DevLake UI

### Phase 2: Data Source Integration (Week 2)

- [ ] Configure GitHub/Git collector
- [ ] Configure Jenkins collector
- [ ] Set up incident webhook receiver
- [ ] Create initial projects in DevLake

### Phase 3: Visualization (Week 3)

- [ ] Import DORA Grafana dashboards
- [ ] Create Backstage DevLake plugin
- [ ] Configure team-level views
- [ ] Set up alerting for metric degradation

### Phase 4: Documentation & Training (Week 4)

- [ ] Update architecture documentation
- [ ] Create DORA metrics definition guide
- [ ] Add Dojo learning module
- [ ] Create runbooks for operations

## References

- [Apache DevLake Documentation](https://devlake.apache.org/docs/Overview/Introduction)
- [DORA Metrics Definition](https://dora.dev/guides/dora-metrics-four-keys/)
- [DevLake Grafana Dashboards](https://devlake.apache.org/docs/Configuration/Dashboards/)
- [ADR-012: Metrics Monitoring and Management](ADR-012%20Metrics%20Monitoring%20and%20Management.md)
