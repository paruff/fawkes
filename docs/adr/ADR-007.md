# ADR-007: Mattermost for Team Collaboration

## Status
**Accepted** - October 7, 2025

## Context

Fawkes is evolving from an infrastructure-focused Internal Delivery Platform to a comprehensive **Internal Product Delivery Platform**. To support product delivery effectively, teams need integrated collaboration capabilities that go beyond code and CI/CD pipelines.

### The Need for Integrated Collaboration

**Current Gap**: Teams using Fawkes must use external tools for:
- **Real-time communication**: Slack, Microsoft Teams, Discord
- **Bot integrations and ChatOps**: Limited integration with external tools
- **Platform notifications**: Email or external chat platforms
- **Community building**: Fragmented across multiple platforms
- **Dojo learning support**: No integrated space for learner discussions

**Requirements for Collaboration Tool**:
1. **Self-Hosted**: Data sovereignty, no vendor lock-in, customizable
2. **Open Source**: Aligns with Fawkes' values, community-driven
3. **Platform Integration**: Webhooks, bots, API for CI/CD notifications
4. **ChatOps**: Trigger platform actions from chat
5. **Rich Features**: Threads, search, file sharing, video calls
6. **Dojo Integration**: Dedicated channels for learning, mentorship
7. **Project Management Integration**: Connect with Focalboard seamlessly
8. **Scalable**: Support growing communities (100+ users initially, 1000+ future)
9. **Mobile Support**: Native iOS and Android apps
10. **Cost Effective**: Free or low-cost at scale

### Forces at Play

**Technical Forces**:
- Need real-time communication for incident response
- ChatOps capabilities increasingly expected in platforms
- Notification fatigue from email-only communications
- Integration complexity with external tools

**Business Forces**:
- Data sovereignty and security concerns with SaaS tools
- Cost at scale (Slack pricing: $7.25-$12.50/user/month × 100 users = $725-$1,250/month)
- Vendor lock-in risks with proprietary platforms
- Open source preference for transparency and control

**Community Forces**:
- Community members prefer familiar platforms (Slack, Discord)
- Learning curve for new platforms
- Network effects (everyone uses Slack already)
- Need for inclusive, welcoming community space

**Organizational Forces**:
- Platform team wants to avoid platform sprawl
- Desire for single integrated platform experience
- Need to model self-hosted, open-source values

## Decision

**We will use Mattermost as the integrated team collaboration platform for Fawkes.**

Specifically:
- **Self-hosted deployment** in Kubernetes alongside other Fawkes components
- **Mattermost Team Edition** (open source) with optional Enterprise upgrade path
- **Native Focalboard integration** for project management
- **Deep platform integration** via webhooks, slash commands, and bots
- **Backstage integration** via iframe or custom plugin

### Rationale

1. **Open Source & Self-Hosted**: Mattermost is fully open source (MIT/Apache 2.0), aligns with Fawkes values, and gives complete control over data

2. **Feature Completeness**: Comparable feature set to Slack (channels, threads, search, reactions, file sharing, video calls)

3. **Native Focalboard Integration**: Focalboard (Notion-like project management) is built into Mattermost, creating seamless collaboration + project management experience

4. **Strong Integration Capabilities**: 
   - Webhooks (incoming/outgoing)
   - Slash commands for ChatOps
   - REST API for custom integrations
   - Bot framework
   - 700+ integrations available

5. **Platform Notifications**: Natural home for CI/CD notifications, deployment updates, DORA metric alerts, security scan results

6. **Dojo Community Support**: Dedicated channels for each belt level, peer learning, mentor office hours

7. **Cost Effectiveness**: 
   - Team Edition: Free, unlimited users
   - Enterprise: Optional, $10/user/year (10x cheaper than Slack at scale)
   - Self-hosted: No per-user fees, only infrastructure costs (~$50-100/month)

8. **Mobile & Desktop Apps**: Native apps for all major platforms (iOS, Android, macOS, Windows, Linux)

