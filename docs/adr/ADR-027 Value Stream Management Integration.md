# ADR-027: Value Stream Management Integration

## Status

**Proposed** - Pending team review and approval

**Date**: December 2025

**Decision Makers**: Platform Architecture Team, Product Leadership

**Consulted**: Development Teams, DevOps Engineers, Product Managers

**Informed**: All Engineering, Executive Leadership

-----

## Context

### Background

Based on the 2025 DORA Report findings, organizations with mature Value Stream Management (VSM) practices see significant improvements in:

- **3.5x higher organizational performance** compared to low VSM maturity
- **Better visibility** into software delivery bottlenecks
- **Data-driven decision making** for process improvements
- **Alignment** between business value and technical delivery

Currently, Fawkes collects DORA metrics (deployment frequency, lead time, change failure rate, MTTR) but lacks:

1. **End-to-end value stream visibility** - Can’t trace from idea to production
1. **Work item integration** - DORA metrics aren’t linked to business value
1. **Flow metrics** - No measurement of work in progress, cycle time by stage
1. **Bottleneck identification** - No automated detection of process constraints
1. **Value delivery measurement** - No connection between features and business outcomes

### DORA 2025 VSM Findings

The 2025 DORA Report identifies **8 Value Stream Management Capabilities**:

1. **Visualization of work** - Teams see work flowing through the value stream
1. **Work integrated with toolchains** - Tracking tools connected to CI/CD
1. **Work limited in process** - WIP limits enforced
1. **Flow metrics** - Cycle time, throughput, WIP measured
1. **Quality integrated in process** - Quality gates in the value stream
1. **Work prioritized by business value** - Value-driven backlog
1. **Customer feedback** - Fast feedback loops from production
1. **Continuous improvement** - Regular process optimization

Organizations with **high VSM maturity** (6-8 capabilities) significantly outperform those with low maturity (0-3 capabilities).

### Current Fawkes Architecture Gaps

**What We Have**:

- ✅ DORA metrics collection (4 key metrics)
- ✅ Focalboard for project management
- ✅ Backstage service catalog
- ✅ ArgoCD for deployment tracking
- ✅ Jenkins for CI/CD

**What We’re Missing**:

- ❌ Integration between Focalboard work items and DORA metrics
- ❌ Value stream visualization (idea → code → deploy → operate)
- ❌ Flow metrics (cycle time by stage, WIP, throughput)
- ❌ Bottleneck detection and alerts
- ❌ Business value tracking per feature
- ❌ Customer feedback integration
- ❌ Value stream dashboards for stakeholders

### Forces at Play

**Technical Forces**:

- Need to integrate disparate tools (Focalboard, GitHub, Jenkins, ArgoCD, Grafana)
- Require consistent work item identifiers across the toolchain
- Must handle real-time data aggregation from multiple sources
- Need to maintain low overhead (no manual data entry)

**Organizational Forces**:

- Product managers need visibility into delivery performance
- Engineering leaders need bottleneck identification
- Executives need business value delivery metrics
- Teams need actionable insights, not just dashboards

**User Experience Forces**:

- Developers shouldn’t be burdened with extra process
- Data collection should be automated
- Insights should be contextual and actionable
- Integration should be seamless with existing workflows

### Decision Drivers

1. **DORA Alignment**: 2025 DORA Report emphasizes VSM as a key differentiator
1. **Platform-as-Product**: VSM enables us to measure platform value delivery
1. **User-Centric**: Understanding flow helps us reduce developer friction
1. **Competitive Advantage**: Few open-source IDPs offer integrated VSM
1. **Data-Driven Improvement**: Can’t improve what we don’t measure

-----

## Decision

**We will implement an integrated Value Stream Management system in Fawkes** that:

1. **Connects work items** (Focalboard) with code changes (GitHub), builds (Jenkins), and deployments (ArgoCD)
1. **Automates flow metrics collection** (cycle time, WIP, throughput) across value stream stages
1. **Visualizes the end-to-end value stream** from idea to production
1. **Detects and alerts on bottlenecks** using ML-based anomaly detection
1. **Measures business value delivery** by linking work items to customer outcomes
1. **Integrates customer feedback** from production into the value stream

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                   VALUE STREAM MANAGEMENT LAYER                  │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ VSM Hub (New Component)                                    │ │
│  │ - Work item correlation engine                             │ │
│  │ - Flow metrics calculation service                         │ │
│  │ - Bottleneck detection (ML-based)                          │ │
│  │ - Business value tracking                                  │ │
│  │ - API for dashboards and integrations                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           ↓         ↓                            │
│  ┌──────────────────────────┐  ┌──────────────────────────┐    │
│  │ VSM Backstage Plugin     │  │ Grafana VSM Dashboards   │    │
│  │ - Value stream view      │  │ - Flow metrics           │    │
│  │ - Work item tracker      │  │ - Bottleneck alerts      │    │
│  │ - Team health dashboard  │  │ - Value delivery trends  │    │
│  └──────────────────────────┘  └──────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                            ↑
                            │ (Event streams & webhooks)
                            │
