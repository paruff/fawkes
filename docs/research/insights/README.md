# Research Insights

This directory contains synthesized insights from user research activities. Insights help us identify patterns across multiple research sources and inform product decisions.

## About Insights

Research insights are:

- **Synthesized**: Patterns across multiple interviews, surveys, or data sources
- **Evidence-Based**: Grounded in actual user research
- **Actionable**: Include recommendations for product improvements
- **Time-Bound**: Reflect understanding at a point in time

## Creating Insights

1. **Review research artifacts**:

   - Multiple interview notes
   - Survey results
   - Analytics data
   - Support tickets
   - Usage patterns

2. **Identify patterns**:

   - Common pain points across users
   - Frequently requested features
   - Workflow inefficiencies
   - Unmet needs

3. **Document insights**:

   ```markdown
   # [Topic] Insights - [Date]

   ## Summary

   [2-3 sentence overview of key findings]

   ## Key Findings

   1. [Finding 1 with supporting evidence]
   2. [Finding 2 with supporting evidence]
   3. [Finding 3 with supporting evidence]

   ## Evidence

   - [Reference to interviews: "5/7 platform engineers mentioned..."]
   - [Survey data: "68% of developers reported..."]
   - [Analytics: "Average time to first deployment: 4.5 hours"]

   ## Impact

   - [How this affects users]
   - [Business impact]
   - [DORA metrics impact]

   ## Recommendations

   1. [Prioritized action 1]
      - Expected impact: [High/Medium/Low]
      - Effort estimate: [High/Medium/Low]
   2. [Prioritized action 2]
   3. [Prioritized action 3]

   ## Next Steps

   - [Follow-up research needed]
   - [Features to prioritize]
   - [Experiments to run]

   ## Related Artifacts

   - [Link to interviews]
   - [Link to personas]
   - [Link to journey maps]
   ```

## Naming Convention

Use: `YYYY-MM-{topic}-insights.md`

Examples:

- `2025-12-deployment-experience-insights.md`
- `2025-Q4-platform-adoption-insights.md`
- `2026-01-observability-gaps-insights.md`

## Types of Insights

### Sprint Insights

- **Frequency**: After each research sprint (2-4 weeks)
- **Scope**: Specific topic or feature
- **Purpose**: Inform current sprint planning

### Quarterly Insights

- **Frequency**: End of each quarter
- **Scope**: Broader themes and patterns
- **Purpose**: Strategic planning and OKR setting

### Ad-hoc Insights

- **Frequency**: As needed
- **Scope**: Emerging patterns or urgent findings
- **Purpose**: Rapid decision-making

### Annual Synthesis

- **Frequency**: End of year
- **Scope**: Year-over-year trends
- **Purpose**: Long-term strategy and retrospective

## Current Insights

<!-- List your insights here as you create them -->
<!-- Example:
- [Q4 2025 - Deployment Experience](2025-12-deployment-experience-insights.md)
- [Q4 2025 - Platform Adoption](2025-Q4-platform-adoption-insights.md)
-->

## Best Practices

✅ **Do:**

- Base insights on multiple data sources
- Include quantitative and qualitative evidence
- Cite specific sources (interview dates, survey n=)
- Prioritize recommendations by impact and effort
- Link to supporting research artifacts
- Update insights as new data emerges
- Share insights with stakeholders

❌ **Don't:**

- Base insights on single interviews
- Cherry-pick data to support assumptions
- Make recommendations without evidence
- Use vague language ("some users", "many people")
- Let insights become outdated
- Hoard insights—share widely

## Insight Quality Checklist

Before publishing an insight, ensure:

- [ ] **Evidence-Based**: References specific research sources
- [ ] **Quantified**: Includes numbers (frequency, sample size, percentages)
- [ ] **Representative**: Covers diverse user segments
- [ ] **Actionable**: Includes clear recommendations
- [ ] **Prioritized**: Recommendations ranked by impact/effort
- [ ] **Linked**: References related personas, journey maps, interviews
- [ ] **Dated**: Clear about when research was conducted
- [ ] **Reviewed**: Validated by research team or product owner

## Synthesis Process

1. **Gather**: Collect research artifacts (interviews, surveys, data)
2. **Code**: Tag key themes and patterns
3. **Cluster**: Group similar findings
4. **Analyze**: Identify root causes and relationships
5. **Prioritize**: Rank by frequency and severity
6. **Recommend**: Propose actionable improvements
7. **Validate**: Review with stakeholders
8. **Share**: Distribute to relevant teams

## Presenting Insights

### Research Shareout Meeting

**Format**: 30-45 minute presentation

**Agenda**:

1. Context: What we researched and why (5 min)
2. Method: How we gathered data (5 min)
3. Key findings: Top 3-5 insights (15 min)
4. Recommendations: Prioritized actions (10 min)
5. Discussion: Q&A and next steps (10 min)

**Audience**: Product, engineering, design, leadership

**Deliverables**:

- Slide deck (keep it visual)
- Written insight document
- Recording for those who can't attend

### Insight Distribution

- **Mattermost**: Post summary in `#product-research` channel
- **Email**: Send to stakeholders with link to full document
- **Wiki**: Update product knowledge base
- **Meetings**: Reference in sprint planning and roadmap discussions

## Resources

- [Interview Notes](../interviews/)
- [Personas](../personas/)
- [Journey Maps](../journey-maps/)
- [Main Research README](../README.md)
- [Teresa Torres - Continuous Discovery](https://www.producttalk.org/)
