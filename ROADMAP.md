# uFawkes Platform — Product Suite Roadmap

> **Owner**: @paruff | **Status**: Living document | **Updated**: 2026-06-11
> **Research Basis**: DORA 2025-2026, CNCF Platform Engineering, SPACE Framework

---

## 1. Vision & Strategy

**Mission**: Deliver platform engineering stacks that achieve DORA Elite performance in 60 seconds.

**North Star**: Teams using uFawkes stacks measurably improve their DORA metrics (deployment frequency, lead time for changes, change failure rate, time to restore service) within 30 days.

**Differentiation**: The only platform engineering suite that maps stacks → DORA AI Capabilities → measurable ROI, backed by objective research.

**Sustainability Model**: Open source core with GitHub Sponsors for members who derive value from the repos. No paywalled features in core stacks.

---

## 2. Research Foundation

### DORA 2025-2026 — Core Findings

| Finding | Source | uFawkes Implication |
|---------|--------|---------------------|
| **AI is an amplifier** — magnifies strengths AND dysfunctions | DORA 2025 State of AI-Assisted Software Development | Every stack must strengthen foundations (observability, pipelines, small batches) before adding AI features |
| **7 AI Capabilities** amplify AI benefits — clear AI stance, healthy data ecosystems, AI-accessible internal data, quality internal platform, user-centric focus, strong version control, working in small batches | DORA AI Capabilities Model 2025 | Map each stack to specific capabilities; stack combinations address all 7 |
| **AI Productivity Paradox** — individual output up 21%, PRs merged up 98%, but organizational delivery metrics flat | Faros.ai telemetry (10k devs) + DORA 2025 | Stacks must include delivery metrics (DORA), not just coding metrics |
| **ROI framework** — AI creates ROI when org converts local speed → stable delivery, reduced rework, better experiments, reinvested engineering capacity | DORA ROI of AI-Assisted Software Development 2026 | Each stack must demonstrate end-to-end flow improvement |
| **7 team archetypes** need different AI strategies | DORA 2025 | Offer stack profiles for different maturity levels |
| **VSM as force multiplier** — Value Stream Management ensures local gains translate to product outcomes | DORA 2025 + Honeycomb analysis | uFawkesDORA connects value streams to delivery metrics |

### CNCF Platform Engineering Research

| Finding | Source | uFawkes Implication |
|---------|--------|---------------------|
| **Platform engineering reduces cognitive load** — developers focus on business value, not infrastructure | CNCF Platforms White Paper (2023) | DevX stack abstracts infrastructure complexity via golden paths |
| **85% of orgs implementing IDPs** — market is maturing rapidly | Port 2025 State of Internal Developer Portals | Timing is right for open-source IDP stack |
| **Developer tool sprawl costs $1M/year** in lost productivity (7.4 tools avg, 75% lose 6-15 hrs/week) | Port 2025 | Composable stacks reduce tool sprawl — one stack, one concern |
| **78% of teams wait 1+ day for SRE/DevOps assistance** | Port 2025 | Self-service stacks eliminate ticket-ops bottleneck |
| **Only 34% use portals to drive engineering standards** | Port 2025 | uFawkesDevX enforces standards via templates + scorecards |
| **Hybrid platform approaches** emerging as dominant model for AI workloads | CNCF Technology Radar Q1 2026 | Composable stacks support hybrid AI platform patterns |
| **Platform maturity model** — 5 aspects × 4 levels (Ad-Hoc → Standardized → Optimized → Advanced) | CNCF Platform Engineering Maturity Model 2023-2025 | Stack profiles map to maturity levels |
| **Helm, Backstage, kro** are "Adopt" technologies | CNCF Technology Radar Q1 2026 | Align stack tech choices with CNCF recommendations |

### SPACE Framework — Developer Productivity

| Dimension | What It Measures | uFawkes Alignment |
|-----------|------------------|-------------------|
| **Satisfaction & Well-being** | Developer happiness, burnout, work-life balance | DevX stack reduces cognitive load; Obs stack provides actionable (not overwhelming) alerts |
| **Performance** | Code quality, reliability, user satisfaction | DORA stack measures delivery performance; Sec stack prevents rework |
| **Activity** | Commits, PRs, deployments (in context) | Pipe stack tracks deployment frequency; DORA stack contextualizes activity |
| **Communication & Collaboration** | Code reviews, knowledge sharing, documentation | DevX stack provides golden paths that encode team knowledge |
| **Efficiency & Flow** | Flow state time, context switching, blocked time | Composable stacks reduce context switching; self-service eliminates blocked time |

