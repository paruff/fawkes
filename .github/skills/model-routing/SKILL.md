> Load with: "model-routing skill" in your prompt
> Example: "Use the model-routing skill to implement this feature."

# Fawkes Model Routing Skill

## Mode decision table
| Need | Mode | Use when |
|---|---|---|
| Clarification, explanation, audit | Ask | No file edits or only guidance is needed |
| Small, scoped change | Edit | 1-3 known files and straightforward validation |
| Multi-file execution | Agent Mode | Cross-file implementation, investigation, or validation requires orchestration |

## Model decision table
| Tier | Models | Use for | Avoid when |
|---|---|---|---|
| Cheap | GPT-5 mini, GPT-4.1 | Docs, small config edits, summaries, focused Python/YAML fixes | Cross-layer reasoning or long investigations |
| Mid | GPT-5.2, GPT-5.2-Codex, Gemini 3 Flash | Medium refactors, test updates, structured config generation | Simple markdown or one-line edits |
| Frontier | Claude Sonnet 4.6, GPT-5.4 | Ambiguous multi-system debugging, architecture trade-offs, high-risk migrations | Routine tasks that fit cheap or mid tiers |

## Scope check protocol
Before Agent Mode, paste this into the issue or prompt:
```text
Scope check
- Files to read first: <3-5 exact paths>
- Files allowed to change: <exact paths>
- Validation to run: <existing commands only>
- Plan: <two sentences on the smallest acceptable diff>
```

## Local model guidance
- If Ollama is available, use it first for brainstorming, summarization, grep triage, and draft docs.
- Keep repository-specific or sensitive context local when a local model is good enough.
- Escalate to paid Copilot models only for repo-writing tasks, validation, or when local output is not reliable enough.

## Rule of thumb
Use the cheapest mode and model that can finish the task without a second pass.

See `docs/MODEL_ROUTING_GUIDE.md` for the full routing guide.
