# Interview Guide: Application Developer

## Document Information

**Version**: 1.0
**Last Updated**: December 2025
**Status**: Active
**Owner**: Product Team
**Target Persona**: Application Developer (Maria Rodriguez - "The Feature Shipper")
**Interview Type**: Discovery Interview
**Estimated Duration**: 45-60 minutes

---

## Interview Objectives

- Understand the full development lifecycle from the developer's perspective
- Identify pain points in deployment, debugging, and troubleshooting workflows
- Discover Jobs to be Done (JTBD) and unmet needs
- Evaluate platform feature awareness and adoption barriers
- Gather insights on developer experience and productivity blockers

---

## Pre-Interview Preparation

### Screener Questions

Use these questions to select appropriate interview participants:

1. **Role**: What is your current role and team?
2. **Experience**: How long have you been developing applications?
3. **Technology Stack**: What programming languages and frameworks do you primarily use?
4. **Deployment Frequency**: How often do you deploy code to production?
5. **Platform Usage**: How long have you been using the Fawkes platform?

**Selection Criteria**:

- Application developers (frontend, backend, full-stack)
- Mix of experience levels (junior: <2 years, mid: 2-5 years, senior: 5+ years)
- Various technology stacks (Java, Node.js, Python, Go, etc.)
- Active platform users (deploy at least monthly)
- Different teams and product domains

### Materials to Prepare

- [ ] Consent form ready
- [ ] Recording setup tested (with participant permission)
- [ ] Note-taking template prepared
- [ ] Platform access available (for demo/show-me scenarios)
- [ ] Interview objectives shared with participant in advance

---

## Interview Protocol

### Introduction (5 minutes)

"Thank you for taking the time to speak with me today. I'm [Your Name] from the Product Team, and I'm conducting research to understand how developers use the Fawkes platform and how we can improve it.

**Purpose**: We want to learn about your day-to-day experiences, challenges, and needs. This isn't a test of your knowledge—there are no wrong answers. We're here to learn from you.

**Confidentiality**: Your responses will be anonymized. We won't share anything that identifies you personally. The insights will inform platform improvements.

**Recording**: [If applicable] With your permission, I'd like to record this session for note-taking purposes only. The recording will be deleted after we transcribe it. Are you comfortable with that?

**Format**: I'll ask you questions about your workflows and experiences. Feel free to share examples, show me how you do things, or even demonstrate challenges you face. We have about 45-60 minutes.

**Questions?**: Do you have any questions before we start?"

---

## Main Interview Questions

### Section 1: Background and Context (5-7 minutes)

**Objective**: Establish rapport and understand the participant's background

1. **Can you tell me about your role and what you're currently working on?**

   - _Follow-up_: What technologies are you using?
   - _Follow-up_: What's your team structure like?

2. **How long have you been working with the Fawkes platform?**

   - _Follow-up_: What was your onboarding experience like?
   - _Follow-up_: What were your first impressions?

3. **What does a typical day or week look like for you?**
   - _Follow-up_: What percentage of time do you spend on feature development vs. other tasks?
   - _Follow-up_: What activities take up the most time?

---

### Section 2: Development Workflow (10-12 minutes)

**Objective**: Understand the end-to-end development process and identify friction points

**JTBD Focus**: "Help me ship code from my local machine to production quickly and confidently"

4. **Walk me through your typical development workflow from starting a new feature to getting it into production.**

   - _Follow-up_: What tools do you use at each stage?
   - _Follow-up_: Where in this process do you spend the most time?
   - _Follow-up_: What steps feel unnecessary or repetitive?

5. **Tell me about the last time you deployed code to production. How did it go?**

   - _Follow-up_: What was your confidence level before deploying?
   - _Follow-up_: How long did the entire deployment take?
   - _Follow-up_: What did you do to verify the deployment was successful?
   - _Pain point probe_: What made you anxious or uncertain during this process?

6. **How do you test your code before deploying to production?**

   - _Follow-up_: What testing environments do you have access to?
   - _Follow-up_: How confident are you that your tests catch issues?
   - _Follow-up_: What testing challenges do you face?

7. **What tasks in your workflow feel like they should be automated but aren't?**
   - _Follow-up_: How much time would automation save you?
   - _Follow-up_: Have you tried to automate these tasks yourself?
   - _JTBD_: What would enable you to automate these more easily?

---

### Section 3: Troubleshooting and Production Issues (8-10 minutes)

**Objective**: Identify challenges in debugging and resolving production issues

**JTBD Focus**: "Help me quickly identify and fix production issues"

