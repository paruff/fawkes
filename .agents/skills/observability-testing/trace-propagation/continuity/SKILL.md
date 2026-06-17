---
name: cross-service-trace-continuity
description: "Ensure trace_id propagates across all Fawkes services. Use when validating PIPE → OBS → GitOps → cluster propagation."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Cross-Service Trace Continuity

> **Load trigger:** `"load cross-service-trace-continuity skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Ensure trace_id propagates across all Fawkes services.

## Responsibilities

- Validate PIPE → OBS propagation
- Validate OBS → GitOps propagation
- Validate GitOps → cluster propagation

## Inputs

- Trace data

## Outputs

- `trace-continuity.json`

## Propagation Chain

```
PIPE (build trigger)
  → trace_id injected in header
  → OBS (reconcile)
    → trace_id forwarded
    → GitOps (sync)
      → trace_id forwarded
      → Cluster (deploy)
        → trace_id forwarded
```

## Propagation Headers

| Header         | Standard          |
| -------------- | ----------------- |
| `traceparent`  | W3C Trace Context |
| `tracestate`   | W3C Trace Context |
| `x-b3-traceid` | B3 (Zipkin)       |
| `x-request-id` | AWS X-Ray         |

## Validation Rules

- [ ] trace_id present in all services
- [ ] trace_id value identical across chain
- [ ] No trace_id breaks at service boundaries
- [ ] Propagation headers correct format

## Output Format

```json
{
  "skill": "cross-service-trace-continuity",
  "status": "pass | fail",
  "propagation_chain": [
    { "service": "pipe", "trace_id": "abc123", "status": "present" },
    { "service": "obs", "trace_id": "abc123", "status": "present" },
    { "service": "gitops", "trace_id": "abc123", "status": "broken" },
    { "service": "cluster", "trace_id": "abc123", "status": "missing" }
  ],
  "breaks": [{ "service": "gitops", "issue": "trace_id not propagated" }]
}
```

## Success Criteria

- No broken trace chains
- trace_id identical across all services
