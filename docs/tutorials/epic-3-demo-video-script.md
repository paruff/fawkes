---
title: Epic 3 Demo Video Walkthrough Script
description: Comprehensive script for recording a 30-minute demo of Epic 3 Product Discovery & UX functionality
---

# Epic 3 Demo Video Walkthrough Script

**Duration**: 30 minutes
**Epic**: Product Discovery & UX
**Milestone**: M3.4 - Final Integration
**Target Audience**: Product Teams, UX Researchers, Platform Engineers, Engineering Leaders

## Overview

This document provides a comprehensive script for recording a video demonstration of the Epic 3 Fawkes Product Discovery & UX deliverables. The demo showcases the complete product discovery infrastructure, DevEx measurement (SPACE framework), multi-channel feedback system, design system, analytics, and continuous discovery process.

## Recording Prerequisites

### Technical Setup

- [ ] Local Kubernetes cluster running with Epic 1, 2, and 3 deployed
- [ ] All Epic 3 components deployed and healthy
- [ ] Screen recording software installed (OBS Studio, Loom, or similar)
- [ ] Audio recording equipment tested
- [ ] Browser windows prepared with relevant tabs
- [ ] Terminal sessions configured
- [ ] Sample data populated in all systems

### Platform Access URLs

Verify access to these services before recording:

- **Backstage Developer Portal**: `https://backstage.127.0.0.1.nip.io`
- **SPACE Metrics Dashboard**: `https://grafana.127.0.0.1.nip.io` (SPACE dashboard)
- **Feedback Analytics**: `https://grafana.127.0.0.1.nip.io` (Feedback dashboard)
- **Storybook (Design System)**: `https://storybook.fawkes.local`
- **Unleash (Feature Flags)**: `https://unleash.fawkes.local`
- **Product Analytics**: `https://analytics.fawkes.local` (if deployed)
- **Mattermost**: For feedback bot demonstration
- **Research Repository**: `docs/research/` in file browser

### Pre-Demo Checklist

- [ ] SPACE metrics showing populated data
- [ ] Feedback submissions exist in database
- [ ] Feedback bot is online in Mattermost
- [ ] Design system Storybook is accessible
- [ ] Journey maps are complete
- [ ] Feature flags are configured in Unleash
- [ ] Sample personas exist in research repository
- [ ] Grafana dashboards show data

---

## Video Script

### Segment 1: Introduction & Product Discovery Overview (3 minutes)

**[0:00-0:30] Opening**

> "Hello! Today I'm excited to walk you through Epic 3 of the Fawkes platform - our Product Discovery and User Experience capabilities. In this 30-minute demo, you'll see how we've built a comprehensive system for understanding our users, measuring developer experience, collecting feedback, and continuously improving our platform."

**[0:30-1:30] Product Discovery Philosophy**

Switch to conceptual overview:

> "Product discovery is about building the right things, not just building things right. Traditional platforms focus on delivery metrics - and we do that too with DORA in Epic 1. But Epic 3 answers a different question: How do we know we're building what developers actually need?
>
> We've implemented a multi-layered approach:
> - **Research Infrastructure** for qualitative insights
> - **SPACE Framework** for quantitative DevEx measurement
> - **Multi-Channel Feedback** to capture continuous input
> - **Product Analytics** to understand actual usage
> - **Experimentation** to validate hypotheses
> - **Design System** to ensure consistent, accessible experiences"

**[1:30-3:00] Epic 3 Key Deliverables**

> "Here's what we've built in Epic 3:
>
> 1. **User Research Infrastructure** - Personas, journey maps, interview guides
> 2. **SPACE Metrics** - Automated DevEx measurement across 5 dimensions
> 3. **Feedback System** - 4 channels: widget, CLI, bot, and NPS surveys
> 4. **Design System** - 42 components with Storybook, WCAG 2.1 AA compliant
> 5. **Product Analytics** - Event tracking and usage dashboards
> 6. **Feature Flags** - Unleash for safe rollouts and A/B testing
> 7. **Continuous Discovery** - Weekly process with advisory board
>
> Let's explore each of these in action!"

---

### Segment 2: User Research Infrastructure (4 minutes)

**[3:00-4:00] Research Repository Overview**

Navigate to `docs/research/` directory:

> "First, let's look at our research repository. This is where we centralize all our user research activities.
>
> We have five main areas:
> - **Personas** - 5 validated user personas representing our key user types
> - **Journey Maps** - 5 detailed journey maps covering critical workflows
> - **Interview Guides** - Templates for conducting user research
> - **Insights** - Weekly synthesis of findings
> - **Data** - Raw research artifacts"

