# User Persona Template

## Document Information

**Version**: 1.0
**Last Updated**: December 2025
**Status**: Active
**Owner**: Product Team

---

## How to Use This Template

A persona is a fictional but data-driven representation of a key user segment. Personas help teams:

- Build empathy with users
- Make user-centered design decisions
- Prioritize features based on user needs
- Communicate user insights across teams
- Align stakeholders on target users

**Creating Your Persona:**
1. Base personas on real user research (interviews, surveys, analytics)
2. Focus on behaviors and goals, not just demographics
3. Keep it realistic and specific
4. Update regularly as you learn more
5. Create 3-5 personas max (more creates complexity without value)

---

## Persona Template

### [Persona Name]

**Photo**: [Placeholder image or description]

---

### Role and Responsibilities

**Job Title**: [e.g., Senior Platform Engineer, Application Developer]

**Team**: [e.g., Platform Engineering, Product Development]

**Reporting Structure**: [e.g., Reports to Engineering Manager]

**Key Responsibilities**:
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]
- [Responsibility 4]

**Time Allocation**:
- [X]% on [Activity 1]
- [X]% on [Activity 2]
- [X]% on [Activity 3]

---

### Goals and Motivations

**Primary Goals**:
1. [Goal 1 - What they want to achieve]
2. [Goal 2]
3. [Goal 3]

**Success Metrics**: [How they measure their own success]
- [Metric 1]
- [Metric 2]

**Motivations**:
- **Professional**: [Career advancement, skill development, recognition]
- **Personal**: [Work-life balance, learning, impact]
- **Team**: [Team success, collaboration, culture]

**What drives them at work**:
> [1-2 sentence description of core motivations]

---

### Pain Points and Frustrations

**Major Pain Points**:

1. **[Pain Point 1 Title]**
   - **Description**: [Detailed description of the problem]
   - **Impact**: [How this affects their work]
   - **Frequency**: [How often this occurs]
   - **Current Workaround**: [How they deal with it now]

2. **[Pain Point 2 Title]**
   - **Description**: [Detailed description]
   - **Impact**: [How this affects their work]
   - **Frequency**: [How often]
   - **Current Workaround**: [How they deal with it]

3. **[Pain Point 3 Title]**
   - **Description**: [Detailed description]
   - **Impact**: [How this affects their work]
   - **Frequency**: [How often]
   - **Current Workaround**: [How they deal with it]

**Frustrations**:
- [Frustration 1]
- [Frustration 2]
- [Frustration 3]

---

### Tools and Workflows

**Primary Tools**:
- **Development**: [e.g., VS Code, IntelliJ, Vim]
- **Version Control**: [e.g., Git, GitHub]
- **CI/CD**: [e.g., Jenkins, GitHub Actions]
- **Monitoring**: [e.g., Prometheus, Grafana, Datadog]
- **Communication**: [e.g., Slack, Mattermost, Email]
- **Other**: [List other critical tools]

**Typical Daily Workflow**:
1. [Morning routine - e.g., Check monitoring dashboards, review PRs]
2. [Mid-day activities - e.g., Development work, meetings]
3. [Afternoon tasks - e.g., Code reviews, documentation]
4. [End of day - e.g., Deploy to staging, update tickets]

**Platform Interaction Points**:
- [How often they interact with platform: hourly, daily, weekly]
- [Most frequently used features]
- [Critical path workflows]

---

### Technical Skill Level

**Overall Technical Proficiency**: [Beginner / Intermediate / Advanced / Expert]

**Specific Skills**:
- **Programming Languages**: [Languages and proficiency level]
- **Cloud Platforms**: [AWS/Azure/GCP experience level]
- **Containers & Orchestration**: [Docker, Kubernetes knowledge]
- **Infrastructure as Code**: [Terraform, CloudFormation, etc.]
- **CI/CD Tools**: [Proficiency level]
- **Observability**: [Monitoring, logging, tracing skills]

**Learning Style**: [e.g., Hands-on experimentation, Documentation reader, Video tutorials, Peer learning]

**Comfort with New Tools**: [Quick adopter / Cautious / Resistant to change]

---

### Quotes from Research

> "[Direct quote that captures their perspective on problem 1]"

