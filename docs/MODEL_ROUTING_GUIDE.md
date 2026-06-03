# Fawkes Model Routing Guide

## One-sentence routing rule
Use the cheapest mode and model that can finish the task correctly in one pass.

## Mode decision tree
```text
Need only an answer or audit?
├─ Yes -> Ask mode
└─ No
   Need to change 1-3 known files with a clear fix?
   ├─ Yes -> Edit mode
   └─ No
      Does the task need repo exploration, multi-file orchestration,
      repeated validation, or cross-layer reasoning?
      ├─ Yes -> Agent Mode
      └─ No -> Edit mode
```

## Model selection table
| Tier | Example models | Relative cost signal | Best for | Example Fawkes tasks |
|---|---|---|---|---|
| Cheap | GPT-5 mini, GPT-4.1 | Lowest | Docs, small YAML, scoped Python fixes | `.copilotignore`, markdown, one-file validation fixes |
| Mid | GPT-5.2, GPT-5.2-Codex, Gemini 3 Flash | Medium | Multi-file but still bounded implementation | focused test additions, moderate refactors |
| Frontier | Claude Sonnet 4.6, GPT-5.4 | Highest | Ambiguous debugging, deep reasoning, risky migrations | CI failure triage, cross-system design trade-offs |

## Scope-before-you-start protocol
Paste this into the agent prompt before any Agent Mode task:

```text
Scope check
- Files to read first: <3-5 exact paths>
- Files allowed to change: <exact paths>
- Validation to run: <existing commands only>
- Plan: <two sentences on the smallest acceptable diff>
```

## Expensive anti-patterns
| Anti-pattern | Why it is expensive | Cheaper alternative |
|---|---|---|
| "Audit the whole repo" with frontier model | Large repo context plus high model rate | Scope to exact directories and start with Ask mode |
| Agent Mode for markdown or `.gitignore` edits | Multiple tool/model turns for trivial work | Edit mode with GPT-5 mini |
| Re-sending long architectural policy on every prompt | Always-on input tax repeats all month | Keep AGENTS lean; load skills only when needed |
| Letting sticky model selection stay on a frontier model | Every follow-up inherits expensive pricing | Confirm the model selector before each new task |

## Local model strategy
If the team has Ollama available:
- Use local models for brainstorming, summaries, issue drafting, and first-pass document structure.
- Keep paid Copilot usage for repo-aware editing, validation, and tasks that need GitHub-integrated agents.
- Do not trust local output without comparing it to repo files and existing conventions.

## Fawkes examples
- Ask + cheap: explain `docs/ARCHITECTURE.md`, summarize a workflow, draft release notes.
- Edit + cheap: update `.copilotignore`, fix a shell script comment, trim markdown.
- Edit + mid: add a focused unit test or adjust a small FastAPI endpoint plus test.
- Agent Mode + frontier: trace a failing CI workflow across workflow YAML, scripts, and Terraform.
