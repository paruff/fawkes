# ADR-019: User Research & Feedback Collection System

## Status

Accepted

## Context

ADR-018 established the SPACE framework for *quantitative* measurement of developer experience. However, numbers alone cannot tell the complete story. Metrics show *what* is happening but rarely explain *why*. To build a truly user-centric platform, we need deep qualitative insights to complement our quantitative metrics.

**The 2025 DORA Report Finding**:

> “User-centric focus is THE differentiator. Without it, AI adoption can have a negative impact on team performance.”

**What “User-Centric” Actually Means**:

- Regular direct contact with developers (our users)
- Understanding their goals, pain points, and workflows
- Validating assumptions before building features
- Closing the feedback loop: “You said X, we did Y”
- Treating the platform as a product, developers as customers

**Current State - Critical Gaps**:

- ❌ No systematic user interviews
- ❌ No user journey mapping
- ❌ No usability testing of platform features
- ❌ No process for collecting/triaging feedback
- ❌ Platform decisions made by platform team in isolation
- ❌ Developers have no clear way to influence roadmap

**Why This Matters for Fawkes**:

1. **AI Amplification**: User-centric focus amplifies AI benefits (DORA finding)
1. **Avoid “Build It and They Won’t Come”**: Features nobody asked for = wasted effort
1. **Early Problem Detection**: Catch issues before they become widespread
1. **Build Trust**: Developers feel heard when their feedback shapes the platform
1. **Competitive Advantage**: Great DevEx attracts and retains top talent

## Decision

We will implement a comprehensive **User Research & Feedback Collection System** with three interconnected components:

1. **Continuous Feedback Channels** (always-on, low-friction)
1. **Structured User Research** (proactive, scheduled)
1. **Feedback Processing Pipeline** (turning insights into action)

### Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  FEEDBACK COLLECTION LAYER                                   │
│                                                               │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │ In-Platform    │  │ Mattermost     │  │ Office Hours   │ │
│  │ Feedback       │  │ #platform      │  │ (Bi-weekly)    │ │
│  │ Widget         │  │ -feedback      │  │                │ │
│  └────────────────┘  └────────────────┘  └────────────────┘ │
│                                                               │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │ User           │  │ Usability      │  │ Feature        │ │
│  │ Interviews     │  │ Testing        │  │ Requests       │ │
│  │ (Monthly)      │  │ Sessions       │  │ (GitHub)       │ │
│  └────────────────┘  └────────────────┘  └────────────────┘ │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  AGGREGATION & ANALYSIS LAYER                                │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Feedback Database (PostgreSQL)                         │  │
│  │ - All feedback tagged and categorized                  │  │
│  │ - Sentiment analysis (AI-powered)                      │  │
│  │ - Deduplication and clustering                         │  │
│  │ - Priority scoring algorithm                           │  │
│  └────────────────────────────────────────────────────────┘  │
│                            ↓                                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Analysis & Insights                                    │  │
│  │ - Theme identification (qualitative coding)            │  │
│  │ - Trend analysis (increasing/decreasing issues)        │  │
│  │ - Impact assessment (how many users affected?)         │  │
│  │ - User journey pain point mapping                      │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  ACTION & COMMUNICATION LAYER                                │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Monthly DevEx Review Meeting                           │  │
│  │ - Review top feedback themes                           │  │
│  │ - Prioritize improvements (impact vs. effort)          │  │
│  │ - Assign owners and set deadlines                      │  │
│  │ - Track experiments and measure impact                 │  │
│  └────────────────────────────────────────────────────────┘  │
│                            ↓                                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ "You Said, We Did" Communication                       │  │
│  │ - Monthly update post (Mattermost + email)             │  │
│  │ - Quarterly DevEx town hall                            │  │
│  │ - Close the loop on every piece of feedback            │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

## Component 1: Continuous Feedback Channels

### 1.1 In-Platform Feedback Widget (Backstage Plugin)

