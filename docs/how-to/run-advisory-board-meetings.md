# How to Run Customer Advisory Board Meetings

> A practical guide for the Fawkes product team to facilitate effective Customer Advisory Board meetings

---

## Overview

This guide provides step-by-step instructions for planning, running, and following up on Customer Advisory Board (CAB) quarterly meetings.

**Target Audience**: Fawkes product team, particularly the CAB lead and meeting facilitator

**Related Documents**:
- [Customer Advisory Board Charter](../CUSTOMER_ADVISORY_BOARD.md)
- [CAB Meeting Agenda Template](../research/templates/cab-meeting-agenda.md)
- [CAB Feedback Form Template](../research/templates/cab-feedback-form.md)

---

## Meeting Lifecycle

### Pre-Meeting (4-6 weeks before)

#### Step 1: Schedule the Meeting (6 weeks before)

**Choose Date and Time**:
- Review member preferences from onboarding
- Consider timezone distribution
- Avoid major holidays and common vacation periods
- Book 2.5 hours (2hr meeting + 30min buffer)

**Send Calendar Invite**:
- Title: "Fawkes CAB Q[X] [YEAR] Meeting"
- Include video conference link (Zoom/Meet/Teams)
- Add to-be-completed agenda in description
- Invite: `@fawkes/advisory-board` + product team
- Set reminder for 24 hours before

**Tools**:
```bash
# Use GitHub API to get CAB member emails
gh api /orgs/paruff/teams/advisory-board/members --jq '.[].email'
```

#### Step 2: Prepare Materials (2-3 weeks before)

**Create Meeting Agenda**:
1. Copy template: `docs/research/templates/cab-meeting-agenda.md`
2. Fill in sections:
   - Platform updates (releases, metrics, highlights)
   - Roadmap priorities for next quarter
   - 2-3 features for deep dive
   - 1 specific decision requiring input
3. Review with product team
4. Finalize 1 week before meeting

**Gather Supporting Materials**:
- Roadmap document (slide deck or doc)
- Feature mockups or designs (if applicable)
- Metrics dashboard screenshots
- Release notes since last meeting
- Previous meeting notes for reference

**Create Pre-Read Document** (optional but recommended):
- 2-5 page summary of key topics
- Link to detailed materials
- Specific questions for members to consider

#### Step 3: Send Pre-Read (1 week before)

**Mattermost Announcement**:
```markdown
@advisory-board - Our Q[X] CAB meeting is in one week!

📅 **Date**: [Day, Month DD] at [Time] [TZ]
🎯 **Meeting Goals**:
1. Review Q[X] roadmap priorities
2. Get feedback on [Feature Name]
3. Discuss [Strategic Topic]

📄 **Pre-Read**: [Link to document]
⏱️ **Time needed**: 20-30 minutes to review

Looking forward to seeing everyone! Let me know if you have questions or can't make it.

Video link in calendar invite. Recording will be available if you can't attend live.
```

**Pin Message** in channel for visibility

#### Step 4: Final Preparations (1-2 days before)

**Confirm Attendance**:
- Check RSVPs in calendar
- Follow up with non-responders in Mattermost
- Plan for quorum (at least 3 members ideally)

**Prep Facilitator**:
- Review agenda thoroughly
- Prepare questions and discussion prompts
- Assign note-taker (not the facilitator)
- Test video conferencing setup
- Prepare polls if needed (Mattermost polls or manual)

**Send Reminder** (24 hours before):
```markdown
@advisory-board - Reminder: CAB meeting tomorrow!

⏰ **Tomorrow** at [Time] [TZ]
🔗 **Join**: [Video Link]
📄 **Agenda**: [Link]

See you there! 👋
```

---

### During Meeting (2 hours)

#### Opening (10 minutes)

**Welcome and Setup**:
1. Start on time (even if not everyone has joined)
2. Welcome everyone and thank them for their time
3. Quick round of intros if new members
4. Housekeeping:
   - Recording status (ask permission)
   - Note-taker identified
   - Agenda review
   - Timing plan
5. Review meeting goals

**Facilitator Tips**:
- Be warm and welcoming
- Set collaborative tone
- Encourage questions and interruptions
- "No such thing as a bad question"

#### Platform Updates (20 minutes)

**Progress Since Last Meeting**:
- Show, don't just tell (screenshots, demos if quick)
- Highlight how previous CAB feedback was used
- Celebrate wins and be honest about challenges
- Keep it high-level, save details for Q&A

