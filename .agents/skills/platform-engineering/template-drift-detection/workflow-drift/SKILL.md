---
name: workflow-drift-detection
description: "Detect drift in GitHub Actions workflows. Use when comparing workflows to template versions, detecting missing jobs, or identifying modified steps."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Workflow Drift Detection

> **Load trigger:** `"load workflow-drift-detection skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Detect drift in GitHub Actions workflows.

## Responsibilities

- Compare workflows to template versions
- Detect missing jobs
- Detect modified steps
- Detect trigger changes

## Inputs

- `.github/workflows/`
- Template workflows

## Outputs

- `workflow-drift.json`

## Drift Checks

| Check          | Description                |
| -------------- | -------------------------- |
| Missing job    | Required job removed       |
| Modified step  | Step changed from template |
| Trigger change | Trigger modified           |
| Secret drift   | Secret reference changed   |
| Action version | Action version outdated    |

## Validation Rules

- [ ] All required jobs present
- [ ] No unapproved step modifications
- [ ] Triggers match template
- [ ] Action versions current
- [ ] Secrets unchanged

## Output Format

```json
{
  "skill": "workflow-drift-detection",
  "status": "clean | drift",
  "workflows": {
    "ci.yml": {
      "status": "clean",
      "missing_jobs": [],
      "modified_steps": [],
      "trigger_changes": []
    },
    "cd.yml": {
      "status": "drift",
      "missing_jobs": [],
      "modified_steps": ["deploy-prod"],
      "trigger_changes": ["tags"]
    }
  }
}
```

## Success Criteria

- Accurate workflow drift detection
- Clear identification of changes