**What**: A persistent feedback button in Backstage that allows developers to submit feedback in <30 seconds without leaving their workflow.

**Implementation**:

```typescript
// Backstage Plugin: @fawkes/plugin-feedback
// Appears in every Backstage page header

interface FeedbackSubmission {
  type: 'bug' | 'friction' | 'feature-request' | 'praise';
  category: 'ci-cd' | 'gitops' | 'docs' | 'dojo' | 'other';
  description: string;
  context: {
    page: string;
    timestamp: Date;
    userRole: string;
    anonymized: boolean;
  };
  sentiment: 'positive' | 'neutral' | 'negative';
}
```

**Features**:

- One-click access from any Backstage page
- Pre-categorized feedback types (reduces friction)
- Optional anonymous submission
- Automatically captures context (page, time, user role)
- AI-powered sentiment analysis
- “Thank you” confirmation with ticket number

**Example Flow**:

```
[User clicks "Give Feedback" button in Backstage header]

┌─────────────────────────────────────────┐
│  Quick Feedback (30 seconds)            │
│                                          │
│  What type of feedback?                 │
│  ( ) Bug - Something's broken           │
│  (•) Friction - Something's annoying    │
│  ( ) Feature Request - I need...        │
│  ( ) Praise - Something's great!        │
│                                          │
│  Which area?                             │
│  [Dropdown: CI/CD, GitOps, Docs, etc.]  │
│                                          │
│  Tell us more: (required)                │
│  [Text area - 50-500 characters]         │
│                                          │
│  [✓] Make this feedback anonymous        │
│                                          │
│  [Cancel]  [Submit Feedback]             │
└─────────────────────────────────────────┘

[After submission]
✅ Thanks! Your feedback has been recorded as FEEDBACK-1234.
   The platform team reviews all feedback monthly.
```

**Target**: 50+ feedback submissions per month (for 100 developers = 50% monthly participation)

### 1.2 Mattermost #platform-feedback Channel

**What**: A dedicated, monitored channel where developers can share feedback, ask questions, and discuss platform topics.

**Purpose**:

- Lower-friction than formal feedback form
- Enables peer-to-peer discussion
- Platform team can ask clarifying questions
- Public transparency (everyone sees responses)

**Guidelines**:

- Platform team commits to <24 hour response time
- All feedback is acknowledged, even if not immediately actionable
- Emoji reactions for quick validation (“👍 we hear you”)
- Monthly summary post of feedback received and actions taken

**Example Interaction**:

```
@developer_alice [10:23 AM]
The Jenkins build for my service is taking 45 minutes now. 
It used to be 15 minutes last month. Anyone else seeing this?
🐌

@platform_engineer [10:41 AM]
Thanks for flagging @developer_alice! We'll investigate. 
Can you share which service? (DM if sensitive)

@developer_bob [11:02 AM]
Same issue here. My builds went from 12 mins → 35 mins
Seems like it started after the Jenkins upgrade last week?

@platform_engineer [11:15 AM]
Good catch on the timing. We upgraded Jenkins on Oct 28th.
I'll check if we inadvertently changed build parallelism settings.
Created ticket: FAWKES-567. Will update here by EOD.

@platform_engineer [4:30 PM]
Update: Found the issue. Jenkins upgrade reset parallel build 
settings. Fix deployed. Builds should be back to normal speed now.
@developer_alice @developer_bob can you confirm?

@developer_alice [4:45 PM]
Confirmed! Back to 16 minutes. Thanks! 🎉
```

### 1.3 Bi-Weekly Office Hours

**What**: Scheduled 1-hour sessions where developers can drop in to discuss platform topics, demo features, or raise concerns.

**Format**:

- Every other Wednesday, 2:00-3:00 PM (recorded for async viewing)
- Open agenda (anyone can add topics to shared doc)
- Mix of platform team updates + developer Q&A
- Virtual (Zoom/Google Meet) with Mattermost live chat

**Typical Agenda**:

