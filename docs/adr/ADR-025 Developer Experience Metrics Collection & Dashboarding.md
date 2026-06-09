# ADR-025: Developer Experience Metrics Collection & Dashboarding (EXPANDED)

## Status

Accepted

## Context

ADR-014 established the SPACE framework for measuring developer experience across five dimensions:

- **S**atisfaction
- **P**erformance
- **A**ctivity
- **C**ommunication & Collaboration
- **E**fficiency & Flow

ADR-015 established qualitative feedback collection (interviews, surveys, feedback widget).

Now we need the **visualization layer** that brings quantitative and qualitative data together into actionable insights. The 2025 DORA Report emphasizes that metrics alone don’t drive change—_how you visualize and act on metrics_ determines success.

**The Challenge**:

- We’ll be collecting 100+ individual metrics
- Data comes from 15+ different sources
- Multiple audiences need different views (developers, platform team, executives)
- Metrics must drive action, not just observation
- Need to correlate metrics (e.g., does NPS correlate with lead time?)
- Must avoid metric gaming and vanity metrics

**Industry Context**:
Most organizations fail at DevEx dashboards by:

1. **Too many metrics**: Dashboards with 50+ charts are overwhelming
1. **Wrong audience**: Executive dashboards shown to developers (or vice versa)
1. **No action**: Beautiful dashboards that nobody acts on
1. **Lagging indicators only**: By the time you see the problem, it’s too late
1. **Missing context**: Charts without explaining _why_ it matters

We need dashboards that are:

- **Actionable**: Every metric should prompt a question or action
- **Contextual**: Show why metrics matter and how to improve them
- **Predictive**: Leading indicators that warn of future problems
- **Accessible**: Right level of detail for each audience
- **Living**: Updated in real-time, not weekly reports

## Decision

We will build a **three-tier DevEx Dashboard system** in Grafana that serves three distinct audiences with progressive levels of detail:

1. **Executive Health Dashboard** (10,000-foot view)
1. **Platform Team Operations Dashboard** (1,000-foot view)
1. **Team-Level Deep Dive Dashboard** (ground-level view)

### Overall Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  DATA COLLECTION LAYER                                      │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Surveys      │  │ System       │  │ User         │     │
│  │ (Qualtrics)  │  │ Metrics      │  │ Behavior     │     │
│  │              │  │ (Prometheus) │  │ (Analytics)  │     │
│  │ - NPS        │  │ - DORA       │  │ - Backstage  │     │
│  │ - Pulse      │  │ - Build time │  │ - GitHub     │     │
│  │ - Feedback   │  │ - Uptime     │  │ - Copilot    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  DATA WAREHOUSE (PostgreSQL + Prometheus)                   │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Aggregated Metrics Tables                              │ │
│  │ - devex_satisfaction (NPS, ratings, sentiment)         │ │
│  │ - devex_performance (DORA, build, deploy metrics)      │ │
│  │ - devex_activity (commits, PRs, reviews, AI usage)     │ │
│  │ - devex_collaboration (review time, comments, etc.)    │ │
│  │ - devex_efficiency (flow state, friction, toil)        │ │
│  │ - devex_correlations (pre-computed relationships)      │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ ETL Pipeline (Apache Airflow)                          │ │
│  │ - Hourly: Sync GitHub, Backstage, Prometheus          │ │
│  │ - Daily: Compute derived metrics and correlations     │ │
│  │ - Weekly: Generate trend analysis and forecasts       │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  VISUALIZATION LAYER (Grafana)                              │
│                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐│
│  │ Executive       │  │ Platform Team   │  │ Team         ││
│  │ Health          │  │ Operations      │  │ Deep Dive    ││
│  │ Dashboard       │  │ Dashboard       │  │ Dashboard    ││
│  └─────────────────┘  └─────────────────┘  └──────────────┘│
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Alerting & Notifications                               │ │
│  │ - Slack: Real-time alerts for platform team           │ │
│  │ - Email: Weekly digest for executives                 │ │
│  │ - Mattermost: Monthly "State of DevEx" for all        │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Dashboard 1: Executive Health Dashboard

