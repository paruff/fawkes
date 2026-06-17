---
name: manifest-render-performance
description: "Measure Kustomize/Helm render time under many environments and overlays. Use when rendering all environments repeatedly, measuring render time, or identifying scaling issues."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Manifest Render Performance Testing

> **Load trigger:** `"load manifest-render-performance skill"` > **DORA:** Cap 4 (CI/CD Automation)
> **Token cost:** Low

## Purpose

Measure Kustomize/Helm render time under many environments and overlays.

## Responsibilities

- Render all environments repeatedly
- Measure render time
- Identify scaling issues

## Inputs

- Manifests
- Overlays

## Outputs

- `render-performance.json`

## Test Scenario

```bash
# Render all environments 100 times
for i in {1..100}; do
  time kustomize build overlays/dev > /dev/null
  time kustomize build overlays/staging > /dev/null
  time kustomize build overlays/prod > /dev/null
done
```

## Validation Rules

- [ ] Render time predictable
- [ ] No scaling issues
- [ ] All overlays render successfully
- [ ] Render time within SLA

## Output Format

```json
{
  "skill": "manifest-render-performance",
  "status": "pass | fail",
  "overlays": {
    "dev": { "p50_ms": 100, "p95_ms": 200, "p99_ms": 300 },
    "staging": { "p50_ms": 120, "p95_ms": 250, "p99_ms": 350 },
    "prod": { "p50_ms": 150, "p95_ms": 300, "p99_ms": 400 }
  },
  "scaling_linear": true
}
```

## Success Criteria

- Predictable render time growth with scale
