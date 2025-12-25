# Usability Testing Guide

## Document Information

**Version**: 1.0
**Last Updated**: December 2025
**Status**: Active
**Owner**: Product Team
**Audience**: Product Managers, UX Researchers, Platform Engineers conducting usability tests

---

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Planning Usability Tests](#planning-usability-tests)
4. [Conducting Tests](#conducting-tests)
5. [Recording and Analysis](#recording-and-analysis)
6. [Best Practices](#best-practices)
7. [Tools and Resources](#tools-and-resources)

---

## Overview

### What is Usability Testing?

Usability testing is a method to evaluate how easy and intuitive the Fawkes platform is for users to accomplish their goals. By observing real users attempting realistic tasks, we identify friction points, confusing workflows, and opportunities for improvement.

### Purpose

- **Validate Design Decisions**: Test whether platform features work as intended for real users
- **Identify Friction Points**: Discover where users struggle or get confused
- **Improve User Experience**: Make data-driven improvements based on actual user behavior
- **Catch Issues Early**: Find usability problems before they impact many users
- **Measure Success**: Track improvements in task completion rates and satisfaction

### When to Conduct Usability Testing

- **Before Major Releases**: Test new features with target users
- **During Beta Testing**: Validate workflows with early adopters
- **After User Feedback**: Investigate reported issues or complaints
- **Quarterly Reviews**: Regular testing to track UX improvements
- **After Significant Changes**: Verify migrations or redesigns work well

### Types of Usability Tests

#### 1. Moderated Remote Testing
- **Best for**: In-depth feedback, complex workflows
- **Format**: Live session with facilitator via video call
- **Duration**: 45-60 minutes
- **Tools**: Zoom/Teams + screen recording

#### 2. Unmoderated Remote Testing
- **Best for**: Quick validation, simple tasks
- **Format**: User completes tasks independently
- **Duration**: 15-30 minutes
- **Tools**: Session recording platform

#### 3. In-Person Testing
- **Best for**: Observing physical behavior, workshop settings
- **Format**: Face-to-face in lab or office
- **Duration**: 60-90 minutes
- **Tools**: Physical recording setup

---

## Getting Started

### Prerequisites

1. **Access to Recording Tools**
   - OpenReplay session recording platform (deployed via ArgoCD)
   - Video conferencing with recording (Zoom, Teams, Google Meet)
   - Screen recording software (optional backup)

2. **Required Materials**
   - Test script template (see `docs/research/templates/usability-test-script.md`)
   - Consent form (see `docs/research/interviews/consent-form.md`)
   - Participant screener questionnaire
   - Observation checklist

3. **Environment Setup**
   - Test environment URL (staging or dedicated test instance)
   - Test accounts with appropriate permissions
   - Sample data for realistic scenarios

### Quick Start Checklist

- [ ] Define test objectives (what do you want to learn?)
- [ ] Create task scenarios (what will users do?)
- [ ] Recruit participants (5-8 users per persona)
- [ ] Prepare test script and materials
- [ ] Set up recording tools
- [ ] Conduct pilot test (practice run)
- [ ] Schedule sessions with participants
- [ ] Run usability tests
- [ ] Analyze findings and synthesize insights
- [ ] Share results and recommendations

---

## Planning Usability Tests

### 1. Define Research Objectives

**Start with clear questions:**
- What do we want to learn from this test?
- What decisions will the results inform?
- What specific workflows or features are we testing?

**Example Objectives:**
- "Evaluate whether new developers can deploy their first application within 30 minutes"
- "Identify pain points in the incident response workflow"
- "Assess if platform engineers can configure observability without documentation"

### 2. Create Task Scenarios

Tasks should be:
- **Realistic**: Based on actual user goals
- **Specific**: Clear success criteria
- **Measurable**: Can be completed or not
- **Representative**: Cover key workflows

**Task Structure:**
```markdown
## Task [N]: [Task Name]

**Scenario**: [Context that motivates the task]

**Goal**: [What the user needs to accomplish]

**Success Criteria**:
- [ ] User completes task without assistance
- [ ] Task completed in [X] minutes or less
- [ ] User expresses confidence (rating 4/5 or higher)

**Starting Point**: [Where user begins - URL or state]

**Acceptance**:
- Task is complete when: [specific end state]
```

**Example Tasks:**

```markdown
## Task 1: Deploy a New Application

**Scenario**: You're a new developer who needs to deploy a Node.js application to the platform for the first time.

**Goal**: Use Backstage to create a new application from a template and deploy it to the development environment.

**Success Criteria**:
- [ ] User finds the software catalog
- [ ] User creates new app from template
- [ ] User triggers deployment
- [ ] App is running and accessible

**Starting Point**: https://backstage.fawkes.local (logged in)

**Acceptance**: Task is complete when the application is deployed and the user can access the running app.
```

### 3. Recruit Participants

**Selection Criteria:**
- **Primary Users**: 5-8 participants per persona
- **Diverse Experience**: Mix of junior, mid, senior
- **Representative**: Different teams, tech stacks
- **Available**: Can commit 60-90 minutes

**Recruitment Methods:**
- Mattermost announcement in `#platform-feedback`
- Email to platform users
- Personal outreach to power users
- Incentives (gift cards, swag, recognition)

**Screener Questions:** See `docs/research/templates/participant-screener.md`

### 4. Schedule Sessions

**Timing:**
- Space sessions 30 minutes apart (for notes review)
- Avoid Monday mornings and Friday afternoons
- Limit to 3-4 sessions per day (avoid fatigue)

**Calendar Invite Should Include:**
- Purpose and duration (be honest about time commitment)
- Video conferencing link
- What to expect (tasks, recording, confidentiality)
- Pre-work if needed (access test environment, review context)
- Contact info for questions

---

## Conducting Tests

### Before the Session

**15 Minutes Before:**
- [ ] Join meeting room early
- [ ] Test screen sharing and recording
- [ ] Open test script and observation checklist
- [ ] Prepare test environment (clean state, test account ready)
- [ ] Review participant background
- [ ] Clear your mind - be ready to observe, not judge

### Opening (5 minutes)

**Build Rapport:**
```
"Hi [Name], thanks so much for joining me today. I'm [Your Name] from the
Product Team, and I'm excited to learn from you.

Today we're going to test some workflows in the Fawkes platform. I want to
emphasize that we're testing the platform, not you. There are no wrong
answers or mistakes you can make. If something is confusing or doesn't work,
that's valuable feedback for us.

I'll ask you to complete some tasks while thinking aloud - basically, narrate
what you're thinking and doing as you go. This helps me understand your
thought process. I might occasionally ask follow-up questions, but I won't
be able to help with the tasks themselves.

Your responses will be anonymized, and we won't share anything that identifies
you personally. With your permission, I'd like to record this session for
note-taking purposes only. Are you comfortable with that?"
```

**Get Consent:**
- Explicit verbal consent to participate
- Explicit consent to record (screen and audio)
- Explain data retention (recordings deleted after transcription)
- Answer any questions

**Set Expectations:**
```
"We'll spend about [45-60 minutes] today. I have [N] tasks for you to try.
For each one, I'll give you a scenario and ask you to accomplish a goal.
Please share your screen so I can see what you're doing.

Remember to think aloud - tell me what you're looking for, what you expect
to happen, if you're confused, or if something surprises you. This running
commentary is incredibly valuable.

If you get stuck, I'll give you 2-3 minutes to try to figure it out, then
I might jump in with a hint. Some tasks might be impossible - that's okay
and useful for us to know.

Any questions before we start?"
```

### During Tasks (40-50 minutes)

**Introduce Each Task:**
- Read scenario and goal
- Clarify any questions about the scenario (but not how to do it)
- Have them share screen if not already
- Ask them to start thinking aloud
- Start timer (internal, not visible to them)

**While They Work:**

**👍 Do:**
- Observe silently - let them struggle (it reveals problems)
- Take detailed notes on actions, reactions, quotes
- Note timestamps for video review later
- Track task metrics (time, success/fail, help needed)
- Use minimal verbal encouragement ("mm-hmm", "keep going")

**👎 Don't:**
- Jump in to help immediately when they're stuck
- Lead them to the solution
- Explain how features work
- Defend design decisions
- Show your disappointment or surprise

**Thinking Aloud Reminders:**
If they go silent, gently prompt:
- "What are you thinking?"
- "What are you looking for?"
- "Talk me through what you're doing"
- "What do you expect to happen?"

**Probing Questions (use sparingly):**
- "Why did you click there?"
- "What made you think to do that?"
- "Is this what you expected?"
- "How are you feeling about this?"

**When to Intervene:**
- After 2-3 minutes of being completely stuck
- If they're about to do something destructive (delete prod data)
- If they ask directly for help

**When They Complete (or Give Up):**
- "Okay, let's pause there. How did that feel?"
- "On a scale of 1-5, how confident are you that you completed that correctly?"
- "What was most confusing or frustrating?"
- "What would have made that easier?"

### Post-Task Questions

After all tasks:
```
"We've completed all the tasks. I have a few wrap-up questions:

1. Overall, how would you rate the ease of use? (1-5)
2. Which task was most difficult? Why?
3. Which task was easiest? Why?
4. What surprised you (positively or negatively)?
5. If you could change one thing about the platform, what would it be?
6. Is there anything we didn't test that you think is important?
7. Would you recommend this platform to a colleague? Why or why not?"
```

### Closing (5 minutes)

**Thank Participant:**
```
"Thank you so much for your time and honest feedback. This is incredibly
valuable for improving the platform.

Your feedback will be anonymized and shared with the team. We'll use it to
prioritize improvements. You might see some changes in the next few months
based on what we learned today.

Can we reach out if we have follow-up questions or want to test improvements
with you?"
```

**Post-Session Immediate Capture (10 minutes):**
- Rate task success (success, partial, failure)
- Note 3-5 top insights while memory is fresh
- Flag critical issues that need immediate attention
- Score usability ratings
- File detailed notes within 24 hours

---

## Recording and Analysis

### Recording Tools

#### OpenReplay Session Recording
- **Best for**: Unmoderated remote tests, replay sessions
- **Access**: https://openreplay.fawkes.local
- **Features**:
  - Session replay with DOM recording
  - Console logs and network traffic
  - User interaction heatmaps
  - Search by user ID, session metadata

**Setup:**
```bash
# Deploy OpenReplay via ArgoCD
kubectl apply -f platform/apps/openreplay/openreplay-application.yaml

# Add tracking snippet to test environment
# See docs/how-to/session-recording-setup.md
```

#### Video Recording (Zoom/Teams)
- **Best for**: Moderated sessions, capturing think-aloud
- **Settings**:
  - Enable cloud recording
  - Record both gallery and screen share
  - Enable transcript if available
  - Store in secure location (not public)

### Note-Taking During Sessions

**Observation Checklist:**
Use this template: `docs/research/templates/usability-observation-checklist.md`

**Capture:**
- [ ] Task completion (success/fail/partial)
- [ ] Time to complete each task
- [ ] Number of errors or wrong turns
- [ ] Severity of issues (critical, major, minor)
- [ ] Direct quotes (confusion, delight, frustration)
- [ ] Emotional reactions (facial expressions, tone)
- [ ] Workarounds used
- [ ] Features they expected but didn't find

**Severity Ratings:**
- **Critical**: User cannot complete task, blocks workflow
- **Major**: Significant delay or frustration, but completable
- **Minor**: Small confusion or inefficiency, doesn't block
- **Enhancement**: Not a problem, but could be better

### Analysis Process

#### 1. Individual Session Analysis (Within 24 Hours)

**Review Recording:**
- Watch at 1.5-2x speed
- Focus on moments of confusion or delight
- Transcribe key quotes
- Confirm your live notes

**Document Session:**
File: `docs/research/data/processed/usability-tests/YYYY-MM-DD-{persona}-{feature}.md`

```markdown
# Usability Test: [Feature] - [Persona] - [Date]

## Participant Profile
- **Role**: [e.g., Senior Platform Engineer]
- **Experience**: [e.g., 5 years DevOps, 1 year with platform]
- **Tech Stack**: [e.g., Java, Kubernetes, Jenkins]

## Task Results

### Task 1: [Task Name]
- **Status**: Success / Partial / Failure
- **Time**: [X] minutes
- **Confidence**: [1-5]
- **Observations**:
  - [Observation 1]
  - [Observation 2]
- **Quotes**:
  - "[Direct quote about confusion]"
  - "[Direct quote about success]"
- **Issues**:
  - **[Critical]**: [Description of blocking issue]
  - **[Major]**: [Description of significant problem]

[Repeat for each task]

## Overall Ratings
- **Ease of Use**: [1-5]
- **Would Recommend**: Yes / No / Maybe
- **Top Insight**: [Most important finding from this session]
```

#### 2. Cross-Session Synthesis (After All Sessions)

**Look for Patterns:**
- Which issues appeared in multiple sessions?
- Are there issues specific to certain personas?
- What's the success rate for each task?
- What are common points of confusion?

**Create Synthesis Document:**
File: `docs/research/insights/YYYY-MM-{feature}-usability-findings.md`

```markdown
# Usability Test Findings: [Feature] - [Date]

## Executive Summary
[2-3 sentences: what we tested, who we tested with, key findings]

## Methodology
- **Participants**: [N] users ([breakdown by persona])
- **Tasks**: [N] task scenarios
- **Format**: [Moderated remote / Unmoderated / In-person]
- **Dates**: [Date range]

## Key Findings

### Finding 1: [Critical Issue]
**Severity**: Critical
**Frequency**: [X/N] participants affected
**Impact**: [Description of user impact]

**Evidence**:
- Task 2: 6/8 participants failed to complete
- Quotes: "[User quote]", "[User quote]"
- Video: [Timestamp in recording]

**Recommendation**: [Specific fix]

[Repeat for each finding]

## Task Performance Summary

| Task | Success Rate | Avg Time | Avg Confidence |
|------|-------------|----------|----------------|
| Task 1: Deploy App | 75% (6/8) | 12 min | 4.2/5 |
| Task 2: Configure Observability | 25% (2/8) | 18 min | 2.1/5 |
| Task 3: Troubleshoot Error | 50% (4/8) | 22 min | 3.5/5 |

## Prioritized Recommendations

### Must Fix (P0)
1. **[Issue]**: [Brief description]
   - Impact: [Why critical]
   - Effort: [Low/Medium/High]
   - Owner: [Team/person]

### Should Fix (P1)
[Similar structure]

### Nice to Have (P2)
[Similar structure]

## Positive Findings
- [What users loved or found easy]
- [Features that exceeded expectations]

## Next Steps
- [ ] Create GitHub issues for P0 items
- [ ] Schedule design review for recommendations
- [ ] Plan follow-up test after fixes
- [ ] Share findings with stakeholders
```

### 3. Communicate Results

**Immediate (Within 1 Week):**
- Email summary to stakeholders
- Post in `#product-research` Mattermost channel
- Create GitHub issues for critical items
- Add to product backlog

**Monthly:**
- Include in product review meeting
- Update roadmap based on findings
- Track issue resolution

---

## Best Practices

### Planning

✅ **Do:**
- Test early and often (don't wait for perfection)
- Recruit diverse participants (experience, role, tech stack)
- Test realistic scenarios based on actual user goals
- Pilot test your script with a colleague first
- Allow enough time between sessions for notes review

❌ **Don't:**
- Test with internal team only (you're too familiar with the platform)
- Make tasks too easy or too specific (not realistic)
- Skip consent or recording permission
- Schedule back-to-back sessions (you'll burn out)

### During Tests

✅ **Do:**
- Let users struggle - silence reveals problems
- Capture exact quotes (use their language)
- Note emotional reactions (frustration, delight, confusion)
- Be empathetic and non-judgmental
- Test in environment similar to production

❌ **Don't:**
- Jump in to help immediately
- Explain how features "should" work
- Defend design decisions
- Lead participants to correct answer
- Interrupt their thought process

### Analysis

✅ **Do:**
- Analyze within 24 hours (while memory is fresh)
- Look for patterns across multiple users
- Prioritize by severity and frequency
- Include positive findings too
- Make specific, actionable recommendations

❌ **Don't:**
- Generalize from one user's experience
- Cherry-pick only findings that support your position
- Focus only on what's broken (also capture what works)
- Leave findings in your notes (share them!)

---

## Tools and Resources

### Internal Resources

**Templates:**
- [Usability Test Script Template](../research/templates/usability-test-script.md)
- [Observation Checklist](../research/templates/usability-observation-checklist.md)
- [Participant Screener](../research/templates/participant-screener.md)
- [Analysis Template](../research/templates/usability-analysis-template.md)

**Guides:**
- [Interview Protocol](../research/interviews/interview-protocol.md)
- [Consent Form](../research/interviews/consent-form.md)
- [Research Repository](../research/README.md)

**Platform Tools:**
- [OpenReplay Setup Guide](./session-recording-setup.md)
- [Recording Best Practices](./recording-best-practices.md)

### External Resources

**Books:**
- "Rocket Surgery Made Easy" by Steve Krug (quintessential guide)
- "Don't Make Me Think" by Steve Krug (usability principles)
- "The User Experience Team of One" by Leah Buley (practical tips for solo researchers)

**Articles:**
- [Nielsen Norman Group - Usability Testing 101](https://www.nngroup.com/articles/usability-testing-101/)
- [How Many Test Users in a Usability Study?](https://www.nngroup.com/articles/how-many-test-users/)
- [Thinking Aloud: The #1 Usability Tool](https://www.nngroup.com/articles/thinking-aloud-the-1-usability-tool/)

**Videos:**
- [Steve Krug's Usability Test Demo](https://www.youtube.com/watch?v=1UCDUOB_aS8)

### Support

**Questions?**
- **Mattermost**: `#product-research` channel
- **Email**: product-team@fawkes.local
- **Office Hours**: Wednesdays 2-3 PM

**Need Help?**
- **Recruiting Participants**: Post in `#platform-feedback`
- **Technical Issues**: `#platform-support`
- **Analysis Help**: Schedule time with Product Team

---

## Changelog

### Version 1.0 - December 2025
- Initial usability testing guide
- Comprehensive planning, execution, analysis guidance
- Templates and tools reference
- Best practices and anti-patterns

---

**Document Owner**: Product Team
**Last Review**: December 2025
**Next Review**: June 2026 or based on feedback