**Audience**: CTO, VPs, Engineering Directors
**Update Frequency**: Real-time (but typically viewed weekly)
**Purpose**: High-level health check and business value demonstration

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Fawkes Developer Experience Health - Q4 2024                        │
│  Updated: 2 minutes ago                        [Export] [Share]      │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────┐  ┌─────────────────────┐                   │
│  │  Overall NPS        │  │  Platform ROI       │                   │
│  │                     │  │                     │                   │
│  │      62             │  │    $2.1M/year       │                   │
│  │   ↑ +4 from Q3      │  │  (productivity +    │                   │
│  │                     │  │   reduced incidents)│                   │
│  │  Target: 65         │  │                     │                   │
│  │  Industry: 58       │  │  Investment: $480k  │                   │
│  └─────────────────────┘  └─────────────────────┘                   │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  SPACE Framework Health (vs. Target)                          │  │
│  │                                                                │  │
│  │  Satisfaction      ████████████░░░░  4.2/5  Target: 4.5       │  │
│  │  Performance       ███████████████░  4.5/5  ✓ Exceeds Target  │  │
│  │  Activity          ██████████████░░  4.3/5  Target: 4.5       │  │
│  │  Communication     █████████████░░░  4.1/5  Target: 4.5       │  │
│  │  Efficiency        ████████████░░░░  4.0/5  ⚠ Below Target    │  │
│  │                                                                │  │
│  │  Overall Score: 4.2/5 (up from 3.8 last quarter)              │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  DORA Metrics - Last 30 Days                                 │    │
│  │                                                               │    │
│  │  Deployment Frequency:  2.3/day  ↑ +15%  Elite Performer    │    │
│  │  Lead Time:            18 hours  ↓ -22%  Elite Performer    │    │
│  │  Change Failure Rate:       12%  ↓ -3%   Elite Performer    │    │
│  │  MTTR:                 47 mins   ↓ -18%  Elite Performer    │    │
│  │                                                               │    │
│  │  ✅ Fawkes team is now in "Elite Performer" category!        │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌───────────────────────────────────────┐  ┌──────────────────────┐│
│  │  🚨 Attention Required                │  │  🎉 Wins This Month  ││
│  │                                        │  │                      ││
│  │  ⚠️  Efficiency score dropped from    │  │  ✅ NPS increased +4 ││
│  │     4.3 → 4.0 (friction increasing)   │  │  ✅ Lead time -22%   ││
│  │     Action: Review friction reports   │  │  ✅ AI adoption 85%  ││
│  │                                        │  │  ✅ 3 teams achieved ││
│  │  ⚠️  Build times up 20% past 2 weeks  │  │     elite status     ││
│  │     Action: Jenkins capacity review   │  │                      ││
│  └───────────────────────────────────────┘  └──────────────────────┘│
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  Quarterly Trend (NPS & DORA Deployment Frequency)          │    │
│  │                                                               │    │
│  │  70│     NPS                                                 │    │
│  │  65│      ╱────────────                                      │    │
│  │  60│  ───╱                                                   │    │
│  │  55│ ╱                                                       │    │
│  │  50│╱                                                        │    │
│  │    └─────────────────────────────────────                   │    │
│  │     Q1    Q2    Q3    Q4                                     │    │
│  │                                                               │    │
│  │   3│     Deploy/Day                                          │    │
│  │   2│              ╱────────                                  │    │
│  │   1│      ───────╱                                           │    │
│  │    └─────────────────────────────────                        │    │
│  │     Q1    Q2    Q3    Q4                                     │    │
│  └─────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

### Key Features

### 1. Single Number Health Indicators

- NPS (leading indicator of platform health)
- Platform ROI (business value in dollars)
- Overall SPACE score (composite health metric)

### 2. Traffic Light System

- 🟢 Green: Exceeds target
- 🟡 Yellow: Meets target
- 🔴 Red: Below target
- All thresholds configurable

