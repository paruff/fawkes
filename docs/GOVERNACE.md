# Fawkes Project Governance

## Overview

Fawkes is an open-source Internal Delivery Platform committed to transparent, inclusive, and collaborative governance. This document defines how decisions are made, how contributors can become maintainers, and how the project evolves.

## Project Mission

To provide a production-ready, DORA-driven Internal Delivery Platform that accelerates software delivery while fostering continuous learning and improvement in platform engineering practices.

## Core Values

- **Developer Experience First**: Every decision prioritizes the experience of platform users
- **Transparency**: Decision-making processes are open and documented
- **Inclusivity**: We welcome contributors from all backgrounds and experience levels
- **Quality**: We maintain high standards for code, documentation, and community interactions
- **Continuous Learning**: The platform serves as both a tool and a teaching environment
- **Data-Driven**: Decisions are informed by metrics, user feedback, and DORA research

## Project Structure

### Roles

#### Users
Anyone who uses Fawkes to build and operate their internal delivery platform.

**Responsibilities**:
- Provide feedback through issues and discussions
- Follow the Code of Conduct
- Help other users when possible

#### Contributors
Anyone who contributes to the project (code, documentation, design, support).

**How to become a Contributor**:
- Submit at least one merged pull request or significant issue/discussion contribution
- Sign the Developer Certificate of Origin (DCO)

**Responsibilities**:
- Follow contribution guidelines
- Participate constructively in code reviews and discussions
- Maintain quality standards

#### Core Contributors
Contributors who have made sustained, significant contributions over time.

**How to become a Core Contributor**:
- 5+ merged pull requests over 3+ months
- Demonstrated technical expertise in specific area
- Active participation in community discussions
- Nominated by a Maintainer and approved by Maintainer team

**Responsibilities**:
- Review pull requests
- Triage issues
- Mentor new contributors
- Participate in technical discussions
- Help maintain documentation

**Benefits**:
- Listed in CONTRIBUTORS.md
- "Core Contributor" badge
- Invitation to Core Contributor meetings (monthly)
- Input on roadmap priorities

#### Maintainers
Trusted individuals with commit access and release responsibilities.

**How to become a Maintainer**:
- 25+ merged contributions over 6+ months OR significant architectural contributions
- Consistent, high-quality code reviews
- Demonstrated commitment to community health
- Understanding of project architecture and goals
- Nominated by existing Maintainer
- Approved by 2/3 vote of existing Maintainers

**Responsibilities**:
- Review and merge pull requests
- Triage and prioritize issues
- Make architectural decisions
- Release management
- Mentor contributors and core contributors
- Enforce Code of Conduct
- Participate in governance decisions
- Available for critical incidents (on-call rotation)

**Benefits**:
- Commit access to repositories
- Listed in MAINTAINERS.md
- Voice in major project decisions
- Speaking opportunities representing the project

#### Project Lead
The initial founder(s) who provide overall strategic direction.

**Responsibilities**:
- Final decision authority on major disputes (used rarely)
- External partnerships and relationships
- Fundraising and resource allocation
- Project vision and long-term strategy
- Maintainer appointments (with Maintainer input)

**Current Project Lead**: [Your Name/Handle]

### Decision-Making Process

#### Minor Decisions
*Examples: Bug fixes, documentation improvements, small features*

**Process**: 
- Single maintainer approval required for merge
- Use "Lazy Consensus" - if no objections within 48 hours, proceed
- Document in pull request comments

#### Major Decisions
*Examples: New dependencies, architectural changes, breaking changes*

**Process**:
1. Create Architectural Decision Record (ADR) or detailed RFC (Request for Comments)
2. Post in GitHub Discussions for community input
3. Allow 7 days for feedback
4. Maintainers discuss in next maintainer meeting
5. Decision requires 2/3 approval from active Maintainers
6. Document decision and rationale publicly

#### Critical Decisions
*Examples: Licensing changes, project governance changes, Code of Conduct updates*

**Process**:
1. Create detailed proposal with rationale
2. Post for public comment (14-day minimum)
3. Discuss in maintainer meeting
4. Decision requires 3/4 approval from Maintainers
5. Project Lead has veto power (used rarely, with public justification)

### Conflict Resolution

