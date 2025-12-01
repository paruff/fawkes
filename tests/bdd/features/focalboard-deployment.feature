# tests/bdd/features/focalboard-deployment.feature

@focalboard @project-management @collaboration
Feature: Focalboard Project Management Deployment
  As a platform engineer
  I want to deploy and integrate Focalboard as a centralized project management service
  So that the team can achieve full transparency on all ongoing features, incidents, and stories

  Background:
    Given I have kubectl configured for the cluster
    And the PostgreSQL Operator is installed and running
    And the Focalboard PostgreSQL database cluster is deployed

  @service-deployment @access
  Scenario: Service Deployment & Access
    Given the platform is healthy
    When the Focalboard deployment is applied
    Then the service must be accessible via the platform URL
    And the service must return a successful HTTP 200 status

  @persistence @data
  Scenario: Data Persistence
    Given Focalboard is deployed and running
    And a board has been created with 10 cards
    When the Focalboard Kubernetes deployment is deleted and redeployed
    Then all 10 cards and the original board structure must be retrieved successfully
    And the data must persist in the PostgreSQL backend

  @authentication @sso
  Scenario: Authentication Integration
    Given a user is an authenticated platform user
    When they access the Focalboard URL
    Then they must be able to log in successfully
    And they should not need a separate set of credentials

  @board-functionality @kanban
  Scenario: Core Board Functionality
    Given an authenticated user is on the main board
    When they attempt to create a new card
    And move the card between columns
    And assign a priority to the card
    Then all actions must be successful
    And the changes must be immediately visible to other authenticated users

  @team-onboarding @templates
  Scenario: Team Onboarding with Default Board Template
    Given the service is deployed and accessible
    When a Platform Team Member accesses the service for the first time
    Then they must find a default board template
    And the template must have columns representing the Platform's defined workflow
    And the columns should include Backlog, To Do, In Progress, Review, and Done

  @resource-limits @stability
  Scenario: Resource Allocation and Stability
    Given Focalboard is deployed
    When I check the deployment resource specifications
    Then the deployment must specify resource requests
    And the deployment must specify resource limits
    And the service should not impact other core platform services

  @monitoring @metrics
  Scenario: Prometheus Metrics Exposure
    Given Focalboard is deployed and running
    When Prometheus scrapes the metrics endpoint
    Then the Focalboard metrics should be collected successfully
    And they should be available in the Grafana dashboards