**[4:00-5:00] Persona Example**

Open a persona file (e.g., `personas/persona-new-developer.md`):

> "Here's one of our personas - 'Alex the New Developer'. This persona was created from interviews with 10 recent hires. You can see:
> - Demographics and background
> - Goals and motivations
> - Pain points and frustrations
> - Current tools and workflows
> - Quotes from actual interviews
>
> This helps us empathize with our users and design for their needs."

**[5:00-6:30] Journey Map Walkthrough**

Open `journey-maps/01-developer-onboarding.md`:

> "Now let's look at a journey map - specifically the Developer Onboarding journey.
>
> This map shows the end-to-end experience of a new developer joining the team. For each stage:
> - **Touchpoints** - Where they interact with the platform
> - **Pain Points** - What frustrates them (marked in red)
> - **Opportunities** - How we can improve (marked in green)
> - **Emotion Graph** - How they feel throughout the journey
>
> We validated this with 10 developers who onboarded in the last quarter. Notice the dip in satisfaction during 'Getting Access to Tools' - this is a key opportunity for improvement that we're addressing."

**[6:30-7:00] How Research Informs Product**

> "These research artifacts aren't just documentation - they directly inform our product decisions. When we prioritize features, we reference these journey maps and personas. When we design new features, we validate them against these insights."

---

### Segment 3: SPACE Framework & DevEx Measurement (5 minutes)

**[7:00-7:30] SPACE Framework Introduction**

> "Now let's talk about developer experience measurement. We use the SPACE framework - created by GitHub, Microsoft, and academia - to quantify DevEx across five dimensions:
> - **Satisfaction** - How developers feel
> - **Performance** - System and delivery metrics
> - **Activity** - Development activity levels
> - **Communication** - Collaboration effectiveness
> - **Efficiency** - Developer productivity"

**[7:30-9:00] SPACE Metrics Dashboard**

Navigate to Grafana SPACE metrics dashboard:

> "Here's our SPACE metrics dashboard. This updates automatically every week and aggregates data from multiple sources.
>
> Let's walk through each dimension:
>
> **Satisfaction** (top left):
> - eNPS score of 45 - that's in the 'Good' range
> - Based on quarterly NPS surveys
> - Average feedback rating of 4.2 out of 5
> - We aggregate responses to protect individual privacy - we never show data for fewer than 5 developers
>
> **Performance** (top right):
> - Deployment frequency: 12.5 per week
> - Lead time: 4.2 hours
> - Build success rate: 95%
> - These tie directly to our Epic 1 DORA metrics
>
> **Activity** (middle left):
> - 85 commits per week (team average)
> - 23 PRs merged
> - 4.8 active development days
> - This helps us understand team engagement patterns
>
> **Communication** (middle right):
> - 450 Mattermost messages
> - 156 PR comments
> - 12 documentation updates
> - Healthy collaboration indicators
>
> **Efficiency** (bottom):
> - Time to first commit for new hires: 3.5 hours
> - Time to production: 8.2 hours
> - Cognitive load index: 3.8 out of 10 (lower is better)
> - These efficiency metrics help us remove friction"

**[9:00-10:30] SPACE Metrics API & Collection**

Port-forward and demo API:

```bash
kubectl port-forward -n fawkes-local svc/space-metrics 8000:8000
curl http://localhost:8000/api/v1/metrics/space | jq .
```

> "Behind the scenes, we have a SPACE metrics service with a REST API. This collects data from:
> - Prometheus for performance metrics
> - GitHub API for activity metrics
> - Mattermost API for communication metrics
> - Our feedback system for satisfaction
> - Custom surveys for cognitive load assessment
>
> Teams can also submit pulse surveys and friction logs through the API. Let me show you..."

Demo submitting a friction log:

```bash
curl -X POST http://localhost:8000/api/v1/friction-log/submit \
  -H "Content-Type: application/json" \
  -d '{
    "category": "deployment",
    "description": "Had to manually restart pod after deploy",
    "severity": "medium",
    "time_lost_minutes": 15
  }'
```

> "Friction logging is a key part of DevEx measurement. When developers hit a snag, they can quickly log it, and we track patterns over time."

**[10:30-12:00] Cognitive Load Assessment**

Show NASA-TLX assessment form:

