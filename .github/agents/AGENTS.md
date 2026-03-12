# fawkes Copilot Agent Routing Table

All agents below are configured with **`model: gpt-4.1` (0x premium credits)**
unless otherwise noted. Select the agent from the dropdown when assigning an
issue to Copilot on GitHub.com.

> **How to assign**: Issue → "Assign to Copilot" → select agent from dropdown.
> Agent files live in `.github/agents/*.agent.md` and are automatically
> discovered by GitHub Copilot.

---

## Agent Index

| Agent | File | Model | Cost | Use for |
|---|---|---|---|---|
| `issue-writer` | `issue-writer.agent.md` | Claude Sonnet 4.6 | 1x | Expand stub issues into full specs |
| `code-reviewer` | `code-reviewer.agent.md` | Claude Sonnet 4.6 | 1x | PR review — severity-tagged, AC-mapped |
| `ci-debugger` | `ci-debugger.agent.md` | Claude Sonnet 4.6 | 1x | Root cause diagnosis of CI failures |
| `gpt41-default` | `gpt41-default.agent.md` | GPT-4.1 | 0x | Feature work, bug fixes, refactoring |
| `otel-engineer` | `otel-engineer.agent.md` | GPT-4.1 | 0x | OTEL pipelines, gen_ai spans, Grafana |
| `docs-writer` | `docs-writer.agent.md` | GPT-4.1 | 0x | README, ADRs, runbooks, API docs |
| `test-engineer` | `test-engineer.agent.md` | GPT-4.1 | 0x | pytest, BDD/behave, acceptance criteria |
| `infra-gitops` | `infra-gitops.agent.md` | GPT-4.1 | 0x | Terraform, Helm, ArgoCD, Actions |

> **Note on code review**: The `.github/instructions/code-review.instructions.md`
> file provides review standards to the built-in Copilot code review system
> (accessed via PR → Reviewers → Copilot). The `code-reviewer.agent.md` is
> used when you want to trigger a review via `@copilot` mention or agent
> assignment.

---

## Core principle
**Sonnet 4.6 does the thinking. GPT-4.1 does the typing.**

## Routing Decision Tree

```
Needs inference, ambiguity resolution, or cross-file reasoning?
  ├─ Stub issue → spec?              → issue-writer   (Sonnet 4.6, 1x)
  ├─ Reviewing a PR?                 → code-reviewer  (Sonnet 4.6, 1x)
  ├─ CI failing, unclear why?        → ci-debugger    (Sonnet 4.6, 1x)
  └─ Complex multi-file impl?        → gpt41-default + Auto model

Well-specified, single-concern, mechanical?
  ├─ OTEL / observability / Grafana? → otel-engineer  (GPT-4.1, 0x)
  ├─ Docs / README / ADR / runbook?  → docs-writer    (GPT-4.1, 0x)
  ├─ Tests / BDD / pytest?           → test-engineer  (GPT-4.1, 0x)
  ├─ Terraform / Helm / Actions?     → infra-gitops   (GPT-4.1, 0x)
  └─ Everything else?                → gpt41-default  (GPT-4.1, 0x)

Cross-cutting architecture (3+ services)?
  └─ One-off planning session        → Claude Opus 4.6 (3x, manual)
```

## Recommended workflow per issue

```
1. Create stub issue (title + rough notes)
2. Assign → issue-writer          ← expands to full spec with AC
3. Review the expanded issue
4. Assign → appropriate impl agent ← does the work, opens PR
5. Add Copilot as PR reviewer      ← code-reviewer checks AC coverage
6. Merge
```

---

## When to escalate to a higher-cost model

Use **Claude Sonnet 4.6 (1x)** or **Claude Opus 4.6 (3x)** when:

- The issue requires cross-cutting architectural decisions (3+ services)
- The issue involves security design or threat modelling
- GPT-4.1 has already attempted the task and produced incorrect results
- The issue description is highly ambiguous and requires inference

To use a different model: assign to Copilot → model picker → select manually.

---

## Adding new agents

1. Create `.github/agents/<name>.agent.md` with YAML frontmatter including
   `model: gpt-4.1`
2. Add a row to the table above
3. Update the decision tree

Reference: [GitHub Copilot custom agents docs](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents)
