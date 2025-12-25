# Interview Guide: Platform Engineer

## Document Information

**Version**: 1.0
**Last Updated**: December 2025
**Status**: Active
**Owner**: Product Team
**Target Persona**: Platform Engineer (Alex Chen - "The Infrastructure Guardian")
**Interview Type**: Discovery Interview
**Estimated Duration**: 45-60 minutes

---

## Interview Objectives

- Understand platform engineering workflows, responsibilities, and priorities
- Identify pain points in platform operations, maintenance, and developer support
- Discover Jobs to be Done (JTBD) for platform reliability and developer enablement
- Evaluate platform tooling effectiveness and automation gaps
- Gather insights on scalability challenges and improvement opportunities

---

## Pre-Interview Preparation

### Screener Questions

Use these questions to select appropriate interview participants:

1. **Role**: What is your current role and team?
2. **Experience**: How long have you been working in platform engineering or DevOps?
3. **Platform Scope**: What platforms or infrastructure do you manage?
4. **Team Size**: How many developers or teams do you support?
5. **Responsibilities**: What percentage of your time is spent on operations vs. new capabilities?

**Selection Criteria**:
- Platform engineers, DevOps engineers, SREs
- Mix of experience levels (mid: 2-5 years, senior: 5-10 years, staff: 10+ years)
- Various platform domains (compute, networking, security, observability)
- Support different-sized development organizations (small: <20, medium: 20-100, large: >100)
- Different cloud providers or on-premises experience

### Materials to Prepare

- [ ] Consent form ready
- [ ] Recording setup tested (with participant permission)
- [ ] Note-taking template prepared
- [ ] Platform architecture diagram available (for reference)
- [ ] Recent incident or metrics data (if appropriate)
- [ ] Interview objectives shared with participant in advance

---

## Interview Protocol

### Introduction (5 minutes)

"Thank you for taking the time to speak with me today. I'm [Your Name] from the Product Team, and I'm conducting research to understand how platform engineers manage and operate the Fawkes platform and how we can make it better.

**Purpose**: We want to learn about your day-to-day challenges, operational workflows, and what would help you enable developers more effectively. This isn't an evaluation—there are no wrong answers. We're here to learn from your expertise.

**Confidentiality**: Your responses will be anonymized. We won't share anything that identifies you personally. The insights will inform platform improvements and feature prioritization.

**Recording**: [If applicable] With your permission, I'd like to record this session for note-taking purposes only. The recording will be deleted after we transcribe it. Are you comfortable with that?

**Format**: I'll ask you questions about your workflows, challenges, and how you support developers. Feel free to share examples, show me dashboards or tools you use, or even demonstrate challenges you face. We have about 45-60 minutes.

**Questions?**: Do you have any questions before we start?"

---

## Main Interview Questions

### Section 1: Background and Context (5-7 minutes)

**Objective**: Establish rapport and understand the participant's responsibilities

1. **Can you tell me about your role and what you're responsible for?**
   - *Follow-up*: What platforms or systems do you manage?
   - *Follow-up*: How many developers or teams do you support?
   - *Follow-up*: What's your team structure like?

2. **How long have you been working with the Fawkes platform?**
   - *Follow-up*: What was your onboarding experience like?
   - *Follow-up*: What were your first impressions of the platform architecture?
   - *Follow-up*: How has your role evolved since you started?

3. **What does a typical day or week look like for you?**
   - *Follow-up*: What percentage of time do you spend on incidents vs. proactive work?
   - *Follow-up*: What activities take up the most time?
   - *Follow-up*: How much time do you spend supporting developers?

---

### Section 2: Platform Operations and Reliability (10-12 minutes)

**Objective**: Understand operational workflows and identify reliability challenges

**JTBD Focus**: "Help me keep the platform reliable and available for developers"

4. **Walk me through how you ensure the platform is running smoothly.**
   - *Follow-up*: What do you monitor? How?
   - *Follow-up*: What does "healthy" look like for the platform?
   - *Follow-up*: What early warning signals do you watch for?

