# Learning Culture Pattern

DORA research consistently finds that a generative learning culture is one of the
strongest predictors of software delivery performance. Teams that experiment, share
failures openly, and invest in continuous learning outperform those that don't —
not just on cultural metrics, but on deployment frequency, lead time, and CFR.

## What a Learning Culture Looks Like

A learning culture means:

- **Blameless post-mortems** — Incidents are learning opportunities, not occasions for blame
- **Psychological safety** — Team members raise concerns without fear of punishment
- **Experimentation encouraged** — Teams try new approaches and share what they learn
- **Knowledge flows freely** — Learnings are documented and shared, not hoarded
- **Failure is expected** — Complex systems fail; the goal is to learn and recover quickly

## The Fawkes Dojo Learning Path

Fawkes implements a structured belt-based learning curriculum inspired by martial arts dojos:

| Belt | Focus | Duration |
|------|-------|---------|
| **White** | What is an IDP? DORA metrics fundamentals | 1–2 weeks |
| **Yellow** | CI fundamentals, Jenkins pipelines | 2–3 weeks |
| **Green** | GitOps with ArgoCD, Kubernetes | 3–4 weeks |
| **Brown** | Observability, SRE practices | 4–6 weeks |
| **Black** | Platform product thinking, advanced IDP | 6–8 weeks |

Each belt has a module, exercises, and an assessment. Belt-holders are expected to
mentor those at lower belts.

## Communities of Practice

Fawkes communities of practice (CoPs) bring together people with shared interests
across team boundaries:

- **Platform Engineering CoP** — IDP components, Backstage plugins, ArgoCD patterns
- **Security CoP** — Threat modelling, security tooling, compliance
- **Observability CoP** — SLOs, dashboards, alerting best practices
- **Dev Experience CoP** — Developer productivity, golden paths, friction logging

CoPs meet fortnightly, post to Discourse, and maintain a reading list in the platform wiki.

## Blameless Post-Mortems

After every P1/P2 incident, the on-call team writes a blameless post-mortem within
48 hours. The format:

1. **Summary** — What happened and what was the user impact?
2. **Timeline** — Chronological sequence of events
3. **Root cause** — The contributing factors (avoid "human error" as a root cause)
4. **Action items** — What will prevent recurrence?
5. **Lessons learned** — What did the team learn?

Post-mortems are stored in `docs/runbooks/post-mortems/` and shared in the weekly
engineering newsletter.

## See Also

- [Dojo Getting Started](../dojo/getting-started.md)
- [Incident Response Pattern](incident-response.md)
- [Discourse](../tools/discourse.md)