> "[Direct quote about their goals or motivations]"

> "[Direct quote about pain points or frustrations]"

> "[Direct quote about ideal solutions or features]"

---

### Behaviors and Preferences

**Communication Preferences**:
- Prefers [Slack/Email/Face-to-face] for [type of communication]
- Documentation style: [Prefers detailed docs / Quick start guides / Video tutorials]
- Feedback style: [Direct / Diplomatic / Written / Verbal]

**Decision-Making Style**: [Data-driven / Intuition-based / Consensus-seeking]

**Approach to Problem-Solving**: [Systematic / Experimental / Collaborative]

**Attitude Toward Platform**: [Early adopter / Skeptical / Pragmatic / Enthusiastic]

---

### Needs from the Platform

**Must Have**:
1. [Critical need 1]
2. [Critical need 2]
3. [Critical need 3]

**Should Have**:
1. [Important need 1]
2. [Important need 2]

**Nice to Have**:
1. [Desired feature 1]
2. [Desired feature 2]

---

### Journey Touchpoints

**Discovery**: [How they first learn about platform features]

**Onboarding**: [How they get started with new capabilities]

**Daily Use**: [Regular interaction patterns]

**Troubleshooting**: [How they resolve issues]

**Advanced Use**: [How they leverage advanced features]

---

## Example Persona 1: Platform Engineer

### Alex Chen - "The Infrastructure Guardian"

**Photo**: [Professional photo - Asian male, 30s, casual tech company attire]

---

### Role and Responsibilities

**Job Title**: Senior Platform Engineer

**Team**: Platform Engineering (team of 8)

**Reporting Structure**: Reports to Engineering Manager, Platform Team

**Key Responsibilities**:
- Design and maintain internal developer platform (Kubernetes, ArgoCD, Jenkins)
- Ensure platform reliability, scalability, and security
- Support application teams with platform onboarding and troubleshooting
- Implement observability and monitoring solutions
- Define platform standards and best practices

**Time Allocation**:
- 40% on platform reliability and incident response
- 30% on new platform capabilities and improvements
- 20% on developer support and consultation
- 10% on documentation and knowledge sharing

---

### Goals and Motivations

**Primary Goals**:
1. Reduce platform incidents and mean time to recovery (MTTR < 30 minutes)
2. Enable developer self-service to reduce support requests by 50%
3. Achieve 99.9% platform uptime
4. Improve developer satisfaction with platform (NPS > 40)

**Success Metrics**:
- Platform uptime and reliability metrics
- Developer satisfaction scores
- Number of support tickets (downward trend)
- Time to onboard new services (< 1 day)

**Motivations**:
- **Professional**: Wants to build a world-class platform that enables elite DORA performance
- **Personal**: Enjoys solving complex infrastructure problems and automation
- **Team**: Takes pride in unblocking developers and seeing their success

**What drives them at work**:
> "I want to make infrastructure invisible. Developers should focus on business logic, not on Kubernetes YAML or CI/CD pipelines. A great platform is one that developers don't have to think about."

---

### Pain Points and Frustrations

**Major Pain Points**:

1. **Alert Fatigue and On-Call Burden**
   - **Description**: Too many false-positive alerts, unclear alert messages, and difficulty correlating alerts to root causes
   - **Impact**: Interrupts deep work, causes burnout, delays incident resolution
   - **Frequency**: 5-10 pages per week, 80% are false positives or low severity
   - **Current Workaround**: Manually correlate metrics across multiple dashboards, document runbooks for common issues

2. **Developer Self-Service Limitations**
   - **Description**: Developers frequently need platform team help for routine tasks (deployments, scaling, config changes)
   - **Impact**: Platform team becomes bottleneck, can't focus on strategic work
   - **Frequency**: 15-20 support requests per week
   - **Current Workaround**: Hold weekly office hours, maintain detailed runbooks, but still get interrupted

3. **Observability Gaps**
   - **Description**: Lack of unified view across metrics, logs, and traces; difficult to troubleshoot distributed systems
   - **Impact**: Longer incident resolution times, can't proactively identify issues
   - **Frequency**: Every incident involves hunting across multiple tools
   - **Current Workaround**: Manually correlate data from Prometheus, ELK, and Jaeger; train developers on troubleshooting