```
Fawkes Platform Office Hours - Nov 15, 2024

📋 Agenda (add your topics below):
1. [Platform Team] Demo: New AI code review bot (10 min)
2. [Platform Team] Update: DORA metrics dashboard launch (5 min)
3. [@developer_charlie] Question: How do I set up multi-region deployments? (10 min)
4. [@developer_diana] Feedback: Backstage search is slow (10 min)
5. Open discussion + Q&A (25 min)

📊 Since Last Office Hours:
- 47 feedback submissions received
- Top issue: Jenkins build times → Fixed
- NPS score: 62 (↑ from 58 last quarter)

🎯 Coming Next Sprint:
- AI-powered PR review suggestions
- Dojo Module 6: Advanced GitOps
- Backstage performance improvements
```

**Target**: 10-15 attendees per session, 40+ watching recording

### 1.4 GitHub Issues (Feature Requests)

**What**: A public repository (`fawkes/platform-feedback`) where developers can submit feature requests, vote on proposals, and discuss implementations.

**Process**:

1. Developer opens issue with feature request template
1. Platform team labels and categorizes (P0/P1/P2)
1. Community can upvote (👍 reactions)
1. Monthly review: Top 3 upvoted features → roadmap consideration
1. Status updates posted as comments
1. Closed with link to implementation or explanation if rejected

**Feature Request Template**:

```markdown
## Feature Request

**Problem Statement**:
What problem are you trying to solve? (Be specific)

**Proposed Solution**:
How would you like this to work?

**Alternatives Considered**:
What workarounds are you currently using?

**Impact**:
How many people would benefit? How often would this be used?

**Additional Context**:
Screenshots, examples, related issues?
```

**Success Metric**: 10+ feature requests per month, 80% receive response within 1 week

## Component 2: Structured User Research

### 2.1 Monthly User Interviews (5 per month)

**What**: One-on-one, semi-structured interviews with developers to deeply understand their workflows, pain points, and needs.

**Recruitment**:

- Stratified sampling: Mix of roles, teams, experience levels
- Rotate through teams (don’t interview same people repeatedly)
- $50 gift card incentive for 1-hour participation
- Opt-in via Mattermost announcement

**Interview Guide Template**:

```markdown
Fawkes User Interview Guide (60 minutes)

Introduction (5 min):
- Thank participant, explain purpose
- Emphasize: No right/wrong answers, all feedback valuable
- Confirm recording consent

Warm-Up (5 min):
- What's your role and team?
- How long have you been using Fawkes?
- On a scale of 1-5, how would you rate your overall experience?

Current Workflow (15 min):
- Walk me through your typical day using Fawkes
- What's the first thing you do in the morning?
- How do you deploy code from idea to production?
- [Screen share: Show me how you do X]

Pain Points (15 min):
- What's the most frustrating part of using Fawkes?
- When was the last time Fawkes slowed you down?
- If you could fix one thing tomorrow, what would it be?
- What workarounds have you developed?

AI Tools (10 min):
- Are you using AI coding assistants (Copilot, etc.)?
- How has AI changed your workflow?
- What would make AI tools more useful in Fawkes?

Aspirations (5 min):
- What does an ideal platform look like to you?
- What would make you recommend Fawkes to others?

Wrap-Up (5 min):
- Anything we haven't covered?
- Can we follow up if we have clarifying questions?
- Thank you + next steps
```

**Analysis Process**:

1. Transcribe interviews (automated via Otter.ai)
1. Qualitative coding: Tag themes (e.g., “Jenkins slow”, “docs unclear”, “AI helpful”)
1. Affinity mapping: Cluster similar feedback
1. Synthesis: Write 1-page summary per interview
1. Monthly report: Top 5 themes across all interviews

**Target**: 5 interviews per month = 60/year = ~60% of developers interviewed annually (for 100-person org)

### 2.2 User Journey Mapping Workshops (Quarterly)

**What**: Collaborative workshops where developers and platform team map the end-to-end journey of using Fawkes, identifying pain points and opportunities.

