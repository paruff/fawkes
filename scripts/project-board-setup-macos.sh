#!/bin/bash

# Fawkes GitHub Projects Setup Script
# Creates project board with automation for 3-epic implementation
# Requires: gh (GitHub CLI) version 2.20+ with projects extension

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REPO="paruff/fawkes"
PROJECT_NAME="Fawkes MVP Implementation"
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --repo)
      REPO="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --repo OWNER/REPO  Specify repository (default: paruff/fawkes)"
      echo "  --dry-run          Preview without creating"
      echo "  --help             Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${GREEN}=== Fawkes GitHub Projects Setup ===${NC}"
echo "Repository: $REPO"
echo "Project: $PROJECT_NAME"
echo "Dry Run: $DRY_RUN"
echo ""

# Check prerequisites
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) not installed${NC}"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
    exit 1
fi

# Extract owner and repo
IFS='/' read -r OWNER REPO_NAME <<< "$REPO"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}=== DRY RUN MODE ===${NC}"
    echo "Would create project: $PROJECT_NAME"
    echo "Would create 18 milestones (6 per epic)"
    echo "Would create 45+ labels"
    echo "Would configure 6 columns with automation"
    echo "Would create 4 views (All Issues, By Epic, By Priority, Timeline)"
    exit 0
fi

# Step 1: Create Labels
echo -e "${BLUE}Step 1: Creating labels...${NC}"

create_label() {
    local name=$1
    local color=$2
    local description=$3

    gh label create "$name" \
        --repo "$REPO" \
        --color "$color" \
        --description "$description" \
        --force 2>/dev/null || true
}

# Epic labels
create_label "epic-1-dora-2023" "0E8A16" "Epic 1 - DORA 2023 Foundation"
create_label "epic-2-ai-data" "1D76DB" "Epic 2 - AI & Data Platform"
create_label "epic-3-discovery" "5319E7" "Epic 3 - Product Discovery & UX"

# Priority labels
create_label "p0-critical" "B60205" "Blocking, must be done"
create_label "p1-high" "D93F0B" "Important, should be done"
create_label "p2-medium" "FBCA04" "Nice to have"

# Type labels
create_label "type-infrastructure" "C5DEF5" "Infrastructure component"
create_label "type-feature" "84B6EB" "New feature"
create_label "type-documentation" "D4C5F9" "Documentation"
create_label "type-testing" "C2E0C6" "Testing"
create_label "type-ai-agent" "BFD4F2" "Optimized for Copilot agent"

# Status labels
create_label "status-blocked" "E99695" "Blocked by dependencies"
create_label "status-ready" "0E8A16" "Ready for development"
create_label "status-testing" "FEF2C0" "In testing phase"
create_label "acceptance-test" "C5DEF5" "Acceptance test validation"

# Component labels
create_label "comp-backstage" "E1F5FE" "Backstage component"
create_label "comp-jenkins" "FFF9C4" "Jenkins component"
create_label "comp-argocd" "F3E5F5" "ArgoCD component"
create_label "comp-kubernetes" "E8F5E9" "Kubernetes component"
create_label "comp-ai" "E0F2F1" "AI component"
create_label "comp-data" "FFF3E0" "Data platform component"
create_label "comp-observability" "FCE4EC" "Observability component"

echo -e "${GREEN}✓ Labels created${NC}"

# Step 2: Create Milestones
echo -e "${BLUE}Step 2: Creating milestones...${NC}"

create_milestone() {
    local title=$1
    local description=$2
    local due_date=$3

    gh api repos/"$REPO"/milestones \
        -X POST \
        -f title="$title" \
        -f description="$description" \
        -f due_on="$due_date" 2>/dev/null || true
}

# Calculate due dates (4 weeks per epic) - macOS/BSD compatible
if date --version >/dev/null 2>&1; then
    # GNU date (Linux)
    calc_date() { date -u -d "$1" +"%Y-%m-%dT23:59:59Z"; }
else
    # BSD date (macOS)
    calc_date() { date -u -v "$1" +"%Y-%m-%dT23:59:59Z"; }
fi

# Epic 1 milestones
create_milestone "1.1 - Local Infrastructure" "Week 1: K8s cluster, ArgoCD, Git structure" "$(calc_date '+1w')"
create_milestone "1.2 - Developer Portal & CI/CD" "Week 2: Backstage, Jenkins, Harbor" "$(calc_date '+2w')"
create_milestone "1.3 - Security & Observability" "Week 3: SonarQube, Prometheus, Grafana" "$(calc_date '+3w')"
create_milestone "1.4 - DORA Metrics & Integration" "Week 4: DORA service, E2E testing, docs" "$(calc_date '+4w')"

# Epic 2 milestones
create_milestone "2.1 - AI Foundation" "Week 5: Vector DB, RAG, AI assistant" "$(calc_date '+5w')"
create_milestone "2.2 - Data Platform" "Week 6: DataHub, Great Expectations" "$(calc_date '+6w')"
create_milestone "2.3 - VSM & APIs" "Week 7: Value stream mapping, GraphQL API" "$(calc_date '+7w')"
create_milestone "2.4 - AI-Enhanced Operations" "Week 8: AI code review, anomaly detection" "$(calc_date '+8w')"

