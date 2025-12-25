---
title: Epic 3 Demo Video Recording Checklist
description: Quick reference checklist for recording the Epic 3 platform demo
---

# Epic 3 Demo Video Recording Checklist

**Epic**: Product Discovery & UX  
**Target Duration**: 30 minutes  
**Last Updated**: December 2024

## Pre-Recording Setup

### Environment Setup
- [ ] Kubernetes cluster is running
- [ ] All Epic 3 components deployed: `kubectl get pods -n fawkes -l epic=3`
- [ ] All Epic 3 components deployed: `kubectl get pods -n fawkes-local -l epic=3`
- [ ] Run health check: `./scripts/health-check-epic3.sh`
- [ ] Clear browser cache and history
- [ ] Set browser zoom to 100%
- [ ] Close unnecessary tabs

### Recording Software
- [ ] Screen recording software installed and tested
- [ ] Audio input tested (microphone quality check)
- [ ] Recording quality set to HD (1080p minimum)
- [ ] Framerate set to 30fps or 60fps
- [ ] Test short recording to verify audio/video sync

### Browser Windows & Tabs
Prepare these tabs in order (use separate browser window):

1. [ ] Backstage Developer Portal: `https://backstage.127.0.0.1.nip.io`
2. [ ] SPACE Metrics Dashboard in Grafana
3. [ ] Feedback Analytics Dashboard in Grafana
4. [ ] Storybook: `https://storybook.fawkes.local`
5. [ ] Unleash UI: `https://unleash.fawkes.local`
6. [ ] Product Analytics (if deployed)
7. [ ] Mattermost web app
8. [ ] File browser open to `docs/research/`

### Terminal Sessions
Prepare these terminal sessions:

- [ ] Terminal 1: Main terminal for commands (large font, clear history)
- [ ] Terminal 2: Port-forward session for SPACE metrics API
- [ ] Terminal 3: Backup terminal for kubectl commands

### Data Preparation
- [ ] SPACE metrics populated with sample data
- [ ] At least 20 feedback submissions in database
- [ ] Feedback bot is online in Mattermost
- [ ] Test NPS survey is accessible
- [ ] Feature flags configured in Unleash with metrics
- [ ] Design system Storybook fully built and accessible
- [ ] Journey maps are complete (all 5)
- [ ] Personas exist (all 5)

### Content Preparation
- [ ] Script reviewed and practiced
- [ ] Key talking points memorized
- [ ] Transitions between segments planned
- [ ] Demo flow tested end-to-end at least once

---

## Recording Checklist by Segment

### Segment 1: Introduction (0:00-3:00)
- [ ] Clear, welcoming opening statement
- [ ] Epic 3 overview delivered confidently
- [ ] Key deliverables list covered
- [ ] Energy level: High, enthusiastic

### Segment 2: User Research (3:00-7:00)
- [ ] Research repository structure explained
- [ ] Persona example shown and explained
- [ ] Journey map demonstrated clearly
- [ ] Connection to product decisions explained

### Segment 3: SPACE Framework (7:00-12:00)
- [ ] SPACE acronym explained
- [ ] Grafana dashboard walkthrough complete
- [ ] All 5 dimensions covered
- [ ] API demonstration successful
- [ ] Friction log submission shown
- [ ] Cognitive load assessment explained

### Segment 4: Feedback System (12:00-17:00)
- [ ] All 4 channels explained
- [ ] Backstage widget demonstrated
- [ ] CLI tool usage shown
- [ ] Mattermost bot interaction recorded
- [ ] NPS survey example shown
- [ ] Feedback analytics dashboard displayed

### Segment 5: Design System (17:00-21:30)
- [ ] Storybook navigation demonstrated
- [ ] Component example thoroughly shown
- [ ] Design tokens explained
- [ ] Accessibility features highlighted
- [ ] Code usage example provided

### Segment 6: Analytics & Flags (21:30-25:30)
- [ ] Product analytics dashboard shown
- [ ] Event tracking explained with code
- [ ] Unleash UI demonstrated
- [ ] Feature flag strategy explained
- [ ] Gradual rollout concept clear
- [ ] OpenFeature SDK shown

### Segment 7: Discovery Process (25:30-28:30)
- [ ] Weekly cadence explained
- [ ] Advisory board mentioned
- [ ] Real example shared (insight → feature)
- [ ] Value of continuous discovery clear

### Segment 8: Wrap-Up (28:30-30:00)
- [ ] Key takeaways summarized
- [ ] Value proposition restated
- [ ] Resources mentioned
- [ ] Strong closing statement

---

## Technical Checks During Recording

### Every 5 Minutes
- [ ] Check audio levels (not clipping)
- [ ] Check video recording status (still recording)
- [ ] Check time remaining in segment

### When Switching Context
- [ ] Pause to allow for clean edit point
- [ ] Announce context switch clearly
- [ ] Ensure new window/tab is visible before speaking

### When Demonstrating APIs
- [ ] Command is visible and readable
- [ ] Output is clean and formatted
- [ ] Pause to let viewers read output
- [ ] Explain what the output means

### When Showing Dashboards
- [ ] Wait for dashboard to fully load
- [ ] Point out key metrics explicitly
- [ ] Use cursor to highlight important areas
- [ ] Don't move too quickly

---

## Common Mistakes to Avoid

