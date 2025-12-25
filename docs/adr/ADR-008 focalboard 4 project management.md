# ADR-008: Focalboard for Project Management

## Status

**Accepted** - October 7, 2025

## Context

Fawkes is a comprehensive Internal Product Delivery Platform that integrates infrastructure, collaboration, learning, and project management. While we've addressed collaboration needs with Mattermost (ADR-007), teams need integrated project management capabilities to:

- **Track Platform Work**: Sprint planning, roadmap visualization, backlog management
- **Manage Product Delivery**: Feature planning, release management, dependency tracking
- **Coordinate Dojo Learning**: Track learner progress, module completion, assessment status
- **Visualize Workflows**: Kanban boards, calendars, tables for different team needs
- **Enable Self-Service**: Teams manage their own work without external tools

### The Need for Integrated Project Management

**Current Gap**: Teams using Fawkes must use external tools for:

- **Sprint Planning**: Jira, Azure DevOps, Linear, or spreadsheets
- **Roadmap Visualization**: Separate roadmapping tools (ProductPlan, Aha!)
- **Task Management**: Trello, Asana, Monday.com, or GitHub Projects
- **Learner Progress Tracking**: Manual spreadsheets or LMS platforms
- **Resource Planning**: Disconnected from delivery platform

**Problems with External Tools**:

- **Context Switching**: Jump between platforms (Fawkes → Jira → Confluence)
- **Integration Overhead**: Custom integrations required, often fragile
- **Data Silos**: Work tracking separate from actual delivery metrics
- **Access Control**: Different permission models, SSO complexity
- **Cost**: Commercial tools expensive at scale (Jira: $7-14/user/month)
- **Vendor Lock-In**: Proprietary data formats, migration challenges

### Requirements for Project Management Tool

1. **Self-Hosted & Open Source**: Aligns with Fawkes values, data sovereignty
2. **Native Mattermost Integration**: Seamless with our collaboration platform
3. **Multiple View Types**: Boards (Kanban), tables, calendar, gallery
4. **Dojo Integration**: Track learner progress, module completion, assessments
5. **DORA Metrics Connection**: Link work items to deployments and metrics
6. **Flexible & Lightweight**: Not overly complex like Jira, but powerful enough
7. **Developer-Friendly**: API for automation, CLI support, GitOps integration
8. **Template System**: Pre-built templates for sprints, roadmaps, dojo tracking
9. **Real-Time Collaboration**: Multiple users editing simultaneously
10. **Mobile Support**: iOS and Android apps for on-the-go updates

### Forces at Play

**Technical Forces**:

- Need to track both platform development and team usage
- Dojo learner progress requires structured tracking
- Sprint planning needs integration with CI/CD metrics
- Multiple stakeholders with different view preferences

**Business Forces**:

- Cost consciousness (avoid per-user fees)
- Data sovereignty and compliance requirements
- Desire for unified platform experience
- Open source community expectations

**User Experience Forces**:

- Teams familiar with Trello/Jira/Asana expect similar UX
- Learning curve for new tools creates friction
- Mobile access increasingly important
- Real-time collaboration expected

**Integration Forces**:

- Must integrate deeply with Mattermost (discussions, notifications)
- Should connect to DORA metrics and deployments
- Needs SSO with platform authentication
- API for automation and custom workflows

## Decision

**We will use Focalboard as the integrated project management tool for Fawkes.**

Specifically:

- **Focalboard bundled with Mattermost** (native integration)
- **Self-hosted deployment** in Kubernetes alongside Mattermost
- **Deep integration** with Mattermost channels (board discussions, notifications)
- **Custom templates** for dojo tracking, sprint planning, platform roadmaps
- **Backstage integration** via iframe or custom plugin for visibility

### Rationale

1. **Native Mattermost Integration**: Focalboard is developed by Mattermost, Inc. and integrates seamlessly:

   - Built into Mattermost (no separate deployment complexity)
   - Linked discussions (board cards → Mattermost threads)
   - Unified notifications (updates appear in Mattermost)
   - Single SSO and permission model
   - Share boards directly in channels

