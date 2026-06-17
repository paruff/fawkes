---
name: observability
description: "Emit structured telemetry for all agent invocations. Use when adding observability to any agent or when tracking agent performance."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Observability

> **Load trigger:** `"load observability skill"` > **DORA:** Cap 2 (Observability) + Cap 6 (Reliability)
> **Token cost:** Low

## Purpose

Emit structured telemetry for all agent invocations. Every agent should load this skill to ensure consistent observability.

## Responsibilities

- Emit invocation spans (start, complete, fail)
- Track skill loading events
- Record findings with actionability
- Log decisions for post-hoc analysis
- Correlate traces across agent pipeline

## Dependencies

| Skill  | Relationship                      |
| ------ | --------------------------------- |
| (none) | Foundation skill, no dependencies |

## Telemetry Protocol

### Every Agent Must

1. **On Start:** Emit `agent.invocation.started` span
2. **On Skill Load:** Emit `agent.skill.loaded` span
3. **On Finding:** Emit `agent.finding.produced` span
4. **On Decision:** Emit `agent.decision.made` span
5. **On Complete:** Emit `agent.invocation.completed` span
6. **On Error:** Emit `agent.invocation.failed` span

### Span Attributes

| Attribute              | Type    | Description                                           |
| ---------------------- | ------- | ----------------------------------------------------- |
| `agent.name`           | string  | Agent name (e.g., "spec", "build", "review")          |
| `session_id`           | string  | Unique session identifier                             |
| `mode`                 | string  | Agent mode (e.g., "pr-review", "build-validation")    |
| `skill.name`           | string  | Skill name (e.g., "build", "review")                  |
| `skill.domain`         | string  | Skill domain (e.g., "core", "platform")               |
| `severity`             | string  | Finding severity (critical/high/medium/low)           |
| `category`             | string  | Finding category (architecture/test/security/quality) |
| `actionable`           | boolean | Whether finding requires action                       |
| `manual_review_needed` | boolean | Whether finding needs human review                    |
| `decision`             | string  | Final decision (approve/request-changes/fail)         |
| `blocker_count`        | int     | Number of blockers found                              |
| `finding_count`        | int     | Total findings                                        |
| `duration_ms`          | int     | Duration in milliseconds                              |
| `total_skills_loaded`  | int     | Total skills loaded during invocation                 |
| `total_findings`       | int     | Total findings produced                               |
| `error`                | string  | Error message (if failed)                             |
| `stage`                | string  | Stage where error occurred                            |

## Integration with Existing Logging

### Phase 0 Logs

Phase 0 logs (`.agents/logs/YYYY-MM-DD.jsonl`) are the data source. Observability spans are the OTEL representation of the same events.

Mapping:

- `agent.invocation.started` + `agent.invocation.completed` → one log entry
- `agent.skill.loaded` → `skills_loaded[]` array in log entry
- `agent.finding.produced` → each item in `findings[]` array
- `agent.decision.made` → `decision` and `blockers` fields

### Post-Task Logging

After producing output, every agent must:

1. Append one JSON object to `.agents/logs/YYYY-MM-DD.jsonl`
2. Follow the schema in `.agents/schema/skill-invocation-log.json`
3. Include: agent name, session_id, skills loaded, findings, decision, blockers
4. For each finding, set `actionable` and `manual_review_needed` accurately

## Output Format

```json
{
  "skill": "observability",
  "status": "pass | fail",
  "spans_emitted": [
    {
      "name": "agent.invocation.started",
      "attributes": {
        "agent.name": "build",
        "session_id": "abc-123",
        "timestamp": "2024-01-15T10:30:00Z"
      }
    }
  ],
  "log_entry": {
    "agent": "build",
    "session_id": "abc-123",
    "skills_loaded": ["build", "code-generation"],
    "findings": [],
    "decision": "pass",
    "blockers": 0
  }
}
```

## Success Criteria

- All agents emit telemetry spans
- Log entries follow schema
- Traces are correlated across pipeline
- Metrics are available for DORA calculation
