# Epic 1 Demo Video Resources

This directory contains comprehensive resources for creating a professional demo video walkthrough of the Fawkes Epic 1 (DORA 2023 Foundation) platform deliverables.

## 📹 Video Status

**Current Status**: 🎬 Ready for Recording

The recording script and checklist have been prepared. The video is ready to be recorded following the comprehensive guides below.

## 📚 Documentation Files

### 1. [Epic 1 Demo Video Script](epic-1-demo-video-script.md)
**Purpose**: Complete 30-minute recording script  
**Use When**: Recording the actual video  
**Contents**:
- Detailed segment-by-segment script with timestamps
- Technical setup requirements
- Platform access URLs and credentials
- Talking points and demonstrations for each component
- Post-recording checklist
- Video description templates
- Presenter tips and best practices

**Key Sections**:
- Introduction & Platform Overview (3 min)
- Developer Portal - Backstage (5 min)
- GitOps with ArgoCD (4 min)
- CI/CD with Jenkins (5 min)
- Security Scanning (3 min)
- Observability Stack (3 min)
- DORA Metrics Dashboard (5 min)
- Complete Workflow Demo (1.5 min)
- Closing & Next Steps (1 min)

### 2. [Epic 1 Demo Video Checklist](epic-1-demo-video-checklist.md)
**Purpose**: Quick reference for recording  
**Use When**: During setup and recording  
**Contents**:
- Pre-recording setup checklist (15 minutes)
- Segment-by-segment tracking
- Key commands reference
- Essential URLs list
- Key points to emphasize
- Time management guide
- Post-recording tasks
- Troubleshooting tips

### 3. [Epic 1 Demo Video](epic-1-demo-video.md)
**Purpose**: Video access and information  
**Use When**: Sharing the completed video  
**Contents**:
- Links to uploaded video (YouTube, GitHub, etc.)
- Video overview and timestamps
- Technical specifications
- Related documentation links
- Support information

## 🎯 Quick Start

### For Recording the Video

1. **Prepare Your Environment** (15 minutes)
   ```bash
   # Ensure all pods are running
   kubectl get pods -A | grep -E 'backstage|argocd|jenkins|grafana|devlake'
   
   # Verify all ingress routes
   kubectl get ingress -A
   
   # Check resource utilization
   kubectl top nodes
   ```

2. **Open the Script**
   - Open [epic-1-demo-video-script.md](epic-1-demo-video-script.md)
   - Review all segments and talking points
   - Prepare browser tabs for all services

3. **Use the Checklist**
   - Open [epic-1-demo-video-checklist.md](epic-1-demo-video-checklist.md)
   - Follow pre-recording setup
   - Check off items as you complete them

4. **Record the Video**
   - Follow the script segment by segment
   - Use the checklist to track progress
   - Aim for 30 minutes total duration

5. **Post-Production**
   - Edit using the post-recording checklist
   - Upload to chosen platform(s)
   - Update [epic-1-demo-video.md](epic-1-demo-video.md) with links

### For Viewing the Video

Once recorded, access the video at:
- [Epic 1 Demo Video](epic-1-demo-video.md) - Contains all access links

## 🎬 What the Demo Covers

The Epic 1 demo video provides a comprehensive walkthrough of:

### ✅ Complete Platform Functionality
- **Infrastructure**: 4-node Kubernetes cluster
- **Developer Portal**: Backstage with service catalog
- **GitOps**: ArgoCD for declarative deployments
- **CI/CD**: Jenkins with golden path pipelines
- **Security**: SonarQube, Trivy, Vault, Kyverno
- **Observability**: Prometheus, Grafana, OpenTelemetry
- **Registry**: Harbor with image scanning
- **Metrics**: Apache DevLake for DORA automation

### ✅ Golden Path Workflow
Complete developer journey from code to production:
1. Create service from Backstage template
2. Write code and open Pull Request
3. PR pipeline validates changes
4. Merge triggers full golden path pipeline
5. Security gates (SonarQube + Trivy)
6. Container image built and pushed
7. GitOps repository updated
8. ArgoCD deploys to Kubernetes
9. DORA metrics automatically recorded
10. Service monitored and observable

