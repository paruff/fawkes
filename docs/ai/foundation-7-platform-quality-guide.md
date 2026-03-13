# Foundation 7: Quality Internal Platforms — Improvement Guide

> **DORA 2025 Foundation 7:** "Internal platforms with paved paths, guardrails, and
> automated tooling are the critical multiplier for AI effectiveness. Poor platforms
> neutralise AI gains."
>
> **Fawkes is the platform.** Every improvement here directly improves the quality
> of every AI-generated change on this platform. This is the highest-leverage
> investment available.

---

## Why Foundation 7 matters more than any other

DORA 2025 data shows that teams with high-quality internal platforms see 3–5× better
outcomes from AI tooling than teams with poor platforms. AI amplifies what already
exists. If the platform is fragmented, undocumented, or inconsistent, AI generates
fragmented, undocumented, inconsistent code — faster.

**The compounding effect:** Each Foundation 7 improvement:
1. Makes the next AI-generated PR higher quality
2. Reduces rework rate, freeing engineering time
3. Frees time that can be reinvested in more Foundation 7 improvements

---

## Current Foundation 7 status (as of 2026-03-13)

| Element | Status | Evidence |
|---|---|---|
| ArgoCD GitOps reconciliation | ✅ Active | `platform/apps/` — 74 Application manifests |
| Helm charts with `helm lint` gate | ✅ Active | `charts/`, `.github/workflows/` |
| `make` CLI for common tasks | ✅ Active | `Makefile` |
| Pre-commit hooks | ⚠️ Partial | `make pre-commit-setup` documented but hook adoption not tracked |
| Golden path templates | ⚠️ Partial | `templates/` directory exists; not all services use it |
| Path-scoped agent instructions | ⚠️ Partial | 5 files in `.github/instructions/` (missing Python services) |
| Specialist coding agents | ⚠️ Partial | 4 agents exist; specialist coverage incomplete |
| Platform health metrics | ❌ Missing | Type-hint %, paved-path %, rework rate not tracked |
| Workspace configuration | ❌ Missing | No `.vscode/settings.json` or `.copilot/workspace.json` |
| Python services instruction file | ❌ Missing | No `python-services.instructions.md` in `.github/instructions/` |

---

## Recommended improvements — ranked by impact / effort

### Tier 1 — Highest impact, low effort (do first)

#### 1.1 Add `python-services.instructions.md` to `.github/instructions/`

**Why:** Python FastAPI services are the dominant language in `services/` (16+ services).
Without a path-scoped instruction file, every agent must re-derive Python rules from
`AGENTS.md`. A scoped file activates automatically whenever any `services/**/*.py`
file is edited in Copilot.

**What to include:**
- FastAPI route patterns (Pydantic models, `async def`, `HTTPException`)
- Type hint requirements on all signatures
- Error wrapping pattern (`raise HTTPException(...) from exc`)
- OpenTelemetry instrumentation pattern
- Structlog structured logging pattern
- Pytest `TestClient` pattern for route tests
- `ruff` + `black` + `mypy` commands to run locally

**File to create:** `.github/instructions/python-services.instructions.md`
**Suggested agent:** `docs-writer` or `gpt41-default`

---

#### 1.2 Add specialist agents for remaining coverage gaps

The following agents are either missing or insufficiently specialised for fawkes:

| Agent | Model | Gap it fills | Priority |
|---|---|---|---|
| `test-engineer.agent.md` | GPT-4.1 | pytest, pytest-bdd, bats tests | ⬅ Created (see suggestion file) |
| `issue-writer.agent.md` | Claude Sonnet 4.6 | Fully-specified GitHub issues | ⬅ Created (see suggestion file) |
| `code-reviewer.agent.md` | Claude Sonnet 4.6 | PR review across all layers | ⬅ Created (see suggestion file) |
| `infra-gitops.agent.md` | GPT-4.1 | Terraform, Helm, ArgoCD, K8s | ⬅ Created (see suggestion file) |
| `gpt41-default.agent.md` | GPT-4.1 | General fallback for any task | ⬅ Created (see suggestion file) |
| `docs-writer.agent.md` | GPT-4.1 | Keep docs fresh (see §1.3) | High |
| `security-agent.agent.md` | Claude Sonnet 4.6 | SAST, SBOM, secret scanning review | Medium |
| `python-service.agent.md` | GPT-4.1 | FastAPI service development | Medium |

---

#### 1.3 Create `docs-writer.agent.md` (GPT-4.1, 0× cost)

**Why:** Documentation rot is the primary cause of AI hallucination in context-aware
agents. When `docs/API_SURFACE.md`, `docs/ARCHITECTURE.md`, and BDD features fall
behind the code, agents invent endpoints and function names that do not exist.

**Scope:** All files in `docs/`, `README.md`, `CONTRIBUTING.md`, ADRs.

