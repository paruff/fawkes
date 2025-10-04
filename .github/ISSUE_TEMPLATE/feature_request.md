# .github/ISSUE_TEMPLATE/feature_request.yml
name: ✨ Feature Request
description: Suggest a new feature or enhancement for Fawkes
title: "[Feature]: "
labels: ["enhancement", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for suggesting a feature! Please provide details to help us understand your needs.

  - type: textarea
    id: problem
    attributes:
      label: Problem Statement
      description: Describe the problem this feature would solve. Is your feature request related to a problem?
      placeholder: "I'm frustrated when... It would be helpful if..."
    validations:
      required: true

  - type: textarea
    id: solution
    attributes:
      label: Proposed Solution
      description: Describe the solution you'd like to see
      placeholder: What would you like to happen?
    validations:
      required: true

  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives Considered
      description: Have you considered any alternative solutions or workarounds?
      placeholder: What other approaches did you think about?
    validations:
      required: false

  - type: dropdown
    id: component
    attributes:
      label: Component
      description: Which area of Fawkes would this feature affect?
      options:
        - Infrastructure/Terraform
        - Backstage Portal
        - CI/CD (Jenkins)
        - GitOps (ArgoCD)
        - Observability (Prometheus/Grafana)
        - Security Scanning
        - Dojo Learning Curriculum
        - DORA Metrics
        - Documentation
        - Other (specify in description)
    validations:
      required: true

  - type: dropdown
    id: priority
    attributes:
      label: Priority
      description: How important is this feature to you?
      options:
        - Critical - Blocking our adoption
        - High - Would significantly improve our experience
        - Medium - Nice to have
        - Low - Minor improvement
    validations:
      required: true

  - type: textarea
    id: use-case
    attributes:
      label: Use Case
      description: Describe your specific use case for this feature
      placeholder: |
        We need this feature because...
        Our team would use it to...
    validations:
      required: true

  - type: textarea
    id: acceptance
    attributes:
      label: Acceptance Criteria
      description: What would successful implementation look like?
      placeholder: |
        - [ ] Criterion 1
        - [ ] Criterion 2
        - [ ] Criterion 3
    validations:
      required: false

  - type: checkboxes
    id: contribution
    attributes:
      label: Contribution
      description: Are you willing to contribute to this feature?
      options:
        - label: I'm willing to implement this feature and submit a PR
        - label: I'm willing to help test this feature
        - label: I'm willing to contribute documentation

  - type: textarea
    id: additional
    attributes:
      label: Additional Context
      description: Add any other context, mockups, or examples
    validations:
      required: false

  - type: checkboxes
    id: terms
    attributes:
      label: Code of Conduct
      description: By submitting this issue, you agree to follow our Code of Conduct
      options:
        - label: I agree to follow the Fawkes Code of Conduct
          required: true