### ✅ DORA Metrics Dashboard
Real-time visibility into four key metrics:
- **Deployment Frequency**: How often we deploy
- **Lead Time for Changes**: Commit to production time
- **Change Failure Rate**: % of deployments causing issues
- **Mean Time to Restore**: Time to recover from failures

## 📋 Acceptance Criteria

From Issue #37: Create Epic 1 demo video walkthrough

- [x] **Script Created**: Comprehensive 30-minute script with all segments ✅
- [x] **Checklist Prepared**: Quick reference for recording ✅
- [ ] **Video Recorded**: 30-minute walkthrough captured ⏳
- [ ] **Platform Functionality**: Shows complete platform ⏳
- [ ] **Golden Path**: Demonstrates workflow ⏳
- [ ] **DORA Dashboard**: Shows all four metrics ⏳
- [ ] **Video Uploaded**: Available and accessible ⏳

**Current Status**: Documentation complete, ready for video recording.

## 🔗 Related Documentation

### Epic 1 Resources
- [Epic 1 Platform Operations Runbook](../runbooks/epic-1-platform-operations.md)
- [Epic 1 Architecture Diagrams](../runbooks/epic-1-architecture-diagrams.md)
- [Epic 1 Platform APIs](../reference/api/epic-1-platform-apis.md)

### User Guides
- [Getting Started Guide](../getting-started.md)
- [Golden Path Usage Guide](../golden-path-usage.md)
- [DORA Metrics Guide](../observability/dora-metrics-guide.md)

### Tutorials
- [Tutorial 1: Deploy Your First Service](1-deploy-first-service.md)
- [Tutorial 6: Measure DORA Metrics](6-measure-dora-metrics.md)

### Architecture
- [Architecture Overview](../architecture.md)
- [Implementation Handoff](../implementation-plan/fawkes-handoff-doc.md)

## 🛠️ Technical Requirements

### Recording Software
- **Screen Recording**: OBS Studio, Loom, QuickTime, or similar
- **Audio**: Good quality microphone
- **Video Format**: MP4 (H.264), 1920x1080, 30fps
- **Audio Format**: 44.1 kHz, stereo

### Platform Prerequisites
- All Epic 1 components deployed and healthy
- Sample applications deployed (for metrics data)
- Recent pipeline runs (for Jenkins history)
- DORA metrics populated (requires previous deployments)
- All services accessible via ingress

### Environment Setup
- Browser with tabs pre-opened to all services
- Terminal with appropriate font size (16-18pt)
- Clean desktop/background
- Recording area configured (full screen or window)

## 📞 Support

### Questions or Issues?

- **Issue Tracker**: https://github.com/paruff/fawkes/issues
- **Related Issue**: paruff/fawkes#37
- **Dependencies**: paruff/fawkes#34 (BDD tests), paruff/fawkes#36 (Logging)

### Need Help Recording?

Check these resources:
- [Platform Operations Runbook](../runbooks/epic-1-platform-operations.md) - Troubleshooting
- [Getting Started Guide](../getting-started.md) - Platform setup
- [Troubleshooting Guide](../troubleshooting.md) - Common issues

## 📝 Notes

### Recording Tips
- **Practice First**: Do a dry run before recording
- **Check Audio**: Test microphone and eliminate background noise
- **Steady Pace**: Speak clearly, not too fast
- **Show, Don't Tell**: Click through interfaces, show actual data
- **Energy**: Stay enthusiastic throughout
- **Time Management**: Use chapter markers to stay on track

### What to Emphasize
- **Automation**: Everything is automated, not manual
- **Security**: Built-in security gates, not optional
- **Observability**: Full visibility into everything
- **Developer Experience**: Fast, easy, self-service
- **DORA Metrics**: Automatic, actionable insights
- **GitOps**: Single source of truth in Git

### Common Questions
Be prepared to address:
- How long to onboard a new service? → Minutes
- What if a deployment fails? → Auto-rollback
- How do we track improvement? → DORA trends
- Is this secure? → Multiple security layers
- Can we customize? → Yes, via shared libraries
- What about secrets? → Vault integration

---

**Version**: 1.0  
**Last Updated**: December 2024  
**Issue**: paruff/fawkes#37  
**Milestone**: 1.4 - DORA Metrics & Integration  
**Priority**: p1-high  
**Effort**: 3 hours
