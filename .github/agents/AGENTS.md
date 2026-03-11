# fawkes Copilot Agent Routing Table

All agents below are configured with **`model: gpt-4.1` (0x premium credits)**
unless otherwise noted. Select the agent from the dropdown when assigning an
issue to Copilot on GitHub.com.

> **How to assign**: Issue → "Assign to Copilot" → select agent from dropdown.
> Agent files live in `.github/agents/*.agent.md` and are automatically
> discovered by GitHub Copilot.

---

## Agent Index

| Agent | File | Use for | When |
|---|---|---|---|
| `gpt41-default` | `gpt41-default.agent.md` | Feature work, bug fixes, refactoring, config edits | Implementing issues |
| `otel-engineer` | `otel-engineer.agent.md` | OTEL pipelines, gen_ai spans, Prometheus, Grafana | Labels: `gap`, `dora` |
| `docs-writer` | `docs-writer.agent.md` | README, ADRs, runbooks, API docs | Label: `docs` |
| `test-engineer` | `test-engineer.agent.md` | pytest, BDD/behave, acceptance criteria | Label: `testing` |
| `infra-gitops` | `infra-gitops.agent.md` | Terraform, Helm, ArgoCD, GitHub Actions | Labels: `infra`, `gitops` |
| `code-reviewer` | `code-reviewer.agent.md` | PR review — severity-tagged, criteria-mapped | On every PR |
| `issue-writer` | `issue-writer.agent.md` | Expand stub issues into full implementation specs | Before assigning to any agent |

> **Note on code review**: The `.github/instructions/code-review.instructions.md`
> file provides review standards to the built-in Copilot code review system
> (accessed via PR → Reviewers → Copilot). The `code-reviewer.agent.md` is
> used when you want to trigger a review via `@copilot` mention or agent
> assignment.

---

## Routing Decision Tree

```
Is this a stub issue that needs expanding before implementation?
  └─ YES → issue-writer  (then re-assign to an implementation agent)

Is this a PR that needs reviewing?
  └─ YES → code-reviewer  (or add Copilot as reviewer in PR panel)

Is the issue about OTEL / observability / gen_ai spans / Grafana?
  └─ YES → otel-engineer

Is the issue about docs, README, ADR, or runbook only?
  └─ YES → docs-writer

Is the issue about writing/fixing tests or BDD acceptance criteria?
  └─ YES → test-engineer

Is the issue about Terraform, Helm, Kubernetes, or GitHub Actions?
  └─ YES → infra-gitops

Everything else (features, bugs, refactoring, deps)?
  └─ DEFAULT → gpt41-default
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
