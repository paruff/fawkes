# User Personas

This directory contains user personas for the Fawkes platform. Each persona represents a key user segment based on research data from interviews, surveys, and analytics.

## About Personas

Personas are fictional but data-driven representations of our users. They help us:

- Build empathy with our users
- Make user-centered design decisions
- Prioritize features based on user needs
- Communicate insights across teams

## Creating a New Persona

1. **Copy the template**:

   ```bash
   cp ../templates/persona.md your-persona-name.md
   ```

2. **Base it on research**: Conduct at least 5-7 interviews with similar users before creating a persona

3. **Include key elements**:

   - Role and responsibilities
   - Goals and motivations
   - Pain points and frustrations
   - Tools and workflows
   - Technical skill level
   - Direct quotes from research

4. **Use clear naming**: `{role}-{descriptor}.md`
   - Example: `platform-engineer-senior.md`

## Current Personas

### Active Personas

- **[Platform Developer](platform-developer.md)** - Alex Chen, "The Infrastructure Guardian"

  - Senior Platform Engineer focused on reliability, automation, and developer experience
  - Expert in Kubernetes, Terraform, observability tools
  - Key pain points: Alert fatigue, developer self-service limitations, observability gaps

- **[Application Developer](application-developer.md)** - Maria Rodriguez, "The Feature Shipper"

  - Application Developer focused on feature velocity and code quality
  - Intermediate technical proficiency, strong in Java/Spring Boot
  - Key pain points: Deployment complexity, difficult troubleshooting, unclear platform capabilities

- **[Platform Consumer](platform-consumer.md)** - Sarah Kim, "The Value Navigator"
  - Senior Product Manager focused on business outcomes and user value
  - Technical PM with beginner-to-intermediate platform knowledge
  - Key pain points: Limited visibility into progress, lack of usage analytics, long time-to-market

## Persona Lifecycle

- **Create**: After identifying a distinct user segment from research
- **Review**: Quarterly or when significant new insights emerge
- **Update**: Add new insights, quotes, and behaviors
- **Archive**: Move to `archived/` folder if no longer relevant

## Best Practices

✅ **Do:**

- Base personas on real user data
- Include direct quotes from interviews
- Focus on behaviors and goals, not just demographics
- Keep personas current (review quarterly)
- Cross-reference related journey maps

❌ **Don't:**

- Create personas based on assumptions
- Make personas too generic
- Create too many personas (3-5 is ideal)
- Let personas become outdated
- Include personally identifiable information

## Resources

- [Persona Template](../templates/persona.md)
- [Interview Guide](../templates/interview-guide.md)
- [Main Research README](../README.md)
