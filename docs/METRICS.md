# Fawkes DORA Metrics — Rework Rate

> **AGENTS.md reference:** Section 9 — Fawkes-Specific Principles
> Rework rate is tracked here and checked weekly via `scripts/weekly-metrics.sh`.

---

## 1. Rework Rate Definition

**Resolved 2026-09-16**, grounded in Google DORA's AI-era research (referenced in
`docs/research/dora/README.md`: the 2025 DORA AI Capabilities Model, the 2025 State of
AI-Assisted Software Development report, and the 2026 ROI of AI-Assisted Software
Development report). Those three PDFs are image/CID-font marketing documents with no
extractable text layer via this repo's available tooling, so the definition below is
grounded in the DORA 2026 framing already embedded in this repo's own Grafana panel
(`platform/apps/grafana-dashboards/dora-metrics-dashboard-configmap.yaml`): *"Fraction of
AI output requiring rework (5th DORA metric, DORA 2026)."*

**Rework rate** = the percentage of AI-assisted merged PRs (commits carrying this repo's
own `Co-Authored-By: Claude` attribution trailer) that needed a fix/revert follow-up PR
within seven days of merging. This approximates "AI output requiring rework" using signals
this repo already produces — no new label convention, no IDE-level suggestion
accept/reject telemetry Fawkes doesn't collect.

Two other definitions exist elsewhere in this repo's history and are superseded by this
one: ADR-016's "Jenkins rebuilds / unique commits" (dead — Jenkins was replaced by Tekton,
see the ADR index) and `docs/research/dora/README.md`'s "PR labels (rework) / total PRs"
proxy (never implemented — no label convention was ever adopted).

| Threshold | Status                     | Action                                                 |
| --------- | -------------------------- | ------------------------------------------------------ |
| < 10 %    | 🟢 **GREEN — Healthy**     | No action required. Continue current practices.        |
| 10 – 20 % | 🟡 **YELLOW — Watch**      | Review recent PRs for patterns. Schedule a retro item. |
| > 20 %    | 🔴 **RED — Stop features** | Halt new feature work. Conduct a root-cause analysis.  |

These thresholds align with DORA's definition of *change failure rate* and are applied to
the Fawkes mono-repo across all layers (services, infra, platform, scripts, docs).

**Known limitation**: `scripts/weekly-metrics.sh` counts a fix/revert PR as a follow-up
based on time proximity (merged within 7 days), not file-overlap with the AI PR it's
"reworking" — see the script's header comment for why (added API cost on a repo that
regularly merges 200+ PRs per 14 days). Read the computed rate as an upper bound.

---

## 2. How to Compute the Rework Rate

`scripts/weekly-metrics.sh` computes this directly from GitHub via the `gh` CLI — no
DevLake dependency (DevLake was decommissioned 2026-09-16 in favor of native PromQL DORA
metrics, see `platform/apps/prometheus/rules/dora.yml`).

```bash
./scripts/weekly-metrics.sh            # updates section 3's baseline table
./scripts/weekly-metrics.sh --dry-run  # prints the status without writing the table
```

It prints the traffic-light status plus the underlying counts (`reworked/total AI-assisted
PRs`) and updates the baseline table below. Requires `gh auth login` to have been run
locally or in CI.

---

## 3. Current Baseline

> **Status as of last update:** 🔴 RED (2026-09-16) — first real baseline, established during
> this session's methodology switch from DevLake to GitHub-derived data. See the "Known
> limitation" note in Section 1: this reading is inflated by the session's own unusually
> high fix-commit volume and the lack of file-overlap checking, not a steady-state signal.

| Week | Rework Rate | Status | Notes                                        |
| ---- | ----------- | ------ | -------------------------------------------- |
| 2026-09-16 | 98.0 % | RED | Auto-updated by weekly-metrics.sh (50/51 AI-assisted PRs) |

*This table is updated automatically by `scripts/weekly-metrics.sh` during the weekly
metrics review run.*

---

## 4. Weekly Review Process

The weekly metrics review ensures that rework rate stays within the healthy threshold and
that any degradation is caught early.

### When

