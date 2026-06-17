---
name: workflow-compliance
description: "Ensure GitHub Actions workflows follow Fawkes conventions. Use when validating workflow naming, required jobs, required triggers, or artifact passing."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Workflow Compliance

> **Load trigger:** `"load workflow-compliance skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Ensure GitHub Actions workflows follow Fawkes conventions.

## Responsibilities

- Validate workflow naming
- Validate required jobs
- Validate required triggers
- Validate artifact passing

## Inputs

- `.github/workflows/`

## Outputs

- `workflow-compliance.json`

## Required Workflows

| Workflow | Trigger           | Required Jobs                           |
| -------- | ----------------- | --------------------------------------- |
| `ci.yml` | push, PR          | lint, test, build, security             |
| `cd.yml` | push to main, tag | deploy-dev, deploy-staging, deploy-prod |

## Workflow Naming Convention

- lowercase, kebab-case
- `.yml` extension
- Descriptive name in workflow header

## Validation Rules

- [ ] Required workflows exist
- [ ] Workflow names follow convention
- [ ] Required triggers defined
- [ ] Required jobs present
- [ ] Artifacts passed between jobs
- [ ] Secrets referenced correctly

## Output Format

```json
{
  "skill": "workflow-compliance",
  "status": "pass | fail",
  "workflows": {
    "ci.yml": {
      "exists": true,
      "triggers_valid": true,
      "jobs_valid": true,
      "issues": []
    },
    "cd.yml": {
      "exists": true,
      "triggers_valid": true,
      "jobs_valid": true,
      "issues": []
    }
  }
}
```

## Success Criteria

- All workflows compliant
- No naming violations
- All required jobs present
