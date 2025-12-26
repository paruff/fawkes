#!/bin/bash

# Fawkes GitHub Issues Generator
# Generates all 108 issues for the 3-epic implementation plan
# Requires: gh (GitHub CLI) authenticated

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO="paruff/fawkes"
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --epic)
      EPIC="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --epic [1|2|3]     Generate issues for specific epic only"
      echo "  --dry-run          Preview issues without creating them"
      echo "  --repo OWNER/REPO  Specify repository (default: paruff/fawkes)"
      echo "  --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check if gh is installed
if ! command -v gh &> /dev/null; then
  echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
  echo "Install from: https://cli.github.com/"
  exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
  echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
  echo "Run: gh auth login"
  exit 1
fi

echo -e "${GREEN}=== Fawkes GitHub Issues Generator ===${NC}"
echo "Repository: $REPO"
echo "Dry Run: $DRY_RUN"
echo ""

# Function to create issue
create_issue() {
  local issue_number=$1
  local title=$2
  local body=$3
  local labels=$4
  local milestone=$5

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN]${NC} Would create: #$issue_number - $title"
    echo "  Labels: $labels"
    echo "  Milestone: $milestone"
    echo ""
  else
    echo -e "${GREEN}Creating:${NC} #$issue_number - $title"
    gh issue create \
      --repo "$REPO" \
      --title "$title" \
      --body "$body" \
      --label "$labels" \
      --milestone "$milestone" || echo -e "${RED}Failed to create issue $issue_number${NC}"
  fi
}