┌─────────────────────────────────────────────────────────────────┐
│                      DATA SOURCES (Existing)                     │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐  │
│  │ Focalboard │ │ GitHub     │ │ Jenkins    │ │ ArgoCD     │  │
│  │ (Work)     │ │ (Code)     │ │ (Build)    │ │ (Deploy)   │  │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘  │
│                                                                   │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐  │
│  │ Mattermost │ │ Prometheus │ │ OpenSearch │ │ Customer   │  │
│  │ (Collab)   │ │ (Metrics)  │ │ (Logs)     │ │ Feedback   │  │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Core Components

#### 1. VSM Hub (New Service)

**Technology**: Go microservice (performance, concurrency)

**Responsibilities**:

- Receive webhooks/events from all tools
- Correlate work items across tools using identifiers
- Calculate flow metrics in real-time
- Detect bottlenecks using statistical analysis
- Store value stream data (PostgreSQL)
- Expose REST/GraphQL API

**Data Model**:

```go
type WorkItem struct {
    ID              string
    FocalboardID    string
    Type            string // feature, bug, story
    BusinessValue   int    // 1-100 scale
    Stage           string // backlog, dev, review, test, deploy, done
    CreatedAt       time.Time
    UpdatedAt       time.Time
}

type FlowEvent struct {
    WorkItemID      string
    EventType       string // stage_enter, stage_exit
    Stage           string
    Timestamp       time.Time
    Source          string // focalboard, github, jenkins, argocd
    Metadata        map[string]interface{}
}

type FlowMetrics struct {
    WorkItemID      string
    CycleTime       duration // total time from start to done
    LeadTime        duration // time from commit to deploy
    StageTimings    map[string]duration
    WaitTime        duration
    ActiveTime      duration
    BlockedTime     duration
}
```

#### 2. Work Item Correlation Strategy

**Convention**: All tools must reference work items using consistent identifiers

**GitHub Commits**:

```bash
git commit -m "[FOC-123] Add user authentication feature"
```

**Branch Naming**:

```bash
git checkout -b feature/FOC-123-user-auth
```

**Pull Request Description**:

```markdown
## Related Work Items
- Focalboard: FOC-123

## Changes
...
```

**Automation**:

- Pre-commit hooks validate work item ID format
- GitHub Actions comment on PRs with Focalboard link
- VSM Hub extracts IDs from commit messages

#### 3. Value Stream Stages

**Standard Flow**:

```
1. Backlog (Focalboard)
   ↓
2. In Progress (Focalboard status change)
   ↓
3. Code Review (GitHub PR opened)
   ↓
4. Build (Jenkins triggered)
   ↓
5. Test (Automated tests)
   ↓
6. Deploy Staging (ArgoCD sync - staging)
   ↓
7. Validation (Manual/automated validation)
   ↓
8. Deploy Production (ArgoCD sync - prod)
   ↓
9. Monitoring (24-hour observation)
   ↓
10. Done (Work item closed + deployed)
```

**Customizable**: Teams can define custom stages via config

#### 4. Flow Metrics Calculated

**Cycle Time**: Time from “In Progress” to “Done”

- Total cycle time
- Per-stage cycle time
- Active time vs. wait time

**Lead Time**: Time from first commit to production deployment

- Aligns with DORA lead time metric
- Broken down by CI/CD stages

**Work in Progress (WIP)**:

- Current WIP per stage
- WIP trends over time
- WIP limit violations

**Throughput**:

- Work items completed per week
- By team, by type, by priority

**Flow Efficiency**:

```
Flow Efficiency = Active Time / (Active Time + Wait Time)
```

- Target: >40% (industry benchmark)

**Blocked Time**:

- Time work items spend blocked
- Blocking reasons (categorized)

#### 5. Bottleneck Detection Algorithm

**Approach**: Statistical anomaly detection + rule-based alerts

**Anomaly Detection**:

