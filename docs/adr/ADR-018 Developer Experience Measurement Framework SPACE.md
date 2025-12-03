# ADR-018: Developer Experience Measurement Framework (SPACE)

## Status

Accepted

## Context

The 2025 DORA Report identifies **user-centric focus** as the single most critical capability for successful AI adoption and high-performing teams. The research found with high certainty that:

> “When teams adopt a user-centric focus, the positive influence of AI on their performance is amplified. Conversely, in the absence of a user-centric focus, AI adoption can have a negative impact on team performance.”

For Fawkes to succeed as an Internal Delivery Platform, we must treat developers as our users and continuously measure, understand, and improve their experience. Without systematic measurement of developer experience (DevEx), we risk building features that don’t solve real problems, implementing AI tools that create friction rather than value, and making platform decisions based on assumptions rather than data.

**Current State**:

- ❌ No systematic measurement of developer satisfaction
- ❌ No tracking of cognitive load or friction points
- ❌ No understanding of time spent on valuable vs. toil work
- ❌ No feedback loops from developers to platform team
- ❌ Platform decisions made on assumptions, not validated needs
- ❌ No baseline metrics to measure improvement over time

**The Problem**:
Organizations often measure *outputs* (deployments, lines of code, tickets closed) but fail to measure the *experience* of the people doing the work. This leads to:

- Productivity theater (looking busy without delivering value)
- Burnout from measuring activity instead of outcomes
- Tools and processes that optimize metrics but harm humans
- Disconnect between platform team goals and developer needs

**Industry Context**:
The SPACE framework, developed by researchers at GitHub, Microsoft, and University of Victoria, provides a holistic approach to measuring developer productivity and experience across five dimensions:

1. **S**atisfaction: How fulfilled developers feel
1. **P**erformance: System and process outcomes
1. **A**ctivity: Developer actions and outputs
1. **C**ommunication & Collaboration: Team interaction quality
1. **E**fficiency & Flow: Ability to complete work with minimal interruption

This framework has been validated in industry and aligns with DORA’s research on high-performing teams.

## Decision

We will adopt the **SPACE framework** as our comprehensive Developer Experience measurement strategy for the Fawkes platform. This framework will guide what we measure, how we collect data, and how we act on insights to continuously improve the platform.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Developer Experience Measurement System                    │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ SATISFACTION (Self-Reported)                           │ │
│  │ - NPS surveys (quarterly)                              │ │
│  │ - Platform satisfaction ratings (5-point scale)        │ │
│  │ - Recommendation likelihood                            │ │
│  │ - Well-being assessments                               │ │
│  │ - Job satisfaction                                     │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ PERFORMANCE (System Metrics)                           │ │
│  │ - DORA 4 keys (deployment freq, lead time, CFR, MTTR) │ │
│  │ - Build success rate                                   │ │
│  │ - Test coverage                                        │ │
│  │ - Code review turnaround time                          │ │
│  │ - Incident response time                               │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ ACTIVITY (Behavioral Metrics)                          │ │
│  │ - Commits per developer                                │ │
│  │ - Pull requests opened/merged                          │ │
│  │ - Code review participation                            │ │
│  │ - Documentation contributions                          │ │
│  │ - Platform feature usage                               │ │
│  │ - AI tool adoption rates                               │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ COMMUNICATION & COLLABORATION (Interaction Quality)    │ │
│  │ - Mattermost engagement metrics                        │ │
│  │ - Code review quality (comment depth, resolution time) │ │
│  │ - Documentation clarity ratings                        │ │
│  │ - Cross-team collaboration frequency                   │ │
│  │ - Knowledge sharing (wiki edits, blog posts)          │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ EFFICIENCY & FLOW (Experience Quality)                 │ │
│  │ - Time spent in flow state (self-reported)            │ │
│  │ - Cognitive load assessments                           │ │
│  │ - Context switching frequency                          │ │
│  │ - Percentage of time on valuable work                 │ │
│  │ - Friction incident logging                            │ │
│  │ - Interruption tracking                                │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ DevEx Dashboard (Grafana)                              │ │
│  │ - Real-time metrics visualization                      │ │
│  │ - Historical trend analysis                            │ │
│  │ - Team-level drill-downs                               │ │
│  │ - Alert on degrading metrics                           │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Implementation: Five SPACE Dimensions

#### 1. SATISFACTION (How Happy Are Developers?)

**What We’ll Measure**:

- **Net Promoter Score (NPS)**: “How likely are you to recommend Fawkes to a colleague?” (0-10 scale)
- **Platform Satisfaction**: “How satisfied are you with the Fawkes platform?” (1-5 scale)
- **Feature Satisfaction**: Rate specific features (Backstage, CI/CD, GitOps, etc.)
- **Well-being**: “I feel burned out from work” (strongly disagree to strongly agree)
- **Job Satisfaction**: “I find my work meaningful and fulfilling”

**Collection Methods**:

- Quarterly NPS surveys (5 minutes)
- Post-interaction micro-surveys (1 question after major platform actions)
- Annual comprehensive DevEx survey (15 minutes)
- In-platform feedback widget (always available)

**Target Metrics**:

- NPS >50 (good), >70 (excellent)
- Platform satisfaction >4.0/5.0
- <20% reporting burnout symptoms

**Example Survey Question**:

```
On a scale of 0-10, how likely are you to recommend 
the Fawkes platform to a colleague?

0 = Not at all likely
10 = Extremely likely

[0] [1] [2] [3] [4] [5] [6] [7] [8] [9] [10]

Follow-up: What's the primary reason for your score?
[Text box]
```

#### 2. PERFORMANCE (How Well Do Systems Work?)

**What We’ll Measure**:

- **DORA Metrics**: Deployment frequency, lead time, change failure rate, MTTR
- **Build Metrics**: Build success rate, build duration (P50, P95)
- **Quality Metrics**: Test coverage, security scan pass rate, code quality scores
- **Reliability Metrics**: Service uptime, incident count, MTTR
- **Time-to-Value**: Hours from onboarding to first deployment

**Collection Methods**:

- Automated telemetry from Jenkins, ArgoCD, GitHub
- Prometheus metrics collection
- Grafana dashboards with historical trends
- Automated alerting on threshold breaches

**Target Metrics**:

- Deployment frequency: >1/day
- Lead time for changes: <24 hours
- Change failure rate: <15%
- MTTR: <1 hour
- Build success rate: >95%
- Time to first deployment: <4 hours

**Example Dashboard Panel**:

```
┌─────────────────────────────────────────┐
│ DORA Metrics - Last 30 Days             │
│                                         │
│ Deployment Frequency: 2.3/day ↑ +15%  │
│ Lead Time: 18 hours        ↓ -22%     │
│ Change Failure Rate: 12%   ↓ -3%      │
│ MTTR: 47 minutes          ↓ -18%      │
│                                         │
│ [View Details] [Team Breakdown]        │
└─────────────────────────────────────────┘
```

#### 3. ACTIVITY (What Are Developers Doing?)

**What We’ll Measure**:

- **Code Contributions**: Commits, PRs, lines added/deleted
- **Review Activity**: PRs reviewed, comments per review, approval rate
- **Platform Usage**: Backstage views, dojo module completions, tool adoption
- **AI Tool Usage**: Copilot acceptance rate, AI-generated code percentage
- **Documentation**: Wiki edits, TechDocs updates, README improvements
- **Learning**: Dojo progress, certification completions, training attendance

**Collection Methods**:

- GitHub API for code metrics
- Backstage analytics
- Application logs and usage tracking
- AI tool telemetry (Copilot, RAG queries)

**Target Metrics**:

- 80%+ developers active on platform weekly
- Average 10+ commits per developer per week
- 90%+ PRs reviewed within 24 hours
- 70%+ AI tool adoption within 6 months
- 50%+ developers complete White Belt within 3 months

**Warning**: Activity metrics alone are dangerous. Never use these for:

- Individual performance reviews
- Ranking developers
- Setting quotas or minimums
- Punitive actions

These metrics show *patterns*, not individual worth. High activity ≠ high value.

#### 4. COMMUNICATION & COLLABORATION (How Well Do Teams Work Together?)

**What We’ll Measure**:

- **Code Review Quality**: Average comments per PR, time to first review, resolution time
- **Collaboration Patterns**: Cross-team PRs, pair programming sessions, mob programming
- **Knowledge Sharing**: Mattermost channel activity, documentation contributions
- **Feedback Quality**: Constructive comment ratio, conflict resolution time
- **Onboarding Support**: Mentorship assignments, new developer success rate

**Collection Methods**:

- GitHub PR metadata analysis
- Mattermost analytics
- Backstage TechDocs engagement
- Manual tagging of collaboration events
- Onboarding survey feedback

**Target Metrics**:

- <12 hour average time to first code review
- 80% PRs with at least 1 constructive comment
- 60% developers actively helping in Mattermost
- <5% “toxic” or unconstructive review comments
- 90%+ new developers feel supported during onboarding

**Example Metric**:

