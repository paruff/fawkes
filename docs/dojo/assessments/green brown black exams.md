# Fawkes Dojo Belt Assessments: Green, Brown & Black

---

## 🟢 Green Belt Assessment: Fawkes Deployment Engineer

**Duration**: 2.5 hours
**Passing Score**: 85% (34/40 questions)
**Format**: 40 multiple choice + 3 labs

### Written Exam Topics (40 Questions)

**Section A: GitOps with ArgoCD (10 questions)**

- ArgoCD architecture and components
- Application sync strategies
- Health checks and sync waves
- Multi-cluster management
- Rollback procedures

**Section B: Deployment Strategies (10 questions)**

- Blue-green deployments
- Canary releases
- Rolling updates
- Recreate strategy
- When to use each strategy

**Section C: Progressive Delivery (10 questions)**

- Feature flags and traffic splitting
- Flagger and automated rollouts
- A/B testing implementation
- Metrics-driven deployment
- Automated rollback triggers

**Section D: Incident Response (10 questions)**

- Incident detection and triage
- Rollback procedures
- Communication during incidents
- Postmortem best practices
- MTTR optimization

### Hands-On Labs (70 minutes)

**Lab 1: Implement GitOps Workflow (25 min)**

- Deploy application using ArgoCD
- Configure sync policies and health checks
- Implement multi-environment strategy
- Test automatic sync and rollback

**Lab 2: Canary Deployment (25 min)**

- Configure Flagger for automated canary
- Set up Prometheus metrics
- Define success criteria (error rate, latency)
- Observe automated promotion/rollback

**Lab 3: Incident Simulation (20 min)**

- Respond to simulated production incident
- Roll back deployment quickly
- Document incident timeline
- MTTR must be <5 minutes

### Grading

```
Written: 80 points
Labs:    60 points (20 each)
Total:   140 points
Pass:    119 points (85%)
```

---

## 🟤 Brown Belt Assessment: Fawkes SRE Practitioner

**Duration**: 3 hours
**Passing Score**: 85% (38/45 questions)
**Format**: 45 multiple choice + 4 labs

### Written Exam Topics (45 Questions)

**Section A: Observability (12 questions)**

- Metrics, logs, and traces (three pillars)
- Prometheus architecture and PromQL
- Distributed tracing with Jaeger/Tempo
- Log aggregation patterns
- Correlation between signals

**Section B: DORA Metrics (11 questions)**

- Automated metrics collection
- Dashboard design
- Interpreting trends and anomalies
- Improvement strategies
- Benchmarking against industry

**Section C: SLIs, SLOs & Error Budgets (11 questions)**

- Defining meaningful SLIs
- Setting realistic SLOs
- Error budget policy
- Burn rate calculations
- Balancing reliability and velocity

**Section D: Incident Management (11 questions)**

- On-call best practices
- Runbook creation
- Blameless postmortems
- Root cause analysis
- Learning from incidents

### Hands-On Labs (90 minutes)

**Lab 1: Complete Observability Stack (25 min)**

- Deploy Prometheus, Grafana, Loki, Tempo
- Instrument application with metrics, logs, traces
- Create dashboards showing golden signals
- Set up alerting rules

**Lab 2: DORA Metrics Dashboard (20 min)**

- Implement automated DORA metrics collection
- Build Grafana dashboard
- Calculate current performance level
- Identify improvement opportunities

**Lab 3: Define SLOs (20 min)**

- Choose appropriate SLIs for service
- Set SLO thresholds (e.g., 99.9% availability)
- Calculate error budget
- Create error budget policy

**Lab 4: Incident Response (25 min)**

- Respond to production incident
- Use observability tools to diagnose
- Execute remediation
- Write postmortem
- MTTR target: <30 minutes

### Grading

```
Written: 90 points (45 × 2)
Labs:    70 points (4 labs)
Total:   160 points
Pass:    136 points (85%)
```

---

## ⚫ Black Belt Assessment: Fawkes Platform Architect

**Duration**: 4 hours
**Passing Score**: 90% (45/50 questions + labs)
**Format**: 50 multiple choice + Architecture project + Code contribution + Mentorship

### Written Exam Topics (50 Questions)

**Section A: Platform as a Product (13 questions)**