8. **Describe the last production issue you had to troubleshoot.**

   - _Follow-up_: What symptoms did you observe?
   - _Follow-up_: How did you go about finding the root cause?
   - _Follow-up_: How long did it take to identify and resolve the issue?
   - _Pain point probe_: What information was difficult to find?

9. **When something goes wrong in production, what's your first step?**

   - _Follow-up_: What tools do you use for troubleshooting?
   - _Follow-up_: How easy is it to find relevant logs and metrics?
   - _Follow-up_: Do you need help from other teams? How often?

10. **How do you monitor your applications in production?**
    - _Follow-up_: What metrics or alerts do you have set up?
    - _Follow-up_: How do you know when something is wrong?
    - _Follow-up_: What observability capabilities do you wish you had?
    - _JTBD_: What would make you feel more confident about your application's health?

---

### Section 4: Platform Capabilities and Features (8-10 minutes)

**Objective**: Assess platform awareness, feature adoption, and discoverability

**JTBD Focus**: "Help me understand what the platform can do for me"

11. **What platform features or tools do you use regularly?**

    - _Follow-up_: How did you discover these features?
    - _Follow-up_: What do you like most about them?
    - _Follow-up_: What could be improved?

12. **Are there platform capabilities you know exist but don't use? Why not?**

    - _Follow-up_: What would motivate you to try them?
    - _Follow-up_: What barriers prevent you from adopting them?
    - _Pain point_: How do you currently accomplish these tasks instead?

13. **How do you learn about new platform features or updates?**

    - _Follow-up_: Where do you typically look for platform documentation?
    - _Follow-up_: How useful is the documentation you find?
    - _Follow-up_: What documentation is missing or unclear?
    - _JTBD_: How do you prefer to learn about new tools and features?

14. **If you could add one capability to the platform that would make your job easier, what would it be?**
    - _Follow-up_: Why is this important to you?
    - _Follow-up_: How would you use this capability?
    - _Follow-up_: How much time would it save you or what problems would it solve?

---

### Section 5: Developer Experience and Pain Points (8-10 minutes)

**Objective**: Uncover frustrations, workarounds, and barriers to productivity

**JTBD Focus**: "Help me be productive and focus on writing code, not fighting infrastructure"

15. **What frustrates you most about your current development experience?**

    - _Follow-up_: Can you give me a specific recent example?
    - _Follow-up_: How often does this happen?
    - _Follow-up_: How does this impact your work or productivity?
    - _Pain point probe_: Have you found any workarounds?

16. **What tasks take longer than they should?**

    - _Follow-up_: Why do you think these tasks are slow?
    - _Follow-up_: What would "fast enough" look like to you?
    - _Follow-up_: How much time do you currently spend on these tasks?

17. **Tell me about a time when the platform prevented you from shipping a feature or caused a delay.**

    - _Follow-up_: What was the blocker?
    - _Follow-up_: How did you eventually resolve it?
    - _Follow-up_: What was the business impact?

18. **What do you spend time on that you wish you didn't have to?**
    - _Follow-up_: Why do you have to do these tasks?
    - _Follow-up_: What would it take to eliminate or reduce this work?
    - _JTBD_: What would you rather spend your time on instead?

---

### Section 6: Collaboration and Support (5-7 minutes)

**Objective**: Understand cross-team dynamics and support needs

19. **When you need help with the platform, where do you go?**

    - _Follow-up_: How easy is it to get help when you need it?
    - _Follow-up_: What's the typical response time?
    - _Follow-up_: How often do you need to reach out for help?
    - _Pain point_: What help channels are missing or ineffective?

20. **How do you collaborate with other developers and teams?**
    - _Follow-up_: What tools do you use for collaboration?
    - _Follow-up_: What collaboration challenges do you face?
    - _Follow-up_: How does the platform support or hinder collaboration?

---

### Closing Questions (3-5 minutes)

**Objective**: Capture overall sentiment and additional insights

21. **If you could wave a magic wand and change one thing about your development experience, what would it be?**
    - _Follow-up_: Why is this the most important thing to you?
    - _Follow-up_: How would your day-to-day work change if this were fixed?

**Wrap-up**:

- "Is there anything else about your experience that we haven't covered but you think is important?"
- "Can we reach out to you for follow-up questions if needed?"
- "Would you be interested in testing new features before they're released?"

---

## Post-Interview Protocol

### Immediate Actions (Within 1 hour)

- [ ] Save and backup recording (if applicable)
- [ ] Write down key quotes and memorable moments while fresh
- [ ] Note any strong emotional reactions or body language
- [ ] Identify 3-5 key takeaways