**Process**:

1. Select 1-2 key journeys (e.g., “Onboarding a new service”, “Deploying a hotfix”)
1. Invite 6-8 developers who’ve recently completed that journey
1. 2-hour workshop: Map stages, emotions, pain points, moments of delight
1. Platform team commits to addressing top 3 pain points

**Example Journey Map Output**:

```
Journey: Deploying Your First Service to Production

Stage 1: Setup
😊 Easy: Backstage template worked great
😐 Okay: Jenkins config was confusing but documentation helped
😢 Frustrating: Spent 2 hours debugging IAM permissions

Stage 2: First Deploy
😊 Easy: ArgoCD UI is intuitive
😢 Frustrating: No idea if deployment was successful (logs buried)
😡 Blocker: Deployment failed due to missing secret, took 4 hours to debug

Stage 3: Monitoring
😐 Okay: Grafana dashboard is powerful but overwhelming
😢 Frustrating: Can't tell if my service is healthy without asking SRE team

Top Pain Points:
1. IAM permissions are black magic (fix: better templates + error messages)
2. Deployment status is unclear (fix: real-time status in Backstage)
3. Monitoring setup is manual and confusing (fix: auto-generated dashboards)
```

### 2.3 Usability Testing (As Needed)

**What**: Observing developers trying to complete specific tasks with new or existing platform features.

**When to Use**:

- Before launching major new features (beta testing)
- After receiving complaints about existing features
- To validate design decisions

**Process**:

1. Define 3-5 realistic tasks (e.g., “Deploy a new microservice”)
1. Recruit 5 developers (diverse skill levels)
1. Observe remotely (screen share + think-aloud protocol)
1. Measure: Time to complete, errors, satisfaction rating
1. Identify usability issues and iterate design

**Example Test**:

```
Task: Create a new Python microservice and deploy it to staging

Success Criteria:
- Task completed without assistance: <20 minutes
- No critical errors (blockers that prevent completion)
- Satisfaction rating: >4/5

Observations (n=5 developers):
✅ All completed task in 12-18 minutes
⚠️  3/5 were confused by "Create Component" vs "Create Service" buttons
⚠️  4/5 didn't notice deployment status indicator
✅ Average satisfaction: 4.2/5

Recommendations:
1. Merge "Create Component" and "Create Service" into one flow
2. Make deployment status more prominent (add animation)
3. Add contextual help tooltip on first use
```

## Component 3: Feedback Processing Pipeline

### 3.1 Feedback Database Schema

```sql
CREATE TABLE feedback (
  id SERIAL PRIMARY KEY,
  type VARCHAR(50) NOT NULL, -- 'bug', 'friction', 'feature-request', 'praise'
  category VARCHAR(50) NOT NULL, -- 'ci-cd', 'gitops', 'docs', 'dojo', 'other'
  description TEXT NOT NULL,
  source VARCHAR(50) NOT NULL, -- 'widget', 'mattermost', 'interview', 'github'
  
  -- Context
  user_id VARCHAR(100), -- NULL if anonymous
  user_role VARCHAR(50),
  page_context VARCHAR(200), -- Which Backstage page?
  timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
  
  -- Analysis
  sentiment VARCHAR(20), -- 'positive', 'neutral', 'negative' (AI-generated)
  themes TEXT[], -- e.g., ['performance', 'documentation', 'jenkins']
  impact_score INT, -- 1-5 based on affected users + frequency
  
  -- Lifecycle
  status VARCHAR(50) DEFAULT 'new', -- 'new', 'triaged', 'in-progress', 'resolved', 'wont-fix'
  assigned_to VARCHAR(100),
  resolution_notes TEXT,
  resolved_at TIMESTAMP
);

CREATE INDEX idx_feedback_status ON feedback(status);
CREATE INDEX idx_feedback_category ON feedback(category);
CREATE INDEX idx_feedback_timestamp ON feedback(timestamp DESC);
```

