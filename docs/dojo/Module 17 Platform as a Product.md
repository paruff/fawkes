# Module 17: Platform as a Product

**Belt Level**: ⚫ Black Belt  
**Duration**: 60 minutes  
**Prerequisites**: Modules 1-16, especially Module 2 (DORA Metrics)  
**Certification Track**: Fawkes Platform Architect

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

1. **Apply** product management principles to internal developer platforms
2. **Conduct** user research to understand developer needs and pain points
3. **Build** a platform roadmap driven by user feedback and business value
4. **Measure** platform adoption, satisfaction, and impact using key metrics
5. **Establish** feedback loops and customer success practices for internal platforms

---

## 📚 Theory: Your Platform is a Product

### The Platform as a Product Mindset

**Traditional IT thinking**:
- "We build infrastructure, developers must use it"
- Success = Infrastructure availability (99.9% uptime)
- Mandate adoption through policy
- One-size-fits-all solutions

**Platform as a Product thinking**:
- "We serve developers, they are our customers"
- Success = Developer satisfaction + business outcomes
- Earn adoption through superior experience
- Tailored solutions for different user personas

### Why This Matters

**The "Build It and They Will Come" Fallacy**:

Many platform teams build technically excellent platforms that nobody uses:
- ❌ Kubernetes cluster set up perfectly, but developers still deploy to VMs
- ❌ CI/CD pipelines available, but teams continue using manual processes
- ❌ Observability stack deployed, but no one looks at the dashboards

**Root cause**: Building for technical excellence without understanding user needs.

### The Platform Product Triad

```
┌─────────────────────────────────────────────────────────────┐
│              PLATFORM AS A PRODUCT TRIAD                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    ┌──────────────┐                         │
│                    │   DESIRABLE  │                         │
│                    │  Do users     │                         │
│                    │  want it?     │                         │
│                    └───────┬──────┘                         │
│                            │                                 │
│              ┌─────────────┼─────────────┐                  │
│              │                           │                  │
│              │                           │                  │
│     ┌────────▼────────┐         ┌───────▼────────┐         │
│     │    FEASIBLE     │         │     VIABLE     │         │
│     │  Can we build   │         │  Does it drive │         │
│     │  it reliably?   │         │  business      │         │
│     │                 │         │  value?        │         │
│     └─────────────────┘         └────────────────┘         │
│                                                             │
│  SWEET SPOT: All three overlap                             │
│  - Developers want it (adoption)                           │
│  - We can build/maintain it (technical feasibility)        │
│  - It improves business metrics (DORA, cost, velocity)     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Your Platform's "Customers"

Unlike external products, your customers are internal:

```
┌──────────────────────────────────────────────────────────────┐
│                    USER PERSONAS                             │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  PERSONA 1: Frontend Developer (Alex)                       │
│  ├─ Needs: Fast iteration, preview environments             │
│  ├─ Pain: Complex deployment process, no staging            │
│  ├─ Skills: React/Vue, basic Docker, no Kubernetes          │
│  └─ Success: Can deploy feature in <5 minutes               │
│                                                              │
│  PERSONA 2: Backend Engineer (Jordan)                       │
│  ├─ Needs: Database migrations, service mesh                │
│  ├─ Pain: Manual DB changes, no service discovery           │
│  ├─ Skills: Java/Python, SQL, intermediate Kubernetes       │
│  └─ Success: Zero-downtime deployments with DB changes      │
│                                                              │
│  PERSONA 3: Data Scientist (Sam)                            │
│  ├─ Needs: GPU resources, Jupyter notebooks, data access    │
│  ├─ Pain: No ML infrastructure, manual model deployment     │
│  ├─ Skills: Python/R, ML frameworks, zero DevOps            │
│  └─ Success: Train and deploy models without ops team       │
│                                                              │
│  PERSONA 4: SRE/DevOps (Morgan)                             │
│  ├─ Needs: Observability, incident response tools           │
│  ├─ Pain: Alert fatigue, no runbooks                        │
│  ├─ Skills: Expert Kubernetes, Terraform, monitoring        │
│  └─ Success: MTTR < 5 minutes, no 3am pages                 │
│                                                              │
│  PERSONA 5: Engineering Manager (Taylor)                    │
│  ├─ Needs: Team velocity metrics, cost visibility           │
│  ├─ Pain: No visibility into bottlenecks, surprise bills    │
│  ├─ Skills: Technical background, business focus            │
│  └─ Success: Data-driven decisions, predictable costs       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Key insight**: Different personas have different needs. A one-size-fits-all platform will satisfy no one.