```python
# Simplified algorithm
for stage in value_stream:
    avg_cycle_time = historical_average(stage)
    std_dev = standard_deviation(stage)

    current_items = items_in_stage(stage)

    for item in current_items:
        if item.time_in_stage > avg_cycle_time + (2 * std_dev):
            alert(f"Item {item.id} stuck in {stage}")

    # Stage-level bottleneck
    if count(current_items) > historical_average_wip * 1.5:
        alert(f"Bottleneck detected in {stage}")
```

**Rule-Based Alerts**:

- WIP exceeds limit for 2+ days
- Cycle time >2x team average
- Flow efficiency <30% for 1 week
- Item blocked for >24 hours

#### 6. Business Value Tracking

**Value Assignment**:

- Product managers assign value (1-100) in Focalboard
- VSM Hub tracks value delivered per sprint/quarter
- Value delivery rate calculated

**Metrics**:

```
Value Delivered = Sum(completed_items.business_value)
Value Velocity = Value Delivered / Time Period
Value Efficiency = Value Delivered / Total Cycle Time
```

**Dashboard**:

- Value delivered this sprint vs. planned
- Cumulative flow diagram with value overlay
- High-value items stuck in pipeline (alerts)

#### 7. Customer Feedback Integration

**Sources**:

- Production incidents (linked to work items)
- NPS surveys (per feature)
- Feature usage analytics (Prometheus)
- Support tickets (Mattermost)

**Feedback Loop**:

```
Deploy Feature (FOC-123)
    ↓
Monitor Usage (7 days)
    ↓
Collect Feedback (NPS survey)
    ↓
Calculate Feature Success Score
    ↓
Update Work Item with outcomes
    ↓
Inform Product Roadmap
```

**Feature Success Score**:

```
Success = (Usage * NPS * Uptime) - (Incidents * Severity)
```

### Integration Points

#### Focalboard Integration

**Webhooks**:

- Work item created → VSM Hub (stage: backlog)
- Work item status changed → VSM Hub (stage transition)
- Work item assigned value → VSM Hub (business value update)

**API Calls**:

- VSM Hub queries Focalboard for work item details
- Backstage plugin displays Focalboard cards

**Enhancement**:

- Custom Focalboard field: “Work Item ID” (e.g., FOC-123)
- Displayed prominently for developer reference

#### GitHub Integration

**Webhooks**:

- Commit pushed → VSM Hub (extract work item ID from message)
- PR opened → VSM Hub (stage: code review)
- PR merged → VSM Hub (code review complete)

**Automation**:

```yaml
# .github/workflows/vsm-integration.yml
name: VSM Integration
on: [push, pull_request]
jobs:
  notify-vsm:
    runs-on: ubuntu-latest
    steps:
      - name: Extract Work Item ID
        id: work_item
        run: |
          echo "ID=$(git log -1 --pretty=%B | grep -oP 'FOC-\d+')" >> $GITHUB_OUTPUT

      - name: Notify VSM Hub
        run: |
          curl -X POST $VSM_HUB_URL/events \
            -H "Content-Type: application/json" \
            -d '{
              "work_item_id": "${{ steps.work_item.outputs.ID }}",
              "event": "commit",
              "source": "github",
              "timestamp": "'$(date -Iseconds)'"
            }'
```

#### Jenkins Integration

**Webhooks**:

- Build started → VSM Hub (stage: build)
- Build completed → VSM Hub (build success/failure)
- Tests run → VSM Hub (test results)

**Pipeline Enhancement**:

```groovy
pipeline {
    agent any
    environment {
        WORK_ITEM_ID = sh(script: "git log -1 --pretty=%B | grep -oP 'FOC-\\d+'", returnStdout: true).trim()
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
            post {
                always {
                    sh """
                        curl -X POST $VSM_HUB_URL/events \
                          -H 'Content-Type: application/json' \
                          -d '{
                            "work_item_id": "$WORK_ITEM_ID",
                            "event": "build_complete",
                            "status": "$currentBuild.result"
                          }'
                    """
                }
            }
        }
    }
}
```

#### ArgoCD Integration

**Webhooks**:

- Application synced → VSM Hub (deployment to env)
- Sync failed → VSM Hub (deployment failure)
- Health check → VSM Hub (deployment health)

**Configuration**:

```yaml
# argocd-notifications configmap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
data:
  service.webhook.vsm-hub: |
    url: http://vsm-hub.fawkes.svc.cluster.local/events
    headers:
    - name: Content-Type
      value: application/json

  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [vsm-hub-deployment-success]
```

