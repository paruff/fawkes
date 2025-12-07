# .github/ISSUE_TEMPLATE/bug_report.yml
name: 🐛 Bug Report
description: Report a bug or unexpected behavior in Fawkes
title: "[Bug]: "
labels: ["bug", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to report a bug! Please fill out the form below to help us investigate.

  - type: textarea
    id: description
    attributes:
      label: Bug Description
      description: A clear and concise description of what the bug is
      placeholder: What happened?
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: Expected Behavior
      description: What did you expect to happen?
      placeholder: What should have happened?
    validations:
      required: true

  - type: textarea
    id: reproduction
    attributes:
      label: Steps to Reproduce
      description: Provide detailed steps to reproduce the bug
      placeholder: |
        1. Deploy Fawkes with command '...'
        2. Navigate to '...'
        3. Click on '...'
        4. See error
    validations:
      required: true

  - type: dropdown
    id: component
    attributes:
      label: Component
      description: Which Fawkes component is affected?
      options:
        - Infrastructure/Terraform
        - Backstage Portal
        - CI/CD (Jenkins)
        - GitOps (ArgoCD)
        - Observability (Prometheus/Grafana)
        - Security Scanning
        - Documentation
        - Other (specify in description)
    validations:
      required: true

  - type: input
    id: version
    attributes:
      label: Fawkes Version
      description: What version of Fawkes are you using?
      placeholder: "v0.1.0 or commit SHA"
    validations:
      required: true

  - type: dropdown
    id: cloud
    attributes:
      label: Cloud Provider
      description: Which cloud provider are you deploying to?
      options:
        - AWS
        - Azure
        - GCP
        - On-premises
        - Other
    validations:
      required: true

  - type: input
    id: k8s-version
    attributes:
      label: Kubernetes Version
      description: What version of Kubernetes are you running?
      placeholder: "1.28.0"
    validations:
      required: false

  - type: textarea
    id: environment
    attributes:
      label: Environment Details
      description: Provide additional environment information
      placeholder: |
        - OS: Ubuntu 22.04
        - Terraform Version: 1.6.0
        - kubectl Version: 1.28.0
        - Other relevant details
    validations:
      required: false

  - type: textarea
    id: logs
    attributes:
      label: Relevant Logs
      description: Include any relevant logs or error messages
      placeholder: Paste logs here (will be automatically formatted)
      render: shell
    validations:
      required: false

  - type: textarea
    id: screenshots
    attributes:
      label: Screenshots
      description: If applicable, add screenshots to help explain the problem
    validations:
      required: false

  - type: textarea
    id: additional
    attributes:
      label: Additional Context
      description: Add any other context about the problem here
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