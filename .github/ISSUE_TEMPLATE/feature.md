name: "FEATURE: Feature Short Name — Service/Component"
description: "Feature template for an implementable capability. Include design notes, files to change, tests, and Copilot instructions."
title: "FEATURE: {feature_short} — {component}"
labels:
  - feature
  - area:unknown
  - priority:medium
body:
  - type: markdown
    attributes:
      value: |
        ## Summary & Motivation

  - type: input
    id: feature_short
    attributes:
      label: Feature short name (used in title)
      required: true
  - type: input
    id: component
    attributes:
      label: Service / Component
      description: e.g. control-plane, provisioning, ui
      required: true
  - type: textarea
    id: background
    attributes:
      label: Background & Motivation
      description: Why do this? Who benefits?
      required: true
  - type: textarea
    id: goals_acceptance
    attributes:
      label: Goals & Acceptance Criteria (specific, testable)
      description: Use Gherkin where helpful. Example: Given..., When..., Then...
      required: true
  - type: textarea
    id: design_notes
    attributes:
      label: Design / Implementation Notes
      description: Preferred patterns, references to similar code in repo, constraints
  - type: textarea
    id: files_paths
    attributes:
      label: Files / Paths to modify
      description: Suggested file locations, infra manifests, modules to update
  - type: textarea
    id: infra_considerations
    attributes:
      label: Terraform / Kubernetes / Helm considerations
  - type: textarea
    id: testing_validation
    attributes:
      label: Testing & Validation steps
      description: Unit, integration, e2e steps and commands
  - type: textarea
    id: observability
    attributes:
      label: Observability requirements
      description: Metrics, logs, traces to add or update
  - type: textarea
    id: security
    attributes:
      label: Security considerations
  - type: dropdown
    id: estimate
    attributes:
      label: Estimate
      options:
        - 1d
        - 3d
        - 1w
        - 2w
        - Unknown
  - type: textarea
    id: copilot_notes
    attributes:
      label: Notes for Copilot agents
      description: >
        Example actionable instructions:
        - Create branch: feature/{feature_short}/{ticket}
        - Apply patches to files X, Y; add tests under tests/{component}/
        - Run CI jobs: ci/unit, ci/integration
        - Create PR with title: "FEATURE: {feature_short} — implement <subfeature>"
        - Add checklists and link story issues.
      required: true
  - type: markdown
    attributes:
      value: |
        ---
        Example labels to add: feature, priority:high, area:{component}