**Key insight from Microsoft Research (Brian Houck, STACK 2024)**: AI is reshaping traditional workflows — SPACE dimensions remain relevant but measurement must adapt. PR throughput is useful when viewed across all five dimensions, not in isolation.

---

## 3. Current State

### Repos (as of 2026-06-11)

| Repo | Status | Description | Topics | DORA AI Capability |
|------|--------|-------------|--------|-------------------|
| **fawkes** | ✅ Exists | Modular GitOps IDP — core platform | 6 topics | Quality internal platform |
| **uFawkesObs** | ✅ Fixed | Observability — Prometheus + Grafana + AI | 8 topics | Healthy data ecosystem, AI-accessible data |
| **uFawkesPipe** | ✅ Exists | CI/CD — Jenkins + Buildpacks + DevSecOps | 13 topics | Strong version control, working in small batches |
| **uFawkesAI** | ✅ Exists | Agent templates for golden paths | 10 topics | Clear AI stance, user-centric focus |
| **uFawkesDevX** | ✅ Fixed | Golden paths + developer experience | 7 topics | Quality internal platform, user-centric focus |
| **uFawkesDORA** | ✅ Created | DORA dashboards + VSM + metrics | 8 topics | All 7 capabilities measured |
| **uFawkesSec** | ✅ Created | Policy-as-code + guardrails + supply chain | 7 topics | Quality internal platform |
| **uFawkes.dev** | ✅ Live | Marketing site + learning hub | Set | Drives adoption |

### Marketing Site (uFawkes.dev)

- ✅ All stack pages link to real GitHub repos
- ✅ DORA AI Capabilities section uses correct 7 capabilities from research
- ✅ Research-backed positioning with citations
- ✅ "Roadmap" link in navigation
- ✅ Live badges on all stack pages
- ✅ Features, quick start, compose-with on all stack pages

---

## 4. Portfolio Map

| Repo | Description | Stars | DORA AI Capability | Research Alignment |
|------|-------------|-------|-------------------|-------------------|
| **fawkes** | Modular GitOps IDP — core platform | 1 | Quality internal platform | CNCF Platforms White Paper |
| **uFawkesObs** | Observability — Prometheus + Grafana + AI | 0 | Healthy data ecosystem, AI-accessible data | DORA AI Capabilities |
| **uFawkesPipe** | CI/CD — Jenkins + Buildpacks + DevSecOps | 0 | Strong version control, working in small batches | CNCF App Delivery, DORA |
| **uFawkesAI** | Agent templates for golden paths | 2 | Clear AI stance, user-centric focus | DORA AI Capabilities |
| **uFawkesDevX** | Golden paths + developer experience | 0 | Quality internal platform, user-centric focus | CNCF Platforms, SPACE |
| **uFawkesDORA** | DORA dashboards + VSM + metrics | 0 | All 7 capabilities measured | DORA metrics, VSM |
| **uFawkesSec** | Policy-as-code + guardrails + supply chain | 0 | Quality internal platform | CNCF Security, SLSA, SSDF |
| **uFawkes.dev** | Marketing site + learning hub | N/A | — | Drives adoption |

---

## 5. DORA AI Capabilities → Stack Mapping

| Capability | Primary Stack | Supporting Stacks | Measurable Outcome |
|------------|---------------|-------------------|-------------------|
| **Clear + communicated AI stance** | AI | All | AI policy doc in repo README |
| **Healthy data ecosystems** | Obs + DORA | Pipe | Data quality SLIs defined |
| **AI-accessible internal data** | Obs | DevX | Feature store / context API accessible |
| **Quality internal platform** | DevX | Pipe, Sec | Platform adoption rate >80% |
| **User-centric focus** | DevX | All | DX Core 4 satisfaction scores |
| **Strong version control** | Pipe | All | Trunk-based adoption %, branch lifetime |
| **Working in small batches** | Pipe | DORA | Batch size, deployment frequency |

---

## 6. Team Archetype → Stack Profile Mapping

| DORA Archetype | Recommended Stacks | Entry Point | Priority |
|----------------|-------------------|-------------|----------|
| **Harmonious High-Achievers** | All (composable) | DevX golden paths | Low — they're already winning |
| **Legacy Bottleneck** | Obs → Pipe → DORA | Observability first | High — biggest ROI opportunity |
| **AI Experimenters** | AI → Obs → DORA | Agent templates | Medium — need guardrails fast |
| **Platform Builders** | DevX → Pipe → Sec | IDP scaffolding | High — aligns with CNCF recommendations |
| **Security-First** | Sec → Pipe → Obs | Policy-as-code | Medium — regulated industries |
| **Metrics-Driven** | DORA → Obs → Pipe | Dashboard starter | Medium — need data to act |
| **Starting Out** | Obs (only) | 60-second Grafana | High — lowest barrier to entry |