### 3.2 Automated Analysis (AI-Powered)

**Sentiment Analysis**:

```python
# Using OpenAI API for sentiment classification
def analyze_sentiment(feedback_text):
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "Classify sentiment as positive, neutral, or negative."},
            {"role": "user", "content": feedback_text}
        ]
    )
    return response.choices[0].message.content  # 'positive' | 'neutral' | 'negative'
```

**Theme Extraction**:

```python
# Identify common themes across feedback
def extract_themes(feedback_batch):
    prompt = f"""
    Analyze these {len(feedback_batch)} feedback items and identify 3-5 recurring themes.
    
    Feedback:
    {format_feedback(feedback_batch)}
    
    Return themes as a JSON array, e.g., ["performance", "documentation", "onboarding"]
    """
    # Returns: ['jenkins-slow', 'backstage-search', 'dojo-outdated', ...]
```

**Impact Scoring Algorithm**:

```python
def calculate_impact_score(feedback):
    score = 0
    
    # How many users mention similar issues?
    score += count_similar_feedback(feedback) * 2  # 0-10 points
    
    # Severity (based on type)
    severity_weights = {'bug': 3, 'friction': 2, 'feature-request': 1, 'praise': 0}
    score += severity_weights[feedback.type]
    
    # Sentiment (negative = more urgent)
    if feedback.sentiment == 'negative':
        score += 2
    
    # Recency (recent = more relevant)
    days_old = (now() - feedback.timestamp).days
    if days_old < 7:
        score += 3
    elif days_old < 30:
        score += 1
    
    return min(score, 10)  # Cap at 10
```

### 3.3 Monthly DevEx Review Meeting

**Attendees**: Platform team (5-7 people)
**Duration**: 90 minutes
**Frequency**: First Wednesday of every month

**Agenda**:

```
1. Metrics Review (15 min)
   - NPS score trend
   - DORA metrics
   - Feedback volume and sentiment

2. Feedback Deep Dive (30 min)
   - Top 5 themes from past month
   - High-impact individual issues
   - User interview synthesis

3. Prioritization (25 min)
   - Evaluate top issues (impact vs. effort)
   - Select 1-2 improvements to tackle next month
   - Assign owners and set deadlines

4. Experiment Review (15 min)
   - Did last month's changes work?
   - Measure before/after metrics
   - Lessons learned

5. Communication Planning (5 min)
   - Draft "You Said, We Did" post
   - Plan quarterly town hall content
```

**Output**:

- 1-2 committed improvements for next month
- Owners assigned with clear success criteria
- Communication plan for closing the loop

### 3.4 “You Said, We Did” Communication

**Monthly Post** (Mattermost + Email):

```markdown
## You Said, We Did - November 2024

Hey team! Here's what we heard from you last month and what we're doing about it.

### 📊 Feedback by the Numbers
- 52 feedback submissions (↑ from 41 last month)
- 5 user interviews conducted
- Overall sentiment: 68% positive, 24% neutral, 8% negative

### 🔥 Top 3 Themes We Heard
1. **Jenkins builds are slow** (18 mentions)
   👉 WE DID: Optimized build parallelism, reduced avg build time 45min → 18min
   
2. **Backstage search doesn't find docs** (12 mentions)
   👉 WE DID: Upgraded search index, now indexes TechDocs + ADRs + Mattermost
   
3. **Dojo modules are outdated** (9 mentions)
   👉 WORKING ON IT: Updating modules 6-10, target completion Dec 15

### 🎉 Wins to Celebrate
- @developer_eve completed Black Belt! 🥋
- Deployment frequency hit 2.4/day (↑ from 1.9/day)
- NPS score: 62 (↑ from 58)

### 💡 What We're Focusing on Next Month
- AI-powered code review suggestions (pilot with 3 teams)
- Improved error messages in ArgoCD
- Self-service secrets rotation

### 📣 We Want to Hear From You
- Use the feedback button in Backstage
- Join office hours (next one: Nov 20, 2pm)
- DM us anytime in #platform-feedback

Thanks for making Fawkes better! 🚀
- The Platform Team
```

