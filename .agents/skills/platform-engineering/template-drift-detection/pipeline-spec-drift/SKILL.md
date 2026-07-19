---
name: pipeline-spec-drift-detection
description: "Detect drift in pipeline-spec.yaml. Use when comparing pipeline-spec to golden version, detecting missing stages, or identifying modified contracts."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Pipeline Spec Drift Detection

> **Load trigger:** `"load pipeline-spec-drift-detection skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Detect drift in pipeline-spec.yaml.

## Responsibilities

- Compare pipeline-spec.yaml to golden version
- Detect missing stages
- Detect modified contracts
- Detect schema changes

## Inputs

- `pipeline-spec.yaml`
- Golden pipeline-spec.yaml

## Outputs

- `pipeline-spec-drift.json`

## Drift Checks

| Check             | Description                  |
| ----------------- | ---------------------------- |
| Missing stage     | Required stage removed       |
| Modified contract | Stage inputs/outputs changed |
| Schema change     | Spec structure changed       |
| Version drift     | Spec version outdated        |
| Extra stage       | Non-standard stage added     |

## Validation Rules

- [ ] All required stages present
- [ ] Stage contracts unchanged
- [ ] Schema version current
- [ ] No unapproved modifications

## Output Format

```json
{
  "skill": "pipeline-spec-drift-detection",
  "status": "clean | drift",
  "drift": {
    "missing_stages": [],
    "modified_contracts": ["security-scan"],
    "schema_changes": [],
    "extra_stages": []
  },
  "severity": "medium"
}
```

## Success Criteria

- Accurate pipeline-spec drift detection
- Clear identification of changes
