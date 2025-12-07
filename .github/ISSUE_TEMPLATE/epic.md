name: "EPIC: Concise Epic Name — Area/Team"
description: "Canonical Epic template for grouping features and stories. Use this to capture goals, scope, milestones, and instructions for Copilot agents."
title: "EPIC: {epic_short} — {area_or_team}"
labels:
  - epic
  - area:unknown
  - priority:medium
body:
  - type: markdown
    attributes:
      value: |
        ## Summary
        Provide a short, clear summary of the epic.

  - type: input
    id: epic_short
    attributes:
      label: Epic short name (used in title)
      description: A concise name for the epic (e.g. "Multi-cloud Provisioning")
      required: true
  - type: input
    id: area_or_team
    attributes:
      label: Area / Team
      description: Component or owning team (used in title)
      required: true
  - type: textarea
    id: goals
    attributes:
      label: Goals
      description: What business/technical goals does this epic achieve?
      required: true
  - type: textarea
    id: success_criteria
    attributes:
      label: Success Criteria / Metrics
      description: Measurable outcomes (SLOs, adoption, cost savings, etc.)
      required: true
  - type: textarea
    id: scope_in
    attributes:
      label: Scope (In-scope)
      description: What is included
      required: true
  - type: textarea
    id: scope_out
    attributes:
      label: Scope (Out-of-scope)
      description: What is explicitly NOT included
  - type: textarea
    id: milestones
    attributes:
      label: High-level Milestones
      description: Dates or checkpoints (optional)
  - type: textarea
    id: dependencies
    attributes:
      label: Dependencies
      description: Blocking dependencies, teams, or external services
  - type: textarea
    id: risks_mitigations
    attributes:
      label: Risks & Mitigations
      description: Top risks, mitigation actions, and owners
  - type: textarea
    id: acceptance_criteria
    attributes:
      label: Acceptance Criteria (high-level)
      description: High-level conditions for the epic to be Done (testable)
  - type: dropdown
    id: estimate
    attributes:
      label: Estimated Effort
      options:
        - Small
        - Medium
        - Large
        - Unknown
      description: Rough effort estimate
  - type: textarea
    id: copilot_notes
    attributes:
      label: Notes for Copilot agents
      description: >
        Explicit guidance for Copilot agents: how to split epic into features/stories,
        repo paths to check, branch naming conventions, PR naming, tests to add, and
        expected artifacts (manifests/terraform/helm). Example:
        - Break into features and create feature issues with label `feature`.
        - Look in infra/ terraform/ and apps/ directories.
        - Branch: epic/{epic_short}/<feature>-<task>.
        - PR title: "EPIC: {epic_short} — add <feature>".
      required: true
  - type: textarea
    id: examples
    attributes:
      label: Example titles & labels
      description: |
        Examples:
        - EPIC: Multi-cloud Provisioning — infra
        - EPIC: Observability Consolidation — platform
        Suggested labels: epic, priority:high, area:infra
  - type: markdown
    attributes:
      value: |
        ---
        Example acceptance criteria formatting:
        - [ ] All features implemented and linked
        - [ ] Terraform applied in staging
        - [ ] Load test results meet target
        ---