**Frustrations**:
- Spending more time on support than building
- Lack of standardization across application teams
- Difficulty measuring platform value and ROI
- Slow adoption of new platform capabilities

---

### Tools and Workflows

**Primary Tools**:
- **Development**: VS Code, Vim (for quick edits), iTerm2
- **Version Control**: Git, GitHub
- **CI/CD**: Jenkins (legacy), migrating to ArgoCD
- **Infrastructure**: Terraform, Helm, Kubernetes
- **Monitoring**: Prometheus, Grafana, Alertmanager, ELK Stack
- **Communication**: Mattermost, Zoom, Confluence

**Typical Daily Workflow**:
1. **8:00 AM** - Check Grafana dashboards, review alerts from overnight
2. **9:00 AM** - Triage support tickets, prioritize for the day
3. **10:00 AM** - Deep work on platform improvements or incidents
4. **12:00 PM** - Lunch and reading technical blogs/docs
5. **1:00 PM** - Pair with junior engineer on platform feature
6. **3:00 PM** - Developer office hours (Zoom drop-in)
7. **4:00 PM** - Review PRs, update documentation
8. **5:00 PM** - Check on deployments, hand off to next on-call

**Platform Interaction Points**:
- Monitors platform health constantly (Grafana dashboards always open)
- Deploys platform changes 2-3 times per week
- Reviews all platform-related PRs
- Responds to platform incidents within 15 minutes

---

### Technical Skill Level

**Overall Technical Proficiency**: Expert

**Specific Skills**:
- **Programming Languages**: Python (Advanced), Go (Intermediate), Bash (Expert)
- **Cloud Platforms**: AWS (Advanced), Azure (Intermediate)
- **Containers & Orchestration**: Docker (Expert), Kubernetes (Expert)
- **Infrastructure as Code**: Terraform (Advanced), Helm (Advanced)
- **CI/CD Tools**: Jenkins (Advanced), ArgoCD (Advanced), GitHub Actions (Intermediate)
- **Observability**: Prometheus (Expert), Grafana (Advanced), OpenTelemetry (Intermediate)

**Learning Style**: Hands-on experimentation, reads documentation thoroughly, contributes to open-source projects

**Comfort with New Tools**: Quick adopter of proven technologies, but cautious about introducing bleeding-edge tools to production

---

### Quotes from Research

> "I spend half my time answering questions that should be self-service. I want to build things that make me obsolete."

> "The hardest part isn't the technology—it's getting 50 developers to use the platform consistently. We need golden paths, not just documentation."

> "When an incident happens at 2 AM, I don't want to grep through logs. I need context: What changed? What's the impact? What's the fix?"

> "Developer experience is my product. If developers don't love the platform, we've failed, regardless of our uptime numbers."

---

### Behaviors and Preferences

**Communication Preferences**:
- Prefers async Mattermost for non-urgent questions
- Uses Zoom for complex troubleshooting and pairing
- Documentation style: Loves runbooks with clear decision trees
- Feedback style: Direct and technical, appreciates specificity

**Decision-Making Style**: Data-driven with pragmatic consideration of trade-offs

**Approach to Problem-Solving**: Systematic—starts with observability data, forms hypothesis, tests, then implements fix

**Attitude Toward Platform**: Passionate builder who wants to create the platform they wish they had as a developer

---

### Needs from the Platform

**Must Have**:
1. Unified observability with correlation across metrics, logs, and traces
2. Self-service developer portal for common tasks (deployments, rollbacks, logs)
3. Intelligent alerting that reduces noise and provides context
4. Clear platform documentation and runbooks
5. Infrastructure as Code for all platform components

**Should Have**:
1. DORA metrics dashboard to demonstrate platform value
2. Automated policy enforcement (security, compliance)
3. Cost visibility and optimization recommendations
4. Service dependency mapping
5. Platform API for automation

**Nice to Have**:
1. AI-powered incident analysis and recommendations
2. Automated capacity planning
3. Developer feedback collection built into platform

---

### Journey Touchpoints

**Discovery**: Evaluates new platform tools through POCs, reads vendor docs, attends webinars