#### Backstage Plugin (New)

**Plugin**: `@fawkes/plugin-vsm`

**Features**:

1. **Value Stream View**: Visualize work item flow
1. **Team Dashboard**: Team-level flow metrics
1. **Work Item Tracker**: See status across all tools
1. **Bottleneck Alerts**: In-context alerts for teams

**UI Mockup**:

```
┌─────────────────────────────────────────────────────────────┐
│ Service: payment-service                     Value Stream   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Work Items in Flow (Current Sprint)                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │ Backlog  │→│ In Prog  │→│ Review   │→│ Deploy   │      │
│  │    5     │ │    3     │ │    2     │ │    1     │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
│       ↓             ↓             ↓            ↓            │
│  ⚠️ WIP Limit     ✅ Healthy   🔴 Bottleneck  ✅ Healthy   │
│                                                              │
│  Flow Metrics (Last 30 Days)                                │
│  • Cycle Time: 4.2 days (target: <5 days) ✅               │
│  • Lead Time: 2.1 days (elite: <1 day) 🟡                  │
│  • Flow Efficiency: 35% (target: >40%) 🔴                   │
│  • Throughput: 12 items/week ✅                             │
│                                                              │
│  Active Work Items                                          │
│  FOC-456 [Feature] ████████░░ (80% - Code Review)          │
│  FOC-457 [Bug]     ██░░░░░░░░ (20% - In Progress)          │
│  FOC-458 [Story]   ██████████ (100% - Deploying) 🚀        │
│                                                              │
│  Alerts 🔔                                                  │
│  • FOC-450 stuck in Code Review for 3 days (avg: 1 day)    │
│  • Flow efficiency dropped below 30% - investigate          │
└─────────────────────────────────────────────────────────────┘
```

#### Grafana Dashboards (New)

**Dashboard 1: Executive Value Stream Overview**

- Value delivered (current quarter)
- Cycle time trends (6 months)
- Bottleneck heatmap (by team)
- Top blockers (categorized)

**Dashboard 2: Team Flow Metrics**

- Cumulative flow diagram
- Cycle time distribution
- WIP trends
- Throughput velocity

**Dashboard 3: Work Item Deep Dive**

- Individual work item journey
- Stage timings breakdown
- Wait time vs. active time
- Blockers and delays

**Dashboard 4: Bottleneck Analysis**

- Stage-level bottlenecks
- Historical bottleneck trends
- Bottleneck resolution time
- Impact on flow efficiency

### Data Storage Strategy

**PostgreSQL Schema**:

```sql
-- Work Items
CREATE TABLE work_items (
    id VARCHAR(50) PRIMARY KEY,
    focalboard_id VARCHAR(50) UNIQUE,
    type VARCHAR(20),
    title TEXT,
    business_value INT,
    stage VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- Flow Events
CREATE TABLE flow_events (
    id SERIAL PRIMARY KEY,
    work_item_id VARCHAR(50) REFERENCES work_items(id),
    event_type VARCHAR(50),
    stage VARCHAR(50),
    timestamp TIMESTAMP,
    source VARCHAR(50),
    metadata JSONB
);

CREATE INDEX idx_flow_events_work_item ON flow_events(work_item_id);
CREATE INDEX idx_flow_events_timestamp ON flow_events(timestamp);

-- Flow Metrics (Calculated)
CREATE TABLE flow_metrics (
    work_item_id VARCHAR(50) PRIMARY KEY REFERENCES work_items(id),
    cycle_time_hours DECIMAL,
    lead_time_hours DECIMAL,
    active_time_hours DECIMAL,
    wait_time_hours DECIMAL,
    blocked_time_hours DECIMAL,
    flow_efficiency DECIMAL,
    stage_timings JSONB,
    calculated_at TIMESTAMP
);

-- Bottlenecks
CREATE TABLE bottlenecks (
    id SERIAL PRIMARY KEY,
    stage VARCHAR(50),
    detected_at TIMESTAMP,
    resolved_at TIMESTAMP,
    severity VARCHAR(20), -- low, medium, high, critical
    work_items_affected TEXT[],
    root_cause TEXT,
    resolution TEXT
);
```

**Time-Series Data** (Prometheus):

```
# Gauge: Current WIP by stage
vsm_wip_current{stage="code_review", team="payments"} 5

# Histogram: Cycle time distribution
vsm_cycle_time_seconds{stage="build", team="payments"} 3600

# Counter: Work items completed
vsm_items_completed_total{type="feature", team="payments"} 45

# Gauge: Flow efficiency
vsm_flow_efficiency{team="payments"} 0.38
```

