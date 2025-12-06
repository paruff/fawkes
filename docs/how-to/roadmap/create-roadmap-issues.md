# Creating Roadmap Issues in GitHub

This guide explains how to create the Fawkes roadmap epics, features, and stories as GitHub issues and add them to the Fawkes project backlog.

## Overview

The Fawkes roadmap consists of:
- **3 Epics** - Major strategic initiatives  
- **9 Features** - Specific capabilities grouped under epics
- **21 Stories** - Concrete, implementable work items
- **Total**: 33 issues with 84 story points

## Prerequisites

1. **GitHub CLI installed and authenticated**
   ```bash
   # Check if gh is installed
   gh --version
   
   # If not installed, install it
   # macOS: brew install gh
   # Linux: see https://github.com/cli/cli#installation
   
   # Authenticate
   gh auth login
   ```

2. **Repository access** - You need write access to `paruff/fawkes`

3. **Python 3.7+** - For running the automation script

## Quick Start

The fastest way to create all roadmap issues:

```bash
# 1. Preview what will be created
python scripts/create_roadmap_issues.py --dry-run

# 2. Create all issues
python scripts/create_roadmap_issues.py
```

## Detailed Instructions

### Step 1: Create Milestones (Optional but Recommended)

```bash
gh milestone create "DORA Foundations" --repo paruff/fawkes --description "Foundational DORA capabilities"
gh milestone create "AI & Value Stream" --repo paruff/fawkes --description "AI and VSM integration"
gh milestone create "Developer Experience" --repo paruff/fawkes --description "DX improvements"
```

### Step 2: Run Script in Dry-Run Mode

```bash
cd /home/runner/work/fawkes/fawkes
python scripts/create_roadmap_issues.py --dry-run
```

This previews all 33 issues without creating them.

### Step 3: Create Issues

```bash
python scripts/create_roadmap_issues.py
```

The script will:
- Ask for confirmation
- Create each issue with proper labels and milestones
- Display URLs for created issues
- Report any errors

### Step 4: Add to Project Board

#### Using GitHub UI (Recommended)
1. Go to https://github.com/paruff/fawkes/projects
2. Open the "Fawkes" project
3. Click "+ Add items"
4. Search: `is:issue is:open label:epic` → Select all → Add
5. Search: `is:issue is:open label:feature` → Select all → Add
6. Search: `is:issue is:open label:story` → Select all → Add

#### Using GitHub CLI
```bash
# Get project number
gh project list --owner paruff

# Add each issue (example)
gh project item-add PROJECT_NUMBER --owner paruff --url https://github.com/paruff/fawkes/issues/ISSUE_NUMBER
```

### Step 5: Create Parent-Child Links

Edit each epic to add a checklist of its features:
```markdown
## Features
- [ ] #11 Feature 1.1: Automated CI/CD Pipelines
- [ ] #12 Feature 1.2: Integrated Observability Tools
- [ ] #13 Feature 1.3: Continuous Testing Framework
```

Edit each feature to link its stories similarly.

## What Gets Created

### Epic 1: IDP - 2022 DORA Foundations
- Feature 1.1: Automated CI/CD Pipelines
  - Story: Single-command deployment to Staging (3 SP)
  - Story: Integrate automated security scanning (5 SP)
- Feature 1.2: Integrated Observability Tools
  - Story: Standardize logging across microservices (5 SP)
  - Story: Add DORA metrics dashboard (3 SP)
- Feature 1.3: Continuous Testing Framework
  - Story: Provide self-service load-test tool (5 SP)
  - Story: Standardize unit test coverage reporting (3 SP)

### Epic 2: DORA - 2025 AI/VSM Focus
- Feature 2.1: Value Stream Mapping (VSM) Tooling
  - Story: Visualize end-to-end flow in dashboard (5 SP)
  - Story: Collect cycle time data at handoff points (5 SP)
- Feature 2.2: Healthy Data Ecosystems
  - Story: Provide anonymized production event logs (8 SP)
  - Story: Implement data quality checks (5 SP)
- Feature 2.3: AI-Assisted Development Integration
  - Story: SSO for AI assistant (3 SP)
  - Story: Index internal KB for assistant (5 SP)
- Feature 2.4: User-Centric Focus Enablement
  - Story: Tag features with user problem (3 SP)
  - Story: Ingest user feedback into VSM (5 SP)

### Epic 3: Fawkes - Developer Experience (DX)
- Feature 3.1: Developer Self-Service Portal
  - Story: Provision microservice via portal (8 SP)
  - Story: Troubleshoot button linking to runbooks (3 SP)
- Feature 3.2: Discovery and Documentation
  - Story: Central service catalog (5 SP)
  - Story: Flag stale docs (3 SP)
- Feature 3.3: Design System Adoption
  - Story: Implement component library (8 SP)
  - Story: Run internal DX survey (2 SP)

## Troubleshooting

### "gh: command not found"
Install GitHub CLI: https://github.com/cli/cli#installation

### "Authentication required"
```bash
gh auth login
```

### "Resource not accessible"
Ensure you have write access to the repository and re-authenticate.

### Script shows incorrect issue numbers
The script creates new issues. Issue numbers will be assigned sequentially by GitHub.

## Manual Creation (Alternative)

If the script doesn't work, create issues manually:

1. Go to https://github.com/paruff/fawkes/issues/new/choose
2. Select appropriate template (epic/feature/story)
3. Fill in details from `docs/roadmap.md`
4. Apply labels and milestone
5. Submit

## After Creation

1. **Organize Project Board** - Create views by milestone, epic, priority
2. **Set Up Automation** - Auto-add issues, auto-move based on status
3. **Assign Owners** - Assign epics/features to team leads
4. **Refine Estimates** - Update story points based on team capacity
5. **Plan Sprints** - Move stories to sprint backlog

## Support

- **Documentation**: [Fawkes Roadmap](../../roadmap.md)
- **Community**: [Mattermost](https://fawkes-community.mattermost.com)
- **Issues**: https://github.com/paruff/fawkes/issues/new
