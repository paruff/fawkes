---
name: network-chaos
description: "Inject network faults between PIPE, OBS, registry, and cluster. Use when adding latency, packet loss, bandwidth limits, or creating network partitions."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Network Chaos

> **Load trigger:** `"load network-chaos skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Inject network faults between PIPE, OBS, registry, and cluster.

## Responsibilities

- Add latency
- Add packet loss
- Add bandwidth limits
- Create network partitions

## Inputs

- Target services

## Outputs

- `network-chaos.json`

## Network Fault Types

| Fault           | Parameter   | Target           |
| --------------- | ----------- | ---------------- |
| Latency         | duration_ms | PIPE ↔ Registry |
| Packet loss     | percentage  | OBS ↔ GitOps    |
| Bandwidth limit | rate        | All services     |
| Partition       | duration_s  | PIPE ↔ OBS      |

## Toxiproxy Config

```json
{
  "name": "pipe-registry-latency",
  "listen": "0.0.0.0:8474",
  "upstream": "registry:5000",
  "toxics": [
    {
      "type": "latency",
      "attributes": { "latency": 5000 }
    }
  ]
}
```

## Validation Rules

- [ ] Network faults injected successfully
- [ ] Services tolerate degraded network
- [ ] Recovery within expected time
- [ ] No data corruption

## Output Format

```json
{
  "skill": "network-chaos",
  "status": "success",
  "faults_injected": [
    { "type": "latency", "target": "pipe-registry", "value": "5000ms" },
    { "type": "packet_loss", "target": "obs-gitops", "value": "10%" }
  ],
  "recovery": {
    "pipe": { "recovered": true, "time_s": 30 },
    "obs": { "recovered": true, "time_s": 45 }
  }
}
```

## Success Criteria

- System tolerates degraded network
- Recovery within SLA
