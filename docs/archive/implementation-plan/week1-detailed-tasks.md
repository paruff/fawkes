# Week 1 Detailed Tasks - Epic 1: Infrastructure & GitOps

**Epic**: Epic 1 - DORA 2023 Foundation
**Week**: 1 of 4
**Milestone**: 1.1 - Local Infrastructure & 1.2 - GitOps Foundation
**Duration**: 5 working days
**Goal**: Deploy local K8s cluster with ArgoCD managing platform

---

## 📅 Day-by-Day Breakdown

### Day 1: Local Kubernetes Cluster Setup

**Issues**: #1, #2, #3
**Estimated Time**: 6-8 hours
**Goal**: Functional 4-node local K8s cluster with ingress and storage

#### Morning (4 hours): Issue #1 - K8s Cluster

**Task 1.1: Create Terraform module** (90 min)

```bash
# Location: infra/local/cluster/

# Create directory structure
mkdir -p infra/local/cluster/{terraform,inspec/controls,scripts}

# File: infra/local/cluster/terraform/main.tf
```

**Copilot Prompt for main.tf**:

```
Create a Terraform configuration for deploying a local Kubernetes cluster using kind:

Requirements:
1. Create a kind cluster named "fawkes-local"
2. Configure 4 worker nodes
3. Each node: 4 CPU, 8GB memory
4. Enable ingress (extraPortMappings for ports 80, 443)
5. Configure local-path-provisioner as default StorageClass
6. Output the kubeconfig path

Include:
- variables.tf (cluster_name, node_count, resources_per_node)
- outputs.tf (kubeconfig_path, cluster_name, node_count)
- versions.tf (terraform >= 1.0, required providers)

Use kind_cluster resource from tehcyx/kind provider.
Add comments explaining each configuration block.
```

**Task 1.2: Create InSpec validation** (45 min)

```bash
# Location: infra/local/cluster/inspec/controls/cluster.rb
```

**Copilot Prompt**:

```
Create an InSpec test suite for validating Kubernetes cluster deployment:

Test cases:
1. Exactly 4 nodes exist in the cluster
2. All nodes have status "Ready"
3. All system pods in kube-system namespace are "Running"
4. A StorageClass named "local-path" exists and is marked as default
5. Kubernetes version is >= 1.28.0
6. No nodes have MemoryPressure or DiskPressure conditions

Use kubectl commands via command() InSpec resource.
Include descriptive test descriptions and impact levels.
```

**Task 1.3: Create deployment script** (90 min)

```bash
# Location: scripts/deploy-local-cluster.sh
```

**Copilot Prompt**:

```
Create a bash deployment script that:

1. Checks prerequisites:
   - Docker is installed and running
   - kind CLI is installed (>= 0.20.0)
   - kubectl is installed (>= 1.28.0)
   - terraform is installed (>= 1.0.0)
   - inspec is installed (>= 5.0.0)

2. Deployment steps:
   - cd to infra/local/cluster/terraform
   - Run terraform init
   - Run terraform plan
   - Run terraform apply -auto-approve
   - Export KUBECONFIG from terraform output
   - Wait for all nodes to be Ready (timeout 5 minutes)
   - Wait for all system pods Running (timeout 5 minutes)

3. Validation:
   - Run InSpec tests
   - Print cluster info (nodes, pods, storageclasses)

4. Error handling:
   - Trap errors and provide clear messages
   - Offer rollback option on failure
   - Log all output to logs/cluster-deployment.log

Use colors for output (green=success, red=error, yellow=warning).
Include functions for each major step.
```

**Task 1.4: Create documentation** (45 min)

```bash
# Location: docs/runbooks/local-cluster-setup.md
```

**Copilot Prompt**:

```
Create comprehensive documentation for local K8s cluster setup:

Sections:
1. Overview (what, why, architecture diagram in mermaid)
2. Prerequisites (system requirements, software versions)
3. Quick Start (5-minute getting started)
4. Detailed Setup (step-by-step with commands)
5. Verification (how to validate deployment)
6. Troubleshooting (common issues and solutions)
7. Cluster Management (start, stop, destroy, reset)
8. Advanced Configuration (resource tuning, multi-cluster)
9. References (links to kind docs, k8s docs)

Use clear language, code blocks with bash syntax highlighting.
Include expected output for verification commands.
Add troubleshooting for:
- Docker not running
- Insufficient resources
- Port conflicts
- StorageClass issues
```

**Validation Commands**:

```bash
# Test Terraform
cd infra/local/cluster/terraform
terraform init
terraform validate

# Test deployment script
chmod +x scripts/deploy-local-cluster.sh
./scripts/deploy-local-cluster.sh

# Verify cluster
kubectl get nodes
# Expected: 4 nodes, all Ready

kubectl get pods -A
# Expected: All Running

kubectl get storageclass
# Expected: local-path (default)

# Run InSpec tests
inspec exec infra/local/cluster/inspec/ -t k8s://

# Check resource usage
kubectl top nodes
# Expected: <50% CPU, <50% Memory
```