- Product management for platforms
- User research methods
- NPS and adoption metrics
- Roadmap prioritization
- Stakeholder management

**Section B: Multi-Tenancy (12 questions)**

- Namespace isolation strategies
- Resource quotas and limits
- RBAC design
- Self-service onboarding
- Cost allocation

**Section C: Security & Zero Trust (13 questions)**

- Zero trust principles
- Workload identity
- mTLS and service mesh
- Policy-as-code (OPA)
- Supply chain security (SBOM, signing)

**Section D: Multi-Cloud (12 questions)**

- When multi-cloud makes sense
- Abstraction strategies
- Cost implications
- Disaster recovery
- Cloud-agnostic tools

### Practical Assessments

**Part 1: Architecture Design Challenge (90 min)**

You'll receive a scenario:

```
"Design an internal developer platform for a company with:
- 200 developers across 40 teams
- Mix of monoliths and microservices
- Compliance requirements (SOC2, GDPR)
- 3 environments (dev, staging, prod)
- Budget: $500k/year
- Must improve DORA metrics by 40%"
```

**Deliverables**:

1. **Architecture Diagram**: Complete system design
2. **Technology Choices**: Justify tool selection
3. **Security Model**: Zero trust implementation
4. **Multi-Tenancy Design**: Namespace strategy, quotas
5. **Observability Plan**: Metrics, logs, traces strategy
6. **Rollout Plan**: Phased adoption approach
7. **Success Metrics**: How you'll measure platform success

**Evaluation Criteria**:

- Technical soundness (30%)
- Security considerations (20%)
- Cost effectiveness (15%)
- Developer experience (20%)
- Implementation feasibility (15%)

**Part 2: Live Presentation (30 min)**

- Present architecture to review panel (3 senior engineers)
- Defend design decisions
- Answer technical questions
- Handle objections and alternatives

---

**Part 3: Implementation Challenge (60 min)**

Choose ONE:

**Option A: Multi-Tenant Platform**

- Configure namespaces for 3 teams
- Set resource quotas (CPU, memory, storage)
- Implement RBAC (admin, developer, viewer roles)
- Create self-service onboarding workflow
- Test isolation and quota enforcement

**Option B: Zero Trust Pipeline**

- Implement workload identity (OIDC)
- Configure image signing (Cosign)
- Set up policy enforcement (OPA Gatekeeper)
- Deploy with mTLS (Istio)
- Verify end-to-end security

**Option C: Multi-Cloud Deployment**

- Deploy same app to AWS and GCP
- Use Crossplane for cloud abstraction
- Configure Istio multi-cluster
- Test cross-cloud service communication
- Monitor unified observability

---

**Part 4: Code Contribution (Outside assessment time)**

Contribute to Fawkes codebase:

- Feature enhancement OR bug fix
- Minimum 200 lines of code
- Unit tests (80%+ coverage)
- Documentation
- Pull request with clear description
- Code review feedback addressed

**Evaluation**:

- Code quality (40%)
- Testing coverage (25%)
- Documentation (20%)
- Git hygiene (15%)

---

**Part 5: Mentorship (Ongoing)**

Mentor 2 White Belt learners:

- Guide through Modules 1-4
- Weekly 30-min sessions
- Answer questions and troubleshoot
- Document learner progress
- Provide constructive feedback

**Evaluation**:

- Mentee satisfaction survey
- Mentee completion rate
- Quality of guidance
- Communication effectiveness

### Grading

```
Written Exam:           100 points (50 × 2)
Architecture Design:    100 points
Live Presentation:      50 points
Implementation:         50 points
Code Contribution:      50 points
Mentorship:            50 points
────────────────────────────────────
Total:                 400 points

Passing Score: 360 points (90%)
```

**Note**: All components must be completed. Minimum scores required:

- Written: ≥85/100 (85%)
- Architecture: ≥80/100 (80%)
- Implementation: ≥40/50 (80%)
- Code Contribution: ≥40/50 (80%)
- Mentorship: ≥40/50 (80%)

---

## Black Belt Certification Requirements

Upon successful completion, candidates receive:

✅ **Fawkes Platform Architect** certification
✅ Digital credential with verification link
✅ Recognition on Fawkes contributors page
✅ Invitation to Platform Engineering Guild (senior community)
✅ Speaking opportunities at meetups/conferences

**Valid for**: 2 years (recertification required)

---

## Assessment Timeline

### Green Belt

```
Week 1: Complete Modules 9-12
Week 2: Practice labs, review materials
Week 3: Schedule and take assessment
```

### Brown Belt

```
Week 1-2: Complete Modules 13-16
Week 3: Practice labs, build dashboards
Week 4: Schedule and take assessment
```

### Black Belt

```
Week 1-2: Complete Modules 17-20
Week 3: Prepare architecture design
Week 4: Implementation practice
Week 5: Complete code contribution
Week 6: Schedule assessment
Week 7-10: Mentorship commitment (ongoing)
Week 11: Final assessment
```

---

## Support Resources

### Study Groups

- Weekly study sessions on Mattermost
- Peer review of practice projects
- Mock interviews for Black Belt

### Office Hours

- **Green Belt**: Tuesdays 2-3pm UTC
- **Brown Belt**: Wednesdays 3-4pm UTC
- **Black Belt**: Fridays 1-3pm UTC (by appointment)

### Practice Environments

```bash
# Launch practice labs
fawkes lab start --module [9-20] --practice-mode

# Review example solutions
fawkes examples show --belt [green|brown|black]

# Mock assessments
fawkes assessment mock --belt [green|brown|black]
```

---

## Frequently Asked Questions

**Q: Can I take assessments out of order?**
A: No. Must complete in sequence: White → Yellow → Green → Brown → Black

**Q: How long are certifications valid?**
A: White/Yellow/Green/Brown: No expiration. Black Belt: 2 years (recertification required)

**Q: What if I fail?**
A: Review score report, retake after waiting period (Green: 14 days, Brown: 21 days, Black: 30 days)

**Q: Can I get accommodations?**
A: Yes. Contact dojo-accessibility@fawkes.io for extended time, alternate formats, etc.

**Q: Are assessments proctored?**
A: Written exams: No. Labs: Auto-validated. Black Belt presentation: Yes (live panel)

**Q: What's the pass rate?**
A: White: 92%, Yellow: 85%, Green: 78%, Brown: 71%, Black: 45%

---

## Assessment Scheduling

```bash
# Check prerequisites
fawkes assessment check-eligibility --belt [green|brown|black]

# View available dates
fawkes assessment available-slots --belt [green|brown|black]

# Schedule
fawkes assessment schedule \
  --belt [green|brown|black] \
  --date "YYYY-MM-DD" \
  --time "HH:MM"

# For Black Belt, also schedule:
fawkes assessment schedule-presentation \
  --date "YYYY-MM-DD" \
  --panel-members 3
```

---

## Tips for Success

### Green Belt

- 🔄 Practice GitOps workflows daily
- 📊 Understand when to use each deployment strategy
- ⚡ Focus on fast rollback procedures
- 📝 Master incident documentation

### Brown Belt

- 📈 Build lots of dashboards
- 🔍 Practice with PromQL and log queries
- 📊 Calculate SLOs for real services
- 🚨 Simulate incidents for practice

### Black Belt

- 🎯 Study real platform architectures (Spotify, Netflix)
- 💬 Interview engineers about their needs
- 🏗️ Design end-to-end systems regularly
- 👥 Mentor others (great practice)
- 📚 Read platform engineering blogs/papers

---

**All Belt Assessments** | Fawkes Dojo | Version 1.0
_Your path to Platform Engineering mastery_ 🥋

---

## Quick Reference

| Belt      | Duration | Questions | Labs    | Passing | Focus Area    |
| --------- | -------- | --------- | ------- | ------- | ------------- |
| ⚪ White  | 2h       | 30        | 3       | 80%     | Fundamentals  |
| 🟡 Yellow | 2.5h     | 40        | 3       | 85%     | CI/CD         |
| 🟢 Green  | 2.5h     | 40        | 3       | 85%     | Deployment    |
| 🟤 Brown  | 3h       | 45        | 4       | 85%     | Observability |
| ⚫ Black  | 4h+      | 50        | Project | 90%     | Architecture  |

**Good luck on your journey to Platform Architect!** 🚀
