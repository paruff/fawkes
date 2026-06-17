---
name: dependency-correlation
description: "Use service dependency graph to identify upstream/downstream causes. Use when correlating failures across dependent services."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Dependency-Aware Correlation

> **Load trigger:** `"load dependency-correlation skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Use service dependency graph to identify upstream/downstream causes.

## Responsibilities

- Identify upstream failures causing downstream symptoms
- Identify downstream symptoms of upstream failure
- Produce dependency-aware incident

## Inputs

- Dependency graph
- Telemetry data

## Outputs

- `dependency-correlation.json`

## Correlation Logic

### Upstream Detection

```
1. Identify failing service(s)
2. Find all upstream callers
3. Check if upstream callers are also failing
4. If yes → upstream is likely root cause
```

### Downstream Detection

```
1. Identify failing service(s)
2. Find all downstream dependencies
3. Check if downstream dependencies are failing
4. If yes → downstream failure may be root cause
```

### Blast Radius

```
1. Identify root cause service
2. Traverse dependency graph downstream
3. Count affected services
4. Classify blast radius: small (1-3), medium (4-10), large (>10)
```

## Dependency Patterns

| Pattern              | Symptom                         | Root Cause |
| -------------------- | ------------------------------- | ---------- |
| Database down        | All DB-dependent services fail  | Database   |
| API gateway down     | All API-dependent services fail | Gateway    |
| Payment service down | Checkout fails, orders fail     | Payment    |
| Cache down           | Slow responses, timeouts        | Cache      |

## Output Format

```json
{
  "skill": "dependency-correlation",
  "root_cause": {
    "service": "database",
    "evidence": "Connection refused for all dependent services",
    "confidence": "HIGH"
  },
  "affected_services": [
    { "service": "user-api", "symptom": "500 errors" },
    { "service": "order-api", "symptom": "500 errors" },
    { "service": "payment-api", "symptom": "Timeouts" }
  ],
  "blast_radius": "medium",
  "dependency_path": ["database", "user-api", "order-api", "payment-api"]
}
```

## Success Criteria

- Accurate dependency-based correlation
- Root cause identified
- Blast radius calculated