**Key rules:**
- Read the code before updating the docs — never invent based on old docs
- Diataxis structure: tutorials, how-to guides, reference, explanation
- Every new service → entry in `docs/API_SURFACE.md` in the same PR
- Every known limitation → entry in `docs/KNOWN_LIMITATIONS.md`
- Every cross-component dependency change → update `docs/CHANGE_IMPACT_MAP.md`

**File to create:** `.github/agents/docs-writer.agent.md`

---

### Tier 2 — High impact, medium effort

#### 2.1 Create `docs/GOLDEN_PATH.md` (referenced in AGENTS.md §12 but missing)

**Why:** The standard feature development workflow is documented in `AGENTS.md` but
the dedicated `docs/GOLDEN_PATH.md` file referenced by AGENTS.md §12 does not exist.
Without it, every new engineer must reconstruct the workflow from multiple sources.

**What to include:**
1. Prerequisites: tools, access, environment setup
2. Feature development loop: BDD first → implement → deploy locally → test → iterate
3. Golden path commands: `make deploy-local`, `make test-bdd`, `make lint`, `make sync`
4. PR checklist with DORA CI logging requirements
5. Definition of "ready to merge" with links to specific CI gates

**File to create:** `docs/GOLDEN_PATH.md`
**Suggested agent:** `docs-writer`

---

#### 2.2 Add AI-readiness checklist to every service's README

**Why:** The AI-readiness checklist (AGENTS.md §11) identifies whether an agent can
work on a module reliably. Without this per-service, agents frequently fail on
modules with missing type hints or no existing tests.

**What to add** to each `services/<service>/README.md`:

```markdown
## AI-Readiness Status

| Criterion | Status |
|---|---|
| Type hints on all public functions | ✅ / ❌ |
| Docstrings on all public classes | ✅ / ❌ |
| Tests exist and are green | ✅ / ❌ |
| Module is single-purpose | ✅ / ❌ |
| Error messages include context | ✅ / ❌ |
| Covered by BDD scenario | ✅ / ❌ |
```

**Quick assessment script:**

```bash
# Count functions without type hints in a service
grep -rn "^\s*\(async \)\?def " services/<service>/app/ | grep -v ") ->" | wc -l

# Count functions without docstrings (approximate)
python -c "
import ast, sys
tree = ast.parse(open(sys.argv[1]).read())
missing = [n.name for n in ast.walk(tree) if isinstance(n, ast.FunctionDef) and not ast.get_docstring(n)]
print(f'{len(missing)} functions without docstrings: {missing[:5]}')" services/<service>/app/main.py
```

---

#### 2.3 Add `scripts/check-ai-readiness.sh` platform health script

**Why:** The DORA alignment doc (`docs/ai/dora-2025-alignment.md` §7) calls for
measuring paved-path adoption and type-hint coverage. Without a script, this remains
manual and gets skipped.

**What the script should do:**

```bash
#!/usr/bin/env bash
set -euo pipefail
# scripts/check-ai-readiness.sh
# Checks each service in services/ for AI-readiness signals.
# Outputs a table and writes results to docs/METRICS.md update section.
#
# Usage: bash scripts/check-ai-readiness.sh
#
# Metrics emitted:
#   - type_hint_coverage: % of public functions with return type hints
#   - docstring_coverage: % of public functions with docstrings
#   - test_coverage: 1 if tests/unit/test_<service>*.py exists
#   - bdd_coverage: 1 if tests/bdd/features/<service>*.feature exists

for service in services/*/; do
    name=$(basename "$service")
    # Count all function definitions (handles indentation correctly)
    total=$(grep -rn "^\s*\(async \)\?def " "$service/app/" 2>/dev/null | wc -l || echo 0)
    typed=$(grep -rn "^\s*\(async \)\?def " "$service/app/" 2>/dev/null | grep -c ") ->" || echo 0)
    # Check tests
    test_exists=$(ls tests/unit/test_*"${name}"*.py 2>/dev/null | wc -l || echo 0)
    bdd_exists=$(ls tests/bdd/features/*"${name}"*.feature 2>/dev/null | wc -l || echo 0)
    echo "| $name | $typed/$total typed | ${test_exists}+ unit tests | ${bdd_exists}+ BDD |"
done
```

---

#### 2.4 Add `.vscode/settings.json` for consistent developer workspace

**Why:** Inconsistent editor settings lead to formatting disagreements caught only at
CI, adding friction to every PR. Standardising settings in the repository ensures
every developer and AI tool sees the same configuration.

