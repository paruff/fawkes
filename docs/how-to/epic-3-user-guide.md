---
title: Epic 3 Product Discovery & UX User Guide
description: Comprehensive guide for using all Epic 3 Product Discovery and UX capabilities
---

# Epic 3 Product Discovery & UX User Guide

**Version**: 1.0
**Last Updated**: December 2024
**Target Audience**: Development Teams, Product Managers, UX Researchers, Platform Engineers

## Overview

This guide provides end-to-end instructions for using all Epic 3 Product Discovery & UX capabilities. Whether you're a developer giving feedback, a product manager analyzing insights, or a researcher conducting studies, you'll find what you need here.

## Table of Contents

1. [Getting Started](#getting-started)
2. [For Developers](#for-developers)
3. [For Product Managers](#for-product-managers)
4. [For UX Researchers](#for-ux-researchers)
5. [For Platform Engineers](#for-platform-engineers)
6. [Quick Reference](#quick-reference)

---

## Getting Started

### What is Epic 3?

Epic 3 adds comprehensive Product Discovery and UX capabilities to the Fawkes platform:

- **Measure** developer experience with SPACE framework
- **Listen** to feedback through multiple channels
- **Research** user needs with structured methods
- **Design** with a consistent, accessible component library
- **Analyze** actual usage with product analytics
- **Experiment** safely with feature flags
- **Discover** continuously with a weekly process

### Prerequisites

- Access to Backstage developer portal
- Mattermost account (for feedback bot and notifications)
- GitHub account (if contributing to platform)
- For researchers: Access to `docs/research/` repository

### Key Resources

- **Documentation**: All docs in `docs/` directory
- **Support Channel**: #product-discovery on Mattermost
- **Feedback Channels**: Widget, CLI, bot, or surveys
- **Design System**: https://storybook.fawkes.local

---

## For Developers

### Giving Feedback

You have **four easy ways** to give feedback about the platform:

#### 1. Backstage Widget (Quickest)

1. Look for the floating feedback button in the bottom-right corner of Backstage
2. Click it
3. Rate your experience (1-5 stars)
4. Select a category (UI/UX, Performance, Documentation, CI/CD, Other)
5. Write your feedback
6. Optionally attach a screenshot
7. Submit!

**When to use**: Quick feedback while using the platform

#### 2. CLI Tool (For Terminal Users)

**Installation**:

```bash
cd services/feedback-cli
pip install -e .
```

**Quick Submit**:

```bash
fawkes-feedback submit -r 5 -c "CI/CD" -m "Pipeline is much faster now!"
```

**Interactive Mode**:

```bash
fawkes-feedback submit -i
# Follow the prompts
```

**View Your Feedback**:

```bash
fawkes-feedback list
fawkes-feedback stats
```

**When to use**: You're already in the terminal, or you want offline queueing

📖 **Detailed Guide**: [Feedback CLI Documentation](../reference/feedback-cli.md)

#### 3. Mattermost Bot (Most Conversational)

**In any channel**:

```
@feedback The new dashboard is really helpful for tracking deployments
```

**Direct Message**:
Just DM `@feedback` with your feedback

**Check Status**:

```
@feedback status
```

**When to use**: You're already chatting in Mattermost, or you want a conversational experience

#### 4. NPS Surveys (Quarterly)

Every quarter, you'll receive an NPS survey via Mattermost DM:

> "How likely are you to recommend the Fawkes platform to a colleague? (0-10)"

Please take 60 seconds to respond - this helps us track satisfaction over time.

**When to use**: When prompted quarterly

### Logging Friction Points

Encountered something frustrating? Log it so we can improve:

**Via API** (if you have access):

```bash
curl -X POST http://space-metrics:8000/api/v1/friction-log/submit \
  -H "Content-Type: application/json" \
  -d '{
    "category": "deployment",
    "description": "Had to manually restart pod after deploy",
    "severity": "medium",
    "time_lost_minutes": 15
  }'
```

**Via Feedback Widget**: Select category "Friction/Blocker" and describe the issue

### Cognitive Load Assessment

Occasionally, you may be invited to take a cognitive load assessment (NASA-TLX) after completing a task like:

- Deploying to production
- Debugging a critical issue
- Onboarding as a new team member
- Setting up a new service

This takes 2-3 minutes and helps us understand and reduce mental workload.

### Using the Design System

If you're building UIs for the platform:

**Installation**:

```bash
npm install @fawkes/design-system
```

**Import Components**:

```javascript
import { Button, Card, Modal, Alert } from "@fawkes/design-system";
import "@fawkes/design-system/dist/styles.css";

function MyComponent() {
  return (
    <Card>
      <h2>Hello World</h2>
      <Button variant="primary">Click Me</Button>
      <Alert type="success">Operation completed!</Alert>
    </Card>
  );
}
```

**Browse Components**: Visit https://storybook.fawkes.local

📖 **Detailed Guide**: [Deploy Design System Storybook](deploy-design-system-storybook.md)

### Feature Flags (Advanced)

If you're building features that need gradual rollout or A/B testing:

**Check if Feature is Enabled**:

```javascript
import { OpenFeature } from "@openfeature/sdk";

const client = OpenFeature.getClient();
const isEnabled = await client.getBooleanValue("my-new-feature", false);

if (isEnabled) {
  // New feature code
} else {
  // Old feature code
}
```

**Request a Feature Flag**: Create a GitHub issue or ask in #platform-team

📖 **Detailed Guide**: [Feature Flags with Unleash](../reference/unleash-guide.md)

---

## For Product Managers

### Understanding Developer Experience (SPACE Metrics)

**Access the Dashboard**:

1. Go to Grafana: https://grafana.127.0.0.1.nip.io
2. Navigate to Dashboards → SPACE Metrics Dashboard
3. Select your team from the dropdown

**The Five Dimensions**:

1. **Satisfaction** - How developers feel

   - eNPS score (goal: >20)
   - Average feedback rating (goal: >4.0)
   - Based on surveys and feedback

2. **Performance** - System and delivery metrics

   - Deployment frequency (higher is better)
   - Lead time (lower is better)
   - Build success rate (goal: >90%)

3. **Activity** - Development activity levels

   - Commits per week
   - PRs merged
   - Active development days

4. **Communication** - Collaboration effectiveness

   - Mattermost messages
   - PR comments and discussions
   - Documentation contributions

5. **Efficiency** - Developer productivity
   - Time to first commit (onboarding)
   - Time to production
   - Cognitive load index (goal: <5.0)

**Interpreting Trends**:

- Look for week-over-week changes
- Compare against baseline (first measurement)
- Correlate with platform changes or team events
- All data is aggregated (minimum 5 developers) for privacy

📖 **Detailed Guide**: [SPACE Metrics Guide](space-metrics-guide.md)

### Analyzing Feedback

**Access Feedback Analytics**:

1. Go to Grafana: https://grafana.127.0.0.1.nip.io
2. Navigate to Dashboards → Feedback Analytics
3. Review metrics:
   - Feedback volume over time
   - Rating distribution (1-5 stars)
   - Category breakdown
   - Sentiment analysis (positive/neutral/negative)
   - Top pain points and feature requests

**Using Feedback API** (for deeper analysis):

```bash
# Port forward to feedback service
kubectl port-forward -n fawkes svc/feedback-service 8080:8080

# Get statistics
curl http://localhost:8080/api/v1/feedback/stats | jq .

# List recent feedback
curl http://localhost:8080/api/v1/feedback?status=validated | jq .
```

**Acting on Feedback**:

1. Review validated feedback weekly
2. Look for patterns across multiple submissions
3. Prioritize based on severity and frequency
4. Create GitHub issues for actionable items
5. Close the loop: respond to feedback submitters

### Product Analytics

**Access Analytics Dashboard** (if deployed):

1. Go to https://analytics.fawkes.local
2. Navigate to relevant dashboards:
   - Usage Trends
   - Feature Adoption
   - User Journeys
   - Funnels
   - Retention

**Key Metrics to Track**:

- **Activation**: Time to first value for new users
- **Adoption**: % of users using new features
- **Engagement**: Session duration, feature usage frequency
- **Retention**: Weekly/Monthly Active Users
- **Discovery**: Time to feature discovery

📖 **Detailed Guide**: [Product Analytics Quickstart](product-analytics-quickstart.md)
📖 **Detailed Guide**: [Event Tracking Integration](event-tracking-integration.md)

### Feature Flags & Experimentation

**Access Unleash**:

1. Go to https://unleash.fawkes.local
2. Log in with your credentials

**Creating a Feature Flag**:

1. Click "New feature toggle"
2. Name: `feature-name` (use kebab-case)
3. Description: What does this flag control?
4. Type: Release, Experiment, Operational, Kill Switch, or Permission
5. Enable: Start with OFF unless testing in dev
6. Save

**Rollout Strategies**:

1. **Gradual Rollout**:

   - Start at 10%
   - Monitor metrics for 1-2 days
   - Increase to 25%, 50%, 100% gradually

2. **User Targeting**:

   - Enable for specific users or teams first
   - Beta testers, friendly users
   - Gather feedback before wider rollout

3. **Environment-based**:
   - Dev: Always ON
   - Staging: ON for testing
   - Production: Gradual or gated

**A/B Testing**:

1. Create feature flag with variants (e.g., "control", "variant-a", "variant-b")
2. Set equal distribution (33% each)
3. Track outcomes in product analytics
4. Choose winner based on data
5. Roll out winner to 100%

### Customer Advisory Board

**Purpose**: Get strategic feedback from power users

**Meeting Cadence**: Quarterly (4 times per year)

**Agenda Template**:

1. Platform updates (15 min)
2. Roadmap preview (20 min)
3. Discussion topics (20 min)
4. Open feedback (5 min)

📖 **Detailed Guide**: [Run Advisory Board Meetings](run-advisory-board-meetings.md)

---

## For UX Researchers

### Research Repository

All research artifacts are stored in `docs/research/`:

```
docs/research/
├── personas/           # User personas
├── journey-maps/       # User journey maps
├── interviews/         # Interview notes
├── insights/           # Weekly synthesis
├── templates/          # Research templates
├── data/              # Raw data
└── assets/            # Images and diagrams
```

### Conducting User Interviews

**1. Prepare**:

- Use template: `docs/research/templates/interview-guide.md`
- Schedule 45-60 minute sessions
- Get consent for recording (if applicable)

**2. Conduct**:

- Build rapport (5 min)
- Ask open-ended questions
- Listen actively, probe deeper
- Observe behaviors, not just words

**3. Document**:

- Take detailed notes during interview
- Create summary document: `interviews/YYYY-MM-DD-participant-role.md`
- Include quotes, observations, and insights
- Tag with relevant themes

**4. Share**:

- Post summary in #ux-research Mattermost channel
- Add insights to weekly synthesis

### Creating and Updating Personas

**Location**: `docs/research/personas/`

**Template**: `docs/research/templates/persona-template.md`

**Structure**:

- Name and photo (use generic/stock)
- Role and demographics
- Goals and motivations
- Pain points and frustrations
- Current tools and workflows
- Quotes from real users
- Validation: Number of interviews

**Example**: See `personas/persona-new-developer.md`

**When to Update**:

- Quarterly review
- After major feature launches
- When user base changes significantly

### Journey Mapping

**Location**: `docs/research/journey-maps/`

**Template**: `docs/research/templates/journey-map.md`

**The 5 Key Journeys**:

1. Developer Onboarding
2. Deploying First App
3. Debugging Production Issue
4. Requesting Platform Feature
5. Contributing to Platform

**Journey Map Components**:

- **Stages**: Key phases in the journey
- **Actions**: What user does at each stage
- **Touchpoints**: Where they interact with platform
- **Pain Points**: Frustrations (⚠️)
- **Opportunities**: Improvements (✨)
- **Emotions**: How user feels (😊😐😟)
- **Metrics**: How we measure success

**Creating a Journey Map**:

1. Identify the journey to map
2. Interview 5-10 users who've completed this journey
3. List out stages, actions, touchpoints
4. Identify pain points and emotions
5. Brainstorm opportunities
6. Define success metrics
7. Create visual representation
8. Validate with users
9. Document in markdown

**Example**: See `journey-maps/01-developer-onboarding.md`

### Weekly Synthesis

**Purpose**: Distill weekly learnings into actionable insights

**Location**: `docs/research/insights/YYYY-week-WW-insights.md`

**Process**:

1. **Collect** (Monday):

   - Review feedback from all channels
   - Read interview notes
   - Check analytics data
   - Review SPACE metrics

2. **Synthesize** (Monday-Tuesday):

   - Identify patterns and themes
   - Cluster related feedback
   - Prioritize by impact and frequency

3. **Document** (Tuesday):

   - Create insights document
   - Include quotes and data
   - Suggest next steps

4. **Share** (Tuesday):
   - Post in #product-discovery
   - Present at weekly sync
   - Create GitHub issues for actions

**Insight Format**:

```markdown
## Insight: [Theme/Pattern Name]

**Evidence**:

- Feedback submissions: 5 users mentioned X
- Interview quotes: "quote from user"
- Metrics: Y decreased by Z%

**Impact**: [High/Medium/Low]

**Recommendation**: [What should we do?]

**Next Steps**: [Specific actions]
```

### Usability Testing

**When to Test**:

- Before major feature launches
- When redesigning existing features
- After receiving repeated negative feedback
- Quarterly platform health checks

**How to Test**:

1. Define goals and tasks
2. Recruit 5-8 participants
3. Prepare test script
4. Conduct moderated sessions
5. Observe and take notes
6. Synthesize findings
7. Create recommendations

📖 **Detailed Guide**: [Usability Testing Guide](usability-testing-guide.md)

### Accessibility Testing

All designs and implementations must meet WCAG 2.1 AA standards.

**Tools**:

- **Automated**: axe-core, Lighthouse CI
- **Manual**: Keyboard navigation, screen reader testing
- **Integrated**: Storybook a11y addon

📖 **Detailed Guide**: [Accessibility Testing Guide](accessibility-testing-guide.md)

---

## For Platform Engineers

### Deploying Epic 3 Components

All Epic 3 components are managed via GitOps (ArgoCD).

**Component Overview**:

| Component           | Namespace    | Deployment Type | Database          |
| ------------------- | ------------ | --------------- | ----------------- |
| SPACE Metrics       | fawkes-local | Deployment      | PostgreSQL (CNPG) |
| Feedback Service    | fawkes       | Deployment      | PostgreSQL (CNPG) |
| Feedback Bot        | fawkes       | Deployment      | N/A               |
| Feedback Automation | fawkes       | CronJob         | N/A               |
| Unleash             | fawkes       | Deployment      | PostgreSQL (CNPG) |
| Storybook           | fawkes       | Deployment      | N/A (static)      |
| Product Analytics   | fawkes       | StatefulSet     | ClickHouse        |

**Health Check**:

```bash
./scripts/health-check-epic3.sh
```

**Troubleshooting**: See [Epic 3 Operations Runbook](../runbooks/epic-3-product-discovery-operations.md)

### Monitoring and Observability

**Prometheus Metrics**:

```bash
# SPACE metrics
curl http://space-metrics:8000/metrics

# Feedback service
curl http://feedback-service:8080/metrics
```

**Grafana Dashboards**:

- Epic 3 Resource Usage
- SPACE Metrics Dashboard
- Feedback Analytics Dashboard
- Discovery Metrics Dashboard

**Logs**:

```bash
# SPACE metrics logs
kubectl logs -n fawkes-local -l app=space-metrics --tail=100

# Feedback service logs
kubectl logs -n fawkes -l app=feedback-service --tail=100

# Feedback bot logs
kubectl logs -n fawkes -l app=feedback-bot --tail=100
```

**Alerts**: See [Alert Rules](../observability/alert-rules.md)

### Backup and Recovery

**Databases**:

```bash
# Backup SPACE metrics DB
kubectl cnpg backup space-metrics-pg -n fawkes-local

# Backup feedback DB
kubectl cnpg backup feedback-db -n fawkes

# Backup Unleash DB
kubectl cnpg backup db-unleash -n fawkes
```

**Restore**: See [Disaster Recovery](../runbooks/epic-3-product-discovery-operations.md#disaster-recovery)

### API Access and Integration

**SPACE Metrics API**:

```bash
kubectl port-forward -n fawkes-local svc/space-metrics 8000:8000
curl http://localhost:8000/api/v1/metrics/space
```

**Feedback API**:

```bash
kubectl port-forward -n fawkes svc/feedback-service 8080:8080
curl http://localhost:8080/api/v1/feedback
```

**Unleash API**:

```bash
kubectl port-forward -n fawkes svc/unleash 4242:4242
curl http://localhost:4242/api/admin/features
```

📖 **Detailed Reference**: [Epic 3 API Reference](../reference/api/epic-3-product-discovery-apis.md)

---

## Quick Reference

### Feedback Channels Summary

| Channel          | When to Use                         | How to Access                    |
| ---------------- | ----------------------------------- | -------------------------------- |
| Backstage Widget | Quick feedback while using platform | Bottom-right corner of Backstage |
| CLI Tool         | Terminal users, offline support     | `fawkes-feedback submit -i`      |
| Mattermost Bot   | Conversational, already in chat     | `@feedback` or DM                |
| NPS Survey       | Quarterly satisfaction tracking     | Mattermost DM (automated)        |

### Key URLs

| Service            | URL                                | Purpose           |
| ------------------ | ---------------------------------- | ----------------- |
| Backstage          | https://backstage.127.0.0.1.nip.io | Developer portal  |
| SPACE Dashboard    | Grafana → SPACE Metrics            | DevEx measurement |
| Feedback Dashboard | Grafana → Feedback Analytics       | Feedback insights |
| Storybook          | https://storybook.fawkes.local     | Design system     |
| Unleash            | https://unleash.fawkes.local       | Feature flags     |
| Analytics          | https://analytics.fawkes.local     | Product analytics |

### Important Directories

| Path                          | Contains            |
| ----------------------------- | ------------------- |
| `docs/research/personas/`     | User personas       |
| `docs/research/journey-maps/` | User journeys       |
| `docs/research/interviews/`   | Interview notes     |
| `docs/research/insights/`     | Weekly synthesis    |
| `docs/research/templates/`    | Research templates  |
| `docs/runbooks/`              | Operations runbooks |
| `docs/reference/api/`         | API documentation   |
| `docs/how-to/`                | Step-by-step guides |

### Support Channels

| Need Help With         | Where to Ask       |
| ---------------------- | ------------------ |
| General questions      | #product-discovery |
| Feedback system issues | #platform-team     |
| Research collaboration | #ux-research       |
| Design system          | #design-system     |
| Technical issues       | #platform-support  |

### Common Commands

```bash
# Feedback CLI
fawkes-feedback submit -i
fawkes-feedback list
fawkes-feedback stats

# Health checks
./scripts/health-check-epic3.sh
kubectl get pods -n fawkes -l epic=3
kubectl get pods -n fawkes-local -l epic=3

# Port forwarding
kubectl port-forward -n fawkes-local svc/space-metrics 8000:8000
kubectl port-forward -n fawkes svc/feedback-service 8080:8080
kubectl port-forward -n fawkes svc/unleash 4242:4242

# Logs
kubectl logs -n fawkes -l app=feedback-service --tail=100
kubectl logs -n fawkes-local -l app=space-metrics --tail=100
```

---

## Related Documentation

**Runbooks & Operations**:

- [Epic 3 Operations Runbook](../runbooks/epic-3-product-discovery-operations.md)
- [Epic 3 Architecture Diagrams](../runbooks/epic-3-architecture-diagrams.md)

**API References**:

- [Epic 3 API Reference](../reference/api/epic-3-product-discovery-apis.md)

**How-To Guides**:

- [SPACE Metrics Guide](space-metrics-guide.md)
- [Product Analytics Quickstart](product-analytics-quickstart.md)
- [Deploy Design System Storybook](deploy-design-system-storybook.md)
- [Run Advisory Board Meetings](run-advisory-board-meetings.md)
- [Usability Testing Guide](usability-testing-guide.md)
- [Accessibility Testing Guide](accessibility-testing-guide.md)
- [Event Tracking Integration](event-tracking-integration.md)

**Validation Documents**:

- [AT-E3-002: SPACE Framework](../validation/AT-E3-002-IMPLEMENTATION.md)
- [AT-E3-003: Feedback System](../validation/AT-E3-003-IMPLEMENTATION.md)
- [AT-E3-004/005/009: Design System](../validation/AT-E3-004-005-009-IMPLEMENTATION.md)

**Video Resources**:

- [Epic 3 Demo Video](../tutorials/epic-3-demo-video.md)
- [Epic 3 Demo Script](../tutorials/epic-3-demo-video-script.md)

---

## Feedback on This Guide

This guide itself can be improved! If you have suggestions:

- Submit via Backstage feedback widget
- Use: `fawkes-feedback submit -c "Documentation"`
- DM @feedback in Mattermost
- Open a GitHub issue with label `documentation`

**Last Updated**: December 2024
**Maintainers**: Platform Team, Product Team, UX Research Team