2. **Open Source & Self-Hosted**: Fully open source (MIT/Apache 2.0), aligns with Fawkes values, complete control over data

3. **Notion-Like Experience**: Modern, intuitive UX inspired by Notion:

   - Flexible databases with custom properties
   - Multiple views (board, table, calendar, gallery)
   - Rich content (markdown, embeds, checklists)
   - Templates for quick setup

4. **Perfect for Dojo Tracking**: Ideal for tracking learner progress:

   - Board per belt level (White, Yellow, Green, Brown, Black)
   - Cards represent learners with completion status
   - Custom properties: score, time spent, assessment results
   - Calendar view for cohort scheduling
   - Gallery view for learner profiles

5. **Lightweight & Fast**: Unlike Jira, Focalboard is lightweight:

   - Fast page loads, responsive UI
   - Simple setup, minimal configuration
   - Not overly complex for small teams
   - Scales well to large teams when needed

6. **Developer-Friendly**:

   - REST API for automation
   - Import/export in JSON format
   - Can integrate with CI/CD pipelines
   - Archive and backup easily

7. **Cost Effectiveness**:

   - Free with Mattermost (no additional cost)
   - No per-user fees
   - Only infrastructure costs (already paying for Mattermost)

8. **Multiple Use Cases**:

   - **Sprint Planning**: Kanban boards for backlog → in progress → done
   - **Roadmap Visualization**: Timeline view for quarters/releases
   - **Dojo Tracking**: Learner progress boards with custom properties
   - **Incident Management**: Board for tracking incidents and postmortems
   - **Team OKRs**: Tables for objectives and key results
   - **Content Calendar**: Calendar view for blog posts, webinars

9. **Mobile Support**: Native mobile apps for iOS and Android (via Mattermost apps)

10. **Active Development**: Actively maintained by Mattermost with regular updates

11. **Familiar UX**: Similar to Trello/Notion/Asana, reducing learning curve

## Consequences

### Positive

✅ **Unified Platform Experience**: Single ecosystem eliminates context switching (chat → boards → tasks)

✅ **Seamless Collaboration**: Discuss board cards directly in Mattermost channels

✅ **Perfect Dojo Tracking**: Custom boards track learner progress, module completion, assessment scores

✅ **Cost Effective**: No additional cost beyond Mattermost infrastructure

✅ **Data Sovereignty**: Complete control over project data, no third-party access

✅ **Flexible Views**: Teams choose board, table, calendar, or gallery based on needs

✅ **Real-Time Updates**: Collaborative editing, changes visible immediately

✅ **Simple Setup**: Minimal configuration, template-based quick start

✅ **Open Source Alignment**: Demonstrates commitment to open source stack

✅ **Developer Automation**: API enables custom workflows and integrations

✅ **Template Ecosystem**: Can create and share templates for common workflows

### Negative

⚠️ **Less Mature Than Jira**: Newer product (launched 2021), fewer advanced features

⚠️ **Smaller Ecosystem**: Fewer third-party integrations compared to Jira/Asana

⚠️ **Limited Reporting**: Basic analytics, lacks advanced reporting of Jira

⚠️ **No Native Time Tracking**: Requires custom properties or external integration

⚠️ **Simpler Workflow Engine**: Less complex workflows than Jira (but this is often a benefit)

⚠️ **Dependency Management**: Limited dependency tracking between cards

⚠️ **Resource Management**: No built-in capacity planning or resource allocation

⚠️ **Learning Curve**: Teams need to learn new tool (mitigated by familiar UX)

⚠️ **Feature Gaps**: Some Jira power-user features don't exist

### Neutral

◽ **Bundled vs. Standalone**: Can deploy standalone but better bundled with Mattermost

◽ **Enterprise Features**: Some features in paid Mattermost Enterprise edition

◽ **Customization**: Less customizable than Jira but easier to configure

### Mitigation Strategies