9. **Slack Compatibility**: Can import Slack workspaces, familiar keyboard shortcuts, similar UX reduces learning curve

10. **Active Development**: Backed by Mattermost Inc., regular releases, large community (30,000+ stars on GitHub)

11. **Security & Compliance**: 
    - SOC 2 Type II certified
    - GDPR compliant
    - End-to-end encryption available
    - Audit logging
    - Advanced security controls in Enterprise

## Consequences

### Positive

✅ **Complete Platform Integration**: Single ecosystem for code, CI/CD, collaboration, project management, and learning

✅ **Data Ownership**: Full control over data, no third-party access, can backup/restore as needed

✅ **Cost Predictability**: Infrastructure costs only, no per-user fees, scales economically

✅ **Customization**: Can modify, extend, and customize to exact needs

✅ **ChatOps Enablement**: Build platform automation triggered from chat (deploy, rollback, check metrics)

✅ **Community Building**: Dedicated, branded space for Fawkes community

✅ **Learning Integration**: Natural home for dojo learner discussions and support

✅ **Project Management**: Focalboard built-in creates seamless workflow

✅ **Open Source Alignment**: Demonstrates commitment to open source values

✅ **Privacy & Security**: No data leaves your infrastructure, audit trail for compliance

✅ **Long-Term Sustainability**: Open source ensures platform won't disappear or change terms

### Negative

⚠️ **Operational Overhead**: Must deploy, maintain, backup, upgrade (mitigated: Kubernetes-native, automated)

⚠️ **Learning Curve**: Users familiar with Slack/Discord need to learn new platform (mitigated: similar UX)

⚠️ **Network Effects**: Many users already have Slack/Discord accounts (mitigated: Slack import, SSO)

⚠️ **Mobile App Quality**: Mobile apps good but not quite as polished as Slack (improving rapidly)

⚠️ **Integration Ecosystem**: Smaller than Slack's marketplace (mitigated: REST API, webhook support)

⚠️ **Voice/Video Calls**: Built-in but not as robust as Zoom/Teams (mitigated: can integrate with external tools)

⚠️ **Adoption Challenge**: Convincing community to join new platform (mitigated: showcase integration benefits)

⚠️ **Resource Requirements**: Requires ~500MB RAM, 1 CPU core, 5GB storage minimum

### Neutral

◽ **Maturity**: Mature product (10+ years) but less ubiquitous than Slack

◽ **Brand Recognition**: Less well-known than Slack (opportunity to educate about open source alternatives)

◽ **Enterprise Features**: Some features require Enterprise license (can start with Team Edition)

### Mitigation Strategies

1. **Operational Overhead**: 
   - Use Mattermost Operator for Kubernetes (automated deployment, upgrades)
   - Include in platform monitoring and backup strategy
   - Document runbooks for common operations

2. **Learning Curve**: 
   - Create onboarding guide with screenshots
   - Highlight Slack-compatible shortcuts
   - Provide comparison guide (Slack vs. Mattermost)
   - Video walkthrough for new users

3. **Adoption**:
   - Lead by example (maintainers active in Mattermost)
   - Showcase platform integration benefits
   - Make it the official channel for announcements
   - Offer Slack/Discord bridges during transition (bot that mirrors messages)

4. **Integration Gaps**:
   - Build custom integrations where needed
   - Contribute integrations back to community
   - Document integration patterns

5. **Voice/Video**:
   - Use Mattermost's built-in calls for quick discussions
   - Integrate with Zoom/Jitsi for larger meetings
   - Document best practices

## Alternatives Considered

### Alternative 1: Slack (SaaS)

**Pros**:
- Most popular enterprise chat platform
- Excellent user experience and mobile apps
- Huge integration marketplace (2,400+ apps)
- Familiar to most users (minimal learning curve)
- Best-in-class search and features
- Strong voice/video calling