**Metrics and Community**:
- Share adoption metrics (GitHub stars, deployments)
- Community highlights (contributions, case studies)
- DORA metrics improvements
- Keep it brief (5 minutes max)

**Facilitator Tips**:
- Use visuals (slides or screen share)
- Pause for questions but stay on time
- "Let's table detailed discussion for later if needed"

#### Roadmap Review (40 minutes)

**Strategic Priorities** (10 mins):
- Present next quarter's top 3-4 priorities
- Explain rationale for each
- Ask: "Do these align with your needs?"
- Invite reaction and quick feedback

**Feature Deep Dives** (20 mins):
- 2-3 features, ~7 minutes each
- For each feature:
  1. Problem statement (2 mins)
  2. Proposed solution (3 mins)
  3. Questions for CAB (2 mins)
- Show mockups/designs if available

**Trade-offs and Decisions** (10 mins):
- Present a specific decision point
- Explain options and trade-offs
- Structured discussion:
  - "Who prefers Option A? Why?"
  - "Who prefers Option B? Why?"
  - "Other perspectives?"
- Synthesize input

**Facilitator Tips**:
- Use timeboxing strictly (set timer)
- "Let's spend 7 minutes on this feature..."
- Encourage diverse voices: "Anyone else?"
- Note dissenting opinions
- Seek clarity: "Can you elaborate on that?"

#### Member Feedback (30 minutes)

**Open Floor**:
1. Ask open-ended questions:
   - "What's working well?"
   - "What pain points are you experiencing?"
   - "What's missing?"
2. Let conversation flow naturally
3. Prompt if needed:
   - "How's the developer onboarding?"
   - "Any operational challenges?"
   - "Documentation gaps?"

**Guided Discussion** (if needed):
- Have backup topics if conversation lags
- Draw out quiet members: "[Name], curious about your experience with X?"

**Success Stories**:
- Invite members to share wins
- "Anyone want to share how Fawkes has helped your team?"

**Facilitator Tips**:
- Listen more than talk (80/20 rule)
- Take notes on key themes
- Don't get defensive - thank members for honest feedback
- Ask clarifying questions
- "Tell me more about that..."

#### Deep Dive Topic (15 minutes)

**Focused Discussion**:
- Present one topic needing detailed input
- Provide context and current thinking
- Structured questions for discussion
- Capture specific feedback and suggestions

**Examples**:
- Architecture decisions
- User experience dilemmas
- Prioritization debates
- Partnership or integration opportunities

#### Closing (5 minutes)

**Wrap Up**:
1. Summarize key themes heard
2. Preview action items (detailed follow-up later)
3. Confirm next meeting date
4. Thank everyone again
5. Remind about async channel for follow-up thoughts

**End on Time** - respect members' schedules

---

### Post-Meeting (Within 48 hours)

#### Step 1: Share Meeting Notes (Same day or next day)

**Process Notes**:
1. Note-taker cleans up raw notes
2. Facilitator reviews and adds context
3. Organize by section (matching agenda)
4. Include:
   - Key discussion points
   - Decisions made
   - Action items with owners
   - Feedback themes
   - Parking lot items

**Share in Mattermost**:
```markdown
@advisory-board - Thank you for a great Q[X] meeting! 🎉

📝 **Meeting Notes**: [Link to notes document or paste inline]
🎥 **Recording**: [Link if available]

**Key Takeaways**:
- [Theme 1]
- [Theme 2]
- [Theme 3]

**Action Items**:
- [ ] [Action 1] - @owner - [Due date]
- [ ] [Action 2] - @owner - [Due date]

Follow-up thoughts? Keep the conversation going in this channel! 💬
```

#### Step 2: Create Action Items (Within 48 hours)

**GitHub Issues**:
- Create issues for each action item
- Label with `cab-feedback`
- Reference meeting date
- Tag relevant team members
- Link in Mattermost thread

**Example Issue**:
```markdown
Title: [CAB Q1] Improve documentation for multi-cloud setup

**Context**:
In Q1 2026 CAB meeting, members requested better documentation for
running Fawkes across multiple cloud providers simultaneously.

**Request Details**:
- Step-by-step guide for hybrid AWS/Azure setup
- Troubleshooting common cross-cloud issues
- Best practices for cost optimization

**Priority**: P1 (multiple members requested)

**Reference**: Q1 2026 CAB Meeting Notes [link]

**Labels**: `cab-feedback`, `documentation`, `enhancement`
```

#### Step 3: Send Thank You (Within 48 hours)

