# Usability Test Script Template

## Document Information

**Test Date**: [YYYY-MM-DD]  
**Facilitator**: [Your Name]  
**Note-Taker**: [Name or N/A]  
**Feature/Area Being Tested**: [e.g., "Application Deployment Workflow"]  
**Version**: 1.0  

---

## Test Overview

**Objectives:**
1. [Primary objective - what do we want to learn?]
2. [Secondary objective]
3. [Additional objective]

**Participants:**
- **Target Persona**: [e.g., Application Developer, Platform Engineer]
- **Number of Participants**: [5-8 recommended]
- **Experience Level**: [Mix of junior, mid, senior]

**Format**: [Moderated Remote / Unmoderated / In-Person]  
**Duration**: [45-60 minutes]  
**Recording**: [Yes - Screen + Audio / Yes - Screen Only / No]

---

## Pre-Test Setup

### Environment Preparation

**Test Environment**: [URL or environment name]  
**Test Account Credentials**:
- Username: `[test-username]`
- Password: `[test-password]` (or provide secure access method)

**Pre-Configured State:**
- [ ] Test environment is clean and reset
- [ ] Test account has appropriate permissions
- [ ] Sample data is loaded (if needed)
- [ ] All services are running and accessible

**Required Access:**
- [ ] Backstage: [URL]
- [ ] Jenkins: [URL]
- [ ] Grafana: [URL]
- [ ] [Other relevant tools]

### Materials Checklist

- [ ] This test script printed or accessible
- [ ] Observation checklist ready
- [ ] Consent form prepared (if recording)
- [ ] Recording tools tested
- [ ] Backup communication method ready
- [ ] Incentive/thank-you gift prepared (if applicable)

---

## Script

### Opening (5 minutes)

**Greeting and Rapport Building:**

```
"Hi [Participant Name], thanks so much for joining me today! I'm [Your Name] 
from the Product Team. How's your day going?"

[Brief small talk - 1-2 minutes]

"Great! Let me tell you what we'll be doing today..."
```

**Introduction:**

```
"Today, we're going to test [feature/workflow] in the Fawkes platform. I want 
to emphasize upfront: we're testing the platform, not you. There are absolutely 
no wrong answers or mistakes you can make.

If something is confusing, doesn't work as you expect, or frustrates you - 
that's exactly what we want to know. It means we need to improve the platform.

I'll ask you to complete some realistic tasks that [persona type] might do in 
their daily work. While you're working on these tasks, I'll ask you to 'think 
aloud' - basically, narrate what you're doing and thinking.

For example, if you're looking for a button, you might say: 'I'm looking for 
a way to create a new application. I expect to see a button somewhere near 
the top...'

This running commentary helps me understand your thought process and what 
you're expecting to see or happen.

I might occasionally ask follow-up questions, but I won't be able to help 
with the tasks themselves - we want to see how the platform works for you 
without guidance.

Does that make sense? Any questions so far?"
```

**Consent and Recording:**

```
"Before we start, I need to get your consent for a couple of things:

1. Are you comfortable participating in this usability test? Your participation 
   is completely voluntary, and you can stop at any time.

2. With your permission, I'd like to record this session - both your screen 
   and our audio. This recording is purely for note-taking purposes. It will 
   be stored securely, only accessible to the research team, and will be 
   deleted after we transcribe our notes.
   
   We will never share anything that identifies you personally. In our reports, 
   you'll be referred to as something like 'Participant 3' or 'Senior Platform 
   Engineer'.

Are you comfortable with me recording? Great, thank you. Let me start the 
recording now.

[Start recording]

For the recording, can you please verbally confirm:
- That you consent to participate in this usability test
- That you consent to being recorded
- That you understand your responses will be anonymized

Thank you."
```

**Set Expectations:**

```
"We have about [45-60 minutes] together. I have [N] tasks for you to try, 
and then a few wrap-up questions at the end.

For each task, I'll give you a scenario - a reason why you'd want to do this - 
and then ask you to accomplish a goal using the platform.

Please share your screen so I can see what you're doing. And remember to think 
aloud as you work - tell me what you're looking for, what you're thinking, 
if you're confused, or if something surprises you.

If you get really stuck on a task, I'll give you a couple of minutes to try 
to figure it out, and then I might jump in with a hint. Some tasks might even 
be impossible to complete - if that's the case, that's really valuable feedback 
for us.

Do you have any questions before we dive in?"
```

