# Platform Consumer Persona

## Document Information

**Version**: 1.0
**Last Updated**: December 2025
**Status**: Active
**Owner**: Product Team
**Based on**: 6 interviews with product managers and business stakeholders (Nov-Dec 2025)
**Validation**: Reviewed and confirmed by 4 product and business leaders

---

## Persona: Sarah Kim - "The Value Navigator"

**Photo**: Professional photo - Asian female, 35-40, business casual attire

---

### Role and Responsibilities

**Job Title**: Senior Product Manager

**Team**: Product Management (team of 5 product managers across different squads)

**Reporting Structure**: Reports to Director of Product, cross-functional team leadership

**Key Responsibilities**:

- Define product roadmap and prioritize features based on business value
- Collaborate with engineering, design, and business stakeholders
- Track product metrics and KPIs (user engagement, revenue impact, adoption)
- Communicate progress and results to executive leadership
- Make data-driven decisions about product investments

**Time Allocation**:

- 35% on strategy and roadmap planning
- 25% on stakeholder communication and alignment
- 20% on data analysis and metrics review
- 15% on cross-functional collaboration (engineering, design, sales)
- 5% on user research and customer feedback

---

### Goals and Motivations

**Primary Goals**:

1. Deliver features that drive measurable business outcomes (revenue, user engagement)
2. Reduce time-to-market for new capabilities (from idea to production in 6 weeks or less)
3. Maintain visibility into development progress and platform health
4. Optimize resource allocation and engineering investment
5. Demonstrate ROI of platform investments to leadership

**Success Metrics**:

- Feature adoption rates (target: >60% within 3 months)
- Time from ideation to production deployment
- Platform uptime and reliability (user-facing)
- Developer velocity and satisfaction
- Business KPIs (revenue, user engagement, cost savings)

**Motivations**:

- **Professional**: Wants to build products users love and that drive business growth
- **Personal**: Enjoys solving complex problems at the intersection of technology and business
- **Team**: Values transparent communication and data-driven decision making

**What drives them at work**:

> "I need to balance what users want, what the business needs, and what engineering can deliver. The platform should empower us to move fast without sacrificing quality or visibility."

---

### Pain Points and Frustrations

**Major Pain Points**:

1. **Limited Visibility into Engineering Progress**

   - **Description**: Difficult to understand actual development status, blockers, and delivery timelines without attending multiple standups
   - **Impact**: Can't accurately communicate to stakeholders, late surprises on delays, difficulty prioritizing
   - **Frequency**: Daily - relies on Jira updates that are often outdated or incomplete
   - **Current Workaround**: Attend multiple standups, send frequent Slack messages, manual status reports

2. **Lack of Product Usage Analytics**

   - **Description**: Can't easily measure feature adoption, user engagement, or identify underutilized capabilities
   - **Impact**: Difficult to justify platform investments, can't data-drive roadmap, miss optimization opportunities
   - **Frequency**: Monthly when preparing leadership reviews
   - **Current Workaround**: Manual data collection from multiple sources, rely on anecdotal feedback from sales/support

3. **Long Time-to-Market for Platform Changes**
   - **Description**: Platform improvements and new capabilities take weeks or months to deliver, slowing product velocity
   - **Impact**: Miss market opportunities, competitive disadvantage, team frustration
   - **Frequency**: Every quarter when planning new initiatives
   - **Current Workaround**: Prioritize ruthlessly, sometimes build workarounds outside the platform

**Frustrations**:

- Difficulty translating technical platform metrics into business value
- Limited self-service access to platform insights and analytics
- Disconnected tools requiring context switching (Jira, Confluence, Grafana, Backstage)
- Unclear platform roadmap and feature availability
- Challenge balancing new features vs. platform stability

---

### Tools and Workflows

**Primary Tools**:

- **Product Management**: Jira, Confluence, Miro (for roadmapping)
- **Analytics**: Google Analytics, Mixpanel, custom dashboards
- **Communication**: Slack/Mattermost, Zoom, Email
- **Presentation**: PowerPoint, Google Slides
- **Data Analysis**: Excel, Google Sheets, Tableau
- **Platform Visibility**: Backstage (occasionally), Grafana (when needed)

**Typical Daily Workflow**:

1. **8:30 AM** - Review overnight metrics, check for incidents or anomalies
2. **9:00 AM** - Standup with engineering team, unblock issues
3. **10:00 AM** - Review PRs and feature specifications for upcoming work
4. **11:00 AM** - Stakeholder meetings (sales, marketing, executive team)
5. **12:00 PM** - Lunch
6. **1:00 PM** - Data analysis, review adoption metrics, identify trends
7. **2:00 PM** - Roadmap planning, prioritization sessions
8. **3:00 PM** - User feedback review, support ticket analysis
9. **4:00 PM** - Documentation updates, team communication
10. **5:00 PM** - Prepare for next day, review action items

**Platform Interaction Points**:

- Checks Backstage weekly to understand service catalog and dependencies
- Reviews DORA metrics monthly for leadership presentations
- Accesses Grafana dashboards when investigating user-reported issues
- Uses Jira daily to track feature progress

---

### Technical Skill Level

**Overall Technical Proficiency**: Beginner to Intermediate (Technical PM background)

**Specific Skills**:

- **Programming Languages**: Basic understanding of code concepts, can read simple Python/JavaScript
- **Cloud Platforms**: Understands AWS/Azure concepts at high level, not hands-on
- **Containers & Orchestration**: Knows what Kubernetes is, understands container benefits, not operational
- **Infrastructure as Code**: Conceptual understanding only
- **CI/CD Tools**: Understands CI/CD value, basic Jenkins/ArgoCD navigation
- **Observability**: Can read Grafana dashboards, understands key metrics (latency, error rate, throughput)

**Learning Style**: Visual learner, prefers dashboards and summaries over detailed technical documentation

**Comfort with New Tools**: Pragmatic - adopts tools that clearly improve workflow and have good UX

---

### Quotes from Research

> "I need a single place to see: What are we building? How's it going? What's the impact? Right now I have to cobble this together from 5 different tools."

> "Platform metrics like 'deployment frequency' are great, but what I really need to know is: Are users adopting our features? Are they happy?"

> "When engineering says 'the platform is down', I need to immediately understand: Which users are affected? What features are broken? When will it be fixed?"

> "I love data, but I don't have time to become a Prometheus expert. Give me a dashboard that tells the story."

---

### Behaviors and Preferences

**Communication Preferences**:

- Prefers visual dashboards and executive summaries over detailed technical reports
- Likes async updates (Slack, Confluence) but appreciates face-time for complex discussions
- Documentation style: Executive summaries with drill-down capability for details
- Feedback style: Appreciates context and business impact, not just technical facts

**Decision-Making Style**: Data-driven with consideration for business context and user impact

**Approach to Problem-Solving**: Strategic - focuses on root causes and systemic improvements, not just symptoms

**Attitude Toward Platform**: Views platform as an enabler of business value, not just technical infrastructure

---

### Needs from the Platform

**Must Have**:

1. Real-time visibility into feature deployment status and health
2. Product usage analytics and adoption metrics
3. Clear understanding of platform capabilities and roadmap
4. Single source of truth for service status and dependencies
5. Ability to communicate platform value to non-technical stakeholders

**Should Have**:

1. Integration between product metrics and platform metrics
2. Automated alerting for user-impacting issues
3. Cost visibility and optimization insights
4. Feature flag management for controlled rollouts
5. User feedback collection integrated into platform

**Nice to Have**:

1. AI-powered insights and recommendations
2. Predictive analytics for capacity planning
3. Competitive benchmarking (DORA metrics vs. industry)
4. Customer advisory board platform integration

---

### Journey Touchpoints

**Discovery**: Learns about platform capabilities through demos, team meetings, and Backstage documentation

**Onboarding**: Needs high-level overview, then drill-down into specific features as needed

**Daily Use**: Checks key dashboards, reviews feature status, monitors business metrics

**Troubleshooting**: Relies on engineering team but wants enough context to communicate with stakeholders

**Strategic Planning**: Uses platform metrics to inform roadmap decisions and resource allocation

---

## Related Resources

- [Journey Map: Product Management Workflow](../journey-maps/product-management.md)
- [Interview Transcripts](../interviews/product-managers/)
- [Research Insights](../insights/platform-visibility.md)
- [Business Value Mapping](../insights/platform-roi.md)
