# DORA 2025 AI Capabilities — Fawkes Alignment Guide

> **Source:** [DORA 2025 State of AI-Assisted Software Development](https://dora.dev/dora-report-2025/)  
> **Category:** Reference | AI Practices  
> **Audience:** Platform engineers, AI coding agents, team leads

---

## Overview

The **DORA 2025 State of AI-Assisted Software Development** report established the
**DORA AI Capabilities Model**: seven technical and cultural foundations that determine
whether AI accelerates or destabilises software delivery. Approximately 90% of
technology professionals now use AI in their work, yet ~30% express little or no
trust in AI-generated code. Speed without stability accelerates chaos, not value.

**Key finding:** AI is an *amplifier* of existing practices, not a shortcut. High-performing
teams get measurably better with AI. Teams with weak foundations see their problems
worsen at greater speed.

---

## The Seven Foundations — Fawkes Status

### 1. Clear AI Stance and Policy

Ambiguity breeds risk. Teams need defined, communicated policies on when and how to
leverage AI safely.

**Fawkes implementation:**
- `AGENTS.md` — universal rules for all agents (Copilot, Claude, VS Code agent mode)
- `.github/copilot-instructions.md` — Copilot-specific standards
- `.github/agents/` — specialist agent profiles with task-scoped instructions
- `AGENTS.md § 10` — Model Selection Policy with cost guardrails

**What to improve:** Ensure `docs/ai/usage-policy.md` is linked prominently from
onboarding materials and kept current as model selection policy evolves.

---

### 2. Healthy Data Ecosystem

AI is only as good as the data it can access. Poor-quality data (undocumented
functions, missing type hints, silent errors) stymies AI effectiveness.

**Fawkes implementation:**
- `ruff` + `mypy` enforce type hints on all Python services
- Google-style docstrings required on all public functions
- Structured logs (structlog) provide machine-readable audit data
- BDD features in business language create readable acceptance criteria

**What to improve:** Track type-hint coverage as a metric in `docs/METRICS.md`.
Target: 100% of public functions in `services/` have type hints.

---

### 3. AI-Accessible Internal Data

Connecting AI to internal documentation, codebases, and decision logs turns a
generic assistant into a specialised expert for your context.

**Fawkes implementation:**
- `docs/API_SURFACE.md` — complete public interface map
- `docs/ARCHITECTURE.md` — component relationships
- `docs/CHANGE_IMPACT_MAP.md` — which files break when a component changes
- `AGENTS.md § 3` — ordered context file list agents must read first
- RAG service (`docs/ai/vector-database.md`) for semantic doc search

**What to improve:** Ensure every new service has an entry in `docs/API_SURFACE.md`
added in the same PR that creates the service.

---

### 4. Strong Version Control Practices

As AI accelerates code generation, robust version control is more critical than ever
to maintain quality and enable safe experimentation.

**Fawkes implementation:**
- Conventional commits: `feat(scope):`, `fix(scope):`, `test(scope):`, `docs(scope):`
- PR size gate: > 400 lines blocked by CI; requires `large-pr-approved` label
- Branch protection on `main` — no direct pushes
- Every AI-generated commit must pass `make lint` before merge

**Enforcement:** `AGENTS.md § 8` Instability Safeguards

---

### 5. Working in Small Batches

AI increases the risk of introducing many changes at once. Small-batch practices
prevent speed from undermining stability.

**Fawkes implementation:**
- PR size limit: 400 lines (CI gate)
- Issue template requires explicit file list — agents must not create files not listed
- `AGENTS.md § 5` — agents must ask before touching more than 5 files in one task
- DORA lead-time target: every issue completable in < 2 days of agent work

**What to improve:** Add a CI check that counts files changed and warns at 10+ files.

---

### 6. User-Centric Focus

Rapid AI-generated delivery only matters if aimed at real user needs. Teams must
maintain tight feedback loops between delivery and user value.

**Fawkes implementation:**
- BDD features written in business language (`tests/bdd/`) — user needs first
- Backstage catalog (`catalog-info.yaml`) maps services to user-facing capabilities
- Golden-path templates (`templates/`) reduce cognitive load for new engineers
- Acceptance tests (`AT-E1-*`) validate platform capabilities from a user perspective

**What to improve:** Add user story links to every BDD feature file header.

---

### 7. Quality Internal Platforms

Internal platforms with paved paths, guardrails, and automated tooling are the
critical multiplier for AI effectiveness. Poor platforms neutralise AI gains.

**Fawkes implementation:**
- ArgoCD GitOps — declarative, automated reconciliation
- Pre-commit hooks (`make pre-commit-setup`) — catch issues before CI
- Helm charts with `helm lint` + `helm template` gates
- `make` targets provide a single, documented CLI for all common tasks
- Fawkes *is* the platform — every improvement here directly improves AI output quality

**What to improve:** Measure and report platform paved-path adoption (% of services
using golden-path templates) in `docs/METRICS.md`.

---

## AI Trust and Verify Protocol

Because ~30% of developers do not trust AI-generated code (DORA 2025), human review
is a trust-building mechanism, not just a quality gate.

### Read → Run → Review

```
1. READ   — AI reads the existing module before writing code.
            Never invent function names or import paths.

2. RUN    — AI executes tests after writing them.
            A test that has never run has unknown value.

3. REVIEW — Human approves all security, RBAC, secrets, and infra changes.
            Regardless of AI confidence level.

4. DECLARE — PR description notes which sections are AI-generated.
```

### AI-Readiness Checklist

A module is "AI-ready" when agents can work on it without hallucinating context.
Use this checklist before assigning an AI agent to a module:

- [ ] Type hints on all public functions
- [ ] Docstrings on all public classes and functions
- [ ] Tests exist and are green
- [ ] Module is single-purpose (not a God file)
- [ ] Error messages include context (`raise ValueError(f"createUser: {detail}")`)
- [ ] Module covered by at least one BDD scenario

---

## Team Archetypes (DORA 2025)

DORA 2025 defines seven team archetypes. Fawkes targets the top tier:

| Archetype | AI Effectiveness | Fawkes Target |
|---|---|---|
| Harmonious high-achievers | Highest | ✅ Target |
| Capable collaborators | High | Acceptable |
| Productive but siloed | Medium | Needs improvement |
| Legacy bottlenecks | Low | Unacceptable |
| Dysfunctional foundations | Negative | Blocked from AI use |

Teams with "legacy bottlenecks" or "dysfunctional foundations" should fix their
foundation before enabling AI tooling — AI will accelerate their problems.

---

## Measuring AI Impact on DORA Metrics

Monitor these alongside classic DORA metrics when AI tooling is active:

| Metric | Positive Signal | Warning Signal |
|---|---|---|
| Deployment frequency | Increasing | Unchanged or decreasing |
| Lead time for changes | Decreasing | Increasing (AI rework) |
| Change failure rate | Stable or decreasing | Increasing (AI-introduced bugs) |
| MTTR | Stable or decreasing | Increasing (harder to debug AI code) |
| Rework rate | < 10% | > 20% → stop, fix instructions |
| PR size | Decreasing trend | Increasing (AI batch risk) |

Rework rate tracked in: `docs/METRICS.md`  
Weekly check: `scripts/weekly-metrics.sh`

---

## Related Resources

- [DORA 2025 Report](https://dora.dev/dora-report-2025/)
- [DORA AI Capabilities Model PDF](https://services.google.com/fh/files/misc/2025_dora_ai_capabilities_model.pdf)
- [AI Usage Policy](usage-policy.md)
- [Copilot Setup](copilot-setup.md)
- AGENTS.md — universal agent instructions
- Model Selection Policy
- [METRICS.md](../METRICS.md)