5. **Tell me about the last significant platform incident. What happened?**
   - *Follow-up*: How did you detect it? How long until you knew there was a problem?
   - *Follow-up*: What was the impact on developers or end users?
   - *Follow-up*: How long did it take to resolve?
   - *Follow-up*: What made it difficult to troubleshoot or fix?
   - *Pain point probe*: What information did you wish you had during this incident?

6. **What keeps you up at night about platform reliability?**
   - *Follow-up*: What scenarios worry you the most?
   - *Follow-up*: How do you mitigate these risks currently?
   - *Follow-up*: What would make you more confident in the platform's resilience?
   - *JTBD*: What would help you sleep better at night?

7. **How do you handle capacity planning and scaling?**
   - *Follow-up*: What triggers you to scale resources?
   - *Follow-up*: How far in advance can you predict capacity needs?
   - *Follow-up*: What makes capacity planning difficult?
   - *Pain point*: What surprises or unexpected growth patterns have you experienced?

---

### Section 3: Developer Support and Enablement (8-10 minutes)

**Objective**: Identify challenges in supporting developers and enabling self-service

**JTBD Focus**: "Help me enable developers to be productive without constant hand-holding"

8. **How do developers typically reach out to you for help?**
   - *Follow-up*: What are the most common requests?
   - *Follow-up*: How much time do you spend responding to support requests?
   - *Follow-up*: What types of requests should developers be able to handle themselves?
   - *Pain point*: What requests feel repetitive or unnecessary?

9. **Describe a recent support request that was particularly challenging or time-consuming.**
   - *Follow-up*: What made it difficult?
   - *Follow-up*: How long did it take to resolve?
   - *Follow-up*: Could the developer have solved it themselves? Why didn't they?
   - *JTBD*: What would have prevented this request from happening?

10. **What platform capabilities do developers not use or underutilize?**
    - *Follow-up*: Why do you think that is?
    - *Follow-up*: How do you educate developers about available features?
    - *Follow-up*: What would increase adoption of self-service capabilities?
    - *Pain point*: What tasks do developers ask you to do that the platform should enable them to do?

11. **How do you balance new feature requests with platform stability?**
    - *Follow-up*: How do you prioritize platform work?
    - *Follow-up*: What pressure do you face to add new capabilities?
    - *Follow-up*: How do you communicate trade-offs to stakeholders?
    - *JTBD*: What would help you make better prioritization decisions?

---

### Section 4: Platform Tooling and Automation (8-10 minutes)

**Objective**: Assess tooling effectiveness and identify automation opportunities

**JTBD Focus**: "Help me automate repetitive tasks and manage complexity efficiently"

12. **What tools do you use daily to manage the platform?**
    - *Follow-up*: What do you like most about these tools?
    - *Follow-up*: What frustrates you about them?
    - *Follow-up*: What tool integrations are missing or broken?

13. **What tasks do you do repeatedly that should be automated but aren't?**
    - *Follow-up*: Why haven't these been automated?
    - *Follow-up*: How much time would automation save?
    - *Follow-up*: What blocks you from automating these tasks?
    - *JTBD*: What would make it easier to automate platform operations?

14. **How do you manage infrastructure as code (IaC) and GitOps workflows?**
    - *Follow-up*: What works well about your current approach?
    - *Follow-up*: What's painful or error-prone?
    - *Follow-up*: How do you handle configuration drift?
    - *Follow-up*: How do you test infrastructure changes before applying them?

15. **Tell me about your observability setup—metrics, logs, traces.**
    - *Follow-up*: What visibility do you have into platform health?
    - *Follow-up*: What blind spots exist?
    - *Follow-up*: How do you correlate issues across services?
    - *Pain point*: What makes troubleshooting difficult or time-consuming?

---

### Section 5: Security, Compliance, and Policies (5-7 minutes)

**Objective**: Understand security and compliance workflows and challenges

**JTBD Focus**: "Help me secure the platform without slowing down developers"

16. **How do you ensure the platform is secure?**
    - *Follow-up*: What security practices or policies do you enforce?
    - *Follow-up*: How do you balance security with developer productivity?
    - *Follow-up*: What security concerns keep you up at night?
    - *Pain point*: What security tasks are manual or difficult to enforce?

