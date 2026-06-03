# Copilot Budget Admin Checklist

## 3-step org setup
1. **Set budget caps**
   - Set enterprise or organization spending limits for additional AI credit usage.
   - Set user-level budgets for known heavy users.
2. **Enable credit pooling intentionally**
   - Confirm Business or Enterprise pooled credits match actual seat counts.
   - Assign cost centers if multiple teams share the same billing entity.
3. **Review Copilot code review policy**
   - Decide which repositories use automatic PR review.
   - Remember PR review spends both AI credits and GitHub Actions minutes.

## Weekly admin ritual
```bash
# Billing overview (replace ORG and enter a billing-enabled token/session)
gh api /orgs/ORG/settings/billing/actions
gh api /orgs/ORG/copilot/billing/seats
gh api /orgs/ORG/copilot/usage

# Repository-level signals
gh api /repos/ORG/REPO/actions/workflows
gh run list --limit 20
```

## Heavy user conversation
- Start with usage data, not blame.
- Show which workflows or task types drive the spend.
- Agree on one cheaper routing change first: leaner prompts, smaller scope, lower model, or fewer automatic PR reviews.
- Re-check usage one week later before tightening budgets further.

## Budget targets by team size
| Team size | Suggested monthly overage cap | Notes |
|---|---:|---|
| 1-5 users | $25-$75 | Enough for occasional frontier debugging |
| 6-15 users | $100-$250 | Pair with user-level budgets |
| 16-40 users | $300-$750 | Use cost centers and weekly review |
| 40+ users | Custom by platform domain | Set enterprise cap plus team sub-budgets |

## Promotional credit reminder
Existing Copilot Business and Enterprise customers receive higher included AI credits from 2026-06-01 through 2026-09-01.
Re-baseline budgets before September billing resets to the standard included pool.
