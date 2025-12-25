Feature: Deploy Backstage to Local Kubernetes
  As a platform engineer
  I want to deploy Backstage as the central Developer Portal
  So that product developers have a unified, authenticated interface to access self-service capabilities

  Background:
    Given I have Docker Desktop with Kubernetes enabled
    And I have kubectl configured for local cluster
    And I have the Backstage Helm chart available
    And the PostgreSQL Operator is installed and running

  @service-deployment @accessibility
  Scenario: Service Accessibility
    Given Backstage is deployed in the cluster
    And Ingress is configured for https://backstage.fawkes.idp
    When a user navigates to the Backstage URL
    Then the browser successfully loads the Backstage login page securely via HTTPS
    And the health check endpoint should return 200

  @authentication @sso @success
  Scenario: Authentication Success
    Given the Backstage app-config.yaml is configured with the platform's SSO/OAuth provider
    When a user successfully completes the SSO login flow
    Then the user is redirected to the main Backstage homepage
    And their identity is correctly displayed in the UI

  @authentication @sso @failure
  Scenario: Authentication Failure Redirect
    Given an unauthenticated user attempts to access a protected internal route
    When the user attempts to bypass the login page
    Then the request is intercepted
    And the user is redirected back to the centralized SSO login page

  @database @service-functionality
  Scenario: Core Service Functionality
    Given Backstage is connected to its dedicated PostgreSQL database
    When the Platform Engineer views the core system readiness checks in the logs
    Then the Service Catalog backend service starts without error
    And the Software Templates backend service starts without error
    And both services are ready for configuration

  @deployment @ha
  Scenario: Deploy Backstage with High Availability configuration
    Given the db-backstage-dev PostgreSQL cluster is running
    When I deploy Backstage using Helm to namespace "fawkes"
    Then the Backstage pods should be running within 120 seconds
    And there should be 2 Backstage replicas for high availability
    And the pods should be spread across different nodes

  @persistence @database
  Scenario: Deploy Backstage with external PostgreSQL
    Given I have a PostgreSQL instance running via CloudNativePG
    And the database cluster is named "db-backstage-dev"
    When I deploy Backstage with external PostgreSQL configuration
    Then Backstage should connect to PostgreSQL successfully
    And the catalog should be queryable
    And the service catalog data should persist across pod restarts

  @ingress @tls
  Scenario: Secure Ingress Configuration
    Given Backstage is deployed with ingress enabled
    When I check the ingress configuration
    Then the ingress should have TLS enabled
    And the ingress should redirect HTTP to HTTPS
    And the ingress should use the nginx ingress class

  @monitoring @metrics
  Scenario: Prometheus Metrics Exposure
    Given Backstage is deployed and running
    When Prometheus scrapes the metrics endpoint
    Then the Backstage metrics should be collected successfully
    And they should be available for monitoring dashboards

  @resource-limits @stability
  Scenario: Resource Allocation and Stability
    Given Backstage is deployed
    When I check the deployment resource specifications
    Then the deployment must specify resource requests
    And the deployment must specify resource limits
    And the service should not impact other core platform services
