# Fawkes Copilot Agent Index

> For GitHub Copilot on github.com. OpenCode uses `.agents/skills/` instead.
>
> **Models available:** gemma4:e4b, deepseek v4 flash, mimo v2.5 free (OpenCode Zen free tier).
> Copilot agents below use GPT-4.1 (0x credits) or Claude Sonnet 4.6 (1x credits).

## Available Agents

| Agent                 | Model      | Use for                                        |
| --------------------- | ---------- | ---------------------------------------------- |
| `gpt41-default`       | GPT-4.1    | Feature work, bug fixes, refactoring           |
| `infra-gitops`        | GPT-4.1    | Terraform, Helm, ArgoCD, GitHub Actions        |
| `test-engineer`       | GPT-4.1    | pytest, BDD/behave, BATS                       |
| `docs-writer`         | GPT-4.1    | README, ADRs, runbooks                         |
| `issue-writer`        | GPT-4.1    | Expand stub issues into specs                  |
| `code-reviewer`       | Sonnet 4.6 | PR review                                      |
| `ci-debugger`         | Sonnet 4.6 | CI failure diagnosis                           |
| `security-agent`      | Sonnet 4.6 | Security review                                |
| `workflow-maintainer` | GPT-4.1    | Workflow DORA timestamps, pinning, permissions |

## How to use

Issue → "Assign to Copilot" → select agent from dropdown.

## OpenCode Skills (load via `skill` tool)

| Skill                       | Use for                                   |
| --------------------------- | ----------------------------------------- |
| `github-actions`            | Pin SHA, timeout-minutes, DORA timestamps |
| `reusable-workflow-builder` | Create/modify reusable workflows          |
| `dora-instrumentor`         | Add DORA metrics to workflows             |
| `workflow-security-audit`   | Audit workflow security                   |
| `pre-commit-local`          | Targeted pre-commit validation by layer   |

For OpenCode workflows, load skills directly via the `skill` tool instead.