```
Code Review Health Score: 87/100

✅ Fast response: 8 hours avg (target: <12)
✅ Thorough: 3.2 comments avg (target: >2)
⚠️  Approval rate: 92% (investigate rubber-stamping?)
✅ Constructive tone: 96% positive
```

#### 5. EFFICIENCY & FLOW (Can Developers Focus and Deliver Value?)

**What We’ll Measure**:

- **Flow State**: “How often did you achieve deep focus?” (self-reported weekly)
- **Valuable Work Time**: “% of time spent on work you consider valuable” (weekly survey)
- **Friction Incidents**: Logging when tools/processes create blockers
- **Context Switching**: “How many different tools/tasks did you use today?”
- **Cognitive Load**: “Rate your mental effort today” (1-5 scale, daily pulse)
- **Wait Time**: Time spent blocked on external dependencies

**Collection Methods**:

- Weekly pulse surveys (2 minutes, 5 questions)
- Friction logging widget in Backstage (“Report a friction point”)
- Time tracking (optional, privacy-preserving)
- Meeting calendar analysis (% time in meetings)

**Target Metrics**:

- 60% time spent on valuable work
- 3 days per week achieving flow state
- <30 friction incidents per 100 developers per month
- Cognitive load average <3.5/5.0 (below “overwhelmed”)
- <25% time in meetings

**Example Weekly Pulse Survey**:

```
Quick Check-In (2 minutes)

1. This week, approximately what % of your time 
   was spent on work you found valuable?
   [Slider: 0% - 100%]

2. How many times did you achieve "flow state" 
   (deep, focused work)?
   [ ] Never  [ ] 1-2 times  [ ] 3-4 times  [ ] 5+ times

3. Rate your cognitive load this week:
   [ ] Very Low  [ ] Low  [ ] Moderate  [ ] High  [ ] Overwhelming

4. Did you experience any significant friction 
   using the platform?
   [ ] No  [ ] Yes → [Report details]

5. One thing to celebrate or improve?
   [Optional text box]
```

### Data Collection Infrastructure

**Technology Stack**:

- **Surveys**: Qualtrics or Typeform (quarterly NPS, annual DevEx)
- **Pulse Surveys**: Custom Backstage plugin (weekly 2-min check-in)
- **Metrics Collection**: Prometheus (system metrics)
- **Dashboards**: Grafana (DevEx Dashboard with SPACE dimensions)
- **Feedback Widget**: Backstage plugin (always-on feedback)
- **Analytics**: PostHog or Amplitude (product analytics)
- **Data Warehouse**: PostgreSQL (survey responses, aggregated metrics)

**Data Pipeline**:

```
Survey Tools → API → Data Warehouse (PostgreSQL)
                ↓
Platform Logs → Prometheus → Grafana DevEx Dashboard
                ↓
GitHub API → ETL → Data Warehouse
                ↓
          Analysis & Reports
```

### Privacy & Ethics

**Privacy-First Principles**:

1. **Individual data is never shared**: Managers never see individual survey responses
1. **Aggregation threshold**: Metrics only shown for groups of 5+ people
1. **Opt-in for detailed tracking**: Time tracking, keystroke analytics always optional
1. **Anonymous feedback**: Developers can always provide feedback anonymously
1. **Data retention limits**: Survey responses deleted after 2 years
1. **Right to be forgotten**: Developers can request data deletion at any time

**Never Use DevEx Data For**:

- ❌ Individual performance reviews
- ❌ Ranking developers
- ❌ Firing decisions
- ❌ Bonus calculations
- ❌ Comparing individuals

**Always Use DevEx Data For**:

- ✅ Identifying platform improvement opportunities
- ✅ Understanding team-level trends
- ✅ Measuring impact of platform changes
- ✅ Celebrating successes
- ✅ Advocating for developer needs to leadership

### The DevEx Dashboard

**Grafana Dashboard Structure** (3 pages):

**Page 1: Executive Summary**

- Overall NPS score with trend
- DORA 4 keys summary
- Satisfaction score across dimensions
- Key alerts (metrics degrading)

**Page 2: SPACE Deep Dive**

- 5 panels (one per SPACE dimension)
- Historical trends (30/60/90 day views)
- Team-level breakdowns
- Correlation analysis (e.g., satisfaction vs. lead time)

**Page 3: Action Dashboard**

- Top 5 friction points (from feedback)
- Suggested improvements (from analysis)
- Experiment tracking (what we’re trying)
- Impact measurement (did changes help?)

### Measurement Cadence