---

## 🔍 User Research for Platforms

### Discovery: Understanding the Problem

**Methods for platform user research**:

#### 1. User Interviews (Most valuable)

```
INTERVIEW SCRIPT TEMPLATE:

Opening (5 min):
- Thank you for your time
- We're improving the platform based on developer feedback
- No wrong answers, honest feedback helps us most
- Will take 30 minutes

Current Workflow (10 min):
- Walk me through how you deployed your last feature
- What tools did you use?
- Where did you get stuck?
- How long did the whole process take?

Pain Points (10 min):
- What's the most frustrating part of your deployment process?
- If you could change one thing, what would it be?
- What takes longer than it should?
- What do you work around or hack together?

Desired Future (5 min):
- If I could wave a magic wand, what would your ideal workflow be?
- What would success look like?
- How would you measure improvement?

Closing:
- Can I follow up if we need clarification?
- Would you be willing to test early versions?
```

**Pro tips**:
- Ask "How?" and "Why?" not "Would you use...?"
- Observe actual behavior, not stated preferences
- Look for workarounds (reveals unmet needs)
- Interview both happy and unhappy users

#### 2. Shadowing / Observation

Sit with developers and watch them work:
- Where do they wait?
- What do they Google?
- What tools do they switch between?
- Where do they ask for help?

**Example insights**:
- "They spent 20 minutes figuring out environment variable syntax"
- "They copy-pasted from another team's repo instead of using docs"
- "They waited 15 minutes for CI pipeline, then force-pushed to debug"

#### 3. Surveys (Quantitative validation)

Use after interviews to validate at scale:

```
PLATFORM SATISFACTION SURVEY (NPS-style):

1. How likely are you to recommend our platform to a colleague? (0-10)

2. What is the PRIMARY reason for your score?
   [Open text field]

3. How often do you deploy to production?
   ○ Multiple times per day
   ○ Daily
   ○ Weekly
   ○ Monthly or less

4. How satisfied are you with the following? (1-5 scale)
   - Deployment speed
   - Documentation quality
   - Getting help when stuck
   - Observability/debugging
   - Local development experience

5. What would make the biggest positive impact on your productivity?
   [Open text field]
```

#### 4. Analytics / Telemetry

Instrument your platform to observe usage:
- Which features are used most/least?
- Where do users drop off?
- How long do tasks take?
- What errors do they hit?

```yaml
# Example: Track platform usage
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: payment-service
  annotations:
    analytics/deploy-frequency: "5.2/day"
    analytics/avg-deploy-time: "8m 32s"
    analytics/rollback-rate: "2.1%"
    analytics/support-tickets: "3/month"
```

### Synthesizing Research

**Turn insights into themes**:

```
RAW FEEDBACK (from 15 interviews):

"Deployments are slow" (8 mentions)
"I don't know if my deploy worked" (12 mentions)
"Kubernetes YAML is confusing" (6 mentions)
"I waste time waiting for CI" (7 mentions)
"Can't debug production issues" (10 mentions)

↓ Synthesize into themes ↓

THEME 1: Lack of visibility (12 mentions)
- No real-time deploy status
- Can't see what's running in production
- No easy way to check logs/metrics

THEME 2: Slow feedback loops (8 mentions)
- Deployments take >10 minutes
- CI pipelines are slow
- No local development that matches prod

THEME 3: Steep learning curve (6 mentions)
- Kubernetes concepts are hard
- Too much YAML configuration
- Documentation assumes too much knowledge
```

**Prioritize using Impact vs Effort**:

