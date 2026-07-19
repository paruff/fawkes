---
name: skill-graph-validation
description: "Ensure the skill dependency graph is valid and acyclic. Use when parsing SKILL.md files, building dependency graphs, detecting cycles, or validating ordering."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Skill Graph Validation

> **Load trigger:** `"load skill-graph-validation skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Ensure the skill dependency graph is valid and acyclic.

## Responsibilities

- Parse all SKILL.md files
- Build dependency graph
- Detect cycles
- Validate ordering

## Inputs

- Skills directory

## Outputs

- `graph-validation.json`

## Validation Rules

- [ ] All skills parsed
- [ ] Dependencies extracted correctly
- [ ] No circular dependencies
- [ ] Topological sort valid
- [ ] All edges valid

## Cycle Detection

```
DFS-based cycle detection:
1. Mark all nodes unvisited
2. For each unvisited node, run DFS
3. If we visit a node already in current DFS stack → cycle
4. Report cycle path
```

## Output Format

```json
{
  "skill": "skill-graph-validation",
  "status": "valid | invalid",
  "nodes": 20,
  "edges": 15,
  "cycles": [],
  "topological_order": ["spec", "design", "plan", "build"],
  "issues": []
}
```

## Success Criteria

- No cycles in dependency graph
- Valid topological ordering
