# Spec: Fawkes-on-Fawkes DORA Self-Measurement

> Functional requirements derived from [discovery-draft.md](discovery-draft.md). Tracks issue #2081.

## Functional Requirements

1. **FR-1 — Project registration.** `paruff/fawkes` SHALL be registered as a project/scope under DevLake's existing GitHub connection, using the same connection already used for `tracer-bullet`/`python-fawkes-path` (`docs/adr/ADR-016 devlake-dora-strategy.md`). No new connection SHALL be created.
2. **FR-2 — Deployment-signal verification (blocking discovery question).** Before any dashboard work begins, the system SHALL verify whether GitHub Releases on `paruff/fawkes` produce `cicd_tasks` rows with `type='Deployment'` once collection runs. If they do not (the KL-12-style gap), this SHALL be documented as its own known limitation rather than worked around with a fabricated data source.
3. **FR-3 — Non-fabrication constraint.** No dashboard panel, metric, or status claim for this feature SHALL be built or marked complete against data that has not been confirmed real via a direct query against `devlake-mysql`, per `AGENTS.md` §9's phase-gate rule.
4. **FR-4 — Dashboard panel.** Once FR-2 is confirmed working, a panel/row SHALL be added to the existing DORA Grafana dashboard (`platform/apps/grafana-dashboards/dora-overview-dashboard-configmap.yaml`), reusing its existing panel structure rather than introducing a new dashboard.
5. **FR-5 — Discoverability.** `README.md` SHALL link to the resulting dashboard once FR-4 ships, per the plan's own reasoning that this needs to be a live demonstration, not a documented claim.
6. **FR-6 — No new infrastructure.** This feature SHALL NOT introduce a Pushgateway, custom exporter, or parallel metrics pipeline — it reuses the existing DevLake → Prometheus → Grafana pipeline exclusively (`docs/elite-engineering-bridge-plan.md` Phase 5's own risk mitigation).

## Out of Scope (this spec)

- Change Failure Rate, MTTR, or Reliability for the fawkes-repo-as-tenant case — Deployment Frequency and Lead Time only, per the MVP scoping in issue #2081.
- Resolving `docs/KNOWN_LIMITATIONS.md` KL-15 itself (the DevLake migration blocker) — that's a separate, human-decision item this spec's implementation is blocked on, not part of it.
