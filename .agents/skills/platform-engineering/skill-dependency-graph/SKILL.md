---
name: skill-dependency-graph
description: "Define and validate the dependency graph between all Fawkes skills to enable intelligent agent orchestration. Use when building skill graphs, validating no circular dependencies, or providing orchestration hints."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Skill Dependency Graph & Cross-Agent Coordination

> **Load trigger:** `"load skill-dependency-graph skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Define and validate the dependency graph between all Fawkes skills to enable intelligent agent orchestration.

## Responsibilities

- Build skill dependency graph
- Validate no circular dependencies
- Validate required skill ordering
- Provide orchestration hints to agents

## Inputs

- Skills directory
- Skill manifests

## Outputs

- `skill-graph.json`
- `orchestration-hints.json`

## Sub-Skills

| Skill                                     | Purpose                               |
| ----------------------------------------- | ------------------------------------- |
| `skill-dependency-graph/graph-validation` | Validate graph is acyclic             |
| `skill-dependency-graph/coordination`     | Define cross-agent coordination rules |

## Skill Order (Fawkes Lifecycle)

```
spec → design → plan → build → test → security → build-review → release → deploy
```

## Dependencies

| Skill                 | Depends On                            |
| --------------------- | ------------------------------------- |
| `design`              | `spec`                                |
| `plan`                | `spec`, `design`                      |
| `build`               | `plan`, `design`                      |
| `test-execution`      | `build`                               |
| `security`            | `build`                               |
| `build-review`        | `build`, `test-execution`, `security` |
| `release-engineering` | `build-review`                        |
| `cd`                  | `release-engineering`                 |

## Validation Rules

- [ ] Graph built from all skills
- [ ] No circular dependencies
- [ ] Ordering valid
- [ ] Orchestration hints generated

## Output Format

```json
{
  "skill": "skill-dependency-graph",
  "status": "valid | invalid",
  "total_skills": 20,
  "edges": 15,
  "cycles": [],
  "topological_order": ["spec", "design", "plan", "build", "test", "review", "release", "deploy"]
}
```

## Success Criteria

- Valid dependency graph
- No cycles
- Clear orchestration order
