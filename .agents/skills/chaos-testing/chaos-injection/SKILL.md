---
name: chaos-injection
description: "Inject controlled failures into PIPE, OBS, GitOps repos, registries, and Kubernetes to validate resilience. Use when injecting network latency, killing processes, or introducing registry outages."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Chaos Injection

> **Load trigger:** `"load chaos-injection skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Inject controlled failures into PIPE, OBS, GitOps repos, registries, and Kubernetes to validate resilience.

## Responsibilities

- Inject network latency, packet loss, and partitions
- Kill PIPE or OBS processes mid-operation
- Introduce registry outages
- Introduce GitOps repo conflicts

## Inputs

- Chaos scenarios
- Live system

## Outputs

- `chaos-injection-report.json`
- `recovery-metrics.json`

## Sub-Skills

| Skill                     | Purpose                        |
| ------------------------- | ------------------------------ |
| `chaos-injection/network` | Network fault injection        |
| `chaos-injection/process` | Process kill/restart injection |

## Chaos Targets

| Target        | Fault Type         | Impact             |
| ------------- | ------------------ | ------------------ |
| PIPE build    | Process kill       | Build interruption |
| OBS reconcile | Network partition  | Reconcile delay    |
| Registry      | Connection timeout | Image pull failure |
| GitOps repo   | Lock/unavailable   | Commit failure     |
| K8s API       | Latency            | Controller delay   |

## Validation Rules

- [ ] System recovers gracefully
- [ ] No data corruption
- [ ] No GitOps drift
- [ ] Recovery within SLA
- [ ] No cascading failures

## Tools

- Toxiproxy
- Pumba
- Chaos Mesh

## Output Format

```json
{
  "skill": "chaos-injection",
  "status": "success",
  "scenarios_executed": 5,
  "recovery": {
    "pipe": { "recovered": true, "recovery_time_s": 30 },
    "obs": { "recovered": true, "recovery_time_s": 45 }
  },
  "data_integrity": "preserved",
  "gitops_drift": "none"
}
```

## Success Criteria

- System recovers gracefully
- No data corruption
- No GitOps drift
