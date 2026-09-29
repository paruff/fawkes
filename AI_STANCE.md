---
repo: paruff/fawkes
suite: fawkes
stance_type: internal-platform
owner: Phil Ruff
last_reviewed: 2026-09-28
next_review_due: 2026-12-28
review_cadence: quarterly
---

# AI Stance — fawkes

This is the living AI stance for the `paruff/fawkes` Internal Developer Platform.
It is the authoritative policy document for this repository.

**Last reviewed:** 2026-09-28
**Next review due:** 2026-12-28 (quarterly)

---

## 1. Expectation of Use

AI is a routine part of how this repository is built and maintained. There are
four execution-boundary agents — `@planner`, `@builder`, `@verifier`,
`@operator` — and agents implement, humans decide. AI output is never merged
without human review, and no agent merges its own work.

This repository is a **polyglot platform repository**: it contains infrastructure
(Terraform, Kubernetes, Helm), CI/CD pipelines, observability stacks, and the
Dojo learning platform. Its product is the IDP itself — and its development
process must exemplify what the platform teaches.

## 2. Organizational Support

AI use here is backed by repository infrastructure, not convention:

- `AGENTS.md` is the single always-loaded policy source, symlinked to
  `CLAUDE.md`, `.cursorrules`, `.cursor/rules/AGENTS.md`, and
  `.github/copilot-instructions.md`.
- Four execution-boundary agents, nine stage skills, three workflows, and nine
  commands are defined under `.agents/`.
- The `ai-stance` and `ai-policy-lifecycle` skills own this document and its
  quarterly review.
- **Feedback and escalation:** raise a stance question or a suspected
  Prohibited-item violation as a GitHub issue on this repo, tagged
  `ai-stance`. The stance is only as good as its ability to be corrected, so
  a disagreement with it is a valid reason to open an issue rather than work
  around it silently. A Prohibited-item violation is also a CI concern: report
  it on the PR.
- A pre-commit hook suite runs on every commit, including gitleaks and
  detect-secrets.
- Contract assertions in `.agents/assertions/` validate agent reports.

Enforcement that actually exists today, verified against `.github/workflows/`:

| Gate                              | Workflow               | Mechanism                                      |
| --------------------------------- | ---------------------- | ---------------------------------------------- |
| Secrets, pre-commit               | local pre-commit hooks | exits non-zero on a finding                    |
| Secret-detection contract         | `agent-ci.yml`         | exits non-zero if the validator cannot go red  |
| Repo-wide secret scan            | `secret-scan.yml`      | gitleaks, exits non-zero on a finding          |
| Dependency review                 | `dependency-review.yml` | gates newly introduced vulnerable or unlicensed deps |
| Merge to `main`                   | `main-ci-guard.yml`    | blocks until `ci-quality` passes               |
| Container CVEs                    | `image-build.yml`, `image-release.yml` | Trivy writes to the job summary only — advisory |
| Static analysis (SAST)            | none                   | no workflow runs Semgrep or CodeQL — advisory   |

Anything not in that table is a reporting target, not a gate. Recording a
finding in a report does not enforce anything on its own.

---

## 3. Three-Bucket Classification

### Prohibited

- Sending PII, credentials, customer data, or proprietary infrastructure
  configuration to any public AI model.
- Committing AI-generated code without `pre-commit run --all-files` passing.
- Bypassing branch protection rules, or an agent merging its own pull request.
- AI-generated security, compliance, or policy documents published without
  qualified human review.
- AI-authored changes to the agent framework itself — `.agents/agents/`,
  `.agents/skills/`, `.agents/workflows/`, `.claude/settings.json`, or
  `.opencode/plugins/` — without explicit human sign-off. These files govern
  what every future contributor and every automated agent is permitted to do,
  and the hook entry points execute shell commands.
- Publishing an enforcement claim that this repository does not implement.
- Editing the secret-detection validator to make a known-finding test pass.

### Permitted with Guardrails

| Use                                                     | Guardrail                                                                 |
| ------------------------------------------------------- | ------------------------------------------------------------------------- |
| AI-generated code merged to `main`                       | Human review required; pre-commit and the enforced gates in section 2 must pass |
| AI-assisted spec and design documents                    | `discovery-brief.md` must exist first                                      |
| AI-authored agent, skill, or workflow definitions        | `scripts/check-harness-parity.sh` and `scripts/dual-harness-smoke.sh` must pass |
| AI-authored hook or secret-scanner changes               | `scripts/test-check-secret-detection.sh` and the hook end-to-end tests must pass |
| Agent sessions modifying infrastructure                   | Evidence gate passed by `@verifier`; human approval before release         |
| AI-generated release notes and PR bodies                  | Human review before publishing                                             |
| AI-generated content in Dojo modules                     | Disclose to learners that AI assisted in authoring                         |
| opencode sessions in this repository                      | Load `AGENTS.md` and the relevant skill at session start                   |

### Allowed

- AI-assisted code completion in any file outside the Prohibited scope.
- AI-generated first drafts of blog posts, dev.to articles, and LinkedIn posts.
- AI-assisted GitHub issue triage, labeling, and grouping.
- AI-generated test stubs, completed and verified by a human.
- Asking an AI tool to explain existing code, skills, or documentation.
- AI assistance in drafting this file, provided a human reviews and edits it.

## 4. Role Applicability

This stance applies to every human contributor and every AI agent working in
this repository, including opencode sessions, Claude Code sessions, GitHub
Copilot, Cursor, any CI automation, and any future agent added to the suite.

Agents must:

1. Load the `ai-stance` skill and confirm this file exists before beginning
   work.
2. Load `AGENTS.md` and the stage-relevant skill at session start.
3. Halt and request explicit human authorization before any action that falls
   into the Prohibited bucket, rather than proceeding on judgement.
4. Report findings as evidence with a source, and never describe an
   unvalidated finding as an enforced gate.

Humans remain accountable for every merge, every release, and every quarterly
review of this document.