-----

## Consequences

### Positive

1. **End-to-End Visibility**: Teams and leaders see work flow from idea to production
- Reduces “where is my feature?” questions
- Identifies bottlenecks quickly
- Enables data-driven process improvements
1. **Automated Data Collection**: No manual tracking required
- Developers continue existing workflows
- Metrics calculated automatically
- Real-time updates
1. **Actionable Insights**: Not just dashboards, but alerts and recommendations
- Bottleneck alerts notify teams immediately
- Trend analysis predicts future issues
- Benchmarking against industry standards
1. **Business Value Connection**: Links engineering work to business outcomes
- Product managers see value delivery rates
- Executives understand ROI of platform improvements
- Prioritization driven by value, not just urgency
1. **Competitive Differentiation**: Few open-source IDPs offer integrated VSM
- Attracts organizations serious about flow metrics
- Aligns with 2025 DORA findings
- Positions Fawkes as cutting-edge
1. **Platform-as-Product Enablement**: Measures platform’s own value delivery
- Internal customers can see platform team throughput
- Continuous improvement becomes data-driven
- Justifies platform investment with metrics

### Negative

1. **Implementation Complexity**: Significant development effort required
- New service (VSM Hub) to build and maintain
- Multiple integrations to implement
- Data model to design and evolve
- **Mitigation**: Phased rollout, start with 2-3 integrations
1. **Convention Enforcement**: Requires consistent work item ID usage
- Teams must adopt naming conventions
- Pre-commit hooks needed
- Change management required
- **Mitigation**: Automation (Git hooks), clear documentation, training
1. **Data Quality Dependency**: Metrics only as good as input data
- Missed commit messages → broken correlation
- Inconsistent Focalboard updates → wrong stage timings
- Webhooks failures → missing events
- **Mitigation**: Data quality monitoring, event replay, manual correction UI
1. **Performance Concerns**: Real-time correlation at scale
- High event volume from CI/CD (100s per hour)
- Complex joins across data sources
- Dashboard query performance
- **Mitigation**: Event streaming (Kafka), caching (Redis), query optimization
1. **Privacy Considerations**: Individual developer performance visibility
- Metrics could be misused for surveillance
- Team metrics, not individual metrics
- Requires careful communication
- **Mitigation**: Team-level aggregation only, explicit privacy policy
1. **Maintenance Overhead**: Another system to operate
- VSM Hub needs monitoring, scaling, updates
- Additional PostgreSQL database
- Integration maintenance as tools evolve
- **Mitigation**: Observability from day one, runbooks, automation

### Neutral

1. **Learning Curve**: Teams need to understand VSM concepts
- Training required on flow metrics
- Dojo module needed (“Value Stream Management”)
- **Action**: Include in Yellow Belt curriculum
1. **Cultural Change**: Shifts focus from velocity to flow
- Story points de-emphasized
- Flow efficiency becomes key metric
- **Action**: Leadership buy-in, communicate why
1. **Tool Dependencies**: Relies on existing tool quality
- Focalboard API stability
- GitHub webhook reliability
- Jenkins plugin ecosystem
- **Action**: Contribute improvements upstream

-----

## Alternatives Considered

### Alternative 1: Use Existing Commercial VSM Tools

**Examples**: Tasktop Hub, ConnectAll, Plutora

**Pros**:

- ✅ Mature, battle-tested solutions
- ✅ Pre-built integrations with popular tools
- ✅ Advanced analytics and ML features
- ✅ Enterprise support available

**Cons**:

- ❌ Expensive ($50-200 per user/month)
- ❌ SaaS-only (data leaves infrastructure)
- ❌ Not open source (vendor lock-in)
- ❌ Limited customization
- ❌ Doesn’t align with Fawkes’ self-hosted ethos

**Why Rejected**:
Fawkes is an open-source, self-hosted platform. Introducing a commercial SaaS tool contradicts our core values and creates vendor dependency. Our users expect integrated, customizable solutions.

### Alternative 2: Basic Dashboards with Manual Correlation

**Approach**: Build Grafana dashboards with manual work item entry

**Pros**:

- ✅ Simple to implement (minimal code)
- ✅ Leverages existing Grafana infrastructure
- ✅ No new services to maintain

**Cons**:

- ❌ Manual data entry is error-prone
- ❌ No automated correlation between tools
- ❌ No real-time updates
- ❌ Poor developer experience
- ❌ Doesn’t scale beyond 1-2 teams