---

## Tasks

### Task 1: [Task Name]

**Scenario:**
```
"[Provide context and motivation for the task]

For example:
You're a new developer who just joined a team. Your team lead has asked you 
to deploy your first microservice to the development environment. You have 
a Node.js application ready to go."
```

**Goal:**
```
"Your goal is to: [Clear, specific objective]

For example:
Use the Backstage developer portal to create a new application from the 
Node.js template and deploy it to the development environment."
```

**Starting Point:**
```
"Let's start here: [URL or specific location]

Please navigate to: [URL]
And use these credentials if you're not already logged in:
- Username: [username]
- Password: [password]

Go ahead and share your screen now, and please start thinking aloud as you work."
```

**Success Criteria (For Your Notes - Don't Share with Participant):**
- [ ] User navigates to correct location
- [ ] User finds the feature/button/menu
- [ ] User completes configuration correctly
- [ ] User successfully accomplishes the goal
- [ ] Task completed in [X] minutes or less

**Observation Notes:**

Time Started: ________  
Time Completed: ________  
Task Status: ☐ Success  ☐ Partial Success  ☐ Failure

**Actions Taken:**
- [Note each major action]
- [Note where they looked first]
- [Note wrong turns or backtracking]

**Quotes:**
- "[Capture exact words when confused]"
- "[Capture expressions of frustration or delight]"

**Issues Encountered:**
- **[Severity]**: [Description]
- **[Severity]**: [Description]

**Probing Questions (Use Sparingly):**
- "What are you thinking right now?"
- "What are you looking for?"
- "Is this what you expected?"
- "Why did you click there?"

**If Stuck (After 2-3 Minutes):**
```
"I can see you're working through this. Can you tell me what you're trying 
to find or do right now?"

[If still stuck after another minute, provide hint]:
"Let me give you a hint: [minimal hint that gets them unstuck]"

[If still unable to proceed]:
"Okay, let's pause here. This is really valuable feedback - if you can't 
find it, we need to make it more obvious. Let me show you where it is, and 
then we'll move on to the next task."
```

**Post-Task Questions:**
```
"Okay, let's pause there. 

1. How did that feel? (Let them respond naturally)

2. On a scale of 1 to 5, where 1 is 'not at all confident' and 5 is 'very 
   confident', how confident are you that you completed that task correctly?

3. What was most confusing or frustrating about that task?

4. What, if anything, would have made that easier?"
```

---

### Task 2: [Task Name]

[Repeat the same structure as Task 1]

**Scenario:**
```
[Context and motivation]
```

**Goal:**
```
[Clear objective]
```

**Starting Point:**
```
[Where to begin]
```

**Success Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

**Observation Notes:**

Time Started: ________  
Time Completed: ________  
Task Status: ☐ Success  ☐ Partial Success  ☐ Failure

[Continue with observation sections as in Task 1]

---

### Task 3: [Task Name]

[Repeat structure]

---

## Post-Task Questions (10 minutes)

**Overall Experience:**

```
"Thank you for working through those tasks. Now I have some questions about 
your overall experience.

1. Overall, how would you rate the ease of use of [feature/workflow] on a 
   scale of 1 to 5, where 1 is very difficult and 5 is very easy?
   
   Rating: [ ]
   Why that rating?

2. Which task was the most difficult for you? Why?

3. Which task was the easiest? Why?

4. What surprised you - either positively or negatively - about the platform?

5. Thinking about your normal workflow, is there anything missing that you'd 
   expect to see or be able to do?

6. If you could wave a magic wand and change one thing about what you tested 
   today, what would it be?

7. Is there anything we didn't test today that you think would be important 
   for [persona type] to be able to do?

8. On a scale of 1 to 5, how likely would you be to recommend this platform 
   to a colleague?
   
   Rating: [ ]
   Why that rating?"
```

**Notes:**
- [Capture responses]
- [Note tone and confidence]
- [Record any additional insights]

---

## Closing (5 minutes)

**Thank You:**

```
"This has been incredibly valuable. Thank you so much for your time and your 
honest feedback. You've given us really important insights that will help us 
improve the platform.

Your feedback will be anonymized and shared with the product and engineering 
teams. We'll use it to prioritize improvements to [feature/workflow]. You 
might see some changes in the next few months based on what we learned today.

Before we finish, I have two quick administrative things:

1. Can we reach out to you if we have brief follow-up questions? [Note response]

2. Would you be willing to participate in future usability tests as we improve 
   the platform? [Note response]

Great. We'll send you [incentive/thank-you gift] within [timeframe].

Thanks again, [Name]. Have a great rest of your day!"
```

**Stop Recording**

---

## Immediate Post-Session Notes (10 minutes)

**Complete This Immediately After Session While Memory is Fresh:**

**Overall Impressions:**
- Top 3 insights from this session:
  1. [Insight 1]
  2. [Insight 2]
  3. [Insight 3]

**Critical Issues:**
- [Any issues that completely block the workflow]
- [Issues that caused significant frustration]

**Positive Findings:**
- [What worked well]
- [What the user appreciated]

**Task Success Summary:**

| Task | Status | Time | Confidence | Issues |
|------|--------|------|------------|--------|
| Task 1: [Name] | [S/P/F] | [min] | [1-5] | [Count] |
| Task 2: [Name] | [S/P/F] | [min] | [1-5] | [Count] |
| Task 3: [Name] | [S/P/F] | [min] | [1-5] | [Count] |

**Usability Ratings:**
- Ease of Use: [1-5]
- Likelihood to Recommend: [1-5]

**Follow-Up Actions:**
- [ ] File detailed session notes within 24 hours
- [ ] Create GitHub issues for critical problems
- [ ] Add quotes to quotes library
- [ ] Update metrics spreadsheet
- [ ] Flag urgent issues to team

---

## Analysis Guidelines

### Within 24 Hours

1. **Review Recording**
   - Watch at 1.5-2x speed
   - Note timestamps of key moments
   - Transcribe important quotes
   - Confirm your live observations

2. **Detailed Session Notes**
   - Create file: `docs/research/data/processed/usability-tests/YYYY-MM-DD-{persona}-{feature}.md`
   - Use the analysis template
   - Include all task results, quotes, and observations
   - Categorize issues by severity

3. **Update Tracking**
   - Add to usability test tracker spreadsheet
   - Update issue counts
   - Track pattern emergence

### After All Sessions Complete

1. **Cross-Session Synthesis**
   - Look for patterns across participants
   - Calculate aggregate metrics (success rates, avg times)
   - Identify issues by frequency
   - Separate persona-specific vs. universal issues

2. **Findings Document**
   - Create: `docs/research/insights/YYYY-MM-{feature}-usability-findings.md`
   - Include methodology, findings, recommendations
   - Prioritize issues (P0, P1, P2)
   - Add supporting evidence (quotes, metrics, video timestamps)

3. **Communication**
   - Share summary with stakeholders
   - Create GitHub issues for prioritized problems
   - Present findings in product review
   - Plan follow-up testing after fixes

---

## Appendices

### Severity Ratings

**Critical (P0):**
- Completely blocks task completion
- Causes data loss or system errors
- Affects majority of users
- No workaround exists

**Major (P1):**
- Causes significant delay or frustration
- Task completable but difficult
- Affects many users
- Workaround exists but not obvious

**Minor (P2):**
- Causes mild confusion or inefficiency
- Task easily completable
- Affects some users
- Minimal impact on workflow

**Enhancement (P3):**
- Not a problem, but could be better
- Suggestion for improvement
- Low impact, high polish

### Sample Probing Questions

**Understanding Expectations:**
- "What do you expect to see when you click that?"
- "Where do you expect to find [feature]?"
- "What do you think that button will do?"

**Exploring Thought Process:**
- "Talk me through what you're thinking"
- "Why did you choose that option?"
- "What made you go back?"

**Uncovering Issues:**
- "Is this what you were looking for?"
- "How are you feeling about this right now?"
- "What would you do if you were stuck like this in your actual work?"

**Gathering Feedback:**
- "How could this be more clear?"
- "What would you call this feature?"
- "Where would you expect to find this?"

---

**Template Version**: 1.0  
**Last Updated**: December 2025  
**Owner**: Product Team