- [ ] ❌ Speaking too fast (slow down by 10-15%)
- [ ] ❌ Not pausing between segments
- [ ] ❌ Moving mouse cursor erratically
- [ ] ❌ Forgetting to explain acronyms
- [ ] ❌ Assuming viewer knowledge
- [ ] ❌ Technical jargon without explanation
- [ ] ❌ Skipping error handling (show what happens when things fail)
- [ ] ❌ Not announcing context switches
- [ ] ❌ Audio issues (breathing into mic, keyboard noise)
- [ ] ❌ Not showing enthusiasm

---

## Post-Recording Checklist

### Immediate (Right After Recording)
- [ ] Save all recording files
- [ ] Create backup copy of raw footage
- [ ] Review full recording for major issues
- [ ] Note timestamps of any errors or retakes needed
- [ ] Verify audio throughout entire recording

### Editing Phase
- [ ] Trim dead air and long pauses
- [ ] Add title cards for each segment:
  - [ ] Segment 1: Introduction
  - [ ] Segment 2: User Research Infrastructure
  - [ ] Segment 3: SPACE Framework
  - [ ] Segment 4: Multi-Channel Feedback
  - [ ] Segment 5: Design System
  - [ ] Segment 6: Analytics & Feature Flags
  - [ ] Segment 7: Continuous Discovery
  - [ ] Segment 8: Wrap-Up
- [ ] Add captions/subtitles (for accessibility)
- [ ] Add zoom-ins for important UI elements
- [ ] Add arrows or highlights for key points
- [ ] Smooth transitions between segments
- [ ] Background music (subtle, non-distracting) - optional
- [ ] Verify final length (28-32 minutes acceptable)

### Quality Checks
- [ ] Audio quality consistent throughout
- [ ] No distracting background noise
- [ ] Video quality is HD (1080p)
- [ ] Text on screen is readable
- [ ] Color balance is correct
- [ ] No awkward pauses or dead air
- [ ] Pacing is comfortable
- [ ] Energy level is consistent

### Pre-Publication
- [ ] Create engaging thumbnail (1280x720px)
- [ ] Write video description including:
  - [ ] Brief summary
  - [ ] Links to documentation
  - [ ] Timestamps for each segment
  - [ ] Contact information
- [ ] Add tags: fawkes, devex, product-discovery, space-framework, feedback, design-system, feature-flags, unleash, storybook
- [ ] Set video title: "Fawkes Epic 3: Product Discovery & UX - Complete Walkthrough"
- [ ] Choose appropriate visibility (unlisted for review, public for release)

### Chapter Markers (for YouTube)
Add these timestamps in video description:
```
0:00 Introduction & Overview
3:00 User Research Infrastructure
7:00 SPACE Framework & DevEx Measurement
12:00 Multi-Channel Feedback System
17:00 Design System & Storybook
21:30 Product Analytics & Feature Flags
25:30 Continuous Discovery Process
28:30 Wrap-Up & Key Takeaways
```

### Publication
- [ ] Upload to YouTube
- [ ] Upload to internal video storage (if applicable)
- [ ] Create GitHub release with video link
- [ ] Update `epic-3-demo-video.md` with video links
- [ ] Share in Mattermost #announcements
- [ ] Share in Mattermost #product-discovery
- [ ] Add to Backstage TechDocs
- [ ] Update README.md with video link

### Post-Publication
- [ ] Monitor comments and questions
- [ ] Respond to feedback
- [ ] Note suggestions for future versions
- [ ] Track view count and engagement metrics

---

## Troubleshooting

### If Recording Fails Mid-Way
1. Save what you have
2. Note the exact timestamp where you want to resume
3. Do a clean slate: close all apps, restart browser
4. Resume from the start of the affected segment
5. Edit the two parts together in post-production

### If Demo Environment Breaks
1. Pause recording
2. Check pod status: `kubectl get pods -A`
3. Restart failed services
4. Wait for stabilization (2-3 minutes)
5. Resume from last clean segment break

### If You Forget What to Say
1. Pause recording
2. Review script section
3. Take a 30-second break
4. Resume with energy

### If Time is Running Long
Can be shortened by:
- Reducing time in Segment 2 (Research) to 3 minutes
- Reducing time in Segment 6 (Analytics) to 3 minutes
- Trimming pauses more aggressively in editing

### If Time is Running Short
Can be expanded by:
- More detailed explanation in Segment 3 (SPACE)
- Additional examples in Segment 7 (Discovery Process)
- More thorough wrap-up in Segment 8

---

## Quick Reference: Time Allocation

| Segment | Title | Duration | Key Points |
|---------|-------|----------|------------|
| 1 | Introduction | 3:00 | Epic 3 overview, deliverables |
| 2 | User Research | 4:00 | Personas, journey maps |
| 3 | SPACE Framework | 5:00 | 5 dimensions, API, metrics |
| 4 | Feedback System | 5:00 | 4 channels, analytics |
| 5 | Design System | 4:30 | Storybook, components, a11y |
| 6 | Analytics & Flags | 4:00 | Usage data, Unleash |
| 7 | Discovery Process | 3:00 | Weekly cadence, advisory board |
| 8 | Wrap-Up | 1:30 | Summary, resources |
| **Total** | | **30:00** | |

---

## Contact

Questions about recording the demo?
- **Platform Team**: #platform-team on Mattermost
- **Product Team**: #product-team on Mattermost
- **Documentation**: `docs/tutorials/epic-3-demo-video-script.md`

Good luck with the recording! 🎬