**Onboarding**: Needs comprehensive documentation, architecture diagrams, and runbooks

**Daily Use**: Lives in Grafana, Kubernetes dashboards, and Mattermost support channel

**Troubleshooting**: Uses observability tools, checks recent changes (ArgoCD history), reviews logs

**Advanced Use**: Extends platform with custom metrics, builds automation scripts, contributes to platform roadmap

---

## Example Persona 2: Application Developer

### Maria Rodriguez - "The Feature Shipper"

**Photo**: [Professional photo - Latina female, 20s, startup casual attire]

---

### Role and Responsibilities

**Job Title**: Application Developer

**Team**: Product Development - Payments Team (team of 5 developers)

**Reporting Structure**: Reports to Engineering Lead, Product Development

**Key Responsibilities**:
- Develop and maintain payment processing microservices (Java/Spring Boot)
- Implement new features based on product requirements
- Fix bugs and resolve production issues
- Write unit and integration tests
- Participate in code reviews and sprint planning

**Time Allocation**:
- 60% on feature development
- 20% on bug fixes and technical debt
- 10% on meetings (standup, planning, retros)
- 10% on deployment and operations

---

### Goals and Motivations

**Primary Goals**:
1. Ship features quickly and reliably (2-week sprint cycles)
2. Minimize production bugs and incidents
3. Learn new technologies and improve coding skills
4. Maintain work-life balance (no weekend deployments or pages)

**Success Metrics**:
- Features delivered on time
- Low bug count in production
- Positive code review feedback
- Team velocity

**Motivations**:
- **Professional**: Wants to become a senior developer, improve full-stack skills
- **Personal**: Values predictable work hours, enjoys problem-solving
- **Team**: Likes collaborating with designers and product managers to ship user-facing features

**What drives them at work**:
> "I love the moment when a feature goes live and users can actually use it. I want to spend my time writing code that matters, not fighting with infrastructure."

---

### Pain Points and Frustrations

**Major Pain Points**:

1. **Deployment Complexity and Anxiety**
   - **Description**: Deploying to production is stressful—unclear deployment status, fear of breaking things, rollback is manual
   - **Impact**: Delays releases, causes after-hours deployments, high stress
   - **Frequency**: Deploys 2-3 times per sprint, each deployment takes 30-60 minutes of monitoring
   - **Current Workaround**: Deploy early in the day, keep teammates on standby, manual rollback scripts

2. **Difficult Production Troubleshooting**
   - **Description**: When production issues occur, hard to find relevant logs, unclear which service is failing
   - **Impact**: Long resolution times, interrupts feature work, need platform team help
   - **Frequency**: 1-2 production issues per month
   - **Current Workaround**: Ask platform team for help, grep through logs in multiple systems, trial and error

3. **Unclear Platform Capabilities**
   - **Description**: Doesn't know what platform features exist or how to use them (e.g., distributed tracing, feature flags)
   - **Impact**: Reinvents solutions, misses opportunities for improvement
   - **Frequency**: Ongoing
   - **Current Workaround**: Asks colleagues, searches Confluence (often outdated)

**Frustrations**:
- Time spent on operational tasks instead of feature development
- Fear of breaking production
- Waiting on platform team for support
- Inconsistent documentation

---

### Tools and Workflows

**Primary Tools**:
- **Development**: IntelliJ IDEA, Postman, Docker Desktop
- **Version Control**: Git, GitHub (uses GitHub Desktop sometimes)
- **CI/CD**: Jenkins (triggered by PR merge)
- **Monitoring**: Grafana (rarely), Kibana for logs (when necessary)
- **Communication**: Mattermost, Jira, Confluence

**Typical Daily Workflow**:
1. **9:00 AM** - Standup, check Jira tickets, read code review comments
2. **9:30 AM** - Feature development in local environment
3. **12:00 PM** - Lunch
4. **1:00 PM** - Finish feature, write tests, submit PR
5. **2:00 PM** - Code review for teammates' PRs
6. **3:00 PM** - Address PR feedback, merge to main
7. **3:30 PM** - Monitor deployment to dev environment
8. **4:00 PM** - Update Jira, plan next day's work
9. **5:00 PM** - End of day