> "We also measure cognitive load using the NASA-TLX assessment. This is a scientifically validated method for measuring mental workload.
>
> Developers can take a quick 2-minute assessment after completing a task like 'Deploying to production' or 'Debugging an incident'. They rate six dimensions on a scale of 0-100:
> - Mental demand
> - Physical demand
> - Temporal demand (time pressure)
> - Performance (how well they felt they did)
> - Effort required
> - Frustration level
>
> We aggregate these scores into our SPACE efficiency metric. The goal is to reduce cognitive load over time by improving our platform's usability."

---

### Segment 4: Multi-Channel Feedback System (5 minutes)

**[12:00-12:30] Feedback System Overview**

> "Now let's look at our multi-channel feedback system. We believe developers should be able to give feedback however and whenever is convenient for them. So we've built four channels that all feed into a central system."

**[12:30-14:00] Channel 1: Backstage Widget**

Navigate to Backstage and show feedback widget:

> "First, the Backstage widget. In the bottom right corner of our developer portal, there's a floating feedback button. Let me click it...
>
> You can:
> - Rate your experience (1-5 stars)
> - Select a category (UI/UX, Performance, Documentation, etc.)
> - Write free-form feedback
> - Attach a screenshot if helpful
> - Choose to remain anonymous or include your name
>
> Let me submit some feedback... 'The new service catalog search is much faster - great improvement!' Category: UI/UX, Rating: 5 stars. Submit.
>
> That feedback is now in our system, automatically analyzed for sentiment, and will appear in our analytics dashboard."

**[14:00-15:00] Channel 2: CLI Tool**

Switch to terminal:

> "Second channel: our CLI tool. For developers who live in the terminal, we have a command-line feedback tool.

```bash
fawkes-feedback submit -r 5 -c "CI/CD" -m "Pipeline is much faster after recent optimization"
```

> It also has an interactive mode:

```bash
fawkes-feedback submit -i
```

> This prompts you for rating, category, and message. The CLI tool even works offline - it queues feedback and syncs when you're back online."

**[15:00-16:00] Channel 3: Mattermost Bot**

Switch to Mattermost:

> "Third channel: our Mattermost bot. You can give feedback in any channel by mentioning @feedback, or just DM the bot directly.
>
> Watch what happens when I type: '@feedback The deployment experience has really improved'
>
> The bot uses NLP to analyze my message, automatically categorizes it as 'CI/CD', detects positive sentiment, and confirms receipt. It then asks if I want to add more detail. This makes feedback as easy as sending a chat message."

**[16:00-17:00] Channel 4: NPS Surveys**

Show example NPS survey:

> "Fourth channel: automated NPS surveys. Every quarter, we send a Net Promoter Score survey via Mattermost DM:
>
> 'How likely are you to recommend the Fawkes platform to a colleague? (0-10)'
>
> Followed by: 'What's the main reason for your score?'
>
> This gives us a standardized satisfaction metric we can track over time. Our current NPS is +45, which translates to an eNPS (employee NPS) in the 'Good' range."

**[17:00-17:30] Feedback Analytics Dashboard**

Navigate to Grafana feedback dashboard:

> "All four channels feed into our feedback analytics dashboard. Here you can see:
> - Feedback volume over time
> - Breakdown by rating and category
> - Sentiment analysis results
> - Response rate and engagement metrics
> - Top pain points and feature requests
>
> This gives product and platform teams a real-time pulse on how developers feel about the platform."

---

### Segment 5: Design System & Storybook (4 minutes)

**[17:30-18:00] Design System Introduction**

> "Moving to our design system. A consistent, accessible design language is crucial for a good developer experience. We've built a comprehensive component library documented in Storybook."

**[18:00-19:30] Storybook Walkthrough**

Navigate to Storybook (`https://storybook.fawkes.local`):

> "Welcome to our design system Storybook. On the left, you see our component library organized by category:
> - Foundations (colors, typography, spacing)
> - Components (buttons, forms, cards, modals)
> - Patterns (navigation, data display, feedback)
>
> We have 42 components currently. Let me click on 'Button' to show you what each component page includes:
>
> **Overview Tab**:
> - Interactive component preview
> - Props/controls to play with variants
> - Code example showing how to use it
>
> **Docs Tab**:
> - Detailed usage guidelines
> - Do's and Don'ts
> - Accessibility considerations
> - Design tokens used
>
> **Accessibility Tab** (from a11y addon):
> - Automated WCAG 2.1 AA checks
> - Violations (if any) are highlighted
> - Our goal is >90% compliance
>
> Let me show you our accessibility scores..."

