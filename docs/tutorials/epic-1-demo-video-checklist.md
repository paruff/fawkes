---
title: Epic 1 Demo Video Recording Checklist
description: Quick reference checklist for recording the Epic 1 demo video
---

# Epic 1 Demo Video Recording Checklist

**Quick Reference for Video Recording**

## Pre-Recording Setup (15 minutes before)

### Technical Setup
- [ ] All K8s pods are running (`kubectl get pods -A`)
- [ ] Screen recording software ready (OBS/Loom/etc.)
- [ ] Audio equipment tested
- [ ] Browser prepared with tabs:
  - [ ] Backstage
  - [ ] ArgoCD
  - [ ] Jenkins
  - [ ] Grafana
  - [ ] Prometheus
  - [ ] SonarQube
  - [ ] Harbor
  - [ ] DevLake
  - [ ] Vault
- [ ] Terminal windows configured (large font, 16-18pt)
- [ ] Sample data exists (deployments, metrics, etc.)

### Verify Access URLs
```bash
# Quick health check
kubectl get ingress -A
kubectl get pods -A | grep -E 'backstage|argocd|jenkins|grafana|devlake'
```

- [ ] `https://backstage.127.0.0.1.nip.io` - ✅ Loading
- [ ] `https://argocd.127.0.0.1.nip.io` - ✅ Loading
- [ ] `https://jenkins.127.0.0.1.nip.io` - ✅ Loading
- [ ] `https://grafana.127.0.0.1.nip.io` - ✅ Loading
- [ ] `https://devlake.127.0.0.1.nip.io` - ✅ Loading

---

## Recording Segments (30 minutes total)

### ✅ Segment 1: Introduction (3 min)
- [ ] Opening statement
- [ ] Architecture overview
- [ ] Epic 1 key deliverables

### ✅ Segment 2: Backstage (5 min)
- [ ] Home page and navigation
- [ ] Service catalog tour
- [ ] Create new service from template
- [ ] TechDocs overview

### ✅ Segment 3: ArgoCD (4 min)
- [ ] Applications dashboard
- [ ] Application deep dive
- [ ] GitOps workflow explanation
- [ ] Rollback capabilities

### ✅ Segment 4: Jenkins (5 min)
- [ ] Dashboard overview
- [ ] Golden path pipeline stages
- [ ] Pipeline execution details
- [ ] PR validation pipeline

### ✅ Segment 5: Security (3 min)
- [ ] SonarQube dashboard and reports
- [ ] Harbor registry and container scanning
- [ ] Vault secrets management

### ✅ Segment 6: Observability (3 min)
- [ ] Prometheus metrics
- [ ] Grafana dashboards (2-3 examples)

### ✅ Segment 7: DORA Metrics (5 min)
- [ ] DevLake overview
- [ ] All 4 metrics explained
- [ ] Trend charts
- [ ] Team/project breakdowns

### ✅ Segment 8: Complete Workflow (1.5 min)
- [ ] End-to-end summary
- [ ] Resource utilization check

### ✅ Segment 9: Closing (1 min)
- [ ] Summary of deliverables
- [ ] Links to documentation
- [ ] Thank you and next steps

---

## Key Commands to Have Ready

```bash
# Quick health check
kubectl get pods -A | grep -E 'argocd|backstage|jenkins|prometheus|grafana'

# Resource utilization
kubectl top nodes

# Git status (if showing GitOps)
git --no-pager log --oneline -5

# Sample queries for Prometheus
# up
# container_cpu_usage_seconds_total
```

---

## Key URLs to Show

**Essential:**
- Backstage: `https://backstage.127.0.0.1.nip.io`
- ArgoCD: `https://argocd.127.0.0.1.nip.io`
- Jenkins: `https://jenkins.127.0.0.1.nip.io`
- Grafana: `https://grafana.127.0.0.1.nip.io`
- DevLake: `https://devlake.127.0.0.1.nip.io`