**Cons**:
- **Cost**: $7.25-$12.50/user/month (prohibitively expensive at scale)
- **Vendor Lock-In**: Proprietary platform, terms can change
- **Data Privacy**: All data on Slack's servers, compliance concerns
- **Message History Limits**: Free tier limited to 90 days history
- **No Self-Hosting**: Must use Slack's infrastructure
- **Misaligned Values**: SaaS, proprietary, not open source

**Reason for Rejection**: Cost at scale is prohibitive for open source project. At 500 users (medium-term goal), cost would be $43,500-$75,000/year. Data sovereignty and vendor lock-in concerns conflict with platform values. Slack doesn't integrate with self-hosted Focalboard.

### Alternative 2: Discord

**Pros**:
- Free for unlimited users
- Excellent voice/video quality
- Popular with developer communities
- Great mobile apps
- Rich media support (embeds, reactions, GIFs)
- Screen sharing and streaming

**Cons**:
- **Gaming-Centric UX**: Designed for gaming, not professional collaboration
- **Limited Integrations**: Fewer business integrations than Slack/Mattermost
- **No Self-Hosting**: SaaS only, data on Discord servers
- **Professional Perception**: Less professional than Slack/Mattermost
- **Search Limitations**: Search not as powerful as Slack/Mattermost
- **No Project Management**: No Focalboard equivalent
- **Organization Features**: Weaker organization/threading than alternatives

**Reason for Rejection**: While free and popular with developers, Discord's gaming focus, lack of self-hosting, and limited business integrations make it suboptimal for a professional platform engineering community. No project management integration path.

### Alternative 3: Rocket.Chat

**Pros**:
- Open source and self-hosted
- Feature-complete (channels, threads, video calls)
- Strong security features
- Active community
- Free and scalable
- Slack-compatible (can import)

**Cons**:
- **Less Mature**: Smaller community than Mattermost
- **Integration Ecosystem**: Fewer integrations available
- **Performance**: Can be slower with large communities
- **Documentation**: Less comprehensive than Mattermost
- **Mobile Apps**: Not as polished
- **No Project Management**: No integrated project management tool
- **Smaller Development Team**: Less resourced than Mattermost

**Reason for Rejection**: While solid open source alternative, Rocket.Chat has smaller ecosystem, less mature integrations, and no project management integration like Focalboard. Mattermost has stronger momentum and backing.

### Alternative 4: Microsoft Teams

**Pros**:
- Deep Microsoft 365 integration
- Excellent voice/video (backed by Skype)
- Widely used in enterprises
- Strong security and compliance
- File collaboration (SharePoint integration)
- Free tier available

**Cons**:
- **Microsoft Ecosystem Lock-In**: Strongly tied to Microsoft services
- **Complex Self-Hosting**: Teams self-hosting extremely complex
- **Not Truly Open Source**: Proprietary platform
- **Resource Heavy**: High resource requirements
- **Overly Complex**: Feature bloat, steep learning curve
- **Poor UX for Chat**: Optimized for meetings, not async chat
- **Limited Customization**: Restricted API, hard to integrate deeply

**Reason for Rejection**: Teams is designed for Microsoft ecosystem and prioritizes video meetings over chat. Self-hosting is impractical, not open source, and doesn't align with platform values. Poor fit for developer community.

### Alternative 5: Matrix/Element

**Pros**:
- Fully open source and decentralized
- Strong encryption and privacy
- Federation support (connect multiple servers)
- Active development
- Growing community
- Modern protocol (Matrix)

**Cons**:
- **Immature Features**: Missing some expected features (threads, polls)
- **Complex Setup**: Federation and encryption add complexity
- **Performance**: Can be slow with large communities
- **Mobile Apps**: Still improving
- **Integration Ecosystem**: Limited compared to Mattermost
- **No Project Management**: No Focalboard equivalent
- **Learning Curve**: Decentralization concepts unfamiliar to most users