#### Disagreements on Technical Decisions
1. Attempt to reach consensus through discussion
2. If consensus fails, maintainers vote (simple majority)
3. If vote is split, Project Lead decides
4. Document decision and dissenting opinions in ADR

#### Code of Conduct Violations
1. Report to conduct@fawkes-project.org or via GitHub private reporting
2. Maintainer team reviews within 48 hours
3. Decision on action (warning, temporary ban, permanent ban) requires 2/3 Maintainer vote
4. Accused party is given opportunity to respond
5. Decision is documented (publicly or privately depending on severity)

#### Maintainer Conflicts
1. Attempt direct resolution
2. If unresolved, bring to Maintainer meeting
3. If needed, Project Lead mediates
4. In extreme cases, Maintainer may be removed by 3/4 vote of other Maintainers

## Communication Channels

### Public Channels
- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: Questions, ideas, RFCs
- **Slack/Discord**: Real-time community chat
- **Mailing List**: Announcements, governance discussions
- **Office Hours**: Bi-weekly video calls (open to all)

### Private Channels
- **Maintainer Meetings**: Bi-weekly (minutes published publicly)
- **Security Issues**: security@fawkes-project.org
- **Code of Conduct Reports**: conduct@fawkes-project.org

## Contribution Recognition

### All Contributors
- Listed in CONTRIBUTORS.md (automated via all-contributors bot)
- Mentioned in release notes for significant contributions

### Monthly Recognition
- "Contributor of the Month" highlighted in newsletter/blog
- Criteria: Impact, quality, community support

### Annual Recognition
- "Top Contributors" featured in end-of-year report
- Special recognition at community events

## Roadmap & Planning

### Roadmap Process
1. Maintainers propose high-level roadmap (quarterly)
2. Community provides feedback via GitHub Discussions
3. Maintainers finalize and publish roadmap
4. Progress tracked publicly in GitHub Projects

### Sprint Planning
- 2-week sprint cycles
- Issues prioritized in maintainer meetings
- Community can propose priorities via discussions

### Release Cadence
- **Minor releases**: Monthly (features, improvements)
- **Patch releases**: As needed (bug fixes, security)
- **Major releases**: Quarterly or as needed (breaking changes)

## Modification of Governance

This governance document may be modified through the Critical Decision process:
1. Propose changes via GitHub Discussion
2. 14-day comment period
3. 3/4 Maintainer approval required
4. Project Lead approval required

## Maintainer Succession

### Emeritus Status
Maintainers who step back from active maintenance:
- Retain emeritus maintainer status and recognition
- Listed in MAINTAINERS.md with emeritus designation
- No commit access or voting rights
- Can return to active status via simple process

### Inactive Maintainers
If a maintainer is inactive for 6+ months without communication:
- Other maintainers attempt to contact
- If no response after 30 days, maintainer moved to emeritus
- Commit access revoked (can be reinstated)

### Maintainer Removal
In rare cases of Code of Conduct violations or actions harmful to project:
- Requires 3/4 vote of other maintainers
- Project Lead can override (with public justification)
- Process is documented for transparency

## Initial Bootstrap Period

For the first 6 months, the Project Lead has broader authority to:
- Appoint initial maintainers (minimum 3)
- Make rapid decisions to establish project foundations
- Adjust governance as needed based on early learnings

After 6 months, this bootstrap period ends and full governance takes effect.

## Credits

This governance model is inspired by:
- CNCF project governance patterns
- Apache Software Foundation governance
- Kubernetes community governance
- Node.js project governance

---

**Document Version**: 1.0  
**Last Updated**: October 4, 2025  
**Status**: Active  
**Contact**: governance@fawkes-project.org

---

## Quick Reference

| Action | Who Can Do It | Approval Needed |
|--------|---------------|-----------------|
| Submit PR | Anyone | Maintainer review |
| Merge minor PR | Maintainer | 1 Maintainer |
| Merge major PR | Maintainer | 2 Maintainers or ADR |
| Create release | Maintainer | 1 other Maintainer |
| Modify governance | Any contributor | 3/4 Maintainers + Project Lead |
| Become Core Contributor | Contributors | Maintainer nomination + approval |
| Become Maintainer | Core Contributors | 2/3 Maintainer vote |