Every **Monday at 09:00 UTC** (or the first working day of the week).

### Who

- Platform Engineering lead (owns the review)
- One rotating team member (shadow reviewer)

### Steps

```bash
# 1. Run the metrics script — it queries GitHub via `gh` and updates this file
./scripts/weekly-metrics.sh

# 2. Check the terminal output for the traffic-light status
#    GREEN  → no action
#    YELLOW → add retro item to this week's board
#    RED    → create a P1 issue, pause new features

# 3. Commit the updated baseline table (section 3 above) with message:
#    chore(metrics): weekly rework rate update YYYY-MM-DD
```

### Escalation

| Status    | Escalation path                                                                      |
| --------- | ------------------------------------------------------------------------------------ |
| 🟢 GREEN  | No escalation                                                                        |
| 🟡 YELLOW | Post summary in `#platform-engineering` Mattermost channel                           |
| 🔴 RED    | Page on-call lead, open a P1 issue, freeze feature merges via branch protection rule |

---

## 5. Related Metrics

The following DORA metrics are tracked alongside rework rate.
The other 4 are computed natively in Prometheus; see `platform/apps/prometheus/rules/dora.yml`.

| Metric                | Target (Elite) | Source                                                      |
| --------------------- | -------------- | ------------------------------------------------------------ |
| Deployment Frequency  | ≥ 1/day        | Prometheus `dora:deployment_frequency:rate30d`               |
| Lead Time for Changes | < 1 hour       | Prometheus `dora:lead_time_hours:p50_30d`                    |
| Change Failure Rate   | < 5 %          | Prometheus `dora:change_failure_rate:ratio30d`                |
| MTTR                  | < 1 hour       | Prometheus `dora:fdrt_hours:p50_30d` (Alertmanager-backed)    |
| **Rework Rate**       | **< 10 %**     | **GitHub PRs via `scripts/weekly-metrics.sh`**                |

---

## 6. See Also

- `scripts/weekly-metrics.sh` — automated weekly data collection
- `platform/apps/prometheus/rules/dora.yml` — the other 4 DORA keys (native PromQL)
- `docs/runbooks/` — incident runbooks
- `docs/AGENTS.md` Section 9 — platform principles
- `docs/research/dora/README.md` — DORA research reference table

## AI-Readiness Metrics

> Last updated: 2026-03-13 by `scripts/check-ai-readiness.sh`
> Threshold: >= 80% GREEN | 50-79% YELLOW | < 50% RED

| Service                 | Type-hints  | Docstrings   | Unit Tests | BDD |
| ----------------------- | ----------- | ------------ | ---------- | --- |
| ai-code-review          | 3/10 (30%)  | 10/10 (100%) | N          | Y   |
| analytics-dashboard     | 9/27 (33%)  | 27/27 (100%) | N          | Y   |
| anomaly-detection       | 3/12 (25%)  | 12/12 (100%) | N          | Y   |
| devex-survey-automation | 1/21 (4%)   | 21/21 (100%) | N          | N   |
| discovery-metrics       | 0/24 (0%)   | 24/24 (100%) | N          | Y   |
| experimentation         | 13/34 (38%) | 34/34 (100%) | N          | Y   |
| feedback-bot            | 5/9 (55%)   | 9/9 (100%)   | N          | Y   |
| feedback                | 21/43 (48%) | 40/43 (93%)  | N          | Y   |
| friction-bot            | 2/8 (25%)   | 8/8 (100%)   | N          | N   |
| insights                | 2/23 (8%)   | 23/23 (100%) | N          | Y   |
| mcp-k8s-server          | 0/3 (0%)    | 0/3 (0%)     | N          | N   |
| nps                     | 2/11 (18%)  | 11/11 (100%) | N          | N   |
| rag                     | 0/8 (0%)    | 8/8 (100%)   | Y          | Y   |
| smart-alerting          | 13/30 (43%) | 30/30 (100%) | N          | Y   |
| space-metrics           | 8/21 (38%)  | 21/21 (100%) | N          | Y   |
| vsm                     | 3/15 (20%)  | 15/15 (100%) | N          | N   |
