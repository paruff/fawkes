---
name: pipeline-spec-enforcement
description: "Ensure every Fawkes project adheres to pipeline-spec.yaml, guaranteeing consistency across all services. Use when validating pipeline structure, required stages, or stage ordering."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Pipeline Spec Enforcement

> **Load trigger:** `"load pipeline-spec-enforcement skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Ensure every Fawkes project adheres to pipeline-spec.yaml, guaranteeing consistency across all services.

## Responsibilities

- Validate pipeline-spec.yaml structure
- Validate required stages (unit, integration, e2e, security, etc.)
- Validate stage ordering
- Validate required artifacts (version.json, SBOM, signatures)
- Validate environment definitions

## Inputs

- `pipeline-spec.yaml`
- Project repo

## Outputs

- `pipeline-spec-report.json`
- `missing-stages.txt`

## Sub-Skills

| Skill                                          | Purpose                       |
| ---------------------------------------------- | ----------------------------- |
| `pipeline-spec-enforcement/stage-contracts`    | Validate stage inputs/outputs |
| `pipeline-spec-enforcement/artifact-contracts` | Validate required artifacts   |

## Required Stages

| Stage              | Required    | Order |
| ------------------ | ----------- | ----- |
| `lint`             | Yes         | 1     |
| `unit-test`        | Yes         | 2     |
| `build`            | Yes         | 3     |
| `security-scan`    | Yes         | 4     |
| `integration-test` | Conditional | 5     |
| `e2e-test`         | Conditional | 6     |
| `publish`          | Yes         | 7     |
| `deploy`           | Yes         | 8     |

## Validation Rules

- [ ] pipeline-spec.yaml exists
- [ ] Schema valid
- [ ] All required stages present
- [ ] Stages in correct order
- [ ] Required artifacts defined
- [ ] Environments defined

## Tools

- yq
- JSON schema validator

## Output Format

```json
{
  "skill": "pipeline-spec-enforcement",
  "status": "pass | fail",
  "spec_version": "1.0",
  "stages": {
    "present": ["lint", "unit-test", "build", "security-scan", "publish", "deploy"],
    "missing": ["integration-test"],
    "invalid": []
  },
  "schema_valid": true
}
```

## Success Criteria

- No missing or invalid stages
- No schema violations