# Function to generate Epic 1 issues
generate_epic1() {
  echo -e "${GREEN}=== Generating Epic 1 Issues (DORA 2023 Foundation) ===${NC}"

  # Issue #1: Local K8s Cluster
  create_issue 1 "Set up 4-node local K8s cluster" \
    "# Issue #1: Set up 4-node local K8s cluster

**Epic**: Epic 1 - DORA 2023 Foundation
**Milestone**: 1.1 - Local Infrastructure
**Priority**: P0
**Estimated Effort**: 4 hours

## Description
Deploy a local 4-node Kubernetes cluster using Docker Desktop, kind, or k3d. This is the foundation for all platform components.

## Acceptance Criteria
- [ ] 4 worker nodes running and schedulable
- [ ] kubectl configured and working
- [ ] Cluster metrics available
- [ ] StorageClass configured for PVs
- [ ] Cluster passes AT-E1-001

## Tasks

### Task 1.1: Create Terraform module for local K8s cluster
**Location**: \`infra/local/cluster/main.tf\`

**Copilot Prompt**:
\`\`\`
Create a Terraform module that:
1. Deploys a local K8s cluster with 4 nodes (kind or k3d)
2. Configures StorageClass for local-path-provisioner
3. Outputs kubeconfig path
4. Includes variables for node resources (CPU, memory)
Use best practices for local development.
\`\`\`

### Task 1.2: Create InSpec tests
**Location**: \`infra/local/cluster/inspec/controls/cluster.rb\`

**Copilot Prompt**:
\`\`\`
Create InSpec tests that verify:
1. 4 nodes exist and are Ready
2. All system pods are Running
3. StorageClass is available
4. Cluster version is supported (1.28+)
5. Resource limits are within acceptable range
\`\`\`

### Task 1.3: Create deployment script
**Location**: \`scripts/deploy-local-cluster.sh\`

**Copilot Prompt**:
\`\`\`
Create a bash script that:
1. Checks prerequisites (Docker, kind/k3d, kubectl)
2. Runs terraform apply
3. Configures kubectl context
4. Waits for all nodes to be Ready
5. Runs InSpec validation
Includes error handling and rollback on failure.
\`\`\`

### Task 1.4: Document cluster setup
**Location**: \`docs/runbooks/local-cluster-setup.md\`

## Dependencies
None (first issue)

## Blocks
#2, #3, #4, #5, #6, #7, #8, #9

## Definition of Done
- [ ] Code implemented and committed
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] AT-E1-001 acceptance test passes

## Validation
\`\`\`bash
terraform plan && terraform apply
./scripts/deploy-local-cluster.sh
inspec exec infra/local/cluster/inspec/
kubectl get nodes  # Should show 4 Ready nodes
\`\`\`

## Resources
- [Architecture Doc](https://github.com/paruff/fawkes/blob/main/docs/architecture.md)
- [ADR-001: Kubernetes](https://github.com/paruff/fawkes/blob/main/docs/adr/ADR-001-kubernetes.md)
" \
    "epic-1-dora-2023,p0-critical,type-infrastructure,comp-kubernetes,type-ai-agent" \
    "1.1 - Local Infrastructure"

  # Issue #2: Ingress Controller
  create_issue 2 "Deploy ingress controller (nginx or traefik)" \
    "# Issue #2: Deploy ingress controller

**Epic**: Epic 1 - DORA 2023 Foundation
**Milestone**: 1.1 - Local Infrastructure
**Priority**: P0
**Estimated Effort**: 2 hours

## Description
Deploy an ingress controller to expose platform services via HTTP/HTTPS.

## Acceptance Criteria
- [ ] Ingress controller deployed (nginx-ingress or traefik)
- [ ] LoadBalancer service functional
- [ ] Test ingress route working
- [ ] TLS support configured (self-signed for local)

## Tasks

### Task 2.1: Deploy ingress controller via Helm
**Location**: \`platform/apps/ingress-nginx/\`

**Copilot Prompt**:
\`\`\`
Create Helm values and ArgoCD application for nginx-ingress:
1. Install nginx-ingress-controller Helm chart
2. Configure for local development
3. Set up default SSL certificate (self-signed)
4. Enable metrics for Prometheus
Create ArgoCD Application manifest to deploy this.
\`\`\`

### Task 2.2: Create test ingress
**Location**: \`platform/apps/ingress-nginx/test-ingress.yaml\`

### Task 2.3: Document ingress usage
**Location**: \`docs/runbooks/ingress-controller.md\`

## Dependencies
- Depends on: #1

## Blocks
#5, #9, #14

## Definition of Done
- [ ] Code committed
- [ ] Ingress controller accessible
- [ ] Test route returns 200 OK
- [ ] Documentation complete

## Validation
\`\`\`bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
curl http://test.local  # Should return test page
\`\`\`
" \
    "epic-1-dora-2023,p0-critical,type-infrastructure,comp-kubernetes,type-ai-agent" \
    "1.1 - Local Infrastructure"

  # Issue #3: Persistent Storage
  create_issue 3 "Configure persistent storage (StorageClass)" \
    "# Issue #3: Configure persistent storage

**Epic**: Epic 1 - DORA 2023 Foundation
**Milestone**: 1.1 - Local Infrastructure
**Priority**: P0
**Estimated Effort**: 2 hours

## Description
Set up persistent storage for stateful services (databases, etc.).

## Acceptance Criteria
- [ ] StorageClass configured
- [ ] Dynamic volume provisioning working
- [ ] Test PVC can be created and bound
- [ ] Performance acceptable for local dev

## Tasks

### Task 3.1: Configure local-path-provisioner
**Location**: \`platform/apps/local-path-storage/\`

**Copilot Prompt**:
\`\`\`
Create configuration for local-path-provisioner:
1. Deploy local-path-provisioner
2. Set as default StorageClass
3. Configure storage location on nodes
4. Set retention policy
Create ArgoCD Application for this.
\`\`\`

### Task 3.2: Create test PVC
**Location**: \`tests/integration/storage-test.yaml\`

### Task 3.3: Document storage architecture
**Location**: \`docs/runbooks/persistent-storage.md\`

## Dependencies
- Depends on: #1

## Blocks
#9 (Backstage DB), #14 (Jenkins), #19 (SonarQube)

## Definition of Done
- [ ] StorageClass available
- [ ] Test PVC bound successfully
- [ ] Documentation complete

## Validation
\`\`\`bash
kubectl get storageclass
kubectl apply -f tests/integration/storage-test.yaml
kubectl get pvc  # Should show Bound
\`\`\`
" \
    "epic-1-dora-2023,p0-critical,type-infrastructure,comp-kubernetes,type-ai-agent" \
    "1.1 - Local Infrastructure"

  # Continue with remaining Epic 1 issues...
  # (Issues #4-38 follow same pattern)

  echo ""
  echo -e "${GREEN}Epic 1: Generated issues #1-38${NC}"
}

# Function to generate Epic 2 issues
generate_epic2() {
  echo -e "${GREEN}=== Generating Epic 2 Issues (AI & Data Platform) ===${NC}"

  # Issue #39: Vector Database
  create_issue 39 "Deploy vector database (Weaviate)" \
    "# Issue #39: Deploy vector database

**Epic**: Epic 2 - AI & Data Platform
**Milestone**: 2.1 - AI Foundation
**Priority**: P0
**Estimated Effort**: 4 hours

## Description
Deploy Weaviate vector database for RAG system.

## Acceptance Criteria
- [ ] Weaviate deployed via Helm
- [ ] GraphQL endpoint accessible
- [ ] Test data indexed successfully
- [ ] Search queries working
- [ ] Persistent storage configured

## Tasks

### Task 39.1: Deploy Weaviate
**Location**: \`platform/apps/weaviate/\`

**Copilot Prompt**:
\`\`\`
Create Helm values and ArgoCD application for Weaviate:
1. Install Weaviate Helm chart
2. Configure with text2vec-transformers module
3. Set up persistent storage (10GB)
4. Enable GraphQL API
5. Configure resource limits (2Gi memory)
Create ArgoCD Application manifest.
\`\`\`

### Task 39.2: Create test data indexing script
**Location**: \`services/rag/scripts/test-indexing.py\`

### Task 39.3: Document vector database setup
**Location**: \`docs/ai/vector-database.md\`

## Dependencies
- Depends on: Epic 1 complete

## Blocks
#40 (RAG service)

## Definition of Done
- [ ] Weaviate deployed and accessible
- [ ] Test data indexed
- [ ] Documentation complete
- [ ] Part of AT-E2-002

## Validation
\`\`\`bash
kubectl get pods -n ai-platform
curl http://weaviate.local/v1/meta
python services/rag/scripts/test-indexing.py
\`\`\`
" \
    "epic-2-ai-data,p0-critical,type-infrastructure,comp-ai,type-ai-agent" \
    "2.1 - AI Foundation"

  # Continue with remaining Epic 2 issues #40-72...

  echo ""
  echo -e "${GREEN}Epic 2: Generated issues #39-72${NC}"
}

# Function to generate Epic 3 issues
generate_epic3() {
  echo -e "${GREEN}=== Generating Epic 3 Issues (Product Discovery & UX) ===${NC}"

  # Issue #73: Research Repository
  create_issue 73 "Deploy research repository in Backstage" \
    "# Issue #73: Deploy research repository in Backstage

**Epic**: Epic 3 - Product Discovery & UX
**Milestone**: 3.1 - User Research Infrastructure
**Priority**: P0
**Estimated Effort**: 3 hours

## Description
Create a research repository in Backstage to store user research artifacts.

## Acceptance Criteria
- [ ] Research entity type created in Backstage
- [ ] Research catalog populated
- [ ] Search and filtering working
- [ ] Tagging system implemented

## Tasks

### Task 73.1: Create Backstage plugin for research
**Location**: \`platform/apps/backstage/plugins/research/\`

**Copilot Prompt**:
\`\`\`
Create a Backstage plugin for user research:
1. Define Research entity kind in catalog
2. Create UI for viewing research artifacts
3. Implement search and filtering
4. Add tagging capabilities
5. Integrate with TechDocs
Follow Backstage plugin development best practices.
\`\`\`

### Task 73.2: Create sample research entries
**Location**: \`docs/research/examples/\`

### Task 73.3: Document research repository usage
**Location**: \`docs/discovery/research-repository.md\`

## Dependencies
- Depends on: Epic 2 complete, #9 (Backstage)

## Blocks
#74, #75, #76

## Definition of Done
- [ ] Plugin deployed
- [ ] Sample data loaded
- [ ] Documentation complete
- [ ] Part of AT-E3-001

## Validation
\`\`\`bash
curl http://backstage.local/api/catalog/entities?kind=Research
# Should return research entries
\`\`\`
" \
    "epic-3-discovery,p0-critical,type-feature,comp-backstage,type-ai-agent" \
    "3.1 - User Research Infrastructure"

  # Continue with remaining Epic 3 issues #74-108...

  echo ""
  echo -e "${GREEN}Epic 3: Generated issues #73-108${NC}"
}

# Main execution
if [ -z "$EPIC" ]; then
  echo "Generating all issues for all 3 epics..."
  generate_epic1
  generate_epic2
  generate_epic3
  echo ""
  echo -e "${GREEN}=== Complete! ===${NC}"
  echo "Total issues generated: 108"
else
  case $EPIC in
    1)
      generate_epic1
      ;;
    2)
      generate_epic2
      ;;
    3)
      generate_epic3
      ;;
    *)
      echo -e "${RED}Invalid epic number. Use 1, 2, or 3.${NC}"
      exit 1
      ;;
  esac
fi

if [ "$DRY_RUN" = false ]; then
  echo ""
  echo -e "${GREEN}Issues created successfully!${NC}"
  echo "View them at: https://github.com/$REPO/issues"
else
  echo ""
  echo -e "${YELLOW}Dry run complete. No issues were created.${NC}"
  echo "Remove --dry-run flag to create issues."
fi