**File to create:** `.vscode/settings.json`

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "ms-python.black-formatter",
  "[python]": {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports": "explicit"
    }
  },
  "[terraform]": {
    "editor.formatOnSave": true
  },
  "[yaml]": {
    "editor.formatOnSave": true
  },
  "python.linting.enabled": true,
  "python.linting.ruffEnabled": true,
  "github.copilot.enable": {
    "*": true,
    "plaintext": false,
    "markdown": true
  },
  "github.copilot.advanced": {
    "listCount": 10
  }
}
```

---

### Tier 3 — Medium impact, higher effort

#### 3.1 Create `security-agent.agent.md` (Claude Sonnet 4.6, 1× cost)

**Why:** Security review is the one area where 30% developer trust gap is highest.
A dedicated security agent that applies OWASP, CWE, and container security standards
builds trust faster than a generalist reviewer.

**Key capabilities:**
- SAST review for Python (SQL injection, command injection, path traversal)
- Secret scanning: detect accidentally committed credentials
- Container security: run-as-non-root, read-only filesystem, no privileged
- Terraform security: `tfsec`, public bucket detection, over-permissive IAM
- Kubernetes RBAC: minimal-privilege principle, ClusterRole vs Role scope

**File to create:** `.github/agents/security-agent.agent.md`

---

#### 3.2 Update `docs/METRICS.md` with AI-effectiveness metrics

**Why:** DORA 2025 requires tracking AI-specific metrics alongside classic DORA
metrics. Without a metrics tracking file, Foundation 7 progress is invisible.

**Metrics to add:**

| Metric | Target | Measurement |
|---|---|---|
| Rework rate (AI PRs) | < 10% | PRs needing > 1 round of review / total PRs |
| Type-hint coverage (`services/`) | > 95% | `scripts/check-ai-readiness.sh` output |
| BDD scenario coverage | ≥ 1 per service capability | `ls tests/bdd/features/ | wc -l` |
| Paved-path adoption | > 80% of services | Services using golden-path template |
| PR size (median) | < 200 lines | GitHub Insights → Pull Requests |
| CI pass rate (first attempt) | > 90% | GitHub Actions → Workflow runs |

---

#### 3.3 Add Copilot workspace file for richer context injection

**Why:** GitHub Copilot workspace files allow injecting repository-specific context
into every Copilot interaction, reducing the burden on individual developers to
remember to read AGENTS.md before every prompt.

**File to create:** `.github/copilot-workspace.yml` (when GA)

```yaml
# .github/copilot-workspace.yml
context:
  - path: AGENTS.md
    description: Universal agent rules — read before every task
  - path: docs/ARCHITECTURE.md
    description: Component relationships and layer dependency rules
  - path: docs/API_SURFACE.md
    description: All public service endpoints
  - path: docs/CHANGE_IMPACT_MAP.md
    description: Cross-component impact — check before touching any file
```

---

## Summary — recommended action sequence

| Step | Action | Effort | Impact | Agent |
|---|---|---|---|---|
| 1 | Apply the 5 new agent suggestion files in `.github/agents/` | 30 min | Very High | Manual |
| 2 | Create `.github/instructions/python-services.instructions.md` | 2h | Very High | `docs-writer` |
| 3 | Create `docs/GOLDEN_PATH.md` | 2h | High | `docs-writer` |
| 4 | Create `docs/agents/docs-writer.agent.md` | 1h | High | Manual / `gpt41-default` |
| 5 | Create `scripts/check-ai-readiness.sh` | 2h | High | `test-engineer` or `gpt41-default` |
| 6 | Add `.vscode/settings.json` | 30 min | Medium | `gpt41-default` |
| 7 | Add AI-readiness table to each service README | 3h | Medium | `docs-writer` |
| 8 | Update `docs/METRICS.md` with AI metrics | 1h | Medium | `docs-writer` |
| 9 | Create `security-agent.agent.md` | 2h | High | Manual |
| 10 | Add `scripts/check-ai-readiness.sh` CI step | 2h | Medium | `gpt41-default` |

---

## Related files

- [`AGENTS.md`](../../AGENTS.md) — universal agent instructions and model selection policy
- [`docs/ai/dora-2025-alignment.md`](dora-2025-alignment.md) — seven-foundation status map
- [`docs/ai/test-engineer-agent-suggestion.md`](test-engineer-agent-suggestion.md) — test-engineer agent (GPT-4.1)
- [`docs/ai/issue-writer-agent-suggestion.md`](issue-writer-agent-suggestion.md) — issue-writer agent (Claude Sonnet 4.6)
- [`docs/ai/code-reviewer-agent-suggestion.md`](code-reviewer-agent-suggestion.md) — code-reviewer agent (Claude Sonnet 4.6)
- [`docs/ai/infra-gitops-agent-suggestion.md`](infra-gitops-agent-suggestion.md) — infra-gitops agent (GPT-4.1)
- [`docs/ai/gpt41-default-agent-suggestion.md`](gpt41-default-agent-suggestion.md) — general-purpose agent (GPT-4.1)
- [`docs/CHANGE_IMPACT_MAP.md`](../CHANGE_IMPACT_MAP.md) — cross-component impact map
- [`docs/METRICS.md`](../METRICS.md) — platform metrics tracking