### 3. Automatic Insights

- “Attention Required” panel auto-generated from anomaly detection
- “Wins This Month” celebrates progress
- No need to manually interpret charts

### 4. Trend Visibility

- Quarterly trends show trajectory
- Compare current quarter to previous
- Project forward based on current trend

### 5. Benchmarking

- Compare to industry standards (DORA research)
- Show peer company comparisons (if available)
- Highlight “elite performer” achievements

---

## Dashboard 2: Platform Team Operations Dashboard

**Audience**: Platform engineers, SREs, DevOps team
**Update Frequency**: Real-time
**Purpose**: Day-to-day operations, troubleshooting, experimentation tracking

### Layout (5 pages, tabbed)

#### Page 1: Real-Time Health

```
┌──────────────────────────────────────────────────────────────────────┐
│  Platform Operations - Real-Time Health                              │
│  [Health] [SPACE Deep Dive] [Experiments] [Feedback] [Correlations]  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  🚨 ACTIVE ALERTS (2)                                                 │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ 🔴 CRITICAL: Jenkins build queue depth = 28 (threshold: 20)     │ │
│  │    Triggered: 15 minutes ago                                    │ │
│  │    Action: Scale up Jenkins agents OR investigate stuck builds  │ │
│  │    [View Details] [Acknowledge] [Create Incident]               │ │
│  │                                                                  │ │
│  │ 🟡 WARNING: ArgoCD sync failures 12% (threshold: 10%)           │ │
│  │    Triggered: 2 hours ago                                       │ │
│  │    Affected: payment-service, auth-service (3 more)             │ │
│  │    [View Details] [Acknowledge]                                 │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  PLATFORM SERVICES STATUS                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ Backstage    │  │ Jenkins      │  │ ArgoCD       │              │
│  │ ✅ Healthy   │  │ ⚠️  Degraded │  │ ⚠️  Degraded │              │
│  │ 99.8% uptime │  │ Queue: 28    │  │ Sync: 88%    │              │
│  │ Latency: 210ms│ │ Agents: 8/15 │  │ Apps: 47/53  │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│                                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ Harbor       │  │ Mattermost   │  │ Prometheus   │              │
│  │ ✅ Healthy   │  │ ✅ Healthy   │  │ ✅ Healthy   │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│                                                                       │
│  CURRENT CAPACITY                                                     │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ Kubernetes Cluster                                              │ │
│  │ CPU:    [████████████░░░░░░] 65%  (target: <80%)               │ │
│  │ Memory: [███████████████░░░] 78%  (⚠️ approaching limit)        │ │
│  │ Pods:   247/300                                                 │ │
│  │                                                                 │ │
│  │ Jenkins Agents                                                  │ │
│  │ Active: [████████████████░░░] 8/15  (⚠️ queue building)        │ │
│  │ Queue:  28 jobs (avg wait: 12 minutes)                         │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  RECENT ACTIVITY (Last Hour)                                          │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ 🚀 Deployments: 12 (11 success, 1 failed)                       │ │
│  │ 🔨 Builds: 47 (43 success, 3 failed, 1 timeout)                 │ │
│  │ 👤 Active Users: 68 developers using platform                   │ │
│  │ 💬 Feedback: 3 new submissions (2 friction, 1 praise)           │ │
│  │ 🤖 AI Usage: Copilot active for 52 developers                   │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

#### Page 2: SPACE Deep Dive

```
┌──────────────────────────────────────────────────────────────────────┐
│  SPACE Framework Deep Dive - Last 30 Days                            │
│  [Health] [SPACE Deep Dive] [Experiments] [Feedback] [Correlations]  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  📊 SATISFACTION                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ NPS Score: 62 (↑ +4 from last month)                            │ │
│  │                                                                  │ │
│  │  70│                              Target: 65                    │ │
│  │  60│     ●─────●────────●────────────────●                      │ │
│  │  50│  ●─╯                                                       │ │
│  │  40│                                                            │ │
│  │     └────────────────────────────────────                       │ │
│  │      Oct   Nov   Dec   Jan   Feb                                │ │
│  │                                                                  │ │
│  │  Breakdown:                                                     │ │
│  │  Promoters (9-10): 45%  ███████████                            │ │
│  │  Passives (7-8):   38%  ████████                               │ │
│  │  Detractors (0-6): 17%  ████                                   │ │
│  │                                                                  │ │
│  │  Top Drivers of Satisfaction:                                  │ │
│  │  ✅ Fast deployments (mentioned by 23 developers)               │ │
│  │  ✅ Good documentation (18 mentions)                            │ │
│  │  ✅ AI tools helpful (15 mentions)                              │ │
│  │                                                                  │ │
│  │  Top Drivers of Dissatisfaction:                               │ │
│  │  ❌ Jenkins slow (18 mentions)                                  │ │
│  │  ❌ Backstage search poor (12 mentions)                         │ │
│  │  ❌ Too many tools (9 mentions)                                 │ │
│  │                                                                  │ │
│  │  [View Detailed Feedback] [View NPS Comments]                  │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  📊 PERFORMANCE (DORA Metrics)                                        │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  Deployment Frequency                Lead Time for Changes      │ │
│  │   3.0│              Target: 2.0/day    30│                     │ │
│  │   2.5│        ●────────●               25│                     │ │
│  │   2.0│    ●──╯                         20│         ●           │ │
│  │   1.5│  ●╯                              15│    ●────╯          │ │
│  │   1.0│                                  10│ ●──╯               │ │
│  │      └────────────────                   └────────────          │ │
│  │       Week 1-4                             Week 1-4             │ │
│  │                                                                  │ │
│  │  Change Failure Rate         MTTR (Mean Time to Recovery)      │ │
│  │   20%│                           120│                          │ │
│  │   15%│  Target: <15%               90│                          │ │
│  │   10%│        ●─────●               60│    ●─────●             │ │
│  │    5%│    ●──╯                      30│  ●─╯                   │ │
│  │    0%│                                0│                         │ │
│  │      └────────────────                 └────────────            │ │
│  │       Week 1-4                          Week 1-4                │ │
│  │                                                                  │ │
│  │  Performance Category: 🏆 ELITE PERFORMER                       │ │
│  │  (All 4 metrics in elite range)                                │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  📊 ACTIVITY                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  Developer Activity Metrics                                     │ │
│  │                                                                  │ │
│  │  Average per Developer (last 7 days):                          │ │
│  │  • Commits: 12.3 (target: 10+)           ✅                     │ │
│  │  • PRs created: 3.1 (target: 2+)         ✅                     │ │
│  │  • PRs reviewed: 4.7 (target: 3+)        ✅                     │ │
│  │  • Documentation edits: 0.8              ⚠️  (target: 1+)      │ │
│  │  • Dojo progress: 2.1 modules/month      ✅                     │ │
│  │                                                                  │ │
│  │  Platform Adoption:                                             │ │
│  │  • Backstage MAU: 94/100 developers (94%) ✅                    │ │
│  │  • AI tools: 85/100 developers (85%)      ✅                    │ │
│  │  • Dojo: 62/100 enrolled (62%)            ⚠️  (target: 70%)    │ │
│  │                                                                  │ │
│  │  [View Team Breakdown] [View Individual Trends]                │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  📊 COMMUNICATION & COLLABORATION                                     │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  Code Review Metrics                                            │ │
│  │  • Time to first review: 8 hrs (target: <12)  ✅               │ │
│  │  • Comments per PR: 3.2 (target: >2)           ✅               │ │
│  │  • Approval rate: 92%                          ✅               │ │
│  │  • Constructive tone: 96%                      ✅               │ │
│  │                                                                  │ │
│  │  Knowledge Sharing:                                             │ │
│  │  • Wiki edits: 47 this month                   ✅               │ │
│  │  • TechDocs updates: 23                        ✅               │ │
│  │  • #help channel responses: 156                ✅               │ │
│  │  • Pair programming sessions: 12               ⚠️  (Low)        │ │
│  │                                                                  │ │
│  │  Cross-Team Collaboration:                                      │ │
│  │  • Cross-team PRs: 18% of all PRs              ✅               │ │
│  │  • Shared library usage: 67%                   ✅               │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  📊 EFFICIENCY & FLOW                                                 │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  Flow State (self-reported weekly pulse):                      │ │
│  │  • Achieved flow 3+ days/week: 68%            ✅  (target: 60%) │ │
│  │  • Never achieved flow: 8%                     ✅  (target: <10%)│ │
│  │                                                                  │ │
│  │  Valuable Work Time:                                            │ │
│  │  • Average % on valuable work: 62%            ✅  (target: 60%) │ │
│  │  • Trend: ↑ +5% from last month                                │ │
│  │                                                                  │ │
│  │  Friction Incidents (last 30 days):                            │ │
│  │  • Total: 34 (down from 47)                   ✅  Improving!    │ │
│  │  • By category:                                                 │ │
│  │    - Jenkins slow: 12 reports                                   │ │
│  │    - Docs unclear: 8 reports                                    │ │
│  │    - Access issues: 7 reports                                   │ │
│  │    - Other: 7 reports                                           │ │
│  │                                                                  │ │
│  │  Cognitive Load (1-5 scale, 5=overwhelmed):                    │ │
│  │  • Average: 3.2                                ✅  (target: <3.5)│ │
│  │  • High load (4-5): 23% of developers          ⚠️  Monitor      │ │
│  │                                                                  │ │
│  │  [View Friction Details] [View High Load Individuals]          │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

