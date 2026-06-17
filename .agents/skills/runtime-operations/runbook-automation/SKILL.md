---
name: runbook-automation
description: "Execute operational runbooks automatically based on incident type. Use when selecting, executing, and validating runbook steps."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Runbook Automation

> **Load trigger:** `"load runbook-automation skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Execute operational runbooks automatically based on incident type.

## Responsibilities

- Select correct runbook
- Execute runbook steps
- Validate results
- Escalate if runbook fails

## Inputs

- Incident type (from triage)
- Runbook library

## Outputs

- `runbook-execution.json`

## Sub-Skills

| Skill                          | Purpose                |
| ------------------------------ | ---------------------- |
| `runbook-automation/selection` | Select correct runbook |
| `runbook-automation/execution` | Execute runbook steps  |

## Runbook Library

| Incident Type        | Runbook             | Auto-Executable      |
| -------------------- | ------------------- | -------------------- |
| Pod CrashLoopBackOff | restart-pod         | Yes                  |
| OOMKilled            | increase-memory     | Yes                  |
| Deployment failure   | rollback-deployment | Yes                  |
| Node not ready       | cordon-node         | Yes                  |
| Disk pressure        | cleanup-disk        | Yes                  |
| Network partition    | check-network       | No (needs diagnosis) |

## Execution Rules

- [ ] Validate runbook applicability before execution
- [ ] Execute steps in order
- [ ] Validate each step before proceeding
- [ ] Stop on failure
- [ ] Log all steps and results

## Safety Rules

- [ ] No destructive actions without confirmation
- [ ] Maximum execution time: 5 minutes
- [ ] Escalate after 2 failed steps

## Success Criteria

- Correct runbook selected
- Runbook executed safely
- Results validated
