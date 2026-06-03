# TOKEN COST: This file loads on every Copilot/Claude Code/Cursor request.
# Every line is billed on every interaction. Keep it lean.
# Full details live in .github/skills/ — load them on demand only.

## AI policy
- Verify repo truth.
- Read files first
- Prefer Ask/Edit.
- Human review: infra, security, workflows, catalog.
- No secrets. Validate. Note gaps.

## Project identity
Fawkes: GitOps IDP + DORA showcase.
Stack: Python, Terraform, Helm/YAML, Bash, Backstage/Jenkins.
Constraint: small PRs; no leaks.

## Never do
1. Workflow/ArgoCD/catalog edits without approval.
2. Wrong-layer logic.
3. Secrets, cloud defaults, latest tags.
4. Delete tests, skip 400-line gate, push/merge main.
5. Invent APIs, paths, resources.

## Token budget protocol
Agent Mode: 3-5 reads, writable files, smallest diff, 2-sentence plan.
Load one skill; re-scope on cross-layer work.

## On-demand skills
| Need | Load |
|---|---|
| Build | architecture; pr-contract |
| Cost | metrics; model-routing |

## Context files table
| Need | Read |
|---|---|
| Core | ARCHITECTURE.md; CHANGE_IMPACT_MAP.md |
| Task docs | API_SURFACE.md; KNOWN_LIMITATIONS.md; METRICS.md |

## See also
Cost: docs/COPILOT_COST_GUIDE.md; Routing: docs/MODEL_ROUTING_GUIDE.md; Golden path: docs/golden-path-usage.md