---

## 7. Roadmap Phases

### Phase 0: Foundation (Now — 2 weeks)
**Goal**: Establish governance, create missing repos, align marketing site, GitOps standards

| # | Task | Owner | Repo | Status |
|---|------|-------|------|--------|
| 0.1 | Create `fawkes/ROADMAP.md` (this doc) | You | fawkes | ✅ Done |
| 0.2 | Create `uFawkesDORA` repo with description, topics, README | You | uFawkesDORA | ✅ Done (repo + topics) |
| 0.3 | Create `uFawkesSec` repo with description, topics, README | You | uFawkesSec | ✅ Done (repo + topics) |
| 0.4 | Fix uFawkesObs: add description, topics, README | You | uFawkesObs | ✅ Done (description + topics) |
| 0.5 | Fix uFawkesDevX: add description, topics, README | You | uFawkesDevX | ✅ Done (description + topics) |
| 0.6 | Add cross-repo links in all READMEs (↔ fawkes, ↔ uFawkes.dev) | You | All | ✅ Done (all 7 repos + fawkes) |
| 0.7 | Update uFawkes.dev stack pages to link real repos | You | uFawkes.dev | ✅ Done |
| 0.8 | Add "Roadmap" link to uFawkes.dev navigation | You | uFawkes.dev | ✅ Done |
| 0.9 | GitHub Sponsors setup | You | GitHub | ⬜ Pending |
| 0.10 | GitOps: Create `.gitops-templates/` in fawkes (pre-commit, CI, dependabot, CODEOWNERS, Makefile, configs) | You | fawkes | 🔄 In progress |
| 0.11 | GitOps: Initialize DORA, Sec, DevX with GitOps templates | You | DORA, Sec, DevX | ⬜ Not started |
| 0.12 | GitOps: Migrate Obs, Pipe, AI, .dev to GitOps standards | You | Obs, Pipe, AI, .dev | ⬜ Not started |
| 0.13 | GitOps: Apply branch protection Rulesets (all 8 repos) | You | All | ⬜ Not started |
| 0.14 | GitOps: Create opencode GitOps agent + update AGENTS.md | You | opencode config | ⬜ Not started |

**Acceptance criteria**: All 7 repos exist, documented, linked. All 8 repos have pre-commit, CI validation, dependabot, CODEOWNERS, branch protection.

### Phase 1: Stack Parity & DORA Integration (2—6 weeks)
**Goal**: Each stack runnable in 60s, DORA metrics integrated

| Stack | Deliverable | DORA Capability | Status |
|-------|-------------|-----------------|--------|
| **Obs** | Prometheus + Grafana + DORA dashboards pre-wired | Observability, Data ecosystem | In progress (ufawkesobs exists) |
| **Pipe** | Jenkins + Buildpacks + DORA metric emission | Small batches, Version control | In progress (uFawkesPipe exists) |
| **DORA** | Unified dashboard: 4 keys + AI capability maturity + VSM | All 7 capabilities measured | Repo created, ready for development |
| **Sec** | Policy-as-code (OPA/Rego), supply chain scanning | Quality platform, AI stance | Repo created, ready for development |
| **DevX** | Backstage-alternative templates, golden path scaffolding | User-centric, Internal platform | Repo created, ready for development |
| **AI** | Agent templates per team archetype (7 types from DORA) | All capabilities via agents | Model repo exists (uFawkesAI) |

**Acceptance criteria**: Each stack has `docker compose up` → running + DORA dashboards populated.

### Phase 2: Dojo Spin-out & Learning Platform (6—10 weeks)
**Goal**: Unbiased, evidence-based learning platform

| Decision | Recommendation | Rationale |
|----------|----------------|-----------|
| **Repo location** | New repo `uFawkesDojo` | Separates learning from platform; enables community contribution; unbiased positioning |
| **Content model** | Restructure around DORA AI Capabilities Model | Each module maps to a capability; aligns with research |
| **Assessment** | Add capability maturity assessments | Diagnostic for which stack/profile fits (maps to CNCF maturity levels) |
| **Monetization** | Free core, paid cohorts/certification | Sustainable via GitHub Sponsors |

**Acceptance criteria**: Dojo repo live, 3+ capability modules published, 100+ learners.