```
┌────────────────────────────────────────────────────────┐
│           IMPACT vs EFFORT MATRIX                      │
├────────────────────────────────────────────────────────┤
│                                                        │
│  HIGH IMPACT                                           │
│    │                                                   │
│    │   [Deployment Status]    [Observability]         │
│    │   📊 DO FIRST            📊 DO NEXT              │
│    │                                                   │
│    │                                                   │
│    │   [Better Docs]          [Local Dev]             │
│    │   📝 QUICK WINS          ⚙️  PLAN FOR            │
│    │                                                   │
│  LOW IMPACT                                            │
│    └─────────────────────────────────────────▶        │
│         LOW EFFORT              HIGH EFFORT            │
│                                                        │
└────────────────────────────────────────────────────────┘

NEXT SPRINT:
1. Deployment status dashboard (high impact, medium effort)
2. Improve documentation (medium impact, low effort)
```

---

## 📋 Building a Platform Roadmap

### Product Roadmap Structure

```
┌──────────────────────────────────────────────────────────────┐
│              PLATFORM ROADMAP (Q1-Q4 2025)                   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  NORTH STAR: Reduce deployment time from 30min to <5min     │
│                                                              │
│  Q1: VISIBILITY & FEEDBACK                                  │
│  ├─ Deployment status dashboard (Backstage plugin)          │
│  ├─ Real-time logs in UI                                    │
│  ├─ Slack notifications for deploy events                   │
│  └─ Metrics: 80% developers check dashboard weekly          │
│                                                              │
│  Q2: SPEED & RELIABILITY                                     │
│  ├─ Progressive delivery (canary deployments)               │
│  ├─ Parallel CI pipelines (5min → 2min)                     │
│  ├─ Auto-rollback on errors                                 │
│  └─ Metrics: Deploy time P95 < 8 minutes                    │
│                                                              │
│  Q3: DEVELOPER EXPERIENCE                                    │
│  ├─ Self-service preview environments                       │
│  ├─ Local development with Tilt                             │
│  ├─ Golden path templates for common patterns               │
│  └─ Metrics: 60% of teams using preview envs                │
│                                                              │
│  Q4: SCALE & OPTIMIZATION                                    │
│  ├─ Cost optimization dashboard                             │
│  ├─ Auto-scaling for production workloads                   │
│  ├─ Multi-region deployments                                │
│  └─ Metrics: 25% cost reduction, 99.9% availability         │
│                                                              │
│  CONTINUOUS:                                                 │
│  ├─ Weekly office hours                                     │
│  ├─ Monthly user interviews (5 developers)                  │
│  ├─ Quarterly satisfaction surveys (NPS)                    │
│  └─ Backstage documentation updates                         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Roadmap Principles

1. **Themes, not features**: Organize by user goals, not technical tasks
2. **Timeboxed**: Quarterly or bi-weekly sprints, not "when it's done"
3. **Outcome-driven**: Each item has success metrics
4. **Communicated**: Public roadmap visible to all developers
5. **Flexible**: Re-prioritize based on feedback

### Saying No (Productively)

Not every request makes the roadmap:

```
REQUEST: "Can we add support for Terraform 1.6?"

BAD RESPONSE:
"No, we're too busy."

GOOD RESPONSE:
"Thanks for the request! We track all feedback. Currently we're 
focused on reducing deploy times (our #1 pain point from user 
research). Terraform 1.6 affects ~5 teams, while deploy speed 
affects all 40 teams. We've added your request to the backlog 
and will revisit in Q3. Does that work for you?"

EVEN BETTER:
"Let's understand the need. What's the use case for 1.6? 
[Discussion reveals they just need a specific provider version]
Oh! We can enable that without upgrading Terraform core. 
Can you test this next week?"
```

---

## 📊 Platform Metrics & KPIs

### Metrics Pyramid

```
┌────────────────────────────────────────────────────────┐
│                  BUSINESS OUTCOMES                     │
│  ┌──────────────────────────────────────────────┐     │
│  │  - Revenue impact                             │     │
│  │  - Time to market                             │     │
│  │  - Engineering cost per deploy                │     │
│  └──────────────────────────────────────────────┘     │
│                        ▲                               │
│                        │                               │
│              ┌─────────┴─────────┐                     │
│              │   DORA METRICS    │                     │
│              │ - Deploy frequency│                     │
│              │ - Lead time       │                     │
│              │ - MTTR            │                     │
│              │ - Change fail rate│                     │
│              └─────────┬─────────┘                     │
│                        ▲                               │
│                        │                               │
│        ┌───────────────┴───────────────┐               │
│        │   PLATFORM ADOPTION           │               │
│        │ - Active users                │               │
│        │ - Usage frequency             │               │
│        │ - Feature adoption            │               │
│        └───────────────┬───────────────┘               │
│                        ▲                               │
│                        │                               │
│  ┌─────────────────────┴─────────────────────────┐    │
│  │         USER SATISFACTION                      │    │
│  │  - NPS (Net Promoter Score)                   │    │
│  │  - Support ticket volume                      │    │
│  │  - Documentation clarity rating               │    │
│  └───────────────────────────────────────────────┘    │
│                                                        │
└────────────────────────────────────────────────────────┘

