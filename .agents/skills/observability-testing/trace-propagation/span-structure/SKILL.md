---
name: span-structure-validation
description: "Ensure spans follow the correct parent-child relationships. Use when validating root spans, child spans, error spans, or timing consistency."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Span Structure Validation

> **Load trigger:** `"load span-structure-validation skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Ensure spans follow the correct parent-child relationships.

## Responsibilities

- Validate root spans
- Validate child spans
- Validate error spans
- Validate timing consistency

## Inputs

- Trace data

## Outputs

- `span-structure.json`

## Span Rules

| Rule       | Description                        |
| ---------- | ---------------------------------- |
| Root span  | One root span per trace, no parent |
| Child span | Exactly one parent                 |
| Timing     | child.start >= parent.start        |
| Timing     | child.end <= parent.end            |
| Error span | status = ERROR, error.message set  |

## Validation Rules

- [ ] Exactly one root span per trace
- [ ] All child spans have valid parent
- [ ] No orphan spans
- [ ] No timing inversions
- [ ] Error spans correctly flagged

## Output Format

```json
{
  "skill": "span-structure-validation",
  "status": "pass | fail",
  "total_spans": 500,
  "root_spans": 100,
  "orphan_spans": 2,
  "timing_inversions": 0,
  "error_spans": 15,
  "issues": [{ "span_id": "xyz789", "issue": "orphan_span", "parent_id": "missing" }]
}
```

## Success Criteria

- No orphan spans
- No timing inversions
- All error spans flagged
