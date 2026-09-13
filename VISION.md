# Fawkes — Vision

> **Horizon:** Years | **Owner:** @paruff | **Review cadence:** Annually, or when a core principle is challenged by real usage

## North Star

A self-service internal developer platform that gives delivery teams DORA metrics and a built-in dojo, so that platform engineers can both *run* elite-performing delivery infrastructure and *learn* how it works — not choose one or the other.

## Core Principles

These are drawn from and stay in sync with `docs/CHARTER.md`'s Guiding Principles — restated here at vision-tier because they're the filter every milestone and queue item gets checked against, not because they've changed:

1. **Developer experience is paramount.** Every feature must improve productivity, reduce cognitive load, or enable self-service — for the platform engineer/DevOps persona specifically, not a generic "developer."
2. **Measure everything.** If it can't be measured, it can't be improved — DORA + SPACE instrumentation is not an add-on feature, it's load-bearing.
3. **Security is non-negotiable.** Scanning, policy enforcement, and compliance are built in, not bolted on after.
4. **Learn while building.** The platform doubles as a learning environment (the Dojo) with an integrated belt-level curriculum — this is Fawkes's actual product differentiator, not a marketing layer.
5. **Community over features.** A healthy, engaged community is worth more long-term than a feature-complete platform nobody understands.
6. **Open by default.** Decisions, roadmap, metrics, and discussions are public unless privacy requires otherwise.
7. **Opinionated but extensible.** Golden paths cover 80% of use cases; the other 20% can customize rather than fork.
8. **Multi-cloud from day one.** Design for cloud portability even where the current implementation (AWS/Azure) is ahead of GCP.

## Non-Goals for the Current Stage (Alpha)

Distinct from `docs/CHARTER.md`'s *permanent* Out-of-Scope list (we will never build a source-control replacement, project-management tool, or application framework). These are things that fit the vision but are deliberately **not** being pursued *yet*, so Alpha-stage work doesn't get pulled sideways:

- **No self-service developer portal yet.** Backstage scaffolding exists (`platform/apps/backstage/`) but isn't deployed — it's Phase 2/3 work, blocked on Sealed Secrets (#1797). Don't add portal features to Alpha-stage issues.
- **No RBAC / production promotion gating yet.** Phase 3 (Human-in-the-Loop) work. Alpha's ArgoCD access is intentionally permissive for velocity.
- **No 5-key DORA dashboard yet.** Alpha ships 2 keys (Deployment Frequency, Lead Time). Change Failure Rate, MTTR, and Reliability are Phase 2/3, and CFR itself is currently blocked on DevLake's own health (`KL-15`).
- **No GCP support yet**, despite the multi-cloud principle above — AWS and Azure are the current targets; GCP is explicitly deferred, not abandoned.
- **No enterprise support/certification partnerships yet** — those are 12/24-month `docs/CHARTER.md` goals, not Alpha concerns.

## The Riskiest Assumption

**That platform engineers will choose a platform that requires understanding how it works over one that abstracts that complexity away entirely.**

Every competing IDP in this space (Backstage-as-a-service offerings, Port, Humanitec) is racing toward "invisible platform" — the less an adopting team needs to understand, the better. Fawkes bets the opposite: that pairing the platform with a belt-level dojo curriculum (Principle 4) is a *feature*, not overhead, and that the target persona (a platform engineer building career capital, not just shipping a feature) will actively prefer a platform they can audit and extend over one that's a black box. If that's wrong — if the market wants invisible, not teachable — the dojo investment is dead weight and Fawkes is a worse-documented competitor to tools that made the opposite bet on purpose.

## How This Connects

| Tier | File | What it answers |
|---|---|---|
| ↓ Months | [MILESTONES.md](MILESTONES.md) | Which phase are we in, and what proves we're allowed to move to the next one? |
| ↓ Weeks | [EXECUTION_QUEUE.md](EXECUTION_QUEUE.md) | What's actually being worked on this sprint, in priority order? |
| ↓ Today | [plan-for-the-day.md](plan-for-the-day.md) | What's today's single goal, and did it move the needle? |
| Cross-cutting | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How are the components allowed to depend on each other? |
| Cross-cutting | [docs/KNOWN_LIMITATIONS.md](docs/KNOWN_LIMITATIONS.md) | What's broken or degraded right now, and are we allowed to make it worse? |
| Cross-cutting | [docs/CHANGE_IMPACT_MAP.md](docs/CHANGE_IMPACT_MAP.md) | What else breaks if I touch this file? |
| Cross-cutting | [docs/API_SURFACE.md](docs/API_SURFACE.md) | What are the actual public contracts between services? (this repo's equivalent of a `CONTRACTS.md` — no separate one needed) |
| Cross-cutting | [AI_STANCE.md](AI_STANCE.md) | What's AI allowed to do here unsupervised, and what always needs a human? |
| Cross-cutting | [docs/RELEASE.md](docs/RELEASE.md) | How does a change actually ship? (this repo's equivalent of a `RELEASE_PROCESS.md`) |
| Cross-cutting | [docs/DEPLOYMENT_STRATEGY.md](docs/DEPLOYMENT_STRATEGY.md) | How does code get from a merged PR to a running cluster, today vs. the target state? |
| Deeper background | [docs/CHARTER.md](docs/CHARTER.md) | Full project charter — audience, success criteria, risks, resourcing (this file distills the parts that should shape day-to-day decisions) |
