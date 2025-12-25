# Interview Guide Templates

## Document Information

**Version**: 1.0
**Last Updated**: December 2025
**Status**: Active
**Owner**: Product Team

---

## Table of Contents

1. [Discovery Interviews](#discovery-interviews)
2. [Usability Testing](#usability-testing)
3. [Feedback Interviews](#feedback-interviews)
4. [Onboarding Interviews](#onboarding-interviews)

---

## Discovery Interviews

**Purpose**: Explore problems, needs, and workflows to identify opportunities for platform improvements.

### Objectives

- Understand current workflows and pain points
- Identify unmet needs and frustrations
- Discover workarounds and manual processes
- Validate problem hypotheses
- Prioritize areas for platform investment

### Screener Questions

Use these questions to select appropriate interview participants:

1. **Role**: What is your current role and team?
2. **Experience**: How long have you been working with internal developer platforms?
3. **Frequency**: How often do you deploy applications or use platform services?
4. **Technology Stack**: What programming languages and frameworks do you primarily use?
5. **Platform Usage**: Which platform tools do you use daily? (e.g., CI/CD, monitoring, service catalog)

**Selection Criteria**:

- Mix of experience levels (junior, mid, senior)
- Diverse roles (developers, DevOps, platform engineers)
- Various teams and business units
- Different technology stacks

### Main Questions

#### Current State

1. **Walk me through your typical development workflow from local development to production.**

   - _Follow-up_: What tools do you use at each stage?
   - _Follow-up_: Where do you spend the most time?

2. **What are the biggest challenges you face when deploying applications?**

   - _Follow-up_: How often does this happen?
   - _Follow-up_: How do you currently work around these issues?

3. **Describe the last time you had to troubleshoot a production issue.**

   - _Follow-up_: What information did you need?
   - _Follow-up_: How long did it take to resolve?
   - _Follow-up_: What made it difficult?

4. **What tasks do you find yourself doing repeatedly that feel like they should be automated?**
   - _Follow-up_: How much time do these tasks consume?
   - _Follow-up_: Have you tried to automate them?

#### Pain Points

5. **What frustrates you most about the current platform?**

   - _Follow-up_: Can you give me a specific example?
   - _Follow-up_: How does this impact your work?

6. **What information do you wish you had easier access to?**

   - _Follow-up_: Where do you currently find this information?
   - _Follow-up_: How often do you need it?

7. **Tell me about a time when the platform prevented you from doing your job effectively.**
   - _Follow-up_: What was the business impact?
   - _Follow-up_: How was it eventually resolved?

#### Ideal State

8. **If you could wave a magic wand and improve one thing about the platform, what would it be?**

   - _Follow-up_: Why is this most important to you?
   - _Follow-up_: How would this change your day-to-day work?

9. **What does "developer experience" mean to you?**

   - _Follow-up_: Can you give examples of good vs. bad developer experience?

10. **What capabilities or features do you wish the platform had?**
    - _Follow-up_: What would you use them for?
    - _Follow-up_: What's preventing you from achieving this today?

### Follow-up Questions

- Can you show me an example of that?
- How often does this happen?
- What did you do instead?
- Who else is affected by this?
- What would success look like?
- Is there anything else you'd like to share?

### Interview Guidelines

**Before the Interview:**

- Schedule 45-60 minutes
- Send objectives and topics in advance
- Request permission to record
- Prepare your note-taking system

**During the Interview:**

- Start with rapport building
- Use the "5 Whys" technique to dig deeper
- Observe non-verbal cues
- Allow for silence (don't rush)
- Be curious, not leading
- Take notes on direct quotes

**After the Interview:**

- Send thank you note
- Synthesize notes within 24 hours
- Identify key themes and insights
- Share anonymized findings with stakeholders

---

## Usability Testing

**Purpose**: Validate that features and workflows are intuitive, efficient, and meet user needs.

### Objectives

- Evaluate feature usability before launch
- Identify UI/UX friction points
- Measure task completion rates and time
- Gather qualitative feedback on design
- Validate information architecture

### Screener Questions

1. **Role**: What is your role and primary responsibilities?
2. **Platform Usage**: How frequently do you use [specific feature/tool]?
3. **Technical Proficiency**: Rate your comfort level with [technology]: Beginner / Intermediate / Advanced
4. **Availability**: Can you participate in a 45-minute usability session?
5. **Environment**: Do you have access to [required environment/tools]?

**Selection Criteria**:

- Representative of target user personas
- Mix of technical skill levels
- Unfamiliar with the specific feature (for new features)
- Regular users (for redesigns)

### Main Questions

#### Pre-Task Questions

1. **What are your expectations for this feature?**

   - _Follow-up_: What problems do you hope it solves?

2. **Have you used similar features in other platforms?**
   - _Follow-up_: What did you like or dislike about them?

#### Task Scenarios

**Task Format**: "Imagine you need to [accomplish goal]. Use the platform to complete this task."

**Example Tasks**:

- Task 1: Deploy a new microservice to the development environment
- Task 2: Set up monitoring and alerts for your service
- Task 3: View the deployment history and rollback to a previous version
- Task 4: Configure environment variables for your application

**For Each Task, Observe**:

- Time to completion
- Number of clicks/steps
- Errors or wrong paths taken
- Hesitation points
- Facial expressions and body language

**During Tasks, Ask**:

1. **What are you thinking as you do this?** (Think-aloud protocol)
2. **What do you expect to happen when you click that?**
3. **Is this what you expected to see?**
   - _If not_: What did you expect?
4. **How would you describe what you just did?**

#### Post-Task Questions

5. **How easy or difficult was that task?** (Scale 1-5: Very Difficult to Very Easy)

   - _Follow-up_: What made it [easy/difficult]?

6. **Was there anything confusing or unclear?**

   - _Follow-up_: What would have helped?

7. **Did you feel confident completing this task?**

   - _Follow-up_: What created uncertainty?

8. **What would you change about this workflow?**

#### Wrap-up Questions

9. **Overall, how would you rate your experience?** (Scale 1-5: Very Poor to Excellent)

10. **Would you use this feature in your daily work?**

    - _Follow-up_: Why or why not?

11. **What did you like most about the experience?**

12. **What frustrated you the most?**

13. **Is there anything we didn't ask about that you think is important?**

### Testing Guidelines

**Before the Session:**

- Prepare test environment
- Create realistic test data
- Test your recording setup
- Have tasks written out clearly
- Prepare consent form

**During the Session:**

- Encourage think-aloud narration
- Don't provide help unless stuck for >2 minutes
- Take notes on both actions and comments
- Use neutral language ("How would you do X?" not "Click X")
- Record time and success metrics

**After the Session:**

- Calculate success rates and time-on-task
- Categorize issues by severity (critical, major, minor)
- Identify patterns across participants
- Prioritize fixes based on frequency and impact

---

## Feedback Interviews

**Purpose**: Gather feedback on existing features to identify improvement areas and prioritize enhancements.

### Objectives

- Understand feature usage patterns
- Identify improvement opportunities
- Gauge user satisfaction
- Prioritize feature requests
- Discover hidden issues

### Screener Questions

1. **Feature Usage**: How often do you use [specific feature]?
2. **Duration**: How long have you been using this feature?
3. **Outcome**: Do you typically achieve what you set out to do with this feature?
4. **Context**: What is your primary use case for this feature?

**Selection Criteria**:

- Active users of the feature
- Mix of successful and struggling users
- Different use cases
- Various team sizes

### Main Questions

#### Usage Patterns

1. **How do you typically use [feature] in your workflow?**

   - _Follow-up_: Walk me through a recent example.
   - _Follow-up_: How often do you use it?

2. **What prompted you to start using this feature?**

   - _Follow-up_: What alternatives did you consider?

3. **What do you use this feature for?**
   - _Follow-up_: Are there use cases we might not have anticipated?

#### Satisfaction

4. **On a scale of 1-10, how satisfied are you with [feature]?**

   - _Follow-up_: What would it take to make it a 10?

5. **What do you like most about this feature?**

   - _Follow-up_: Why is that important to you?

6. **What frustrates you about this feature?**

   - _Follow-up_: How do you work around these limitations?

7. **Is there anything missing that would make this feature more useful?**
   - _Follow-up_: What would you use that for?

#### Specific Feedback

8. **How intuitive is the feature to use?** (Scale 1-5)

   - _Follow-up_: What was confusing when you first used it?
   - _Follow-up_: What would make it more intuitive?

9. **How well does the feature integrate with your other tools?**

   - _Follow-up_: What integration would be most valuable?

10. **How is the performance of this feature?**
    - _Follow-up_: Have you experienced any issues?
    - _Follow-up_: How does this impact your work?

#### Future Direction

11. **If you could add one capability to this feature, what would it be?**

    - _Follow-up_: How would you use that capability?
    - _Follow-up_: How important is this to your work?

12. **What would make you use this feature more often?**

13. **Is there anything about this feature that you wish worked differently?**

### Follow-up Questions

- Can you show me how you do that?
- How much time would that save you?
- How does this compare to other tools you've used?
- Who else on your team would benefit from this?
- What's the impact when this doesn't work as expected?

### Interview Guidelines

**Before the Interview:**

- Review usage data for the participant
- Identify specific behaviors to explore
- Prepare scenarios if needed
- Have recent feedback/issues available

**During the Interview:**

- Ask for demonstrations when possible
- Explore both positive and negative experiences
- Dig into workarounds (they reveal needs)
- Validate feature requests with use cases

**After the Interview:**

- Categorize feedback (bugs, enhancements, education)
- Prioritize by impact and feasibility
- Close the loop with participants on actions taken
- Share themes with product and engineering teams

---

## Onboarding Interviews

**Purpose**: Understand the new user experience and identify barriers to adoption and productivity.

### Objectives

- Evaluate onboarding effectiveness
- Identify knowledge gaps
- Reduce time to first value
- Improve documentation and training
- Measure initial impressions

### Screener Questions

1. **Tenure**: How long have you been using the platform?
2. **Experience Level**: How would you rate your overall technical experience?
3. **Onboarding Method**: How did you learn to use the platform? (docs, training, colleague, trial-and-error)
4. **First Impressions**: What was your initial impression of the platform?

**Selection Criteria**:

- Users within first 30-90 days
- Mix of self-guided and trained users
- Different roles and backgrounds
- Various entry points into platform

### Main Questions

#### First Impressions

1. **What were your first impressions when you started using the platform?**

   - _Follow-up_: What surprised you (positively or negatively)?

2. **How clear was it what the platform could do for you?**

   - _Follow-up_: What helped you understand this?
   - _Follow-up_: What was confusing?

3. **What did you want to accomplish first?**
   - _Follow-up_: Were you able to achieve it?
   - _Follow-up_: How long did it take?

#### Onboarding Experience

4. **Walk me through how you learned to use the platform.**

   - _Follow-up_: What resources did you use?
   - _Follow-up_: What did you find most helpful?

5. **What was the hardest thing to figure out?**

   - _Follow-up_: How did you eventually solve it?
   - _Follow-up_: How long did it take?

6. **Did you get stuck at any point?**

   - _Follow-up_: What helped you get unstuck?
   - _Follow-up_: Who or what did you turn to for help?

7. **How useful was the documentation?**
   - _Follow-up_: What was missing or unclear?
   - _Follow-up_: What documentation did you wish existed?

#### Knowledge Gaps

8. **What concepts or features are you still unclear about?**

   - _Follow-up_: Why do you think that is?

9. **What do you wish someone had told you when you started?**

   - _Follow-up_: How did you eventually learn this?

10. **Are there features you haven't tried yet?**
    - _Follow-up_: Why not?
    - _Follow-up_: What would motivate you to try them?

#### Comparison

11. **How does this platform compare to others you've used?**

    - _Follow-up_: What does it do better?
    - _Follow-up_: What could it learn from others?

12. **How long did it take before you felt productive?**
    - _Follow-up_: What milestone made you feel that way?
    - _Follow-up_: What would have accelerated this?

#### Suggestions

13. **If you were redesigning the onboarding experience, what would you change?**

    - _Follow-up_: What should stay the same?

14. **What would have made your first week easier?**

15. **What advice would you give to someone just starting with the platform?**

### Follow-up Questions

- Can you show me where you looked for that information?
- What did you expect to find?
- How did you feel when that happened?
- What alternatives did you consider?
- Would you recommend this platform to colleagues? Why or why not?

### Interview Guidelines

**Before the Interview:**

- Interview early (within 2 weeks of onboarding)
- Review their activity logs
- Identify which onboarding path they took
- Prepare to capture emotional responses

**During the Interview:**

- Focus on the journey, not just facts
- Capture what they tried that didn't work
- Ask about emotional highs and lows
- Identify "aha moments" and friction points
- Explore workarounds and external resources used

**After the Interview:**

- Map the actual onboarding journey
- Identify drop-off points
- Categorize issues (docs, UX, training, technical)
- Calculate time to productivity
- Prioritize improvements by impact on adoption

---

## Tips for All Interview Types

### Building Rapport

- Start with casual conversation
- Explain the purpose and how feedback will be used
- Assure confidentiality
- Thank them for their time

### Active Listening

- Don't interrupt
- Use non-verbal encouragement (nodding, "mm-hmm")
- Paraphrase to confirm understanding
- Stay curious, not defensive

### Effective Questioning

- Ask open-ended questions ("How...?", "What...?", "Tell me about...")
- Avoid leading questions ("Don't you think...?")
- Use silence to encourage elaboration
- Ask for specific examples, not generalizations

### Note Taking

- Capture direct quotes (mark with quotation marks)
- Note emotional reactions
- Record context and environment
- Use consistent shorthand

### Avoiding Bias

- Don't sell or defend the platform
- Remain neutral in tone
- Don't finish their sentences
- Accept negative feedback gracefully
- Probe negative feedback as deeply as positive

---

## Interview Analysis

### Synthesis Process

1. **Transcribe and Clean Notes** (within 24 hours)
2. **Highlight Key Quotes and Insights**
3. **Identify Patterns Across Interviews**
4. **Create Affinity Diagrams** (group similar themes)
5. **Prioritize Findings** (frequency × severity)

### Deliverables

- **Summary Report**: Key findings, themes, recommendations
- **Quotes Library**: Organized by theme
- **Issue Log**: Prioritized list of problems to address
- **Opportunity Backlog**: Features and improvements to consider
- **Journey Maps**: Visual representation of user experiences
- **Personas**: Updated with real user insights

---

## Additional Resources

- [Persona Template](./persona.md)
- [Journey Map Template](./journey-map.md)
- NNGroup Research Methods: https://www.nngroup.com/articles/
- "The Mom Test" by Rob Fitzpatrick (recommended reading)