**Reason for Rejection**: While philosophically aligned (decentralized, encrypted), Matrix/Element is still maturing and has a steeper learning curve. Mattermost provides better immediate user experience while remaining open source and self-hosted.

### Alternative 6: Zulip

**Pros**:
- Open source and self-hosted
- Unique threading model (topic-based)
- Excellent for asynchronous communication
- Strong search capabilities
- Free and scalable
- Good integrations

**Cons**:
- **Unusual UX**: Topic-based threading very different from Slack
- **Smaller Community**: Less widely known/adopted
- **Learning Curve**: Unique model requires mindset shift
- **Integration Ecosystem**: Smaller than Mattermost
- **No Project Management**: No integrated project management
- **Mobile Apps**: Good but less mature than alternatives

**Reason for Rejection**: Zulip's topic-based threading, while powerful for some use cases, is a significant departure from familiar chat UX. Would increase friction for community adoption. No project management integration.

## Related Decisions

- **ADR-008**: Focalboard for Project Management (direct integration with Mattermost)
- **ADR-002**: Backstage for Developer Portal (Mattermost integration via iframe/plugin)
- **Future ADR**: SSO/OIDC strategy (Mattermost will be SSO-enabled)

## Implementation Notes

### Deployment Architecture

```yaml
# Mattermost deployment in Kubernetes
mattermost:
  namespace: fawkes-collaboration
  resources:
    - mattermost-app (4 replicas for HA)
    - postgresql (database)
    - minio (file storage, optional - can use S3)
    - nginx-ingress (TLS termination)
  
  integrations:
    - backstage (iframe embed or plugin)
    - jenkins (webhook notifications)
    - argocd (deployment notifications)
    - grafana (alert notifications)
    - github (PR/issue notifications)
    - focalboard (built-in integration)
```

### Initial Channel Structure

**System Channels**:
- 📢 `announcements` - Official announcements (maintainers only post)
- 💬 `general` - General discussion
- 🆘 `help-and-support` - Q&A and troubleshooting
- 👥 `introductions` - New member introductions

**Platform Component Channels**:
- `backstage`
- `jenkins-cicd`
- `argocd-gitops`
- `observability`
- `security`
- `infrastructure`

**Dojo Learning Channels**:
- 🎓 `dojo-general` - Learning discussions
- 🥋 `dojo-white-belt`
- 🟡 `dojo-yellow-belt`
- 🟢 `dojo-green-belt`
- 🟤 `dojo-brown-belt`
- ⚫ `dojo-black-belt`
- 🏆 `dojo-achievements` - Celebrate completions

**Contributor Channels**:
- 👨‍💻 `contributors` - General contributor discussion
- 🐛 `good-first-issues` - Synced from GitHub
- 📝 `documentation`
- 🔒 `security-private` (private channel)

**Cloud Provider Channels**:
- ☁️ `aws`
- ☁️ `azure`
- ☁️ `gcp`
- ☁️ `multi-cloud`

**Community Channels**:
- 🎉 `random` - Off-topic, fun
- 🎊 `wins` - Celebrate successes
- 📚 `resources` - Share articles, talks, etc.

### Platform Integration Examples

**1. CI/CD Notifications**:
```javascript
// Jenkins pipeline sends to Mattermost
POST https://mattermost.fawkes.io/hooks/jenkins
{
  "channel": "jenkins-cicd",
  "username": "Jenkins Bot",
  "text": "✅ Build #42 succeeded for `sample-app`\n" +
          "Deployment time: 2m 15s\n" +
          "DORA Lead Time: 8m 42s"
}
```

**2. ChatOps - Deploy from Chat**:
```
User: /deploy sample-app to production
Bot: 🚀 Deploying sample-app to production...
     Using image: registry.fawkes.io/sample-app:v1.2.3
     Triggering ArgoCD sync...
     ✅ Deployment successful! (2m 18s)
     📊 DORA Metrics updated
```

