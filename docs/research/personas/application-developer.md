# Application Developer Persona

## Document Information

**Version**: 1.0
**Last Updated**: December 2025
**Status**: Active
**Owner**: Product Team
**Based on**: 8 interviews with application developers (Nov-Dec 2025)
**Validation**: Reviewed and confirmed by 6 development team members

---

## Persona: Maria Rodriguez - "The Feature Shipper"

**Photo**: Professional photo - Latina female, 20s, startup casual attire

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

## Related Resources

- [Journey Map: Application Development Workflow](../journey-maps/application-development.md)
- [Interview Transcripts](../interviews/application-developers/)
- [Research Insights](../insights/deployment-anxiety.md)
