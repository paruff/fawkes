# Interview Notes and Guides

This directory contains interview guides for conducting user research and notes/findings from completed interviews.

## About Interviews

User interviews help us understand:
- Current workflows and pain points
- Unmet needs and frustrations
- User goals and motivations (Jobs to be Done)
- Opportunities for platform improvement

## Interview Guides

We have developed specialized interview guides for three key personas:

### 1. [Application Developer Interview Guide](./application-developer-interview-guide.md)
**Target Persona**: Application Developer (Maria Rodriguez - "The Feature Shipper")
**Duration**: 45-60 minutes
**Focus Areas**:
- Development workflow from local to production
- Deployment complexity and confidence
- Troubleshooting and debugging
- Platform feature awareness and adoption
- Developer experience pain points

**Key Topics**: 20 main questions covering JTBD, pain points, and workarounds

### 2. [Platform Engineer Interview Guide](./platform-engineer-interview-guide.md)
**Target Persona**: Platform Engineer (Alex Chen - "The Infrastructure Guardian")
**Duration**: 45-60 minutes
**Focus Areas**:
- Platform operations and reliability
- Developer support and enablement
- Tooling and automation effectiveness
- Security and compliance
- Platform evolution and scalability

**Key Topics**: 23 main questions covering reliability, automation, and developer self-service

### 3. [Stakeholder/Leadership Interview Guide](./stakeholder-interview-guide.md)
**Target Persona**: Platform Consumer - Stakeholder (Sarah Kim - "The Value Navigator")
**Duration**: 45-60 minutes
**Focus Areas**:
- Business value and ROI
- Visibility and decision-making
- Time-to-market and competitive advantage
- Team effectiveness and productivity
- Platform governance and investment

**Key Topics**: 23 main questions covering business metrics, visibility, and strategic priorities

## Interview Protocol

**Before conducting interviews, review**:
- [Interview Protocol and Best Practices](./interview-protocol.md) - Comprehensive guide covering:
  - Pre-interview preparation
  - Interview logistics and setup
  - Conducting effective interviews
  - Post-interview process
  - Privacy and ethics guidelines
  - Quality standards

- [Consent Form Template](./consent-form.md) - Required for all interviews

## Creating Interview Notes

1. **Choose the appropriate interview guide**:
   ```bash
   # Reference the guide for your target persona
   # Application Developers
   cat application-developer-interview-guide.md

   # Platform Engineers
   cat platform-engineer-interview-guide.md

   # Stakeholders/Leadership
   cat stakeholder-interview-guide.md
   ```

2. **Follow the interview protocol**:
   - Review [Interview Protocol](./interview-protocol.md)
   - Obtain informed consent using [Consent Form](./consent-form.md)
   - Follow best practices for conducting interviews

3. **Follow naming convention**: `YYYY-MM-DD-{role}-{topic}.md`
   - Example: `2025-12-23-platform-engineer-deployment-experience.md`
   - Example: `2025-12-23-application-developer-troubleshooting.md`
   - Example: `2025-12-23-stakeholder-business-value.md`

4. **Include these sections**:
   - Participant background (role, experience, anonymized)
   - Interview questions and responses
   - Key quotes (verbatim from user)
   - Observations and insights
   - Follow-up actions
   - Tagged pain points, JTBD, and workarounds

5. **Anonymize data**:
   - Remove personally identifiable information (PII)
   - Use role descriptions instead of names
   - Obtain consent before recording
   - Follow privacy guidelines in [Interview Protocol](./interview-protocol.md)

## Interview Types

### Discovery Interviews
- **Purpose**: Explore problems, needs, and workflows
- **When**: Early research, problem validation
- **Duration**: 45-60 minutes
- **Output**: Pain points, opportunity areas

### Usability Testing
- **Purpose**: Test feature usability and workflows
- **When**: Before and after feature launch
- **Duration**: 30-45 minutes
- **Output**: Usability issues, success metrics

### Feedback Interviews
- **Purpose**: Gather feedback on existing features
- **When**: Post-launch, continuous improvement
- **Duration**: 30 minutes
- **Output**: Satisfaction scores, improvement ideas

### Onboarding Interviews
- **Purpose**: Understand new user experience
- **When**: Within 2 weeks of user onboarding
- **Duration**: 30-45 minutes
- **Output**: Onboarding friction, knowledge gaps

## Best Practices

✅ **Do:**
- Transcribe notes within 24 hours while memory is fresh
- Include direct quotes with context
- Capture both what users say and what they do
- Note emotional reactions and body language
- Link to related personas and journey maps
- Store recordings securely (not in this repo)

❌ **Don't:**
- Include names or PII in notes
- Lead participants with biased questions
- Skip consent for recording
- Cherry-pick data to support preconceptions
- Wait too long to document findings

## Privacy Guidelines

- **Consent**: Always obtain explicit consent before recording
- **Anonymization**: Remove all PII from notes
- **Storage**: Keep raw recordings in secure storage (not Git)
- **Retention**: Delete recordings after 1 year or per policy
- **Access**: Limit access to anonymized notes only

## Quick Start Checklist

Before conducting your first interview:
- [ ] Read the [Interview Protocol](./interview-protocol.md)
- [ ] Choose appropriate interview guide for your target persona
- [ ] Prepare [Consent Form](./consent-form.md)
- [ ] Test recording equipment (if recording)
- [ ] Review target persona profile
- [ ] Schedule interview with appropriate participant
- [ ] Send consent form 24 hours in advance

## Resources

### Interview Guides
- [Application Developer Interview Guide](./application-developer-interview-guide.md)
- [Platform Engineer Interview Guide](./platform-engineer-interview-guide.md)
- [Stakeholder Interview Guide](./stakeholder-interview-guide.md)
- [Interview Protocol and Best Practices](./interview-protocol.md)
- [Consent Form Template](./consent-form.md)

### Personas (for context)
- [Application Developer Persona](../personas/application-developer.md)
- [Platform Engineer Persona](../personas/platform-developer.md)
- [Platform Consumer Persona](../personas/platform-consumer.md)

### Additional Resources
- [General Interview Guide Template](../templates/interview-guide.md)
- [Persona Template](../templates/persona.md)
- [Main Research README](../README.md)
- [The Mom Test](https://www.momtestbook.com/) - Recommended reading on effective interviewing

## Coverage Areas

Each interview guide ensures comprehensive coverage of:

### Jobs to be Done (JTBD)
- Primary goals users want to accomplish
- Desired outcomes and success criteria
- Context and constraints affecting their work

### Pain Points
- Current frustrations and challenges
- Blockers and inefficiencies
- Fear, uncertainty, and doubt (FUD)
- Time sinks and toil

### Workarounds
- Creative solutions users have built
- What they do instead of using the platform
- Manual processes that should be automated
- Hidden needs revealed through workarounds

## Changelog

### December 2025
- Added three specialized interview guides (Application Developer, Platform Engineer, Stakeholder)
- Created comprehensive Interview Protocol document
- Added Consent Form template
- Updated README with guide descriptions and quick start checklist
- Added 15-20 questions per guide covering JTBD and pain points