**Individual Thank Yous** (optional but nice):
- Personal message to each member
- Specific appreciation for their contribution
- Via Mattermost DM or email

**Example**:
```markdown
Hi [Name],

Thanks so much for joining our Q[X] CAB meeting! Your insights on
[specific topic] were really valuable and will directly influence
how we approach [feature/decision].

Looking forward to the next one in [Month]!

Best,
[Your Name]
```

---

### Follow-Up (Within 1 month)

#### Week 1-2: Execute Action Items

**Progress Updates**:
- Start work on action items
- Post updates in Mattermost channel
- Tag members who raised the topics

**Example**:
```markdown
Update on CAB feedback: We've started work on the multi-cloud
documentation requested in last meeting. First draft will be ready
for review next week. @member1 @member2 - we'll tag you for review!
```

#### Week 3-4: Publish CAB Summary

**Public Summary** (for blog or docs):
- High-level meeting recap
- Key discussion themes
- How feedback is being incorporated
- Sanitize confidential information

**Template**:
```markdown
# Q[X] [YEAR] Customer Advisory Board Meeting Recap

The Fawkes Customer Advisory Board met on [Date] to discuss [topics].

## Key Discussion Themes
1. [Theme 1]
2. [Theme 2]
3. [Theme 3]

## Feedback Impact
Based on CAB input, we're:
- [Action 1]
- [Action 2]
- [Action 3]

## Thank You
Thank you to our CAB members for their continued guidance and support!

Next meeting: Q[X+1] [YEAR]
```

**Share**:
- Post in community channels
- Include in newsletter
- Add to docs site

#### Ongoing: Close the Loop

**As Action Items Complete**:
- Update CAB in Mattermost
- Show how their feedback made impact
- Include in next meeting recap

**Recognition**:
- Credit CAB when launching features they influenced
- Release notes: "Based on CAB feedback..."
- Blog posts spotlighting member success stories

---

## Facilitator Best Practices

### Creating Psychological Safety

**Do**:
- Thank members for both positive and critical feedback
- Acknowledge dissenting opinions
- Say "That's a great point" or "I hadn't considered that"
- Admit when you don't know something
- Be vulnerable about challenges

**Don't**:
- Get defensive about criticism
- Dismiss concerns or feedback
- Dominate the conversation
- Make members feel stupid for questions
- Over-promise on timelines

### Managing Discussion

**Encouraging Participation**:
- "I'd love to hear from folks who haven't spoken yet"
- "[Name], you have experience with X - what do you think?"
- Use polls for quick input: "Show of hands..."
- Pause after asking questions (count to 5 silently)

**Managing Dominant Voices**:
- "Thanks [Name], let's hear from others too"
- "Let's make sure everyone gets a chance to weigh in"
- Use round-robin for specific questions

**Handling Off-Topic Discussions**:
- "Great topic - let's add that to the parking lot"
- "That's worth a deeper discussion - can we schedule a separate call?"
- "For the sake of time, let's table that for async discussion"

**Time Management**:
- Visible timer (share screen or announce time checks)
- "We have 5 minutes left on this topic"
- Be willing to extend important discussions by 5-10 minutes
- Skip less critical agenda items if needed

### Active Listening