Start measuring from bottom up:
1. Are users satisfied? (surveys, interviews)
2. Are they adopting? (usage analytics)
3. Is it improving DORA? (deployment metrics)
4. Is it driving business value? (cost, velocity)
```

### Key Platform Metrics

#### 1. Adoption Metrics

```
METRIC: Platform Adoption Rate
Formula: (Teams using platform / Total teams) × 100%

Targets:
- Month 1: 10% (early adopters)
- Month 3: 30% (early majority)
- Month 6: 60% (late majority)
- Month 12: 80%+ (full adoption)

Track by feature:
- CI/CD pipeline: 75% adoption
- GitOps deployment: 60% adoption
- Observability: 45% adoption
- Preview environments: 25% adoption
```

#### 2. Satisfaction Metrics (NPS)

```
Net Promoter Score: "How likely would you recommend our 
platform to a colleague?" (0-10)

Calculation:
- Promoters (9-10): Enthusiastic users
- Passives (7-8): Satisfied but not advocates
- Detractors (0-6): Unhappy, at risk

NPS = % Promoters - % Detractors

Benchmark:
- NPS > 50: Excellent
- NPS 30-50: Good
- NPS 0-30: Needs improvement
- NPS < 0: Crisis mode
```

#### 3. Efficiency Metrics

```
METRIC: Time to First Deployment
Track: How long from "I want to deploy" to "It's in production"

Baseline (no platform): 4 hours
- Request infrastructure: 2 hours
- Manual setup: 1 hour  
- Deploy + verify: 1 hour

Target (with platform): 15 minutes
- Self-service: 2 minutes
- Auto-deploy via Git push: 8 minutes
- Auto-verify health: 5 minutes

Impact: 93% reduction in time to deploy
```

#### 4. Support & Reliability Metrics

```
METRIC: Mean Time to Resolution (Support)
Track: How fast can developers unblock themselves?

Support ticket categories:
- Documentation issue: MTTR < 10 minutes (self-service)
- Configuration help: MTTR < 2 hours (async)
- Platform bug: MTTR < 4 hours (urgent)
- Feature request: Tracked in backlog

Target: 80% of issues resolved in <1 hour
```

### Dashboard Example

```
┌──────────────────────────────────────────────────────────────┐
│           FAWKES PLATFORM HEALTH DASHBOARD                   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ADOPTION                                                    │
│  ├─ Active Teams: 32/40 (80%) ▲ +3 this month              │
│  ├─ Daily Deployments: 127 ▲ +15% MoM                       │
│  └─ Feature Usage:                                           │
│      • CI/CD: 85% ▲                                          │
│      • GitOps: 70% ▲                                         │
│      • Observability: 55% ▲                                  │
│                                                              │
│  SATISFACTION (NPS: 42)                                      │
│  ├─ Promoters: 55% (22 users)                               │
│  ├─ Passives: 32% (13 users)                                │
│  └─ Detractors: 13% (5 users) ⚠️                            │
│                                                              │
│  DORA METRICS                                                │
│  ├─ Deploy Frequency: 5.2/day ▲ (Target: >5)               │
│  ├─ Lead Time: 45 min ▼ (Target: <1 hour)                  │
│  ├─ MTTR: 12 min ▲ (Target: <15 min)                       │
│  └─ Change Fail Rate: 3.2% ▲ (Target: <5%)                 │
│                                                              │
│  SUPPORT                                                     │
│  ├─ Open Tickets: 8 (3 urgent)                              │
│  ├─ MTTR: 2.3 hours ▼ (Target: <4 hours)                   │
│  └─ Top Issues:                                              │
│      1. Deployment timeouts (3 tickets)                     │
│      2. Secret management confusion (2 tickets)             │
│                                                              │
│  ACTIONS                                                     │
│  🔴 Investigate detractors (schedule 5 interviews)           │
│  🟡 Improve deployment timeout documentation                │
│  🟢 Celebrate: Hit 80% adoption milestone! 🎉               │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Hands-On Lab: Building a Platform Product

