---
name: stage-contract-validation
description: "Ensure each pipeline stage meets Fawkes contract requirements. Use when validating stage inputs/outputs, artifact passing, or stage dependencies."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Stage Contract Validation

> **Load trigger:** `"load stage-contract-validation skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Ensure each pipeline stage meets Fawkes contract requirements.

## Responsibilities

- Validate inputs/outputs for each stage
- Validate artifact passing between stages
- Validate stage dependencies

## Inputs

- `pipeline-spec.yaml`

## Outputs

- `stage-contracts.json`

## Stage Contracts

| Stage              | Required Inputs     | Required Outputs           |
| ------------------ | ------------------- | -------------------------- |
| `lint`             | Source code         | Lint report                |
| `unit-test`        | Source code         | Test results, coverage     |
| `build`            | Source code, deps   | Container image, manifests |
| `security-scan`    | Image, source       | Scan report                |
| `integration-test` | Image, test config  | Test results               |
| `e2e-test`         | Image, env config   | Test results               |
| `publish`          | Image, version.json | Registry digest            |
| `deploy`           | Manifests, version  | Deployment status          |

## Validation Rules

- [ ] Each stage has defined inputs
- [ ] Each stage has defined outputs
- [ ] Upstream outputs match downstream inputs
- [ ] No broken artifact chains
- [ ] Dependencies respected

## Output Format

```json
{
  "skill": "stage-contract-validation",
  "status": "pass | fail",
  "stages_validated": 8,
  "contracts": {
    "lint": "pass",
    "unit-test": "pass",
    "build": "pass",
    "security-scan": "pass",
    "publish": "pass",
    "deploy": "pass"
  },
  "broken_chains": []
}
```

## Success Criteria

- All stage contracts satisfied
- No broken artifact chains
