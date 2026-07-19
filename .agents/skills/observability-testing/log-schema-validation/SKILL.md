---
name: log-schema-validation
description: "Ensure all Fawkes components emit structured, consistent, machine-parseable logs. Use when validating JSON log structure, required fields, log levels, or detecting plaintext secrets."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Log Schema Validation

> **Load trigger:** `"load log-schema-validation skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Ensure all Fawkes components (OBS, PIPE, CLI, agents) emit structured, consistent, machine-parseable logs.

## Responsibilities

- Validate JSON log structure
- Validate required fields (timestamp, level, service, trace_id)
- Validate log levels
- Validate no plaintext secrets
- Validate log volume under load

## Inputs

- Logs from PIPE, OBS, GitOps controllers

## Outputs

- `log-schema.json`
- `log-anomalies.txt`

## Sub-Skills

| Skill                                      | Purpose                            |
| ------------------------------------------ | ---------------------------------- |
| `log-schema-validation/field-completeness` | Ensure all required fields present |
| `log-schema-validation/log-volume`         | Ensure log volume within limits    |

## Required Fields

| Field       | Type   | Format                | Required |
| ----------- | ------ | --------------------- | -------- |
| `timestamp` | string | ISO 8601              | Yes      |
| `level`     | string | info/warn/error/debug | Yes      |
| `service`   | string | kebab-case            | Yes      |
| `message`   | string | non-empty             | Yes      |
| `trace_id`  | string | 32 hex chars          | Yes      |
| `span_id`   | string | 16 hex chars          | Yes      |
| `version`   | string | semver                | Yes      |

## Validation Rules

- [ ] All logs valid JSON
- [ ] All required fields present
- [ ] Timestamp in ISO 8601
- [ ] Log level valid
- [ ] No plaintext secrets in log values
- [ ] trace_id format correct

## Tools

- Loki
- jq
- logfmt validators

## Output Format

```json
{
  "skill": "log-schema-validation",
  "status": "pass | fail",
  "total_logs": 10000,
  "valid": 9995,
  "invalid": 5,
  "violations": [{ "line": 1234, "field": "trace_id", "issue": "missing" }]
}
```

## Success Criteria

- 100% structured logs
- No schema violations
- No leaked secrets