|Metric Type       |Frequency |Duration|Purpose                           |
|------------------|----------|--------|----------------------------------|
|NPS Survey        |Quarterly |5 min   |Track overall satisfaction trend  |
|DevEx Survey      |Annual    |15 min  |Comprehensive assessment          |
|Weekly Pulse      |Weekly    |2 min   |Quick check-in, catch issues early|
|Friction Reports  |Continuous|1 min   |Log blockers in real-time         |
|DORA Metrics      |Continuous|N/A     |Automated system metrics          |
|Platform Analytics|Continuous|N/A     |Usage patterns, adoption          |

### Acting on Insights: The Feedback Loop

**Monthly DevEx Review Meeting** (Platform Team):

1. Review dashboard (30 minutes)
1. Identify top 3 issues (from friction reports, survey feedback)
1. Prioritize improvements (impact vs. effort)
1. Commit to 1-2 experiments for next month
1. Measure impact in following month

**Quarterly DevEx Report** (to Leadership):

- NPS trend and key drivers
- DORA metrics performance
- Platform adoption metrics
- Top improvements delivered
- Planned focus areas for next quarter

**Communicating Back to Developers**:

- Monthly “You Said, We Did” post in Mattermost
- Quarterly DevEx town hall (results + roadmap)
- Always close the loop on feedback: “We heard X, here’s what we’re doing about it”

## Consequences

### Positive

1. **Data-Driven Decisions**: Platform roadmap based on validated user needs, not assumptions
1. **Early Warning System**: Degrading metrics alert us to problems before they become crises
1. **Demonstrate Value**: Quantify platform impact for leadership (ROI, productivity gains)
1. **Continuous Improvement**: Systematic process for getting better over time
1. **Developer Trust**: Developers feel heard when feedback leads to action
1. **AI Readiness**: User-centric foundation amplifies AI benefits (per DORA research)
1. **Attract Talent**: High DevEx scores help recruit top engineers
1. **Reduce Turnover**: Satisfied developers stay longer, reducing hiring costs
1. **Cultural Shift**: Treating developers as users changes how we build platforms
1. **Benchmark Progress**: Baselines enable “before/after” analysis of changes

### Negative

1. **Survey Fatigue**: Too many surveys can reduce response rates (mitigate with short, purposeful surveys)
1. **Privacy Concerns**: Developers may worry about surveillance (mitigate with clear privacy policy)
1. **Overhead**: Collecting, analyzing, and acting on data takes time (~20% of platform team)
1. **Expectation Management**: Measuring creates expectation that we’ll act on findings
1. **Analysis Paralysis**: Too much data can delay decisions (mitigate with monthly review cadence)
1. **Gaming Metrics**: Teams may try to optimize metrics rather than outcomes (mitigate with education)
1. **Initial Low Scores**: First measurements may reveal uncomfortable truths about current state

### Neutral

1. **Requires Cultural Buy-In**: Leadership must support user-centric approach
1. **Learning Curve**: Platform team must develop research and analysis skills
1. **Ongoing Effort**: DevEx measurement is a permanent practice, not a one-time project

## Alternatives Considered

### Alternative 1: No Formal Measurement (Status Quo)

**Pros**:

- Zero overhead
- No survey fatigue
- No privacy concerns

**Cons**:

- Decisions based on loudest voices or HiPPO (Highest Paid Person’s Opinion)
- No way to prove platform value
- Can’t measure improvement over time
- Miss early warning signs of problems

**Reason for Rejection**: DORA research conclusively shows user-centric focus amplifies AI benefits and team performance. Without measurement, we can’t be user-centric.

### Alternative 2: DORA Metrics Only

**Pros**:

- Well-established framework
- Automated data collection
- Proven correlation with outcomes

**Cons**:

- Only measures system performance, not human experience
- Misses satisfaction, cognitive load, friction
- Can create perverse incentives if used alone
- Doesn’t capture communication/collaboration quality

**Reason for Rejection**: DORA metrics are necessary but insufficient. SPACE framework encompasses DORA metrics (Performance dimension) plus human factors.

### Alternative 3: Custom Metrics Framework

**Pros**:

- Tailored precisely to Fawkes needs
- No need to learn existing framework

**Cons**:

- Reinventing the wheel
- No industry benchmarks for comparison
- Lacks research validation
- Hard to explain to stakeholders

**Reason for Rejection**: SPACE is well-researched, industry-validated, and comprehensive. Better to adopt proven framework than create our own.

### Alternative 4: Simple NPS Only

**Pros**:

- Very simple to implement
- Low survey burden
- Easy to track over time

**Cons**:

- NPS tells you “what” (satisfaction level) but not “why”
- No diagnostic capability
- Can’t identify specific improvement areas
- Misses entire dimensions (activity, flow, collaboration)