**Supporting:**
- SonarQube: `https://sonarqube.127.0.0.1.nip.io`
- Harbor: `https://harbor.127.0.0.1.nip.io`
- Prometheus: `https://prometheus.127.0.0.1.nip.io`
- Vault: `https://vault.127.0.0.1.nip.io`

---

## Key Points to Emphasize

### Throughout Demo
- ✅ **Automation** - Everything is automated
- ✅ **Security** - Built-in, not bolted on
- ✅ **Observability** - Full visibility
- ✅ **GitOps** - Single source of truth
- ✅ **DORA Metrics** - Automatic collection
- ✅ **Developer Experience** - Fast and easy
- ✅ **Resource Efficiency** - <70% utilization

### Golden Path Workflow
1. Create from Backstage template
2. PR pipeline (fast feedback)
3. Main pipeline (full gates)
4. Security scanning
5. GitOps deployment
6. DORA metrics recorded
7. Observable and monitored

### DORA Metrics
1. **Deployment Frequency** - Multiple per day (Elite)
2. **Lead Time** - Commit to production time
3. **Change Failure Rate** - % deployments causing issues
4. **MTTR** - Time to restore service

---

## Post-Recording Checklist

### Editing
- [ ] Trim mistakes and dead air
- [ ] Add title slide
- [ ] Add chapter markers
- [ ] Add text overlays for URLs
- [ ] Ensure audio quality
- [ ] Add closing slide with links
- [ ] Export 1080p

### Upload Options

**Option 1: YouTube**
- [ ] Upload video
- [ ] Title: "Fawkes IDP - Epic 1 Demo Walkthrough (DORA 2023 Foundation)"
- [ ] Add description (see full script)
- [ ] Add timestamps in description
- [ ] Enable captions
- [ ] Set visibility
- [ ] Get shareable link

**Option 2: GitHub Release**
- [ ] Create release (v1.0-epic1-demo)
- [ ] Upload video as asset
- [ ] Add release notes
- [ ] Link in README

**Option 3: Internal Platform**
- [ ] Upload to company platform
- [ ] Set permissions
- [ ] Get shareable link

### Documentation Updates
- [ ] Add link to README.md
- [ ] Add link to docs/index.md
- [ ] Add link to tutorials/index.md
- [ ] Update Epic 1 docs with video
- [ ] Add to Backstage TechDocs

---

## Troubleshooting

### If Something Doesn't Load
- Check pod status: `kubectl get pods -n <namespace>`
- Check logs: `kubectl logs -n <namespace> <pod>`
- Restart if needed: `kubectl rollout restart deployment/<name> -n <namespace>`

### If Demo Data is Missing
- Run sample deployments beforehand
- Trigger Jenkins pipelines to populate data
- Let platform run for a few hours to collect metrics

### If Recording Fails
- Have backup recordings of each segment
- Can record segments separately and edit together
- Practice the trickier parts beforehand

---

## Time Management

| Segment | Target | Running Total |
|---------|--------|---------------|
| Introduction | 3:00 | 3:00 |
| Backstage | 5:00 | 8:00 |
| ArgoCD | 4:00 | 12:00 |
| Jenkins | 5:00 | 17:00 |
| Security | 3:00 | 20:00 |
| Observability | 3:00 | 23:00 |
| DORA Metrics | 5:00 | 28:00 |
| Workflow | 1:30 | 29:30 |
| Closing | 0:30 | 30:00 |

**Buffer**: You have ~1 minute of buffer time. Use it for transitions.

---

## Emergency Contacts / Resources

- Full Script: `docs/tutorials/epic-1-demo-video-script.md`
- Architecture: `docs/architecture.md`
- Operations Runbook: `docs/runbooks/epic-1-platform-operations.md`
- GitHub: https://github.com/paruff/fawkes

---

**Version**: 1.0
**Related Issue**: paruff/fawkes#37
**Last Updated**: December 2024
