---
name: log-field-completeness
description: "Ensure all required log fields are present across all services. Use when validating trace_id, span_id, service, version, timestamp, or log level presence."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Log Field Completeness

> **Load trigger:** `"load log-field-completeness skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Ensure all required log fields are present across all services.

## Responsibilities

- Validate presence of trace_id, span_id, service, version
- Validate timestamp format
- Validate log level correctness

## Inputs

- Log samples

## Outputs

- `log-field-report.json`

## Required Fields Check

| Field       | Presence Threshold | Action if Missing |
| ----------- | ------------------ | ----------------- |
| `timestamp` | 100%               | Block             |
| `level`     | 100%               | Block             |
| `service`   | 100%               | Block             |
| `message`   | 100%               | Block             |
| `trace_id`  | 100%               | Block             |
| `span_id`   | 100%               | Block             |
| `version`   | 95%                | Warn              |

## Validation Rules

- [ ] All required fields present
- [ ] Timestamp in ISO 8601
- [ ] Log level one of: debug, info, warn, error
- [ ] service is kebab-case
- [ ] trace_id is 32 hex chars

## Output Format

```json
{
  "skill": "log-field-completeness",
  "status": "pass | fail",
  "total_logs": 10000,
  "fields": {
    "timestamp": { "present": 10000, "missing": 0, "status": "pass" },
    "trace_id": { "present": 9995, "missing": 5, "status": "fail" },
    "service": { "present": 10000, "missing": 0, "status": "pass" }
  }
}
```

## Success Criteria

- No missing required fields
