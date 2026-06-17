---
name: gitops-commit-rate-testing
description: "Measure how many commits OBS can safely push per minute. Use when running promotion loops, measuring commit frequency, or detecting conflicts or failures."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: GitOps Commit Rate Testing

> **Load trigger:** `"load gitops-commit-rate-testing skill"` > **DORA:** Cap 4 (CI/CD Automation)
> **Token cost:** Low

## Purpose

Measure how many commits OBS can safely push per minute.

## Responsibilities

- Run promotion loops
- Measure commit frequency
- Detect conflicts or failures

## Inputs

- GitOps repo

## Outputs

- `commit-rate.json`

## Test Scenario

```bash
# Simulate rapid promotions
for i in {1..100}; do
  yq -i ".spec.template.spec.containers[0].image = \"app:v${i}\"" deployment.yaml
  git add . && git commit -m "promote v${i}"
done
```

## Validation Rules

- [ ] No excessive conflicts
- [ ] Commit rate stable
- [ ] No repo corruption
- [ ] All commits valid

## Output Format

```json
{
  "skill": "gitops-commit-rate-testing",
  "status": "pass | fail",
  "commits_per_minute": 10,
  "total_commits": 100,
  "conflicts": 0,
  "failures": 0,
  "repo_valid": true
}
```

## Success Criteria

- No excessive conflicts
- Commit rate stable
