# Fawkes DORA Metrics — Rework Rate

> **AGENTS.md reference:** Section 9 — Fawkes-Specific Principles  
> Rework rate is tracked here and checked weekly via `scripts/weekly-metrics.sh`.

---

## 1. Rework Rate Definition

**Rework rate** measures the percentage of pull requests that required follow-up fixes
within seven days of merging (bug fixes, reverts, or hotfixes traceable to a recently
merged PR).

| Threshold | Status | Action |
|---|---|---|
| < 10 % | 🟢 **GREEN — Healthy** | No action required. Continue current practices. |
| 10 – 20 % | 🟡 **YELLOW — Watch** | Review recent PRs for patterns. Schedule a retro item. |
| > 20 % | 🔴 **RED — Stop features** | Halt new feature work. Conduct a root-cause analysis. |

These thresholds align with DORA's definition of *change failure rate* and are applied to
the Fawkes mono-repo across all layers (services, infra, platform, scripts, docs).

---

## 2. How to Read the DevLake Rework Dashboard

1. Open Grafana at `http://devlake-grafana.127.0.0.1.nip.io` (local) or the environment
   URL configured in your `GRAFANA_URL` environment variable.
2. Navigate to **Dashboards → DORA Metrics → Rework Rate**.
3. Set the time range to **Last 7 days** (use the date picker in the top-right corner).
4. Key panels:
   - **Rework Rate (%)** — headline percentage for the selected period.
   - **Rework PRs** — list of individual PRs counted as rework.
   - **Trend** — 12-week rolling chart; look for sustained upward movement.
5. Hover over any bar in the **Rework PRs** panel to see the PR title, author, and the
   original PR it is fixing.

---

## 3. Current Baseline

> **Status as of last update:** TBD — baseline not yet established.

| Week | Rework Rate | Status | Notes |
|---|---|---|---|
| TBD | TBD % | TBD | Awaiting first DevLake data collection cycle |

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
# 1. Run the metrics script — it queries DevLake and updates this file
./scripts/weekly-metrics.sh

# 2. Check the terminal output for the traffic-light status
#    GREEN  → no action
#    YELLOW → add retro item to this week's board
#    RED    → create a P1 issue, pause new features

# 3. Commit the updated baseline table (section 3 above) with message:
#    chore(metrics): weekly rework rate update YYYY-MM-DD
```

### Escalation

| Status | Escalation path |
|---|---|
| 🟢 GREEN | No escalation |
| 🟡 YELLOW | Post summary in `#platform-engineering` Mattermost channel |
| 🔴 RED | Page on-call lead, open a P1 issue, freeze feature merges via branch protection rule |

---

## 5. Related Metrics

The following DORA metrics are tracked alongside rework rate.
See the DevLake DORA dashboard for full details.

| Metric | Target (Elite) | Source |
|---|---|---|
| Deployment Frequency | ≥ 1/day | DevLake / ArgoCD events |
| Lead Time for Changes | < 1 hour | DevLake / GitHub PRs |
| Change Failure Rate | < 5 % | DevLake / incident records |
| MTTR | < 1 hour | DevLake / PagerDuty |
| **Rework Rate** | **< 10 %** | **DevLake / GitHub PRs** |

---

## 6. See Also

- `scripts/weekly-metrics.sh` — automated weekly data collection
- `docs/runbooks/` — incident runbooks
- `docs/AGENTS.md` Section 9 — platform principles
- DevLake documentation: <https://devlake.apache.org/docs>

## AI-Readiness Metrics

> Last updated: 2026-03-13 by `scripts/check-ai-readiness.sh`
> Threshold: >= 80% GREEN | 50-79% YELLOW | < 50% RED

| Service | Type-hints | Docstrings | Unit Tests | BDD |
|---|---|---|---|---|
| ai-code-review | 3/10 (30%) | 10/10 (100%) | N | Y |
| analytics-dashboard | 9/27 (33%) | 27/27 (100%) | N | Y |
| anomaly-detection | 3/12 (25%) | 12/12 (100%) | N | Y |
| devex-survey-automation | 1/21 (4%) | 21/21 (100%) | N | N |
| discovery-metrics | 0/24 (0%) | 24/24 (100%) | N | Y |
| experimentation | 13/34 (38%) | 34/34 (100%) | N | Y |
| feedback-bot | 5/9 (55%) | 9/9 (100%) | N | Y |
| feedback | 21/43 (48%) | 40/43 (93%) | N | Y |
| friction-bot | 2/8 (25%) | 8/8 (100%) | N | N |
| insights | 2/23 (8%) | 23/23 (100%) | N | Y |
| mcp-k8s-server | 0/3 (0%) | 0/3 (0%) | N | N |
| nps | 2/11 (18%) | 11/11 (100%) | N | N |
| rag | 0/8 (0%) | 8/8 (100%) | Y | Y |
| smart-alerting | 13/30 (43%) | 30/30 (100%) | N | Y |
| space-metrics | 8/21 (38%) | 21/21 (100%) | N | Y |
| vsm | 3/15 (20%) | 15/15 (100%) | N | N |
