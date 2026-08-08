# ADR-020: Platform-as-Product Operating Model

## Status

Accepted

## Context

Traditional platform teams operate as "service providers" responding to tickets. The 2025 DORA Report shows this reactive model fails to deliver great developer experience. We must treat Fawkes as an internal product with developers as customers.

**Supporting evidence**: DORA's 2025 research found the platform capability most correlated
with positive developer experience is giving "clear feedback on the outcome of my task"
(logs, diagnostics, actionable errors) — a product-quality concern, not a ticket-response
concern. Separately, organizations with high developer cognitive load see ~40% longer
lead times for changes, and organizations with mature internal developer platforms report
cycle-time reductions in the 40–60% range — reinforcing that platform quality is a
force multiplier, not overhead. See `docs/research/dora/README.md` for the full DORA
capability breakdown this ADR builds on.

## Decision

Adopt **Platform-as-Product** operating model with:

- Dedicated product manager for platform
- Quarterly OKRs driven by developer needs (not tickets)
- Product roadmap visible in Backstage
- Monthly demo days showcasing new features
- Developer advisory board (5-7 developers, rotating)

**Key Practices**:

- User research informs roadmap (not HiPPO decisions)
- Measure platform success by NPS, adoption, DORA metrics
- "You build it, you support it" (platform team owns platform)
- Quarterly business reviews with leadership (prove ROI)

## Consequences

**Positive**: Better features, higher adoption, developer trust
**Negative**: Requires product management skills, cultural shift