**Techniques**:
- Paraphrase to confirm understanding: "So what I'm hearing is..."
- Ask follow-up questions: "Can you tell me more about that?"
- Take notes visibly (shows you're listening)
- Non-verbal cues (nodding, eye contact in video)
- Don't interrupt (unless really off track)

### Handling Difficult Situations

**Conflicting Opinions**:
- "Both perspectives are valuable - let's explore the trade-offs"
- Document all viewpoints
- Explain how product team will weigh input

**Unrealistic Requests**:
- Acknowledge the need: "I understand why that would be valuable"
- Be honest about constraints: "Given [limitation], we may not be able to..."
- Explore alternatives: "What if we approached it this way instead?"

**Technical Issues**:
- Have a backup plan (phone numbers, alternate platform)
- Start on time even if some members can't join
- Record and share with those affected

---

## Tools and Resources

### Meeting Tools

**Video Conferencing**:
- Zoom, Google Meet, or Microsoft Teams
- Test beforehand
- Have co-host for backup
- Enable recording (with permission)

**Collaboration**:
- Mattermost for chat and polls
- Google Docs for live note-taking
- Miro/Mural for visual collaboration (if needed)

**Scheduling**:
- Google Calendar or Outlook
- Consider using Calendly for future meeting scheduling

### Templates

All templates in `docs/research/templates/`:
- `cab-meeting-agenda.md` - Detailed agenda template
- `cab-feedback-form.md` - Structured feedback collection
- `cab-nomination.md` - Member nomination form

### Tracking

**GitHub**:
- Label: `cab-feedback` for issues from CAB
- Project board: "CAB Feedback" (optional)
- Milestone: Track CAB-driven features

**Metrics** (track quarterly):
- Attendance rate
- Feedback items received
- Action items completed
- Roadmap changes influenced by CAB

---

## Quarterly Checklist

Use this checklist for each quarterly meeting:

### 6 Weeks Before
- [ ] Schedule meeting (date, time, video link)
- [ ] Send calendar invite to `@fawkes/advisory-board`
- [ ] Block time for prep work

### 2-3 Weeks Before
- [ ] Create meeting agenda from template
- [ ] Gather supporting materials (roadmap, metrics, designs)
- [ ] Review with product team
- [ ] Finalize agenda

### 1 Week Before
- [ ] Send pre-read materials in Mattermost
- [ ] Pin announcement in channel
- [ ] Prepare presentation/demos

### 1-2 Days Before
- [ ] Check attendance RSVPs
- [ ] Send reminder in Mattermost
- [ ] Test video conferencing setup
- [ ] Assign note-taker
- [ ] Print/open agenda for reference

### Day Of
- [ ] Join 5 minutes early
- [ ] Test screen sharing and recording
- [ ] Welcome members as they join
- [ ] Start on time
- [ ] Facilitate meeting per agenda
- [ ] End on time

### Same Day / Next Day
- [ ] Send thank you message
- [ ] Share meeting notes and recording
- [ ] Debrief with product team

### Within 48 Hours
- [ ] Create GitHub issues for action items
- [ ] Send individual thank yous (optional)
- [ ] Post updates in Mattermost

### Within 1 Week
- [ ] Start work on action items
- [ ] Post progress updates

### Within 1 Month
- [ ] Publish public CAB summary
- [ ] Update CAB on action item progress
- [ ] Begin planning next quarter's meeting

---

## Tips for Success

### Make It Valuable for Members

- **Respect Their Time**: Start and end punctually
- **Show Impact**: Demonstrate how their feedback matters
- **Be Transparent**: Share real challenges and trade-offs
- **Close the Loop**: Follow up on action items
- **Create Connection**: Foster community among members

### Make It Valuable for Product Team

- **Come Prepared**: Clear agenda and goals
- **Ask Specific Questions**: "Would you use X or Y?"
- **Capture Everything**: Don't lose good ideas
- **Be Open**: Genuinely consider input, even if hard to hear
- **Take Action**: Don't let feedback sit idle

### Build Long-Term Relationships

- **Between Meetings**: Engage in Mattermost channel
- **Recognition**: Credit members publicly when appropriate
- **Opportunities**: Invite to speak, write, beta test
- **Personal Touch**: Remember details about their use cases
- **Celebrate**: Recognize member successes and milestones

---

## Common Pitfalls to Avoid

❌ **Scheduling too far in advance**: 6 weeks is good, 3+ months makes it easy to forget

❌ **Not sending pre-read**: Members are unprepared, discussion suffers

❌ **Talking too much**: Product team talks 80%, members 20% - should be reversed

❌ **Ignoring feedback**: Nothing kills CAB engagement faster

❌ **No follow-up**: Members wonder if their time was worthwhile

❌ **Too formal**: Create conversational, collaborative atmosphere

❌ **Too infrequent**: Quarterly is minimum; some ad-hoc touchpoints keep engagement

---

## Measuring Success

### Meeting Effectiveness Metrics

**Engagement**:
- Attendance rate (target: 80%+)
- Speaking time distribution (should be balanced)
- Follow-up questions/comments in channel

**Quality**:
- Actionable feedback items received
- Diversity of perspectives shared
- Depth of discussion on key topics

**Impact**:
- Features/decisions influenced by CAB input
- Issues identified and resolved
- Roadmap changes based on feedback

### Member Satisfaction

**Post-Meeting Survey** (optional, quarterly or bi-annually):
- Meeting was valuable: 1-5 scale
- Felt heard: 1-5 scale
- Time well spent: 1-5 scale
- Would recommend CAB: NPS score
- Open feedback

---

## Questions?

This guide will evolve based on experience. Share improvements and lessons learned!

**Contact**: product-team@fawkes.local or CAB lead

---

**Version**: 1.0
**Last Updated**: December 25, 2025
**Owner**: Product Team