**3. DORA Metric Alerts**:
```
DORA Bot: ⚠️ Change Failure Rate Alert
          Team: platform-team
          Current: 18% (threshold: 15%)
          Last 24h: 3 failed deployments out of 17
          Action: Review recent changes in #platform-team
```

**4. Dojo Lab Completion**:
```
Dojo Bot: 🎉 @john completed Lab 3: Deploy with GitOps!
          Belt: White Belt
          Score: 48/50 (96%)
          Time: 18 minutes
          Say congrats in #dojo-white-belt!
```

### SSO Integration

- **Phase 1 (MVP)**: Email/password authentication
- **Phase 2 (Month 2)**: OIDC/SAML SSO with Keycloak
- **Phase 3 (Month 4)**: GitHub OAuth integration

### Mobile App Strategy

- Encourage users to install Mattermost mobile apps
- Provide download links and setup guide
- Configure push notifications for critical alerts
- Test mobile experience regularly

### Migration from External Platforms

For communities using Slack/Discord:
1. **Export data** from existing platform
2. **Import into Mattermost** using Slack import tool
3. **Run bridge bot** for transition period (messages mirrored)
4. **Sunset bridge** after 30 days

### Resource Requirements

**Minimum** (100 users):
- 2 CPU cores
- 4GB RAM
- 20GB storage
- PostgreSQL database

**Recommended** (500 users):
- 4 CPU cores
- 8GB RAM
- 100GB storage
- PostgreSQL with replication

**Enterprise** (1000+ users):
- 8+ CPU cores
- 16GB+ RAM
- 500GB+ storage
- PostgreSQL cluster
- Redis cache
- S3/MinIO for file storage

### Monitoring & Observability

- Prometheus metrics endpoint enabled
- Grafana dashboard for Mattermost metrics
- Alert on:
  - High response time (>2s)
  - Database connection errors
  - Websocket disconnections
  - High memory usage (>80%)
  - Failed login attempts (potential attack)

### Backup & Disaster Recovery

- **Database**: Daily backups via PostgreSQL dump
- **File Storage**: S3 versioning or MinIO backup
- **Configuration**: Store in Git (Infrastructure as Code)
- **Recovery Time Objective (RTO)**: <4 hours
- **Recovery Point Objective (RPO)**: <24 hours

## Monitoring This Decision

We will revisit this ADR if:
- Community adoption is below 60% after 6 months
- Operational burden is significantly higher than alternatives
- Critical features are missing that block workflows
- A superior open source alternative emerges
- Cost of running Mattermost exceeds $200/month at scale

**Next Review Date**: April 7, 2026 (6 months)

## References

- [Mattermost Documentation](https://docs.mattermost.com/)
- [Mattermost vs Slack Comparison](https://mattermost.com/mattermost-vs-slack/)
- [Mattermost Kubernetes Operator](https://github.com/mattermost/mattermost-operator)
- [Focalboard Integration](https://docs.mattermost.com/boards/overview.html)
- [Mattermost Integrations Directory](https://integrations.mattermost.com/)

## Notes

### Why Not Start with Slack/Discord?

We considered using Slack or Discord initially and migrating later, but:
- **Migration Pain**: Moving established communities is difficult and disruptive
- **Platform Fragmentation**: Running collaboration outside main platform defeats integration purpose
- **Cost Trap**: Once on Slack, hard to justify migration due to sunk costs
- **Value Demonstration**: Integrated Mattermost showcases complete platform vision from day one

### Open Source Community Expectations

The open source community increasingly expects:
- Self-hosted communication options (data sovereignty)
- No reliance on proprietary platforms
- Transparency and control
- Alignment with open source values

Mattermost aligns with these expectations while providing enterprise-grade features.

---

**Decision Made By**: Platform Architecture Team  
**Approved By**: Project Lead  
**Date**: October 7, 2025  
**Author**: [Platform Architect Name]  
**Last Updated**: October 7, 2025