**Reason for Rejection**: NPS is a great summary metric but insufficient for driving improvements. We need diagnostic metrics to understand what to fix.

### Alternative 5: DevEx Framework (DX Core 4)

**Pros**:

- Focused specifically on developer experience
- Simpler than SPACE (4 dimensions vs. 5)
- Good research backing

**Cons**:

- Less comprehensive than SPACE
- Newer framework (less industry adoption)
- Doesn’t explicitly include collaboration dimension

**Reason for Rejection**: SPACE is more comprehensive and has broader industry adoption. DevEx framework is good but SPACE is better established.

## Implementation Plan

### Phase 1: Foundation (Weeks 1-2)

**Week 1: Infrastructure Setup**

1. Deploy survey tools (Qualtrics/Typeform account)
1. Create data warehouse schema in PostgreSQL
1. Design Grafana DevEx dashboard (mockup)
1. Draft privacy policy and data handling procedures
1. Write initial NPS survey (5 questions)

**Week 2: Baseline Measurement**

1. Launch first NPS survey to all developers
1. Collect DORA metrics baseline (automated)
1. Deploy friction reporting widget in Backstage
1. Analyze NPS results and identify themes
1. Set initial targets for each SPACE dimension

### Phase 2: Full Rollout (Weeks 3-4)

**Week 3: Automated Metrics**

1. Implement Prometheus collectors for activity metrics
1. Build Grafana dashboards (all 5 SPACE dimensions)
1. Set up alerting for degrading metrics
1. Document data collection infrastructure
1. Train platform team on dashboard usage

**Week 4: Feedback Loops**

1. Deploy weekly pulse survey (automated in Backstage)
1. Create feedback response process (monthly review meetings)
1. Launch first “You Said, We Did” communication
1. Schedule quarterly DevEx review with leadership
1. Establish monthly user interview schedule (5 devs/month)

### Phase 3: Iteration (Month 2+)

1. Conduct first monthly DevEx review meeting
1. Implement 1-2 improvements based on feedback
1. Measure impact of changes
1. Refine metrics and surveys based on learnings
1. Build momentum: celebrate wins, share results

## Metrics for Success

**Adoption Metrics** (First 3 Months):

- 70%+ response rate on NPS surveys
- 50%+ response rate on weekly pulse surveys
- 20+ friction reports submitted per month
- 100% platform team trained on dashboard usage
- Monthly DevEx review meetings established

**Outcome Metrics** (First 6 Months):

- NPS >50 (baseline + improvement)
- 60% developers report time on valuable work
- <30 friction incidents per 100 developers per month
- DORA metrics trending upward
- 3+ platform improvements delivered from feedback

**Long-Term Metrics** (12+ Months):

- NPS >60 (elite performer territory)
- Deployment frequency >2/day
- Lead time <12 hours
- <10% developers reporting burnout
- Platform team can articulate clear ROI with data

## Related Decisions

- **ADR-002**: Backstage for Developer Portal (primary vehicle for surveys, feedback widget)
- **ADR-006**: Prometheus for Metrics (Performance and Activity dimension data collection)
- **ADR-015**: User Research & Feedback System (complements quantitative metrics with qualitative insights)
- **ADR-016**: Platform-as-Product Operating Model (DevEx metrics inform product roadmap)

## References

- **SPACE Framework Paper**: https://queue.acm.org/detail.cfm?id=3454124
- **2025 DORA Report**: https://dora.dev/dora-report-2025
- **DevEx Framework**: https://queue.acm.org/detail.cfm?id=3595878
- **GitHub Octoverse**: Developer productivity research
- **Accelerate (Book)**: Forsgren, Humble, Kim - DORA metrics foundation
- **Team Topologies (Book)**: Skelton & Pais - Cognitive load research

## Notes

**Key Insight from DORA 2025**:

> “We found with a high degree of certainty that when teams adopt a user-centric focus, the positive influence of AI on their performance is amplified. Conversely, in the absence of a user-centric focus, AI adoption can have a negative impact on team performance.”

**Translation for Fawkes**:

- DevEx measurement is not optional—it’s the foundation for AI success
- Without measuring developer experience, AI adoption may harm performance
- SPACE framework provides the comprehensive measurement system we need
- Measurement without action is worthless—commit to monthly improvements

**Cultural Note**:
Implementing DevEx measurement is a cultural transformation as much as a technical one. The platform team must genuinely care about developer experience and be willing to change based on feedback. If leadership views this as “just more metrics,” it will fail.

## Last Updated

December 7, 2024 - Initial version documenting SPACE framework adoption for Fawkes DevEx measurement