1. **Maturity Concerns**:

   - Start with core use cases (sprint planning, dojo tracking)
   - Contribute features back to open source project
   - Build custom extensions via API where needed
   - Monitor roadmap for feature additions

2. **Reporting Limitations**:

   - Export data to Grafana for advanced analytics
   - Build custom dashboards using REST API
   - Integrate with DORA metrics for delivery insights
   - Create weekly/monthly summary reports

3. **Time Tracking**:

   - Use custom properties for estimated/actual time
   - Integrate with external time tracking if needed
   - Consider building simple time-tracking plugin

4. **Workflow Complexity**:

   - Keep workflows simple (aligns with agile principles)
   - Use Mattermost bot commands for complex automations
   - Document standard workflows in templates

5. **Dependency Management**:

   - Use linked cards feature for simple dependencies
   - Document complex dependencies in card descriptions
   - Consider building dependency visualization

6. **Adoption**:
   - Create video tutorials
   - Provide pre-built templates
   - Show integration benefits (Mattermost notifications, DORA links)
   - Run pilot with one team before broader rollout

## Alternatives Considered

### Alternative 1: Jira (SaaS or Self-Hosted)

**Pros**:

- Industry-standard for software teams
- Extremely powerful and feature-rich
- Extensive reporting and analytics
- Huge marketplace of plugins (1,000+)
- Advanced workflow engine
- Time tracking, resource management, roadmaps
- Familiar to most development teams
- Strong integration ecosystem

**Cons**:

- **Cost**: $7.75-$14.50/user/month SaaS, or $42,000+ for self-hosted Data Center
- **Complexity**: Notoriously complex, requires dedicated admin
- **Performance**: Often slow, especially self-hosted
- **Vendor Lock-In**: Proprietary data format, difficult to migrate
- **No Native Mattermost Integration**: Requires custom webhooks
- **Heavy Resource Requirements**: Self-hosted needs significant infrastructure
- **Not Open Source**: Proprietary software, no source code access
- **Misaligned Values**: Commercial SaaS doesn't align with open source platform

**Reason for Rejection**: Cost is prohibitive for open source project (at 500 users: $46,500-$87,000/year). Complexity overkill for most teams. Self-hosted Data Center extremely expensive and complex to operate. No native Mattermost integration. Proprietary nature conflicts with Fawkes' open source values.

### Alternative 2: Taiga

**Pros**:

- Open source (AGPL license)
- Self-hosted and free
- Built for agile teams (Scrum/Kanban)
- Beautiful, modern UI
- Epics, user stories, tasks, issues
- Sprint planning and burndown charts
- Time tracking and velocity reports
- Wiki for documentation
- Active community

**Cons**:

- **No Mattermost Integration**: Separate platform, no native integration
- **Separate Deployment**: Another service to deploy and maintain
- **Different Tech Stack**: Django/Angular vs. Go/React
- **More Complex**: Feature-rich but steeper learning curve than Focalboard
- **Resource Overhead**: Separate database, more infrastructure
- **Mobile App Quality**: Mobile apps less polished
- **Harder to Customize**: Codebase more complex to extend

**Reason for Rejection**: While excellent tool, running separate platform defeats unified platform vision. No Mattermost integration means context switching. Deployment and maintenance overhead higher than bundled Focalboard. More complexity than needed for most use cases.

### Alternative 3: Plane

**Pros**:

- Open source (AGPL license)
- Modern, beautiful UI (Linear-inspired)
- Fast and lightweight
- Built for engineering teams
- Cycles, modules, views
- Real-time collaboration
- Self-hosted option
- Active development

**Cons**:

- **Very New**: Launched 2023, still maturing
- **No Mattermost Integration**: Separate platform
- **Smaller Community**: Newer project, less proven
- **Limited Documentation**: Still building out docs
- **Feature Set Evolving**: Core features still being added
- **No Mobile Apps Yet**: Web-only currently
- **Separate Infrastructure**: Another service to deploy
- **Unknown Stability**: Too new to assess long-term viability