# Epic 3 milestones
create_milestone "3.1 - User Research Infrastructure" "Week 9: Research tools, DevEx metrics" "$(calc_date '+9w')"
create_milestone "3.2 - Feedback & Design" "Week 10: Feedback systems, design system" "$(calc_date '+10w')"
create_milestone "3.3 - Analytics & Experimentation" "Week 11: Analytics, feature flags" "$(calc_date '+11w')"
create_milestone "3.4 - Process & Integration" "Week 12: Discovery workflow, final testing" "$(calc_date '+12w')"

echo -e "${GREEN}✓ Milestones created${NC}"

# Step 3: Create Project (v2)
echo -e "${BLUE}Step 3: Creating project board...${NC}"

PROJECT_ID=$(gh project create \
    --owner "$OWNER" \
    --title "$PROJECT_NAME" \
    --format json | jq -r '.id')

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Failed to create project${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Project created (ID: $PROJECT_ID)${NC}"

# Step 4: Link project to repository
echo -e "${BLUE}Step 4: Linking project to repository...${NC}"

gh project link "$PROJECT_ID" --repo "$REPO" 2>/dev/null || true

echo -e "${GREEN}✓ Project linked to repository${NC}"

# Step 5: Create custom fields
echo -e "${BLUE}Step 5: Creating custom fields...${NC}"

# Epic field (single select)
gh project field-create "$PROJECT_ID" \
    --name "Epic" \
    --data-type "SINGLE_SELECT" \
    --single-select-options "Epic 1,Epic 2,Epic 3" 2>/dev/null || true

# Acceptance Test field
gh project field-create "$PROJECT_ID" \
    --name "Acceptance Test" \
    --data-type "TEXT" 2>/dev/null || true

# Estimated Effort field
gh project field-create "$PROJECT_ID" \
    --name "Estimated Effort (hours)" \
    --data-type "NUMBER" 2>/dev/null || true

echo -e "${GREEN}✓ Custom fields created${NC}"

# Step 6: Create views
echo -e "${BLUE}Step 6: Creating views...${NC}"

# Note: GitHub Projects v2 API for views is limited via CLI
# Views must be created manually or via GraphQL API
echo -e "${YELLOW}Note: Views must be configured manually in GitHub UI:${NC}"
echo "  1. All Issues (Table view)"
echo "  2. By Epic (Board view, group by Epic)"
echo "  3. By Priority (Table view, sort by Priority)"
echo "  4. Timeline (Roadmap view, group by Milestone)"
echo ""
echo "Configure these at: https://github.com/users/$OWNER/projects/$PROJECT_ID"

# Step 7: Create automation workflows
echo -e "${BLUE}Step 7: Setting up automation...${NC}"

# Create .github/workflows/project-automation.yml
mkdir -p .github/workflows

cat > .github/workflows/project-automation.yml << 'EOF'
name: Project Board Automation

on:
  issues:
    types: [opened, assigned, closed, labeled]
  pull_request:
    types: [opened, closed, review_requested]

jobs:
  update-project:
    runs-on: ubuntu-latest
    steps:
      - name: Move to Ready when labeled
        if: github.event.action == 'labeled' && github.event.label.name == 'status-ready'
        uses: actions/add-to-project@v0.5.0
        with:
          project-url: https://github.com/users/${{ github.repository_owner }}/projects/1
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Move to In Progress when assigned
        if: github.event.action == 'assigned'
        uses: actions/add-to-project@v0.5.0
        with:
          project-url: https://github.com/users/${{ github.repository_owner }}/projects/1
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Move to Done when closed
        if: github.event.action == 'closed'
        uses: actions/add-to-project@v0.5.0
        with:
          project-url: https://github.com/users/${{ github.repository_owner }}/projects/1
          github-token: ${{ secrets.GITHUB_TOKEN }}

  run-acceptance-tests:
    runs-on: ubuntu-latest
    if: github.event.label.name == 'acceptance-test'
    steps:
      - uses: actions/checkout@v4

      - name: Run acceptance tests
        run: |
          # Determine which tests to run based on epic
          if [[ "${{ github.event.issue.labels }}" == *"epic-1"* ]]; then
            ./tests/run-epic1-acceptance-tests.sh
          elif [[ "${{ github.event.issue.labels }}" == *"epic-2"* ]]; then
            ./tests/run-epic2-acceptance-tests.sh
          elif [[ "${{ github.event.issue.labels }}" == *"epic-3"* ]]; then
            ./tests/run-epic3-acceptance-tests.sh
          fi

      - name: Comment test results
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '## Acceptance Test Results\n\nTest run completed. Check logs for details.'
            })
EOF

git add .github/workflows/project-automation.yml 2>/dev/null || true

echo -e "${GREEN}✓ Automation workflow created${NC}"

# Final summary
echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo "Project URL: https://github.com/users/$OWNER/projects"
echo ""
echo "Next steps:"
echo "1. Configure project views manually in GitHub UI"
echo "2. Run ./generate-issues.sh to create all issues"
echo "3. Issues will auto-populate in the project board"
echo "4. Start working on Epic 1, Issue #1"
echo ""
echo "Quick commands:"
echo "  - View project: gh project view $PROJECT_ID"
echo "  - List issues: gh issue list --repo $REPO"
echo "  - Create first issue: ./generate-issues.sh --epic 1"