#### Page 3: Experiments Tracking

```
┌──────────────────────────────────────────────────────────────────────┐
│  Platform Experiments & A/B Tests                                    │
│  [Health] [SPACE Deep Dive] [Experiments] [Feedback] [Correlations]  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ACTIVE EXPERIMENTS (3)                                               │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ Experiment #12: AI-Powered PR Review Bot                        │ │
│  │ Started: Dec 1, 2024  |  Status: ✅ In Progress  |  Cohort: 15% │ │
│  │                                                                  │ │
│  │ Hypothesis:                                                     │ │
│  │ AI-assisted code review will reduce time-to-first-review by    │ │
│  │ 30% and increase code quality scores by 10%.                   │ │
│  │                                                                  │ │
│  │ Current Results (after 2 weeks):                                │ │
│  │                                                                  │ │
│  │          Control   Treatment   Difference   Sig?                │ │
│  │ TTFR     12 hrs    8 hrs      -33%         ✅ Yes (p<0.01)      │ │
│  │ Quality  7.2/10    7.8/10     +8%          ⚠️  Trending         │ │
│  │ Sat.     4.1/5     4.4/5      +7%          ✅ Yes (p<0.05)      │ │
│  │                                                                  │ │
│  │ Qualitative Feedback (5 interviews):                           │ │
│  │ ✅ "Catches issues I would miss" (4 mentions)                   │ │
│  │ ✅ "Faster reviews, less waiting" (3 mentions)                  │ │
│  │ ⚠️  "Sometimes suggests wrong fixes" (2 mentions)               │ │
│  │                                                                  │ │
│  │ Recommendation: ✅ ROLLOUT TO ALL                                │ │
│  │ • TTFR significantly improved                                   │ │
│  │ • Satisfaction significantly improved                           │ │
│  │ • Code quality trending positive (2 more weeks to confirm)     │ │
│  │                                                                  │ │
│  │ [View Detailed Analysis] [Rollout Plan] [Cancel Experiment]    │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ Experiment #13: Self-Service Secrets Rotation                  │ │
│  │ Started: Dec 10, 2024  |  Status: ⚠️  Monitoring  |  Cohort: 20%│ │
│  │                                                                  │ │
│  │ Hypothesis:                                                     │ │
│  │ Self-service secrets rotation will reduce security tickets by  │ │
│  │
```