### Phase 3: Platform Engineering Research Integration (Ongoing)
**Goal**: Incorporate objective research beyond DORA

| Research Area | Sources | uFawkes Application | Review Cadence |
|---------------|---------|---------------------|----------------|
| **Internal Developer Platforms** | CNCF Platforms White Paper, IDP maturity model, Port reports | DevX stack patterns, golden path criteria | Quarterly |
| **Platform Maturity Models** | CNCF Platform Engineering Maturity Model (5 aspects × 4 levels) | Stack profile progression (starter → pro → enterprise) | Quarterly |
| **Developer Productivity** | SPACE Framework (Microsoft Research), DX Core 4 | DevX stack instrumentation, measurement guidance | Quarterly |
| **Security in Platform Engineering** | SLSA, SSDF, CNCF TAG Security, CNCF security best practices | Sec stack policy library, supply chain integrity | Quarterly |
| **AI in Platform Engineering** | DORA AI reports, METR, Stanford HAI, CNCF Technology Radar | AI stack templates, capability mapping | Quarterly |
| **AI Productivity Paradox** | Faros.ai telemetry (10k devs), DORA ROI framework | Ensure stacks measure outcomes, not just output | Quarterly |

**Acceptance criteria**: Research library cited in stack docs, quarterly research review completed.

---

## 8. Success Metrics (per Phase)

| Phase | Metric | Target | Status |
|-------|--------|--------|--------|
| **Phase 0** | All 7 repos exist | 7/7 repos with description, topics | ✅ Done |
| **Phase 0** | Cross-repo links | Every README links to fawkes + uFawkes.dev | ✅ Done |
| **Phase 1** | Stack operability | Each stack `docker compose up` → running in <60s | Not started |
| **Phase 1** | DORA dashboards | Each stack has at least 1 pre-configured DORA dashboard | Not started |
| **Phase 1** | DORA metric emission | Each stack emits deployment frequency, lead time, change failure rate, MTTR | Not started |
| **Phase 2** | Dojo modules | 3+ capability-based modules published | Not started |
| **Phase 2** | Learner adoption | 100+ registered learners | Not started |
| **Phase 3** | Research citations | Each stack README cites relevant research | Not started |
| **Phase 3** | Quarterly review | Research library updated quarterly | Not started |

---

## 9. Governance

- **Roadmap reviewed monthly** — update status, adjust priorities
- **ADRs for architectural decisions** — stored in `fawkes/docs/adr/`
- **Stack maintainers assigned per repo** — see individual READMEs
- **Community advisory board** — see `fawkes/CUSTOMER_ADVISORY_BOARD.md`
- **Open source with sponsorship** — GitHub Sponsors for members who derive value
- **Research objectivity** — all research citations must be from peer-reviewed or industry-standard sources (DORA, CNCF, Microsoft Research, ACM)

---

## 10. Impact on uFawkes.dev (Marketing Site)

| Current Item | Impact | Action | Status |
|--------------|--------|--------|--------|
| PR 4 Sprint 6 (Screenshots) | Blocked — needs real stack screenshots | Defer until Phase 1 stacks runnable | ⬜ Deferred |
| PR 5 (Agent infrastructure) | Align — agents should reference uFawkesAI patterns | Update AGENTS.md to reference uFawkesAI | ⬜ Pending |
| Stack page content | Update — replace "coming soon" with real stack descriptions | Sync after Phase 1 repos ready | ✅ Done |
| DORA AI Capabilities section | Enhance — deepen capability-to-stack mapping | Already done in Sprint 4, add research citations | ✅ Done |
| Learn guides | Restructure — align to Dojo spin-out capability modules | Coordinate with Phase 2 | ⬜ Pending |
| Navigation | Add — "Roadmap" link to fawkes/ROADMAP.md | Add to nav dropdown | ✅ Done |
| Blog | Add — research summaries, stack launch posts | Ongoing content marketing | ⬜ Pending |

---

## 11. Open Questions

1. **Backstage in DevX stack**: Adopt Backstage (CNCF "Adopt" status) or build lighter alternative? Backstage adds complexity but has ecosystem.
2. **uFawkesAI scope**: Agent templates only, or also agent runtime framework? Currently templates align with uFawkesPipe golden paths.
3. **Sec stack tooling**: OPA/Rego for policy-as-code, or Kyverno (CNCF sandbox)? Depends on Kubernetes integration depth.
4. **Dojo community model**: Discord, Slack, or GitHub Discussions? Needs to be accessible but not fragmented.

---

*Last updated: 2026-06-11*
*Review schedule: Monthly*
*Next review: 2026-07-11*
