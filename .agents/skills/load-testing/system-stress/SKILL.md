---
name: system-stress-testing
description: "Push PIPE + OBS + GitOps + registry to and beyond expected limits to understand failure modes. Use when running high-concurrency pipelines, triggering many GitOps updates, stressing registry and cluster, or observing degradation patterns."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: System Stress & Saturation Testing

> **Load trigger:** `"load system-stress-testing skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Push PIPE + OBS + GitOps + registry to and beyond expected limits to understand failure modes.

## Responsibilities

- Run high-concurrency pipelines
- Trigger many GitOps updates
- Stress registry and cluster
- Observe degradation patterns

## Inputs

- Full system
- Stress scenarios

## Outputs

- `stress-report.json`
- `saturation-metrics.json`

## Sub-Skills

| Skill                          | Purpose                             |
| ------------------------------ | ----------------------------------- |
| `system-stress/resource-usage` | Profile CPU, memory, I/O under load |
| `system-stress/degradation`    | Analyze degradation patterns        |

## Stress Scenarios

| Scenario                  | Load                  | Duration |
| ------------------------- | --------------------- | -------- |
| High pipeline concurrency | 100 concurrent        | 30 min   |
| Rapid GitOps updates      | 50 commits/min        | 15 min   |
| Registry saturation       | 100 concurrent pushes | 10 min   |
| Combined stress           | All of the above      | 30 min   |

## Validation Rules

- [ ] Controlled degradation (no catastrophic failure)
- [ ] Clear saturation signals
- [ ] System recovers after stress
- [ ] No data corruption

## Output Format

```json
{
  "skill": "system-stress-testing",
  "status": "pass | fail",
  "scenarios": {
    "high_concurrency": {
      "throughput": 50,
      "error_rate": 2,
      "degradation": "gradual"
    },
    "rapid_gitops": { "commits_per_min": 50, "conflicts": 0 },
    "registry_saturation": { "throughput": 80, "error_rate": 5 }
  },
  "system_recovery": true,
  "data_integrity": "preserved"
}
```

## Success Criteria

- Controlled degradation (no catastrophic failure)
- Clear saturation signals