#### Afternoon (2-3 hours): Issues #2 & #3 - Ingress & Storage

**Task 2.1: Deploy nginx-ingress** (90 min)

```bash
# Location: platform/apps/ingress-nginx/
mkdir -p platform/apps/ingress-nginx
```

**Copilot Prompt**:

```
Create ArgoCD Application and Helm values for nginx-ingress-controller:

Files needed:
1. values.yaml - Helm values for ingress-nginx chart
   - Enable metrics for Prometheus
   - Configure for local development (NodePort)
   - Set resource limits (500m CPU, 512Mi memory)
   - Enable default SSL certificate

2. application.yaml - ArgoCD Application manifest
   - Name: ingress-nginx
   - Namespace: ingress-nginx (create if not exists)
   - Source: helm chart ingress-nginx/ingress-nginx
   - Sync policy: automated, self-heal
   - Sync options: CreateNamespace=true

3. test-ingress.yaml - Test ingress resource
   - Host: test.local
   - Path: /
   - Backend: test service (port 80)
   - Include TLS with self-signed cert

4. README.md - Setup and usage instructions
```

**Task 3.1: Configure persistent storage** (60 min)

```bash
# Location: platform/apps/local-path-storage/
```

**Copilot Prompt**:

```
Create configuration for local-path-provisioner:

Files:
1. application.yaml - ArgoCD Application
   - Deploy rancher/local-path-provisioner
   - Set as default StorageClass
   - Configure storage path: /opt/local-path-provisioner

2. test-pvc.yaml - Test PersistentVolumeClaim
   - Name: test-pvc
   - Size: 1Gi
   - AccessMode: ReadWriteOnce
   - StorageClass: local-path

3. test-pod.yaml - Pod that uses test-pvc
   - Mount PVC at /data
   - Run busybox
   - Create test file in /data

Include cleanup script to delete test resources.
```

**End of Day 1 Validation**:

```bash
# Cluster healthy
kubectl get nodes
kubectl get pods -A

# Ingress working
curl http://localhost:80
# Or: curl http://test.local (if configured in /etc/hosts)

# Storage working
kubectl apply -f platform/apps/local-path-storage/test-pvc.yaml
kubectl get pvc
# Should show: Bound

# Run acceptance test AT-E1-001
./tests/acceptance/run-test.sh AT-E1-001
```

---

### Day 2: ArgoCD Deployment & Git Structure

**Issues**: #5, #6, #7
**Estimated Time**: 6-8 hours
**Goal**: ArgoCD managing all platform components via GitOps

#### Morning (4 hours): Issue #5 - Deploy ArgoCD

**Task 5.1: Deploy ArgoCD** (90 min)

```bash
# Location: platform/apps/argocd/
```

**Copilot Prompt**:

```
Create ArgoCD deployment configuration:

1. install.yaml - ArgoCD installation manifest
   - Use official ArgoCD install manifest (v2.9+)
   - Namespace: argocd
   - High availability disabled (for local)
   - Ingress enabled

2. ingress.yaml - Ingress for ArgoCD UI
   - Host: argocd.local
   - HTTPS with self-signed cert
   - Backend: argocd-server:443

3. initial-admin-secret.yaml (optional)
   - Configure initial admin password
   - Store securely or document retrieval method

4. argocd-cm.yaml - ConfigMap for ArgoCD settings
   - Enable anonymous read access (for local dev)
   - Configure repository credentials
   - Set default app project

5. deploy.sh - Deployment script
   - Apply install.yaml
   - Wait for ArgoCD pods Ready
   - Get initial admin password
   - Configure argocd CLI
   - Login and change password
   - Print ArgoCD URL

Include README with:
- How to access UI
- How to login via CLI
- Initial configuration steps
```

**Task 5.2: Configure ArgoCD CLI** (30 min)

```bash
# Location: scripts/configure-argocd.sh
```

**Copilot Prompt**:

```
Create script to configure ArgoCD CLI:

1. Install argocd CLI if not present
2. Port-forward to argocd-server (8080:443)
3. Login with credentials
4. Add local cluster
5. Create app project "platform"
6. Set up repository credentials for GitHub
7. Verify configuration

Include error handling and validation steps.
```

**Validation**:

```bash
# Deploy ArgoCD
kubectl apply -f platform/apps/argocd/install.yaml
kubectl wait --for=condition=Ready pods -n argocd --all --timeout=300s

# Access UI
kubectl port-forward -n argocd svc/argocd-server 8080:443 &
# Open browser: https://localhost:8080

# CLI login
argocd login localhost:8080 --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Verify
argocd cluster list
argocd app list
```

