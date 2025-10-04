# .github/ISSUE_TEMPLATE/documentation.yml
name: 📚 Documentation
description: Report missing, incorrect, or unclear documentation
title: "[Docs]: "
labels: ["documentation", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        Help us improve the Fawkes documentation!

  - type: dropdown
    id: doc-type
    attributes:
      label: Documentation Type
      description: What type of documentation needs attention?
      options:
        - Getting Started Guide
        - Installation Instructions
        - Configuration Guide
        - Architecture Documentation
        - API Reference
        - Tutorial
        - Troubleshooting Guide
        - Contributing Guide
        - Other
    validations:
      required: true

  - type: input
    id: doc-location
    attributes:
      label: Documentation Location
      description: Link to the documentation page or section
      placeholder: "https://github.com/paruff/fawkes/docs/..."
    validations:
      required: false

  - type: textarea
    id: issue
    attributes:
      label: Issue Description
      description: What's wrong, missing, or unclear about the documentation?
      placeholder: The documentation doesn't explain...
    validations:
      required: true

  - type: textarea
    id: suggestion
    attributes:
      label: Suggested Improvement
      description: How should the documentation be improved?
      placeholder: It would be clearer if...
    validations:
      required: false

  - type: checkboxes
    id: contribution
    attributes:
      label: Contribution
      description: Can you help fix this documentation issue?
      options:
        - label: I'm willing to submit a PR to fix this

  - type: checkboxes
    id: terms
    attributes:
      label: Code of Conduct
      description: By submitting this issue, you agree to follow our Code of Conduct
      options:
        - label: I agree to follow the Fawkes Code of Conduct
          required: true