17. **How do you handle policy enforcement and compliance?**
    - *Follow-up*: What policies do you need to enforce (network, access, resource limits)?
    - *Follow-up*: How do you communicate policies to developers?
    - *Follow-up*: How do you detect and remediate policy violations?
    - *JTBD*: What would make policy management easier?

18. **Tell me about a time when security or compliance requirements conflicted with developer needs.**
    - *Follow-up*: How did you resolve it?
    - *Follow-up*: What was the impact on velocity or developer experience?
    - *Follow-up*: What would have made this easier to navigate?

---

### Section 6: Platform Evolution and Improvement (8-10 minutes)

**Objective**: Discover improvement opportunities and future needs

**JTBD Focus**: "Help me evolve the platform to meet growing demands"

19. **What parts of the platform are most difficult to maintain or operate?**
    - *Follow-up*: Why are they difficult?
    - *Follow-up*: What would simplify these areas?
    - *Follow-up*: What's the impact of this complexity?
    - *Pain point*: What legacy components or technical debt slows you down?

20. **If you could redesign one aspect of the platform, what would it be?**
    - *Follow-up*: Why is this the most important thing?
    - *Follow-up*: What would the ideal state look like?
    - *Follow-up*: What's blocking this improvement today?
    - *JTBD*: How would this change your day-to-day work?

21. **What platform capabilities are you missing that other platforms have?**
    - *Follow-up*: What platforms do you look to as inspiration?
    - *Follow-up*: How would these capabilities help you or developers?
    - *Follow-up*: What's the business case for adding them?

22. **How do you stay current with platform engineering trends and best practices?**
    - *Follow-up*: What communities or resources do you follow?
    - *Follow-up*: What emerging technologies are you excited about?
    - *Follow-up*: What innovations do you want to bring to the platform?

---

### Closing Questions (3-5 minutes)

**Objective**: Capture overall sentiment and additional insights

23. **If you could wave a magic wand and improve one thing about the platform, what would it be?**
    - *Follow-up*: Why is this the most important thing to you?
    - *Follow-up*: How would your role or the developer experience change?

**Wrap-up**:
- "Is there anything else about platform operations or challenges that we haven't covered but you think is important?"
- "Can we reach out to you for follow-up questions if needed?"
- "Would you be interested in providing feedback on platform improvements before they're released?"

---

## Post-Interview Protocol

### Immediate Actions (Within 1 hour)

- [ ] Save and backup recording (if applicable)
- [ ] Write down key quotes and memorable moments while fresh
- [ ] Note any strong emotional reactions or body language
- [ ] Identify 3-5 key takeaways
- [ ] Document any critical issues mentioned that need immediate attention

### Within 24 Hours

- [ ] Transcribe full interview notes
- [ ] Anonymize participant information (use role descriptor: "Senior Platform Engineer, 7 years experience")
- [ ] Highlight key quotes with context
- [ ] Tag pain points, JTBD, and workarounds
- [ ] Identify patterns or themes
- [ ] File notes in `docs/research/interviews/` with naming convention: `YYYY-MM-DD-platform-engineer-{topic}.md`

### Within 1 Week

- [ ] Send thank-you note to participant
- [ ] Share anonymized insights with product and platform teams
- [ ] Update persona with new data points (if applicable)
- [ ] Log findings in insights repository
- [ ] Escalate any critical platform issues to engineering leadership
- [ ] Identify follow-up research questions

---

## Key Topics Coverage Checklist

Ensure all interviews cover these critical areas:

### Jobs to be Done (JTBD)
- [ ] Keep the platform reliable and available for developers
- [ ] Enable developers to be productive without constant support
- [ ] Automate repetitive tasks and manage complexity efficiently
- [ ] Secure the platform without slowing down developers
- [ ] Evolve the platform to meet growing demands
- [ ] Respond to and resolve incidents quickly
- [ ] Plan and scale capacity proactively

