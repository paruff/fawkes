name: "STORY: Short Story Title — Feature"
description: "Small, actionable, testable story template. Includes exact tasks for Copilot agents to implement."
title: "STORY: {story_short} — {feature}"
labels:
  - story
  - area:unknown
  - priority:medium
body:
  - type: input
    id: story_short
    attributes:
      label: Short story title (used in title)
      required: true
  - type: input
    id: feature
    attributes:
      label: Parent Feature
      description: The feature this story rolls up to
  - type: textarea
    id: summary
    attributes:
      label: Summary
      description: Short description of the deliverable
      required: true
  - type: textarea
    id: preconditions
    attributes:
      label: Preconditions
      description: Any required setup or assumptions
  - type: textarea
    id: steps
    attributes:
      label: Implementation steps (detailed)
      description: Step-by-step tasks to complete (be explicit)
      required: true
  - type: textarea
    id: acceptance_criteria
    attributes:
      label: Acceptance Criteria (clear, testable)
      required: true
  - type: textarea
    id: tests_to_add
    attributes:
      label: Unit / Integration / E2E tests to add
  - type: dropdown
    id: environment
    attributes:
      label: Environment to test in
      options:
        - local
        - dev
        - staging
        - production
  - type: dropdown
    id: estimate
    attributes:
      label: Estimate
      options:
        - 1h
        - 4h
        - 1d
        - 3d
  - type: textarea
    id: copilot_tasks
    attributes:
      label: Notes for Copilot agents (exact tasks)
      description: >
        Example:
        - Add file: apps/service/handlers/new_handler.py
        - Update: infra/terraform/module/main.tf
        - Add tests: tests/unit/test_new_handler.py
        - Create branch: story/{story_short}/{ticket}
        - PR title: "STORY: {story_short} — implement <task>"
      required: true
  - type: markdown
    attributes:
      value: |
        ---
        Example checklist:
        - [ ] Code added
        - [ ] Unit tests added and passing
        - [ ] Integration test in staging
        - [ ] PR created with checklist and linked to feature/epic