### Within 24 Hours

- [ ] Transcribe full interview notes
- [ ] Anonymize participant information (use role descriptor: "Mid-level Backend Developer, Team A")
- [ ] Highlight key quotes with context
- [ ] Tag pain points, JTBD, and workarounds
- [ ] Identify patterns or themes
- [ ] File notes in `docs/research/interviews/` with naming convention: `YYYY-MM-DD-application-developer-{topic}.md`

### Within 1 Week

- [ ] Send thank-you note to participant
- [ ] Share anonymized insights with product and engineering teams
- [ ] Update persona with new data points (if applicable)
- [ ] Log findings in insights repository
- [ ] Identify follow-up research questions

---

## Key Topics Coverage Checklist

Ensure all interviews cover these critical areas:

### Jobs to be Done (JTBD)

- [ ] Ship code quickly and confidently to production
- [ ] Troubleshoot and resolve production issues rapidly
- [ ] Understand platform capabilities and how to use them
- [ ] Focus on feature development, not infrastructure
- [ ] Collaborate effectively with team members
- [ ] Learn and adopt new tools and practices

### Pain Points

- [ ] Deployment complexity and anxiety
- [ ] Production troubleshooting difficulty
- [ ] Unclear platform capabilities and documentation
- [ ] Time spent on operational tasks vs. feature development
- [ ] Waiting for platform team support
- [ ] Fear of breaking production
- [ ] Inconsistent or outdated documentation
- [ ] Lack of observability and visibility

### Workarounds

- [ ] Manual deployment scripts
- [ ] Asking colleagues for help instead of using docs
- [ ] Deploying only during specific hours
- [ ] Avoiding certain platform features
- [ ] Building custom tooling outside the platform
- [ ] Relying on platform team for routine tasks

---

## Interview Analysis Guide

### Key Metrics to Track

- **Time to Deploy**: How long from code complete to production?
- **Deployment Frequency**: How often do they deploy? Why not more?
- **Troubleshooting Time**: Average time to resolve production issues
- **Platform Feature Awareness**: What features are they aware of vs. using?
- **Support Requests**: How often do they need help?
- **Time on Operational Tasks**: Percentage of time on non-development work

### Sentiment Analysis

Track emotional responses to:

- Deployment process (anxiety, confidence)
- Production issues (stress, frustration)
- Platform features (confusion, satisfaction)
- Documentation (helpfulness, completeness)
- Support (responsiveness, effectiveness)

### Pattern Identification

Look for common themes across interviews:

- Recurring pain points (3+ participants mention)
- Similar workarounds (indicates systemic issue)
- Consistent feature requests (prioritization signal)
- Shared frustrations (high-impact areas)

---

## Tips for Effective Interviewing

### Do's ✅

- **Listen actively**: Don't interrupt, let participants finish their thoughts
- **Show curiosity**: Use "tell me more" and "can you show me?"
- **Ask for specifics**: "Can you give me a recent example?"
- **Observe body language**: Note hesitation, frustration, excitement
- **Use silence**: Pause after questions to give time to think
- **Dig into workarounds**: They reveal unmet needs
- **Focus on behavior**: What they do, not just what they say

### Don'ts ❌

- **Don't lead**: Avoid "Don't you think...?" or "Wouldn't it be better if...?"
- **Don't defend**: Stay neutral, don't justify platform decisions
- **Don't skip pain**: Explore negative feedback as deeply as positive
- **Don't rush**: Allow time for participants to think and elaborate
- **Don't assume**: Ask clarifying questions even if you think you understand
- **Don't solve**: This is research, not a support session
- **Don't judge**: All feedback is valid and valuable

### Effective Follow-up Questions

- "Can you show me an example?"
- "What did you try first?"
- "How did that make you feel?"
- "What would success look like?"
- "Who else is affected by this?"
- "How often does this happen?"
- "What did you do instead?"
- "Why do you think that is?"

---

## Resources

- [Application Developer Persona](../personas/application-developer.md)
- [Interview Guide Template](../templates/interview-guide.md)
- [Research Repository README](../README.md)
- [Consent Form Template](./consent-form.md)
- **Recommended Reading**: "The Mom Test" by Rob Fitzpatrick

---

## Changelog

### Version 1.0 - December 2025

- Initial interview guide created for application developers
- 20 main questions across 6 sections
- Focus on JTBD, pain points, and workarounds
- Comprehensive protocol and analysis framework

---

**Document Owner**: Product Team
**Last Review**: December 2025
**Next Review**: March 2026 (or after 10+ interviews)
