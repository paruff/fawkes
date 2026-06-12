---
name: adr-writer
description: "Architecture Decision Record template and quality checklist with DORA capability linkage. Use when documenting an architectural decision that agents must follow going forward."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: ADR Writer

> **Load trigger:** `"load adr-writer skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Produce Architecture Decision Records (ADRs) in a format that:

- Humans can understand and approve
- Future agents can read as authoritative context
- Links decisions to DORA capabilities so the Dojo can reference them

## When to Write an ADR

Write an ADR when a decision:

- Affects the architecture layer structure or dependency direction
- Adds or removes a mandatory tool or CI gate
- Changes the agent routing strategy
- Establishes a convention that agents will follow going forward
- Supersedes an existing ADR

Do NOT write an ADR for:

- Implementation choices within a single file
- Temporary workarounds (use a code comment + TODO issue instead)
- Decisions the team hasn't made yet (ADRs record decisions, not options)

## Numbering Convention

ADRs live in `docs/adr/`. Number sequentially: `ADR-001`, `ADR-002`, etc.
Query existing ADRs: `ls docs/adr/` before assigning a number.

## Full ADR Template

```markdown
# ADR-[NNN]: [Short Imperative Title]

> **Status:** Proposed | Accepted | Deprecated | Superseded by ADR-[NNN] > **Date:** [YYYY-MM-DD] > **Author:** [Human name or "AI-assisted, approved by [name]"]
> **DORA Capability:** Cap [N] — [Name] > **Dojo Module:** [Belt] — [Module name] (if applicable)

## Context

[1–2 paragraphs. What situation forced this decision?
What constraints exist? What problem are we solving?
Write this for an agent reading it in a future session with no prior context.]

## Decision

[One clear, specific statement of what was decided.
Start with "We will..." or "This project will..."]

## Rationale

[2–4 bullet points. Why this option specifically?
Reference DORA research or AGENTS.md constraints where relevant.
Be specific — "it's simpler" is not a rationale.]

- [Reason 1]
- [Reason 2]
- [Reason 3]

## Consequences

**Positive:**

- [What improves]

**Negative:**

- [What gets harder, costs more, or requires maintenance]

**For agents:**

- [Specific instruction: what agents MUST or MUST NOT do as a result of this decision]
  Example: "Agents must not add new npm dependencies without checking against this ADR."

## Alternatives Considered

| Option     | Why Rejected                                |
| ---------- | ------------------------------------------- |
| [Option A] | [Specific reason — not just "it was worse"] |
| [Option B] | [Specific reason]                           |

## Implementation

[Optional. If the decision requires specific action items, list them here.
Link to the GitHub issues that implement this decision.]

- [ ] [Action item] → [Issue link or "not yet created"]
```

## Quality Checklist Before Finalising an ADR

- [ ] The "For agents" section in Consequences is specific enough to generate
      a rule in AGENTS.md if needed
- [ ] The decision statement is a single sentence — not a paragraph
- [ ] Alternatives considered are real options that were genuinely evaluated
- [ ] The DORA capability is correctly identified
- [ ] Status is set (never leave it blank)
- [ ] The ADR does not contradict an existing Accepted ADR without superseding it

## Agent Context Rule

After creating an ADR, always check:
"Does this decision need a corresponding rule in AGENTS.md §4 or §5?"

If yes: draft the AGENTS.md addition alongside the ADR PR.
An ADR without a corresponding AGENTS.md rule is not enforced — it is just documented.
