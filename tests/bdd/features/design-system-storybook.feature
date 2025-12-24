Feature: Design System Storybook Deployment
  As a platform engineer
  I want to deploy Storybook for the design system
  So that developers can view and interact with UI components

  Background:
    Given the Kubernetes cluster is accessible
    And the fawkes namespace exists

  @local
  Scenario: Storybook is deployed and accessible
    Given the design-system-storybook deployment exists in the fawkes namespace
    When I check the deployment status
    Then the deployment should have at least 1 ready replica
    And the deployment should have the label "app=design-system-storybook"

  @local
  Scenario: Storybook service is configured correctly
    Given the design-system-storybook service exists in the fawkes namespace
    When I check the service configuration
    Then the service should expose port 80
    And the service should target port 6006
    And the service should have type "ClusterIP"

  @local
  Scenario: Storybook has all component stories
    Given the Storybook instance is running
    When I access the Storybook at "http://design-system.fawkes.local"
    Then the Storybook should include stories for all 42 components
    And the Design Tokens documentation should be available

  @local
  Scenario: Accessibility addon is enabled
    Given the Storybook instance is running
    When I check the Storybook configuration
    Then the accessibility addon should be enabled
    And the addon should be listed in the addons panel

  @local
  Scenario: Backstage integration is configured
    Given the Backstage catalog exists
    When I search for the design-system component
    Then the component should have a Storybook link
    And the link should point to "http://design-system.fawkes.local"

  @local
  Scenario: Ingress routes traffic to Storybook
    Given the design-system-storybook ingress exists in the fawkes namespace
    When I check the ingress configuration
    Then the ingress should route "design-system.fawkes.local" to the design-system-storybook service
    And the ingress should use TLS with the "design-system-tls" secret

  @local
  Scenario: Storybook container is healthy
    Given the design-system-storybook deployment is running
    When I check the pod health
    Then the liveness probe should pass
    And the readiness probe should pass
    And the container should be ready

  @dev @prod
  Scenario: Storybook is synced via ArgoCD
    Given ArgoCD is installed
    And the design-system application is defined
    When I check the ArgoCD application status
    Then the application should be "Healthy"
    And the application should be "Synced"
    And the sync policy should be "Automated"
