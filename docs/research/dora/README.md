# DORA Research — Core to Fawkes Product Direction

> **Why this matters:** Fawkes is an Internal Developer Platform. DORA research is the evidence base for every platform decision we make. These three reports define what "good" looks like and how to measure it.

---

## Reports

| Report                                             | Date     | PDF                                                                                                    | Key Focus                                                  |
| -------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------- |
| **State of AI-assisted Software Development 2025** | Sep 2025 | [PDF](https://services.google.com/fh/files/misc/2025_state_of_ai_assisted_software_development.pdf)    | Who is adopting AI, how they use it, and what happens next |
| **AI Capabilities Model**                          | Nov 2025 | [PDF](https://services.google.com/fh/files/misc/2025_dora_ai_capabilities_model.pdf)                   | The 7 foundational capabilities that amplify AI benefits   |
| **ROI of AI-assisted Software Development**        | Feb 2026 | [PDF](https://services.google.com/fh/files/misc/dora-roi-of-ai-assisted-software-development-2026.pdf) | Navigating the J-Curve, measuring financial impact         |

---

## Key Findings & Fawkes Implications

### 1. AI is an Amplifier (All Reports)

> "AI's primary role in software development is that of an amplifier. It magnifies the strengths of high-performing organizations and the dysfunctions of struggling ones."

**Fawkes implication:** Platform quality is the #1 multiplier. Every improvement to Golden Paths, linters, Helm charts, and CI pipelines directly improves AI output quality. Weak foundations get worse faster with AI.

### 2. The AI Productivity Paradox (State of AI 2025)

Individual output metrics improve dramatically, but organizational delivery stays flat:

- +21% tasks completed per developer
- +98% more PRs merged
- Organizational delivery: **flat**

**Why:** Time saved in code generation is re-allocated to verification and review. The "verification tax" absorbs individual gains.

**Fawkes implication:** We must measure **end-to-end delivery** (VSM), not just individual velocity. DORA 5 metrics are primary; individual metrics are secondary.

### 3. The Acceleration Whiplash (Faros 2026 update)

The paradox is accelerating:

- PR review time: +441%
- Bugs per developer: +54%
- Incidents per PR: +242.7%
- Developers interact with 67.4% more PR contexts daily
- 26% more in-progress tasks stalled for 7+ days

**Fawkes implication:** Small batch discipline is critical. The 400-line PR gate must be enforced more aggressively. AI-generated changes must be chunked.

### 4. The Seven AI Capabilities (AI Capabilities Model)

The capabilities that determine whether AI benefits scale:

| #   | Capability                       | Fawkes Status | Gap                                                       | Phase  |
| --- | -------------------------------- | ------------- | --------------------------------------------------------- | ------ |
| 1   | Clear and communicated AI stance | ⚠️ Partial    | AGENTS.md exists but not socialized beyond this repo      | 3e     |
| 2   | Healthy data ecosystems          | ⚠️ Partial    | Type hints + structured logs; no unified data platform    | 3b     |
| 3   | AI-accessible internal data      | ✅ Strong     | AGENTS.md context files, ARCHITECTURE.md, API_SURFACE.md  | Done   |
| 4   | Strong version control practices | ✅ Strong     | Small PRs, CI gates, conventional commits                 | Done   |
| 5   | Working in small batches         | ⚠️ Partial    | 400-line gate exists; AI pushes toward larger changes     | 3e     |
| 6   | User-centric focus               | ⚠️ Partial    | Backstage templates; no user research yet                 | 3a, 3c |
| 7   | Quality internal platforms       | ✅ Strong     | This IS the platform — paved paths, linters, Helm, ArgoCD | Done   |

### 5. The Seven Team Archetypes (State of AI 2025)

DORA identifies 7 team performance patterns (replacing low/medium/high/elite):

1. **Foundational Challenges** — survival mode, significant process gaps
2. **Legacy Bottleneck** — constantly reacting to unstable systems
3. **Constrained by Process** — consumed by inefficient workflows
4. **High Impact, Low Cadence** — quality work, delivered slowly
5. **Stable and Methodical** — deliberate delivery, high quality
6. **Pragmatic Performers** — impressive speed, functional environments
7. **Harmonious High-Achievers** — virtuous cycle of sustainable excellence

**Fawkes implication:** One-size-fits-all AI strategies fail. Each archetype needs a different approach. Fawkes should classify its teams and tailor AI tooling accordingly.

### 6. The J-Curve (ROI 2026)

> "Navigate the J-Curve: explicitly budget for the 'tuition cost' — a necessary investment in learning before long-term ROI materializes."

Key insight: **Reinvest capacity, don't reduce headcount.** The greatest returns come from reducing unnecessary rework to reclaim engineering capacity.

**Fawkes implication:** Don't cut headcount when AI saves time. Reinvest freed capacity into platform quality, testing, and documentation.

### 7. Value Stream Management (State of AI 2025)

Without end-to-end visibility, teams optimize locally — making code generation faster — while actual constraints shift to review, integration, and deployment. This is "localized pockets of productivity lost to downstream chaos."

**Fawkes implication:** VSM dashboard is P0. We need to map the full path: `Commit → CI → Build → Push → GitOps Commit → ArgoCD Sync → Running in Cluster` and instrument each stage.

---

## How Fawkes Addresses Each Capability

### Capability 1: Clear AI Stance

- [x] AGENTS.md defines permitted AI tasks, model selection, trust/verify rules
- [ ] Socialize beyond this repo (internal blog, team presentations)
- [ ] Create AI usage policy document for the organization
- **Phase:** 3e

### Capability 2: Healthy Data Ecosystems

- [x] Type hints on all Python functions
- [x] Structured logging with trace_id + span_id injection
- [x] Prometheus metrics + gen_ai.\* recording rules
- [ ] Unified data platform (OpenSearch + Prometheus + Grafana correlation)
- [ ] Data quality dashboards
- **Phase:** 3b

### Capability 3: AI-Accessible Internal Data

- [x] AGENTS.md context files for AI agents
- [x] ARCHITECTURE.md component relationships
- [x] API_SURFACE.md public interfaces
- [x] KNOWN_LIMITATIONS.md known issues
- [x] CHANGE_IMPACT_MAP.md dependency analysis
- [ ] Wire docs into AI tool context windows (Copilot, OpenCode)
- **Phase:** 3e

### Capability 4: Strong Version Control

- [x] CI gates (lint, test, security scan)
- [x] Conventional commits
- [x] PR size limits (400 lines → CI blocks)
- [x] ArgoCD self-heal + automated sync
- [ ] Reduce PR size to 200 lines
- [ ] AI code review agent (shift feedback to author)
- **Phase:** 3e

### Capability 5: Working in Small Batches

- [x] PR size gate (400 lines)
- [x] Tracer bullet approach (one service at a time)
- [ ] Reduce PR size to 200 lines
- [ ] Enforce AI-generated changes to be chunked
- [ ] Add PR size warning at 150 lines
- **Phase:** 3e

### Capability 6: User-Centric Focus

- [x] Backstage software templates (Python, Java, Node.js)
- [x] Self-service template discovery
- [ ] User research (personas, interviews, journey maps)
- [ ] Feedback loops (widget, analytics, bot)
- [ ] DevEx metrics dashboard
- **Phase:** 3a, 3c

### Capability 7: Quality Internal Platforms

- [x] Golden Path templates
- [x] CI/CD pipelines (GitHub Actions)
- [x] ArgoCD GitOps deployment
- [x] Observability stack (OTEL + Prometheus + Grafana)
- [x] Security scanning (Trivy, Gitleaks, Bandit)
- [x] Sealed Secrets for secret management
- [ ] Multi-environment support (dev/staging/prod)
- [ ] BDD test coverage
- **Phase:** 5a, 5b

---

## DORA Metrics Fawkes Tracks

### Primary (DORA 5)

| Metric                | Instrumentation                | Status                    |
| --------------------- | ------------------------------ | ------------------------- |
| Deployment Frequency  | ArgoCD sync events             | ✅                        |
| Lead Time for Changes | Git commit → ArgoCD sync       | ✅                        |
| Change Failure Rate   | ArgoCD health + incidents      | ⚠️ Needs alertmanager     |
| Mean Time to Recovery | Incident → resolution          | ⚠️ Needs alertmanager     |
| Rework Rate           | PR labels (rework) / total PRs | ⚠️ Needs label convention |

### AI Amplification (NEW)

| Metric                      | Purpose                                | Status         |
| --------------------------- | -------------------------------------- | -------------- |
| AI Adoption Rate            | Track adoption curve                   | ❌ Not started |
| AI vs. Non-AI PR Size       | Detect Acceleration Whiplash           | ❌ Not started |
| AI vs. Non-AI Review Time   | Detect verification tax                | ❌ Not started |
| AI vs. Non-AI Incident Rate | Detect quality degradation             | ❌ Not started |
| PR Context Load             | Detect cognitive overload              | ❌ Not started |
| Work Restart Rate           | Detect "easy to start, hard to finish" | ❌ Not started |

---

## References

- [DORA Research Program](https://dora.dev/)
- [DORA Quick Check](https://dora.dev/quickcheck/) — self-assessment tool
- [DORA AI Capabilities Model](https://cloud.google.com/resources/content/2025-dora-ai-capabilities-model-report)
- [DORA ROI Report](https://cloud.google.com/resources/content/dora-roi-of-ai-assisted-software-development)
- [Faros AI Engineering Report 2026](https://www.faros.ai/research/ai-acceleration-whiplash)

---

**Last Updated:** 2026-06-08
**Owner:** Platform Team
**Status:** Active — core research base for Fawkes product direction