**Reason for Rejection**: Too new and unproven for critical platform component. No Mattermost integration. Separate deployment adds complexity. While promising, risk too high for early-stage project. Revisit in 1-2 years when more mature.

### Alternative 4: GitHub Projects

**Pros**:

- Free and unlimited
- Native GitHub integration
- Familiar to developers
- Board, table, and roadmap views
- Issue and PR linking
- GitHub Actions automation
- No separate deployment needed
- Already using GitHub

**Cons**:

- **Limited to Code Repositories**: Not general-purpose project management
- **Basic Features**: Lacks advanced PM capabilities
- **No Mattermost Integration**: Separate platform, notifications via email
- **Poor for Non-Code Work**: Not suitable for dojo tracking, general planning
- **No Standalone Boards**: Tied to repositories
- **Limited Customization**: Can't customize fields, workflows much
- **Not Self-Hosted**: GitHub is SaaS (even with GitHub Enterprise)
- **No Real-Time Collaboration**: More static than Focalboard/Jira

**Reason for Rejection**: GitHub Projects excellent for code-centric work but too limited for general project management. Not suitable for dojo learner tracking, team planning, roadmaps. No Mattermost integration. Can complement Focalboard but not replace it.

### Alternative 5: Trello (SaaS)

**Pros**:

- Simple, intuitive Kanban boards
- Free tier available
- Widely known and used
- Power-Ups for extensions
- Mobile apps excellent
- Real-time collaboration
- Butler automation
- Visual and easy to learn

**Cons**:

- **SaaS Only**: No self-hosted option, data on Atlassian servers
- **Cost at Scale**: $5-$17.50/user/month for paid tiers
- **Limited Views**: Primarily Kanban, limited table/calendar
- **Basic Features**: Less powerful than Jira/Focalboard for complex needs
- **No Mattermost Integration**: Separate platform
- **Vendor Lock-In**: Proprietary, owned by Atlassian
- **Not Open Source**: Closed source, can't customize deeply
- **Data Export Limited**: Proprietary format

**Reason for Rejection**: SaaS-only conflicts with self-hosted platform vision. Cost adds up at scale. No Mattermost integration. Atlassian ownership means potential future pricing changes. Too basic for complex project management needs.

### Alternative 6: Wekan

**Pros**:

- Open source (MIT license)
- Self-hosted and free
- Kanban boards (Trello-like)
- Lightweight and simple
- Docker deployment easy
- Multiple languages
- Integrations via webhooks

**Cons**:

- **Limited Features**: Very basic compared to alternatives
- **Development Pace**: Slower development, smaller team
- **No Mattermost Integration**: Separate platform
- **Single View Type**: Only Kanban boards, no tables/calendars
- **Basic Customization**: Limited custom fields
- **Mobile Experience**: Web-only, no native apps
- **Smaller Community**: Less active than alternatives

**Reason for Rejection**: While simple and open source, too basic for needs. No Mattermost integration. Limited to Kanban view. Would need to run separately. Focalboard provides much richer feature set with same self-hosted benefits.

### Alternative 7: Notion (SaaS)

**Pros**:

- Excellent UX, beautiful design
- Flexible databases with multiple views
- Rich content editing (markdown, embeds)
- Templates and team collaboration
- Real-time updates
- Mobile apps excellent
- Integrations and API
- Very popular with teams

**Cons**:

- **SaaS Only**: No self-hosted option
- **Cost**: $8-$15/user/month for teams
- **Vendor Lock-In**: Proprietary platform and format
- **No Mattermost Integration**: Separate platform
- **Performance**: Can be slow with large databases
- **Data Sovereignty**: All data on Notion servers
- **Not Open Source**: Closed source, can't customize
- **Export Limitations**: Limited export options

**Reason for Rejection**: SaaS-only and proprietary conflicts with values. No self-hosting option. No Mattermost integration. Cost at scale. Focalboard provides Notion-like experience in open source, self-hosted package.

## Related Decisions