### Lab Overview

You will practice product management for a platform by:
1. Analyzing user feedback and identifying themes
2. Prioritizing features using impact vs. effort
3. Creating a quarterly roadmap
4. Setting up NPS surveys and adoption tracking
5. Building a platform health dashboard

**Duration**: 25 minutes  
**Tools**: Backstage, Fawkes CLI, survey tools

---

### Lab Setup

```bash
# Start the platform product lab
fawkes lab start --module 17

# This provides:
# - Backstage instance with sample feedback
# - Analytics data from 40 development teams
# - Survey responses (30 developers)
```

---

### Exercise 1: Analyze User Feedback (6 minutes)

**Objective**: Review user interviews and identify top 3 themes.

```bash
# View feedback data
cd ~/fawkes-lab-17/user-research
cat interviews.json | jq '.[] | {name, role, pain_points}'
```

**Sample feedback** (you'll see 15 interviews):

```json
{
  "interviews": [
    {
      "name": "Alex (Frontend Dev)",
      "pain_points": [
        "Deployments take 25 minutes",
        "No way to see if my deploy worked",
        "Kubernetes is confusing"
      ]
    },
    {
      "name": "Jordan (Backend Dev)",
      "pain_points": [
        "Can't debug production issues",
        "No staging environment",
        "Database migrations are manual"
      ]
    }
    // ... 13 more interviews
  ]
}
```

**Your task**: Use the provided script to analyze themes:

```bash
# Run theme analysis
python analyze_feedback.py interviews.json

# Output:
# THEME 1: Slow deployments (12 mentions) 
# THEME 2: Lack of visibility (15 mentions)
# THEME 3: No staging/preview envs (8 mentions)
# THEME 4: Difficult debugging (10 mentions)
# THEME 5: Steep learning curve (7 mentions)
```

**Question**: Which theme should you prioritize? Consider:
- Frequency (how many users mentioned it)
- Severity (how much pain does it cause)
- Feasibility (can you solve it in <1 quarter)

---

### Exercise 2: Prioritize Using Impact vs Effort (5 minutes)

**Objective**: Plot features on an impact/effort matrix.

```bash
# View proposed features
cat features.yaml
```

**features.yaml**:
```yaml
features:
  - name: "Real-time deployment dashboard"
    impact: high
    effort: medium
    theme: "Lack of visibility"
    
  - name: "Self-service preview environments"
    impact: high
    effort: high
    theme: "No staging"
    
  - name: "Improve documentation"
    impact: medium
    effort: low
    theme: "Learning curve"
    
  - name: "Integrated log viewer"
    impact: medium
    effort: medium
    theme: "Debugging"
    
  - name: "Parallel CI pipelines"
    impact: high
    effort: medium
    theme: "Slow deployments"
```

**Your task**: Use the Fawkes CLI to generate a prioritization matrix:

```bash
fawkes product prioritize --input features.yaml --output priority-matrix.png

# Opens an image showing features plotted
```

**Expected result**:
```
DO FIRST (High Impact, Low-Med Effort):
1. Real-time deployment dashboard
2. Parallel CI pipelines
3. Improve documentation

DO NEXT (High Impact, High Effort):
4. Self-service preview environments

BACKLOG:
5. Integrated log viewer
```

---

### Exercise 3: Create a Quarterly Roadmap (6 minutes)

**Objective**: Build a Q1 roadmap based on prioritized features.

```bash
# Use roadmap template
cp templates/roadmap-template.md Q1-2025-roadmap.md
vim Q1-2025-roadmap.md
```

**Fill in the template**:

```markdown
# Q1 2025 Platform Roadmap

## North Star Goal
Reduce deployment time from 25 minutes to <8 minutes (68% improvement)

## Sprint 1-2 (Weeks 1-4): Visibility
**Theme**: Developers can't see what's happening

- [ ] Deployment status dashboard in Backstage
  - Real-time progress (queued → building → deploying → healthy)
  - Estimated time remaining
  - Success metric: 70% of developers check dashboard weekly

- [ ] Slack notifications
  - Deploy started/completed/failed
  - @ mention author on failures
  - Success metric: <2 min to notice failed deploy

## Sprint 3-4 (Weeks 5-8): Speed
**Theme**: Deployments are too slow

- [ ] Parallel CI pipelines
  - Run tests in parallel (8min → 3min)
  - Cache dependencies
  - Success metric: P95 build time <5 minutes

- [ ] Optimize Docker builds
  - Multi-stage builds
  - Layer caching
  - Success metric: Image build <2 minutes

## Sprint 5-6 (Weeks 9-12): Polish
**Theme**: Improve overall experience

- [ ] Documentation overhaul
  - Step-by-step tutorials for common tasks
  - Video walkthroughs
  - Success metric: NPS +10 points

- [ ] Weekly office hours
  - 1 hour/week for Q&A
  - Success metric: 15+ attendees average

## Success Criteria (End of Q1)
- [ ] Deploy time P95: <8 minutes (from 25min)
- [ ] Platform adoption: 85% of teams (from 70%)
- [ ] NPS: 50+ (from 38)
- [ ] Support tickets: <10/week (from 18/week)
```

**Validate your roadmap**:

```bash
fawkes product validate-roadmap Q1-2025-roadmap.md

# Checks:
# ✅ All items have success metrics
# ✅ North Star goal is measurable
# ✅ Timeboxed to one quarter
# ⚠️  Warning: Sprint 1-2 may be overloaded (2 major features)
```

---

### Exercise 4: Set Up NPS Surveys (4 minutes)

**Objective**: Configure automated NPS surveys in Backstage.

```bash
# Install Backstage feedback plugin
cd ~/fawkes-lab-17/backstage
yarn add @backstage/plugin-user-feedback
```

**Configure survey**:

```yaml
# app-config.yaml
userFeedback:
  surveys:
    - id: platform-nps
      title: "Platform Satisfaction Survey"
      frequency: quarterly
      questions:
        - id: nps
          type: nps
          text: "How likely are you to recommend Fawkes Platform to a colleague?"
          
        - id: reason
          type: text
          text: "What's the PRIMARY reason for your score?"
          
        - id: biggest-pain
          type: text
          text: "What's your biggest pain point with the platform?"
          
        - id: feature-satisfaction
          type: matrix
          text: "How satisfied are you with the following?"
          rows:
            - "Deployment speed"
            - "Documentation"
            - "Getting help when stuck"
            - "Observability/debugging"
          scale: 1-5
```

**Test the survey**:

```bash
# Simulate 10 survey responses
fawkes lab simulate-surveys --count 10

# View results dashboard
open http://localhost:3000/user-feedback/platform-nps
```

**Expected dashboard**:
```
Platform NPS: 42
├─ Promoters (9-10): 12 responses (55%)
├─ Passives (7-8): 7 responses (32%)
└─ Detractors (0-6): 3 responses (13%)

Top Pain Points:
1. "Deployments are still too slow" (8 mentions)
2. "Documentation is hard to find" (5 mentions)
3. "Don't know how to debug prod issues" (4 mentions)

Feature Satisfaction (1-5 scale):
├─ Deployment speed: 3.2/5 ⚠️
├─ Documentation: 3.8/5
├─ Getting help: 4.1/5 ✅
└─ Observability: 3.5/5
```

---

### Exercise 5: Build Platform Health Dashboard (4 minutes)

**Objective**: Create a dashboard showing adoption, satisfaction, and DORA metrics.

```bash
# Use Grafana with pre-configured datasources
cd ~/fawkes-lab-17/grafana
docker-compose up -d

# Import dashboard
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @platform-health-dashboard.json
```

**Dashboard panels** (pre-configured):

1. **Adoption Panel**:
```promql
# Teams using platform
count(count by (team) (deployment_total{platform="fawkes"}))

# Daily deployments
rate(deployment_total{platform="fawkes"}[1d])
```

2. **Satisfaction Panel**:
```sql
-- NPS score
SELECT 
  (COUNT(*) FILTER (WHERE score >= 9) * 100.0 / COUNT(*) - 
   COUNT(*) FILTER (WHERE score <= 6) * 100.0 / COUNT(*)) as nps