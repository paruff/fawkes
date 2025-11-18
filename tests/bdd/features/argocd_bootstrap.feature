@smoke @local @gitops
Feature: Argo CD GitOps Bootstrap
  As a platform engineer
  I want the ignite bootstrap to establish Argo CD and root Applications
  So that the platform reconciles desired state from Git immediately

  Background:
    Given the Kubernetes API is reachable
    And the Argo CD namespace "fawkes" exists

  Scenario: Root Applications are healthy after ignite
    When I list Argo CD Applications in namespace "fawkes"
    Then Application "fawkes-app" is Synced and Healthy
    And Application "fawkes-infra" is Synced and Healthy

  Scenario Outline: Specific Application health check
    When I list Argo CD Applications in namespace "fawkes"
    Then Application "<appName>" is Synced and Healthy

    Examples:
      | appName       |
      | fawkes-app    |
      | fawkes-infra  |