- **ADR-007**: Mattermost for Team Collaboration (Focalboard integrates natively)
- **Future ADR**: Backstage Plugin for Focalboard (embed boards in developer portal)
- **Future ADR**: DORA Metrics Integration (link deployments to board cards)

## Implementation Notes

### Deployment Architecture

```yaml
# Focalboard bundled with Mattermost
mattermost:
  namespace: fawkes-collaboration
  components:
    - mattermost-app:
        focalboard:
          enabled: true
          settings:
            enablePublicSharedBoards: true
            enableDataRetention: true

  integrations:
    - mattermost-channels (board discussions)
    - backstage (iframe embed)
    - dora-metrics-service (link cards to deployments)
```

### Initial Board Templates

**1. Sprint Planning Board**

```yaml
template: "Sprint Planning"
views:
  - type: board
    columns: ["Backlog", "This Sprint", "In Progress", "Review", "Done"]
  - type: table
    groupBy: "Priority"
  - type: calendar
    dateProperty: "Due Date"

properties:
  - name: "Priority"
    type: select
    options: ["P0", "P1", "P2", "P3"]
  - name: "Estimate"
    type: number
  - name: "Assignee"
    type: person
  - name: "Component"
    type: multiSelect
    options: ["Backstage", "Jenkins", "ArgoCD", "Observability", "Security"]
  - name: "Sprint"
    type: select
  - name: "Story Points"
    type: number
```

**2. Dojo Learner Progress Board**

```yaml
template: "Dojo - White Belt"
views:
  - type: board
    columns: ["Not Started", "Module 1", "Module 2", "Module 3", "Module 4", "Assessment", "Certified"]
  - type: table
    groupBy: "Status"
  - type: gallery
    cardCover: "profile_image"

properties:
  - name: "Learner Name"
    type: text
  - name: "Email"
    type: email
  - name: "Start Date"
    type: date
  - name: "Target Completion"
    type: date
  - name: "Modules Completed"
    type: number
  - name: "Assessment Score"
    type: number
  - name: "Time Spent (hours)"
    type: number
  - name: "Status"
    type: select
    options: ["Not Started", "In Progress", "Assessment", "Certified", "On Hold"]
  - name: "Notes"
    type: text
```

**3. Platform Roadmap Board**

```yaml
template: "Platform Roadmap"
views:
  - type: board
    columns: ["Idea", "Planned", "In Development", "Testing", "Released"]
  - type: table
    groupBy: "Quarter"
  - type: calendar
    dateProperty: "Target Date"

properties:
  - name: "Feature"
    type: text
  - name: "Quarter"
    type: select
    options: ["Q4 2025", "Q1 2026", "Q2 2026", "Q3 2026", "Q4 2026"]
  - name: "Impact"
    type: select
    options: ["High", "Medium", "Low"]
  - name: "Effort"
    type: select
    options: ["Small", "Medium", "Large", "XL"]
  - name: "Owner"
    type: person
  - name: "Target Date"
    type: date
  - name: "Status"
    type: select
  - name: "Dependencies"
    type: text
```

**4. Incident Management Board**

```yaml
template: "Incident Tracking"
views:
  - type: board
    columns: ["Reported", "Investigating", "Fixing", "Monitoring", "Resolved"]
  - type: table
    sortBy: "Severity"

properties:
  - name: "Incident ID"
    type: text
  - name: "Severity"
    type: select
    options: ["SEV1", "SEV2", "SEV3", "SEV4"]
  - name: "Reported By"
    type: person
  - name: "Incident Commander"
    type: person
  - name: "Reported At"
    type: dateTime
  - name: "Resolved At"
    type: dateTime
  - name: "MTTR (minutes)"
    type: number
  - name: "Affected Services"
    type: multiSelect
  - name: "Root Cause"
    type: text
  - name: "Postmortem Link"
    type: url
```

### Mattermost Integration Examples

**1. Board Updates in Channels**:

```
[Focalboard Bot] 📋 Card moved in "Sprint 01"
@john moved "Implement DORA metrics"
From: In Progress → Review
Board: https://mattermost.fawkes.io/boards/abc123
```