**Quarterly Town Hall** (45 minutes, recorded):

- Review quarter’s progress (metrics, features delivered)
- Deep dive on 2-3 major improvements
- Roadmap preview for next quarter
- Live Q&A

## Implementation Plan

### Phase 1: Minimal Viable Feedback System (Weeks 1-2)

**Week 1: Quick Wins**

1. Create #platform-feedback Mattermost channel
1. Set up Google Form for feedback (temporary, before Backstage plugin)
1. Schedule first 3 user interviews
1. Create feedback database schema

**Week 2: First Feedback Cycle**

1. Announce feedback channels to all developers
1. Conduct first 3 user interviews
1. Collect first batch of feedback
1. Manual analysis and theme identification
1. First “You Said, We Heard” post

### Phase 2: Automation & Scale (Weeks 3-6)

**Week 3-4: Backstage Plugin**

1. Develop feedback widget Backstage plugin
1. Integrate with PostgreSQL database
1. Add AI sentiment analysis
1. Beta test with platform team
1. Launch to all developers

**Week 5-6: Process & Cadence**

1. Establish monthly DevEx review meeting
1. Create feedback analysis dashboard (Grafana)
1. Schedule bi-weekly office hours (recurring)
1. Document user research processes
1. Train platform team on facilitation

### Phase 3: Continuous Improvement (Month 2+)

1. Refine based on initial learnings
1. Add advanced features (theme clustering, trend analysis)
1. Integrate with roadmap planning tools
1. Measure impact: Are we closing the loop effectively?

## Consequences

### Positive

1. **User-Centric Culture**: Platform team stays connected to developer needs
1. **Early Problem Detection**: Catch issues before they become crises
1. **Higher Trust**: Developers feel heard and valued
1. **Better Prioritization**: Roadmap driven by validated user needs, not assumptions
1. **Continuous Learning**: Platform team develops deep domain expertise
1. **Competitive Advantage**: Great DevEx attracts and retains talent
1. **AI Readiness**: User-centric foundation amplifies AI benefits (DORA finding)
1. **Reduced Waste**: Don’t build features nobody wants
1. **Faster Adoption**: Developers embrace platform when they influence it
1. **Measurable Impact**: Can prove platform value with qualitative + quantitative data

### Negative

1. **Time Investment**: ~20% of platform team time on research and analysis
1. **Expectation Management**: Must deliver on feedback or risk losing trust
1. **Potentially Overwhelming**: Too much feedback can be paralyzing
1. **Interview Recruiting**: May struggle to get volunteers (mitigate with incentives)
1. **Analysis Burden**: Qualitative research requires skill and effort
1. **Difficult Tradeoffs**: Must say “no” to some feature requests

### Neutral

1. **Requires Facilitation Skills**: Platform team needs training on research methods
1. **Cultural Shift**: Treating developers as users requires leadership buy-in
1. **Ongoing Commitment**: This is a permanent practice, not a one-time project

## Related Decisions

- **ADR-014**: DevEx Measurement Framework (SPACE) - Quantitative complement to qualitative research
- **ADR-002**: Backstage for Developer Portal - Primary vehicle for feedback widget
- **ADR-007**: Mattermost for Collaboration - #platform-feedback channel
- **ADR-016**: Platform-as-Product - User research informs product decisions

## References

- **2025 DORA Report**: User-centric focus critical for AI success
- **Continuous Discovery Habits** (Teresa Torres): Product discovery best practices
- **The Mom Test** (Rob Fitzpatrick): How to ask good interview questions
- **Just Enough Research** (Erika Hall): Practical research for teams
- **User Interviews**: https://www.userinterviews.com/ux-research-field-guide-chapter/user-interviews

## Last Updated

December 7, 2024 - Initial version documenting user research and feedback system for Fawkes
