---
name: trace-propagation-testing
description: "Ensure OpenTelemetry traces propagate across PIPE → OBS → GitOps → cluster. Use when validating trace_id continuity, span structure, service boundaries, or sampling rules."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Trace Propagation Testing

> **Load trigger:** `"load trace-propagation-testing skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Ensure OpenTelemetry traces propagate across PIPE → OBS → GitOps → cluster.

## Responsibilities

- Validate trace_id continuity
- Validate span structure
- Validate service boundaries
- Validate error spans
- Validate sampling rules

## Inputs

- OpenTelemetry traces

## Outputs

- `trace-report.json`
- `missing-spans.txt`

## Sub-Skills

| Skill                                      | Purpose                                  |
| ------------------------------------------ | ---------------------------------------- |
| `trace-propagation-testing/span-structure` | Validate parent-child relationships      |
| `trace-propagation-testing/continuity`     | Validate cross-service trace propagation |

## Expected Span Chain

```
[PIPE: build] → [OBS: reconcile] → [GitOps: sync] → [Cluster: deploy]
```

## Validation Rules

- [ ] Root span present per trace
- [ ] trace_id consistent across services
- [ ] span_id unique
- [ ] Parent-child relationships valid
- [ ] Error spans have status=ERROR
- [ ] Timing: child start >= parent start

## Tools

- OpenTelemetry Collector
- Jaeger
- Tempo

## Output Format

```json
{
  "skill": "trace-propagation-testing",
  "status": "pass | fail",
  "total_traces": 100,
  "complete_traces": 95,
  "broken_chains": 5,
  "missing_spans": [
    {
      "trace_id": "abc123",
      "missing_service": "gitops",
      "missing_operation": "sync"
    }
  ]
}
```

## Success Criteria

- No broken trace chains
- All spans present