**2. Card Discussions**:

```
User clicks "Discuss in Mattermost" on card
→ Creates thread in linked channel
→ Thread automatically linked back to card
→ Comments sync bidirectionally
```

**3. Daily Stand-up Automation**:

```
[Focalboard Bot] 📊 Daily Stand-up - Sprint 01
Cards completed yesterday: 3
Cards in progress: 7
Blocked cards: 1 ⚠️

@alice: 2 cards in review
@bob: Working on "Security scanning" (blocked)
@carol: Completed "Deploy Backstage"
```

### Backstage Integration

- **Phase 1**: Iframe embed in Backstage (boards visible in developer portal)
- **Phase 2**: Custom Backstage plugin (`@fawkes/plugin-focalboard`)
- **Phase 3**: Deep integration (create cards from Backstage, link to services)

### DORA Metrics Integration

Link board cards to deployments:

```javascript
// When deployment completes
POST /focalboard/api/cards/{cardId}/properties
{
  "deployed": true,
  "deployment_time": "2025-10-07T14:30:00Z",
  "dora_lead_time": "8h 42m",
  "deployment_id": "deploy-12345"
}
```

### Mobile Experience

- Access via Mattermost mobile app
- Focalboard integrated in Mattermost mobile (iOS/Android)
- Full board editing on mobile
- Push notifications for card updates
- Offline support with sync

### Backup & Data Export

- **Backup**: Included in Mattermost backup strategy
- **Export**: JSON format for all boards
- **Import**: Can import from Trello, Asana, Notion
- **Git Backup**: Export boards to Git for version control

### Resource Requirements

**Included in Mattermost deployment**:

- No additional CPU/memory beyond Mattermost
- Shares PostgreSQL database
- File attachments use same storage (S3/MinIO)
- ~100MB additional storage per 100 active boards

### Performance Considerations

- Board loading: <1 second for boards with <1000 cards
- Real-time updates via WebSocket
- Card search indexed for fast queries
- Archive old boards to improve performance

## Monitoring This Decision

We will revisit this ADR if:

- Focalboard becomes unmaintained or development slows significantly
- Critical features remain missing after 12 months
- Performance issues arise that can't be resolved
- A superior open source alternative emerges with Mattermost integration
- Community adoption is below 50% (teams prefer external tools)

**Next Review Date**: April 7, 2026 (6 months)

## References

- [Focalboard Documentation](https://www.focalboard.com/docs/)
- [Focalboard GitHub](https://github.com/mattermost/focalboard)
- [Mattermost Boards Documentation](https://docs.mattermost.com/boards/)
- [Focalboard vs. Alternatives Comparison](https://www.focalboard.com/download/personal-edition/desktop/)

## Notes

### Why Focalboard Over Jira?

The most common question: "Why not use Jira, the industry standard?"

**Three key reasons**:

1. **Integration**: Focalboard's native Mattermost integration creates unified experience. Jira requires complex external integrations.

2. **Cost & Values**: Open source and self-hosted aligns with Fawkes values. Jira's licensing costs don't scale for open source community.

3. **Simplicity**: Most teams don't need Jira's complexity. Focalboard's simplicity is a feature, not a limitation. Start simple, scale up as needed.

### Focalboard's Evolution

Focalboard started as standalone project, acquired by Mattermost in 2021. Now:

- Core part of Mattermost platform
- Active development (monthly releases)
- Growing feature set
- Increasing adoption
- Path to maturity clear

### Enterprise Considerations

While Focalboard is free, some advanced features require Mattermost Enterprise:

- Advanced permissions and compliance
- SAML authentication
- Data retention policies
- Advanced audit logging

For open source Fawkes: Start with free version, upgrade if enterprise adopters need these features.

---

**Decision Made By**: Platform Architecture Team
**Approved By**: Project Lead
**Date**: October 7, 2025
**Author**: [Platform Architect Name]
**Last Updated**: October 7, 2025
