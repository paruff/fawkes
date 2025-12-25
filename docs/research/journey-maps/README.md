# Journey Maps

This directory contains user journey maps that visualize how users interact with the Fawkes platform to accomplish specific goals.

## About Journey Maps

Journey maps help us:

- Understand the end-to-end user experience
- Identify pain points and moments of delight
- Discover improvement opportunities
- Align teams around user needs
- Prioritize features based on impact

## Creating a Journey Map

1. **Copy the template**:

   ```bash
   cp ../templates/journey-map.md your-journey-name.md
   ```

2. **Choose a specific scenario**:

   - Pick one persona and one goal
   - Example: "Platform Engineer deploying new microservice"
   - Focus on a journey users undertake regularly

3. **Map the actual journey** (not the ideal):

   - Base on real user research
   - Include both successful and failed paths
   - Document actions, thoughts, emotions at each stage

4. **Identify opportunities**:
   - Highlight pain points
   - Suggest improvements
   - Prioritize by impact

## Naming Convention

Use: `{persona}-{scenario}.md`

Examples:

- `platform-engineer-incident-response.md`
- `app-developer-first-deployment.md`
- `product-manager-metrics-review.md`

## Journey Map Elements

Each journey map should include:

1. **Persona and Scenario**: Who and what goal
2. **Journey Stages**: Logical phases (discovery, setup, execution, validation)
3. **Actions**: What the user does at each stage
4. **Thoughts**: What's going through their mind
5. **Emotions**: How they feel (with intensity ratings)
6. **Pain Points**: Specific problems encountered
7. **Opportunities**: Proposed improvements
8. **Touchpoints**: Platform features and tools used

## Visualization

Use Mermaid diagrams for visual flow:

```mermaid
graph LR
    Start([Goal]) --> Stage1[Stage 1]
    Stage1 --> Stage2[Stage 2]
    Stage2 --> End([Success])

    Stage1 -.->|Pain| Pain1[Problem]
    Pain1 -.->|Fix| Opp1[Improvement]
```

## Current Journey Maps

### Core Developer Workflows

1. **[Developer Onboarding to Fawkes Platform](01-developer-onboarding.md)**

   - **Persona**: Application Developer (New Team Member)
   - **Scenario**: First week learning the platform
   - **Key Pain Points**: Environment setup complexity, information overload, scattered documentation
   - **Time**: 2-4 weeks
   - **Status**: ✅ Validated with 8 developer interviews

2. **[Deploying First App to Production](02-deploying-first-app.md)**

   - **Persona**: Application Developer
   - **Scenario**: First complete new service deployment
   - **Key Pain Points**: Manual YAML creation, cryptic errors, unclear success criteria
   - **Time**: 8-10 hours
   - **Status**: ✅ Validated with 8 developer interviews

3. **[Debugging Production Issue](03-debugging-production-issue.md)**
   - **Persona**: Application Developer
   - **Scenario**: Investigating and resolving production alert
   - **Key Pain Points**: Difficult log search, disconnected tools, lack of root cause suggestions
   - **Time**: 60-90 minutes
   - **Status**: ✅ Validated with 8 developer interviews and incident observations

### Platform Engagement Workflows

4. **[Requesting Platform Feature](04-requesting-platform-feature.md)**

   - **Persona**: Application Developer
   - **Scenario**: Requesting canary deployment capability
   - **Key Pain Points**: Black box waiting, no roadmap visibility, sparse communication
   - **Time**: 2-3 months
   - **Status**: ✅ Validated with 10 user interviews

5. **[Contributing to Platform](05-contributing-to-platform.md)**
   - **Persona**: Application Developer (Experienced)
   - **Scenario**: Contributing reusable service template
   - **Key Pain Points**: Unclear guidelines, imposter syndrome, no usage visibility
   - **Time**: 2-3 weeks
   - **Status**: ✅ Validated with 6 contributor interviews

## Best Practices

✅ **Do:**

- Base on actual user research (interviews, observations)
- Include specific examples and quotes
- Map the current state, not the ideal
- Show emotional highs and lows
- Identify both pain points and delights
- Link to related personas
- Update as you learn more

❌ **Don't:**

- Rely on assumptions without data
- Create overly complex maps
- Make it generic (be specific to one persona/scenario)
- Skip the emotional dimension
- Forget to prioritize opportunities
- Let maps become outdated

## Journey Map Workshop

**Format**: 2-hour collaborative session

**Steps**:

1. Introduce persona and scenario (10 min)
2. Brainstorm journey stages (15 min)
3. Detail actions for each stage (20 min)
4. Add thoughts and emotions (20 min)
5. Identify pain points (20 min)
6. Generate opportunities (20 min)
7. Prioritize improvements (15 min)

**Materials**:

- Sticky notes and markers
- Large whiteboard or paper
- Research artifacts (interview notes, personas)
- Mermaid diagram tool for digitization

## Resources

- [Journey Map Template](../templates/journey-map.md)
- [Persona Directory](../personas/)
- [Interview Notes](../interviews/)
- [Main Research README](../README.md)
- [Nielsen Norman: Journey Mapping 101](https://www.nngroup.com/articles/customer-journey-mapping/)