**[19:30-20:30] Design Tokens & Accessibility**

Show design tokens and accessibility features:

> "We use design tokens for consistency. These are the atomic values like colors, spacing, and typography that all components use. For example:
> - `color-primary-500` - our primary blue
> - `spacing-md` - 16px
> - `font-size-lg` - 18px
>
> These are defined once and used everywhere, making it easy to maintain consistency and rebrand if needed.
>
> For accessibility, every component is:
> - Tested with axe-core (automated accessibility testing)
> - Keyboard navigable
> - Screen reader compatible
> - Meeting WCAG 2.1 AA standards
> - Color contrast verified
>
> We even integrate this into our CI/CD - the build fails if accessibility scores drop below 90%."

**[20:30-21:30] Using the Design System**

Show code example:

> "Using the design system in your app is simple. Install the npm package:

```bash
npm install @fawkes/design-system
```

Then import components:

```javascript
import { Button, Card, Modal } from '@fawkes/design-system';
import '@fawkes/design-system/dist/styles.css';

function MyApp() {
  return (
    <Card>
      <h2>Hello World</h2>
      <Button variant="primary">Click me</Button>
    </Card>
  );
}
```

> This ensures every application built on Fawkes has a consistent, accessible UI out of the box."

---

### Segment 6: Product Analytics & Feature Flags (4 minutes)

**[21:30-22:30] Product Analytics Overview**

Navigate to product analytics dashboard (if deployed):

> "Next, let's look at product analytics. We track how developers actually use the platform, which features are popular, and where they get stuck.
>
> Our analytics dashboard shows:
> - **Usage Trends**: Active users, session duration, feature adoption
> - **User Journeys**: How do developers navigate through tasks
> - **Funnels**: Where do developers drop off (e.g., service creation funnel)
> - **Retention**: Are developers coming back and using the platform regularly
> - **Discovery Metrics**: Time to discovery, usage depth
>
> For example, this funnel shows the 'Create Service' journey:
> 1. Visit Backstage: 100 users
> 2. Click 'Create': 85 users (85%)
> 3. Choose template: 75 users (75%)
> 4. Complete form: 60 users (60%)
> 5. Service created: 55 users (55%)
>
> We have a 15% drop-off at 'Complete form' - that's an opportunity to simplify the form or provide better guidance."

**[22:30-23:30] Event Tracking**

Show code example of event tracking:

> "Behind the scenes, we use event tracking. When a developer performs an action in Backstage or other UIs, we capture it:

```javascript
analytics.track('service_created', {
  template: 'java-service',
  environment: 'dev',
  component: 'backstage'
});
```

> These events are sent to our analytics platform (PostHog or Plausible) and power all the dashboards you just saw.
>
> We're careful about privacy - we anonymize user IDs and don't collect sensitive data. The goal is to understand patterns, not surveil individuals."

**[23:30-25:00] Feature Flags with Unleash**

Navigate to Unleash UI:

> "Now let's look at feature flags with Unleash. Feature flags let us:
> - Roll out new features gradually
> - A/B test different approaches
> - Kill switch problematic features instantly
> - Target specific users or teams
>
> Here in the Unleash UI, you see our current feature flags. Let me show you one: 'new-dashboard-ui'
>
> **Strategy**: Gradual Rollout
> - Currently at 50% rollout
> - Started at 10%, monitored metrics, increased to 25%, 50%
> - Planning to go to 100% next week if metrics look good
>
> **Metrics**: In the last hour:
> - 1,500 users saw the new dashboard
> - 500 users saw the old dashboard
> - We're tracking satisfaction scores for both groups
>
> If the new dashboard causes issues, I can instantly toggle it off with one click - no deployment required. That's the power of feature flags."

**[25:00-25:30] OpenFeature SDK**

Show code example:

> "In code, we use the OpenFeature SDK, which is vendor-neutral:

```javascript
import { OpenFeature } from '@openfeature/sdk';

const client = OpenFeature.getClient();
const useNewDashboard = await client.getBooleanValue('new-dashboard-ui', false);

if (useNewDashboard) {
  return <NewDashboard />;
} else {
  return <OldDashboard />;
}
```

> This makes it easy to control features from Unleash without changing code."

---

### Segment 7: Continuous Discovery Process (3 minutes)

**[25:30-26:30] Discovery Workflow**

Show discovery workflow diagram or calendar:

