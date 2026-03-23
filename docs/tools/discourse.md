# Discourse

[Discourse](https://www.discourse.org/) is an open-source, modern community forum
platform. Fawkes uses Discourse (or a compatible forum tool) to support the
communities of practice (CoPs) that form around platform topics — GitOps, observability,
security, and developer experience.

## Role in Fawkes

Platform teams use Discourse for:

- **Communities of Practice** — Each practice area (security, CI/CD, observability) has
  a dedicated category where members share learnings, ask questions, and link to relevant
  runbooks.
- **Knowledge base** — Resolved discussions are tagged and searchable, forming a living
  FAQ that complements the formal docs.
- **Dojo Q&A** — Developers working through the dojo learning modules post questions
  and receive answers from belt-holders.
- **RFCs and proposals** — Architecture decision records (ADRs) are drafted in Discourse
  for community feedback before being committed to `docs/adr/`.

## Key Features

- **Categories and tags** — Organise discussions by topic and searchability.
- **SSO integration** — Single sign-on via the platform identity provider means users
  log in once across Backstage, Grafana, and Discourse.
- **Solved threads** — Mark one reply as the accepted answer; builds an automatically
  curated Q&A archive.
- **Webhooks** — Post notifications to Mattermost channels when new topics are created
  in watched categories.

## Best Practices

- Post runbook links in the relevant category when you solve an incident.
- Before opening a support ticket, search Discourse — the answer is often already there.
- Dojo belt-holders should actively monitor the dojo category and respond within 48 hours.

## See Also

- [Learning Culture Pattern](../patterns/learning-culture.md)
- [Contributing](../contributing.md)
- [Dojo Getting Started](../dojo/getting-started.md)