**Platform Interaction Points**:
- Deploys to dev/staging multiple times per day (automatic via Jenkins)
- Deploys to production 2-3 times per sprint (manual trigger)
- Checks logs when investigating bugs (weekly)
- Rarely uses monitoring dashboards (only during incidents)

---

### Technical Skill Level

**Overall Technical Proficiency**: Intermediate

**Specific Skills**:
- **Programming Languages**: Java (Advanced), JavaScript (Intermediate), SQL (Intermediate)
- **Cloud Platforms**: AWS (Beginner - knows EC2, S3, RDS basics)
- **Containers & Orchestration**: Docker (Intermediate), Kubernetes (Beginner - knows basics, not comfortable with kubectl)
- **Infrastructure as Code**: Not familiar with Terraform
- **CI/CD Tools**: Jenkins (Basic usage - triggers builds, views logs), Git (Intermediate)
- **Observability**: Kibana for logs (Basic), Grafana (Beginner - can view dashboards but not create)

**Learning Style**: Prefers learning by doing, likes video tutorials and step-by-step guides, asks teammates for help

**Comfort with New Tools**: Open to new tools if they're easy to learn and improve workflow, but doesn't have time for steep learning curves

---

### Quotes from Research

> "I just want to push a button and deploy. I shouldn't need to understand Kubernetes to ship a feature."

> "When something breaks in production, I have no idea where to start. I end up bothering the platform team every time."

> "I wish I knew what tools we have. I spent a week building a feature flag system, then learned we already had one."

> "Deployment Friday? No way. Too risky. I'd rather work late Thursday than ruin my weekend."

---

### Behaviors and Preferences

**Communication Preferences**:
- Prefers Mattermost for quick questions, Zoom for pair programming
- Documentation style: Wants quick start guides with examples, not comprehensive docs
- Feedback style: Appreciates constructive code review comments with explanations

**Decision-Making Style**: Pragmatic - chooses solutions that work and are maintainable

**Approach to Problem-Solving**: Experimental - tries solutions, iterates based on results

**Attitude Toward Platform**: Grateful when platform "just works", frustrated when it's complex or opaque

---

### Needs from the Platform

**Must Have**:
1. Simple, reliable deployments with clear status
2. Easy access to application logs and errors
3. Automatic rollback when deployments fail
4. Service templates/examples for common use cases
5. Clear error messages and troubleshooting guides

**Should Have**:
1. Integrated testing environments
2. Feature flags for safe rollouts
3. Performance metrics (response time, error rate)
4. Notifications for deployment success/failure

**Nice to Have**:
1. Local development environment that matches production
2. Distributed tracing for debugging
3. Cost visibility for their services

---

### Journey Touchpoints

**Discovery**: Learns about platform features from teammates, team meetings, occasional training sessions

**Onboarding**: Needs guided tutorials and examples, watches over-the-shoulder demos

**Daily Use**: Deploys code, checks Jenkins build status, occasionally views logs

**Troubleshooting**: Searches docs, asks teammates, escalates to platform team

**Advanced Use**: Rarely explores advanced features unless specifically needed for a feature

---

## Using These Personas

### In Product Planning
- Reference personas when prioritizing features: "Does this solve Alex's alert fatigue problem?"
- Validate assumptions: "Would Maria understand this feature?"
- Test messaging: "How would we explain this to each persona?"

### In Design Reviews
- Walk through designs from each persona's perspective
- Ensure UX matches each persona's technical skill level
- Consider each persona's typical workflow

### In Sprint Planning
- Balance work across persona needs
- Use personas to write user stories: "As Maria, I want to..."
- Prioritize based on persona pain points and goals

### In Retrospectives
- Evaluate: "Did our work this sprint improve life for Alex or Maria?"
- Discuss: "What frustrations did we introduce?"

---

## Updating Personas

Review and update personas quarterly based on:
- New user research (interviews, surveys)
- Usage analytics
- Support ticket trends
- Team feedback
- Organizational changes

Keep personas alive by:
- Printing them and posting in team areas
- Referencing them in meetings
- Using them in decision-making conversations
- Gathering new quotes from ongoing research