#### Afternoon (3-4 hours): Issues #6 & #7 - Git Structure & App-of-Apps

**Task 6.1: Create Git repository structure** (90 min)

```bash
# Location: platform/apps/
```

**Copilot Prompt**:

```
Create comprehensive Git repository structure for platform components:

Directory structure:
platform/
├── apps/
│   ├── argocd/                 # ArgoCD itself
│   ├── ingress-nginx/          # Ingress controller
│   ├── local-path-storage/     # Storage provisioner
│   ├── backstage/              # Developer portal (future)
│   ├── jenkins/                # CI/CD (future)
│   ├── harbor/                 # Container registry (future)
│   ├── sonarqube/              # Code quality (future)
│   ├── prometheus/             # Monitoring (future)
│   ├── grafana/                # Dashboards (future)
│   └── dora-metrics/           # DORA service (future)
├── bootstrap/
│   ├── app-of-apps.yaml        # Root application
│   └── README.md               # Bootstrap instructions
└── README.md                   # Platform apps overview

Each app directory contains:
- application.yaml (ArgoCD Application manifest)
- values.yaml (Helm values if using Helm)
- kustomization.yaml (if using Kustomize)
- README.md (app-specific documentation)

Create placeholder directories for future apps.
Add .gitkeep files to maintain empty directories.
```

**Task 6.2: Create app templates** (60 min)

```bash
# Location: platform/templates/
```

**Copilot Prompt**:

```
Create reusable templates for ArgoCD Applications:

1. helm-app-template.yaml
   - Template for Helm-based apps
   - Variables: {APP_NAME}, {NAMESPACE}, {CHART_REPO}, {CHART_NAME}
   - Standard sync policy
   - Automated pruning and self-heal

2. kustomize-app-template.yaml
   - Template for Kustomize-based apps
   - Variables: {APP_NAME}, {NAMESPACE}, {PATH}

3. generate-app.sh
   - Script to generate application from template
   - Usage: ./generate-app.sh --name myapp --type helm --chart mychart

Include documentation on template usage.
```

**Task 7.1: Implement app-of-apps pattern** (90 min)

```bash
# Location: platform/bootstrap/
```

**Copilot Prompt**:

```
Create app-of-apps pattern for managing all platform applications:

1. app-of-apps.yaml - Root ArgoCD Application
   - Name: platform-bootstrap
   - Source: platform/apps/
   - Destination: Multiple namespaces
   - Sync wave: 0 (deploy first)
   - Automated sync with prune
   - Uses ApplicationSet for dynamic app discovery

2. applicationset.yaml - ApplicationSet for auto-discovery
   - Git directory generator
   - Path: platform/apps/*/application.yaml
   - Exclude certain directories (templates, common)
   - Preserve application order with sync waves

3. bootstrap.sh - Bootstrap script
   - Apply app-of-apps.yaml
   - Wait for sync
   - Verify all apps deployed
   - Print status

4. README.md - App-of-apps documentation
   - Explain the pattern
   - How to add new apps
   - Sync wave ordering
   - Troubleshooting

Include sync waves:
- Wave 0: Infrastructure (ArgoCD, ingress, storage)
- Wave 1: Platform services (Backstage, Jenkins)
- Wave 2: Observability (Prometheus, Grafana)
- Wave 3: Applications
```

**End of Day 2 Validation**:

```bash
# Apply app-of-apps
kubectl apply -f platform/bootstrap/app-of-apps.yaml

# Wait for sync
argocd app wait platform-bootstrap --timeout 300

# Verify all apps
argocd app list

# Check sync status
argocd app get platform-bootstrap

# Verify applications in cluster
kubectl get applications -n argocd

# Run acceptance test AT-E1-002
./tests/acceptance/run-test.sh AT-E1-002
```

---

### Day 3: Documentation & Validation

**Issue**: #8, plus documentation
**Estimated Time**: 6-8 hours
**Goal**: Complete documentation and validate Week 1 deliverables

#### Morning (4 hours): Documentation

**Task: Create comprehensive Week 1 documentation**

1. **Architecture Diagrams** (90 min)

```bash
# Location: docs/architecture/diagrams/
```

Create:

- infrastructure-overview.mermaid (C4 Context)
- kubernetes-cluster.mermaid (Nodes, pods, services)
- gitops-workflow.mermaid (Git → ArgoCD → K8s)
- network-topology.mermaid (Ingress, services, pods)

**Copilot Prompt**:

```
Create Mermaid diagrams for Fawkes architecture:

1. infrastructure-overview.mermaid
   - C4 Context diagram
   - Show: Developer, Git Repo, K8s Cluster, Platform Components
   - Relationships and data flows

2. kubernetes-cluster.mermaid
   - Show 4-node cluster
   - Control plane components
   - Worker node components
   - Storage and networking

3. gitops-workflow.mermaid
   - Sequence diagram
   - Developer commits → Git push → ArgoCD sync → K8s apply
   - Include rollback flow

4. network-topology.mermaid
   - Show ingress controller
   - Service mesh (if applicable)
   - Pod networking
   - External access points
```

