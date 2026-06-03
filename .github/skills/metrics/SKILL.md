> Load with: "metrics skill" in your prompt
> Example: "Use the metrics skill to implement this feature."

# Fawkes Metrics Skill

## Metrics tracked

| #   | Metric                | Target                             | Green    | Amber             | Red      |
| --- | --------------------- | ---------------------------------- | -------- | ----------------- | -------- |
| 1   | Deployment Frequency  | >= 1 deploy/day                    | >= 1/day | 1/week to < 1/day | < 1/week |
| 2   | Lead Time for Changes | < 1 hour                           | < 1 hour | 1 hour to 1 day   | > 1 day  |
| 3   | Change Failure Rate   | < 5%                               | < 5%     | 5% to 10%         | > 10%    |
| 4   | Mean Time to Restore  | < 1 hour                           | < 1 hour | 1 hour to 1 day   | > 1 day  |
| 5   | Rework Rate           | < 10%                              | < 10%    | 10% to 20%        | > 20%    |
| 6   | AI Readiness Coverage | >= 80% green modules               | >= 80%   | 50% to 79%        | < 50%    |
| 7   | AI Credit Burn Rate   | <= 70% of monthly budget by day 22 | <= 70%   | 71% to 90%        | > 90%    |

## Measurement commands

- **Deployment Frequency**
  ```sh
  git log --since='30 days ago' --merges --first-parent --pretty=format:%ad --date=short | uniq -c
  ```
- **Lead Time for Changes**
  ```sh
  gh pr list --search 'merged:>=2026-01-01' --json number,createdAt,mergedAt
  ```
- **Change Failure Rate**
  ```sh
  gh pr list --search 'label:incident-fix merged:>=2026-01-01' --json number
  ```
- **MTTR**
  ```sh
  gh issue list --label incident --state closed --json number,createdAt,closedAt
  ```
- **Rework Rate**
  ```sh
  git log --since='30 days ago' --merges --first-parent --pretty=%s | grep -E '^(fix|hotfix|revert)(\(|:)'
  ```
- **AI Readiness Coverage**
  ```sh
  ./scripts/check-ai-readiness.sh
  ```
- **AI Credit Burn Rate**
  ```sh
  bash scripts/token-audit.sh
  ```
  Compare the result with the org billing dashboard export.

## Rework rate formula

```text
merged_prs = count of merge commits on the default branch for the review window
rework_prs = count of merge commits in the same window whose subject starts with fix, hotfix, or revert
rework_rate = (rework_prs / merged_prs) * 100
```

```sh
merged_prs=$(git log --since='30 days ago' --merges --first-parent --pretty=%s | wc -l | tr -d ' ')
rework_prs=$(git log --since='30 days ago' --merges --first-parent --pretty=%s | grep -E '^(fix|hotfix|revert)(\(|:)' | wc -l | tr -d ' ')
awk -v rework="$rework_prs" -v total="$merged_prs" 'BEGIN { if (total == 0) print 0; else printf "%.2f\n", (rework / total) * 100 }'
```

## Monthly review ritual

1. Run `./scripts/weekly-metrics.sh` and capture the latest DORA/rework baseline.
2. Run `bash scripts/token-audit.sh --save` to append the always-on context snapshot.
3. Compare GitHub billing usage against the plan pool and user budgets.
4. Review top token drivers: always-on files, long-running agent tasks, and expensive model choices.
5. Convert repeated red/amber findings into backlog items with explicit owners.
