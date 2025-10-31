Feature: Deploy Backstage to Local Kubernetes
  As a platform engineer
  I want to deploy Backstage locally
  So that I can validate configuration before GitOps sync

  Background:
    Given I have Docker Desktop with Kubernetes enabled
    And I have kubectl configured for local cluster
    And I have the Backstage Helm chart available

  Scenario: Deploy Backstage with default configuration
    When I deploy Backstage using Helm to namespace "backstage-local"
    Then the Backstage pods should be running within 120 seconds
    And the Backstage service should be accessible at "http://localhost:7007"
    And the health check endpoint should return 200

  Scenario: Deploy Backstage with custom PostgreSQL
    Given I have a PostgreSQL instance running locally
    When I deploy Backstage with external PostgreSQL configuration
    Then Backstage should connect to PostgreSQL successfully
    And the catalog should be queryable