2. **Runbook Updates** (90 min)

Update these runbooks:

- docs/runbooks/local-cluster-setup.md
- docs/runbooks/argocd-management.md (new)
- docs/runbooks/gitops-workflow.md (new)
- docs/runbooks/troubleshooting-week1.md (new)

3. **README Updates** (60 min)

Update:

- platform/apps/README.md
- infra/README.md
- Root README.md (add Week 1 status)

#### Afternoon (3-4 hours): Validation & Testing

**Task 8.1: Run all acceptance tests** (90 min)

```bash
# Run AT-E1-001
./tests/acceptance/run-test.sh AT-E1-001

# Run AT-E1-002
./tests/acceptance/run-test.sh AT-E1-002

# Generate test report
./tests/acceptance/generate-report.sh --week 1
```

**Task 8.2: Resource optimization** (60 min)

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Optimize if needed:
# - Reduce replica counts
# - Adjust resource requests/limits
# - Enable pod disruption budgets

# Document optimizations in:
# docs/optimization/week1-resource-tuning.md
```

**Task 8.3: Create demo video** (90 min)

Record screen capture demonstrating:

1. Cluster deployment (2 min)
2. ArgoCD UI tour (3 min)
3. Deploying an app via GitOps (5 min)
4. Viewing synced resources (2 min)
5. Rollback demonstration (3 min)

Upload to: docs/videos/week1-demo.mp4

**End of Day 3 Validation**:

```bash
# All tests passing
./tests/acceptance/run-all-week1.sh

# Documentation complete
find docs/ -name "*.md" | wc -l  # Should be increased

# Resource usage acceptable
kubectl top nodes  # All <70%

# Demo video created
test -f docs/videos/week1-demo.mp4
```

---

### Days 4-5: Buffer & Week 2 Prep

**Use for**:

- Catching up on any delayed tasks
- Fixing bugs discovered during testing
- Additional documentation
- Preparing for Week 2 (Backstage, Jenkins)
- Team review (if applicable)

---

## ✅ Week 1 Definition of Done

- [ ] Local 4-node K8s cluster deployed and healthy
- [ ] Ingress controller serving traffic
- [ ] Persistent storage working
- [ ] ArgoCD managing all platform components
- [ ] Git repository structure established
- [ ] App-of-apps pattern implemented
- [ ] AT-E1-001 acceptance test passing
- [ ] AT-E1-002 acceptance test passing
- [ ] All documentation complete
- [ ] Demo video created
- [ ] Resource usage <70% CPU/Memory
- [ ] Zero critical bugs outstanding

---

## 📊 Progress Tracking

Update daily in PROJECT_STATUS.md:

```markdown
### Week 1 Progress

**Day 1**: ✅ Cluster deployment complete

- Issue #1: ✅ Complete
- Issue #2: ✅ Complete
- Issue #3: ✅ Complete

**Day 2**: ✅ ArgoCD and GitOps complete

- Issue #5: ✅ Complete
- Issue #6: ✅ Complete
- Issue #7: ✅ Complete

**Day 3**: ✅ Documentation and validation

- Issue #8: ✅ Complete
- All Week 1 docs: ✅ Complete

**Days 4-5**: Buffer used for [describe what was done]

**Week 1 Status**: ✅ COMPLETE
```

---

## 🚀 Handoff to Week 2

Once Week 1 is complete, you're ready for:

**Week 2 Focus**: Developer Portal & CI/CD

- Issue #9: Deploy Backstage
- Issue #14: Deploy Jenkins
- Issue #17: Deploy Harbor

**Prerequisites Met**:

- ✅ K8s cluster operational
- ✅ GitOps workflow established
- ✅ Can deploy new apps via ArgoCD

**Start Week 2 with**:

```bash
# Begin Backstage deployment
argocd app create backstage \
  --repo https://github.com/paruff/fawkes \
  --path platform/apps/backstage \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace backstage \
  --sync-policy automated
```

---

## 🆘 Getting Help

If stuck on any task:

1. **Check docs**: Search docs/ for related content
2. **Review ADRs**: See why decisions were made
3. **Test commands**: Validation commands in each task
4. **New chat**: Start fresh chat with specific question
5. **GitHub search**: Look for similar issues/PRs

**Chat template**:

```
Working on Fawkes Epic 1, Week 1, Day X.

Current task: Issue #Y - [Title]
Problem: [Specific issue]
What I've tried: [Commands/approaches]
Error message: [If applicable]

Context: See Week 1 Detailed Tasks document.
```

---

**END OF WEEK 1 DETAILED TASKS**
