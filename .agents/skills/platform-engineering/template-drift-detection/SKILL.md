---
name: template-drift-detection
description: "Detect when a project drifts from the uFawkesAI template or golden paths. Use when comparing repos to templates, detecting modified files, or identifying outdated workflows."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Template Drift Detection

> **Load trigger:** `"load template-drift-detection skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Detect when a project drifts from the uFawkesAI template or golden paths.

## Responsibilities

- Compare project repo to template
- Detect missing or modified files
- Detect outdated workflows
- Detect outdated pipeline-spec.yaml

## Inputs

- Project repo
- Template repo

## Outputs

- `drift-report.json`
- `drift-diff.txt`

## Sub-Skills

| Skill                                          | Purpose                    |
| ---------------------------------------------- | -------------------------- |
| `template-drift-detection/workflow-drift`      | Detect workflow drift      |
| `template-drift-detection/pipeline-spec-drift` | Detect pipeline-spec drift |

## Drift Categories

| Category          | Description              | Severity |
| ----------------- | ------------------------ | -------- |
| Missing file      | Required file deleted    | High     |
| Modified file     | Template file changed    | Medium   |
| Outdated workflow | Workflow behind template | Medium   |
| Extra file        | Non-template file added  | Low      |
| Schema drift      | pipeline-spec changed    | High     |

## Validation Rules

- [ ] All template files present
- [ ] No unapproved modifications
- [ ] Workflows up to date
- [ ] pipeline-spec.yaml current
- [ ] Drift severity assessed

## Output Format

```json
{
  "skill": "template-drift-detection",
  "status": "clean | drift_detected",
  "drift": {
    "missing": [],
    "modified": ["Dockerfile"],
    "outdated": [".github/workflows/ci.yml"],
    "extra": []
  },
  "severity": "medium"
}
```

## Success Criteria

- Accurate drift detection
- Clear severity assessment