### Pain Points
- [ ] Time spent on repetitive support requests
- [ ] Difficulty troubleshooting complex distributed systems
- [ ] Lack of observability or blind spots
- [ ] Manual or error-prone processes
- [ ] Balancing stability with new features
- [ ] Policy enforcement and compliance overhead
- [ ] Legacy systems or technical debt
- [ ] Developer adoption of self-service features
- [ ] Incident response and mean time to recovery (MTTR)

### Workarounds
- [ ] Manual scripts for common operations
- [ ] Custom tooling built outside the platform
- [ ] Responding to every support request personally
- [ ] Over-provisioning to avoid capacity issues
- [ ] Avoiding upgrades or changes due to risk
- [ ] Documentation in personal notes instead of shared system
- [ ] Context switching between multiple tools and dashboards

---

## Interview Analysis Guide

### Key Metrics to Track

- **Support Request Volume**: How many requests per week?
- **Time on Support vs. Proactive Work**: Percentage breakdown
- **Incident Frequency**: How often do platform incidents occur?
- **MTTR (Mean Time to Recovery)**: Average time to resolve incidents
- **Deployment Frequency**: How often is the platform updated?
- **Automation Coverage**: What percentage of tasks are automated?
- **Developer Self-Service Adoption**: What features are used vs. available?

### Sentiment Analysis

Track emotional responses to:
- Platform reliability (confidence, anxiety)
- Support burden (frustration, satisfaction)
- Tooling effectiveness (efficiency, struggle)
- Security requirements (pragmatism, concern)
- Platform evolution (excitement, overwhelm)
- Developer enablement (pride, frustration)

### Pattern Identification

Look for common themes across interviews:
- Recurring pain points (3+ participants mention)
- Similar workarounds (indicates systemic issue)
- Consistent capability gaps (prioritization signal)
- Shared concerns about reliability or scale
- Common automation opportunities

---

## Tips for Effective Interviewing

### Do's ✅
- **Respect their expertise**: Platform engineers are technical experts—value their insights
- **Ask for demonstrations**: "Can you show me your monitoring dashboard?"
- **Explore trade-offs**: Understand their decision-making process
- **Dig into incidents**: Post-mortems reveal valuable insights
- **Understand priorities**: What do they optimize for? (reliability, speed, cost)
- **Ask about metrics**: What DORA metrics or SLOs do they track?
- **Explore team dynamics**: How do they work with security, networking, etc.?

### Don'ts ❌
- **Don't assume they know everything**: Some areas may be owned by others
- **Don't skip emotional responses**: Frustration and pride are valuable signals
- **Don't ignore technical details**: Deep dive into architecture and tools
- **Don't overlook on-call burden**: This is often a major pain point
- **Don't forget the human element**: Platform engineers care deeply about enabling developers
- **Don't dismiss "boring" work**: Maintenance and operations are critical
- **Don't focus only on problems**: Understand what works well too

### Effective Follow-up Questions
- "Can you show me an example in your monitoring system?"
- "What would you do differently if you could start over?"
- "How does this impact developer productivity?"
- "What metrics tell you this is a problem?"
- "Who else is affected by this issue?"
- "What's the cost of not fixing this?"
- "How do other platforms handle this?"
- "What would the ideal workflow look like?"

---

## Resources

- [Platform Engineer Persona](../personas/platform-developer.md)
- [Interview Guide Template](../templates/interview-guide.md)
- [Research Repository README](../README.md)
- [Consent Form Template](./consent-form.md)
- [DORA Metrics Documentation](../../observability/dora-metrics.md)
- **Recommended Reading**:
  - "The Site Reliability Workbook" by Google SRE Team
  - "Team Topologies" by Matthew Skelton and Manuel Pais

---

## Changelog

### Version 1.0 - December 2025
- Initial interview guide created for platform engineers
- 23 main questions across 6 sections
- Focus on JTBD, pain points, reliability, and developer enablement
- Comprehensive protocol and analysis framework

---

**Document Owner**: Product Team
**Last Review**: December 2025
**Next Review**: March 2026 (or after 10+ interviews)