**Why Rejected**:
Manual processes don’t scale and create developer friction. We need automated, seamless integration that respects developer time.

### Alternative 3: Extend Existing Tools (e.g., Backstage Plugin Only)

**Approach**: Build VSM as a Backstage plugin without dedicated service

**Pros**:

- ✅ Fewer components to maintain
- ✅ Integrated into existing portal
- ✅ Simpler architecture

**Cons**:

- ❌ Backstage plugin can’t process real-time events reliably
- ❌ No central data store for historical analysis
- ❌ Limited to Backstage users (not available in Grafana)
- ❌ Poor separation of concerns

**Why Rejected**:
VSM requires real-time event processing, data aggregation, and ML-based analysis. A Backstage plugin alone can’t provide the required functionality. We need a dedicated service with a proper data layer.

### Alternative 4: Third-Party Open Source VSM Tools

**Examples**: Haystack, Faros AI, Swarmia (partially open source)

**Pros**:

- ✅ Open source (some)
- ✅ Active communities
- ✅ Pre-built integrations

**Cons**:

- ❌ May not integrate with our specific stack (Focalboard)
- ❌ Require additional deployment complexity
- ❌ May not align with our UX principles
- ❌ Not designed for learning (dojo integration)

**Why Partially Considered**:
We could use these as *inspiration* or even *components* (e.g., Faros’s data model), but not as drop-in replacements. We’ll evaluate their architectures and adopt patterns that fit Fawkes.

### Alternative 5: Delayed Implementation (Post-MVP)

**Approach**: Focus on core platform features first, add VSM later

**Pros**:

- ✅ Faster MVP delivery
- ✅ Less complexity initially
- ✅ Can learn from user feedback first

**Cons**:

- ❌ Misses opportunity to differentiate at launch
- ❌ Harder to retrofit integrations later
- ❌ 2025 DORA emphasizes VSM importance now
- ❌ Competitors may add VSM first

**Why Rejected**:
The 2025 DORA Report makes clear that VSM is a key differentiator for high-performing organizations. Delaying this means Fawkes won’t be competitive with modern expectations. However, we will use a **phased approach** (see Implementation Plan).

-----

## Implementation Plan

### Phase 1: Foundation (Weeks 1-4) - **MVP Scope**

**Goal**: Basic correlation and cycle time measurement

**Deliverables**:

1. VSM Hub service (Go)
- Webhook receiver
- Work item correlation engine
- Basic API (REST)
- PostgreSQL schema
1. Integrations (simplified):
- Focalboard webhook → VSM Hub
- GitHub webhook → VSM Hub
- Jenkins webhook → VSM Hub
1. Metrics:
- Cycle time (end-to-end)
- Lead time (commit → deploy)
- WIP by stage
1. Visualization:
- Simple Grafana dashboard (flow metrics)
- Backstage plugin (minimal - work item list)

**Success Criteria**:

- ✅ Can correlate work items across Focalboard, GitHub, Jenkins
- ✅ Cycle time calculated for completed work items
- ✅ Dashboard shows basic flow metrics

### Phase 2: Intelligence (Weeks 5-8) - **Post-MVP**

**Goal**: Bottleneck detection and alerts

**Deliverables**:

1. Bottleneck detection algorithm
- Statistical anomaly detection
- Rule-based alerts
1. Enhanced metrics:
- Flow efficiency
- Stage-level cycle times
- Wait time vs. active time
1. Alerting:
- Mattermost notifications for bottlenecks
- Email alerts for leadership
- In-app alerts (Backstage)
1. Enhanced Backstage plugin:
- Value stream visualization
- Bottleneck alerts
- Team health dashboard

**Success Criteria**:

- ✅ Bottlenecks detected within 4 hours of occurrence
- ✅ Alerts sent to appropriate channels
- ✅ Flow efficiency calculated and displayed

### Phase 3: Business Value (Weeks 9-12) - **Post-MVP**

**Goal**: Link work items to business outcomes

**Deliverables**:

1. Business value tracking
- Value assignment in Focalboard
- Value delivery metrics
- Value velocity trends
1. Customer feedback integration
- NPS per feature
- Feature usage tracking
- Incident correlation
1. Advanced dashboards:
- Executive value stream overview
- Value delivery trends
- Feature success scores
1. Dojo module: “Value Stream Management”
- VSM concepts and metrics
- Hands-on lab: Optimize a value stream
- Certification: “Fawkes VSM Practitioner”

**Success Criteria**:

- ✅ Business value tracked for