> "Finally, let's talk about our continuous discovery process. Product discovery isn't a one-time activity - it's an ongoing practice woven into our weekly rhythm.
>
> **Our Weekly Cadence**:
>
> **Monday**: Planning & Synthesis
> - Review last week's feedback, metrics, and research findings
> - Identify patterns and update journey maps
> - Prioritize opportunities for the week
>
> **Tuesday-Wednesday**: Exploration
> - Conduct 1-2 user interviews
> - Run usability tests on prototypes
> - Gather feedback on new features
>
> **Thursday**: Validation
> - Review A/B test results from feature flags
> - Analyze product analytics data
> - Quick pulse surveys if needed
>
> **Friday**: Documentation & Planning
> - Update research repository
> - Share insights in Mattermost #product-discovery
> - Plan next week's research activities"

**[26:30-27:30] Advisory Board**

Show advisory board documentation:

> "We also have a Customer Advisory Board that meets quarterly. This is a group of 10-12 power users who:
> - Provide strategic feedback on our roadmap
> - Participate in early access programs
> - Act as evangelists for the platform
> - Give us direct access to developer needs
>
> We documented our advisory board setup in `docs/how-to/run-advisory-board-meetings.md` including:
> - How to recruit members
> - Meeting agenda templates
> - How to synthesize feedback
> - Recognizing and rewarding participation"

**[27:30-28:30] Research to Product Pipeline**

Show example of insight → feature:

> "Here's a real example of our discovery process in action:
>
> **Week 1**: Through friction logging, we noticed 15 developers reported issues with 'slow documentation search'
>
> **Week 2**: We interviewed 5 developers to understand the problem deeper. They were using Backstage's default search which only searched titles, not content.
>
> **Week 3**: We prototyped an improved search that indexes full-text. Tested with 3 developers. Positive feedback.
>
> **Week 4**: Released improved search behind a feature flag at 25% rollout. Monitored: search success rate improved from 45% to 78%.
>
> **Week 5**: Gradually rolled out to 100%. Overall satisfaction score improved by 0.3 points.
>
> This insight came from our feedback system, was validated through user research, tested with feature flags, and measured with analytics. That's continuous discovery in action!"

---

### Segment 8: Wrap-Up & Key Takeaways (2 minutes)

**[28:30-29:30] Summary of Epic 3 Value**

> "Let me summarize what we've built in Epic 3 and why it matters:
>
> **1. We Know Our Users**: Through personas and journey maps, we deeply understand who we're building for.
>
> **2. We Measure DevEx**: SPACE framework gives us quantitative data on developer experience across 5 dimensions.
>
> **3. We Listen Continuously**: 4 feedback channels make it easy for developers to share input anytime, anywhere.
>
> **4. We Design Consistently**: 42-component design system with Storybook ensures accessible, cohesive experiences.
>
> **5. We Understand Usage**: Product analytics shows us what developers actually do, not just what they say.
>
> **6. We Experiment Safely**: Feature flags let us validate hypotheses with gradual rollouts and A/B tests.
>
> **7. We Discover Continuously**: Weekly cadence ensures we're always learning and improving.
>
> The result? We're not just building a platform - we're building the RIGHT platform based on real user needs."

**[29:30-30:00] Call to Action & Resources**

> "All of this is documented in our Epic 3 docs:
> - Operations runbook for maintaining these systems
> - API reference for integrating with them
> - Architecture diagrams showing how it all fits together
> - Journey maps and personas in docs/research/
>
> If you have questions or want to learn more, join us in #product-discovery on Mattermost.
>
> Thanks for watching, and happy discovering!"

---

## Post-Production Checklist

After recording:

- [ ] Edit for length (target 30 minutes, acceptable 28-32 minutes)
- [ ] Add title cards for each segment
- [ ] Add captions/subtitles for accessibility
- [ ] Include links to documentation in video description
- [ ] Add chapter markers in video platform
- [ ] Create thumbnail image
- [ ] Review and get feedback before publishing
- [ ] Upload to YouTube and link in docs

## Related Documentation

- [Epic 3 Operations Runbook](../../runbooks/epic-3-product-discovery-operations.md)
- [Epic 3 Architecture Diagrams](../../runbooks/epic-3-architecture-diagrams.md)
- [Epic 3 API Reference](../../reference/api/epic-3-product-discovery-apis.md)
- [Demo Video Checklist](epic-3-demo-video-checklist.md)
- [Demo Video Access](epic-3-demo-video.md)
