# ============================================================================
# FILE: tests/bdd/features/feature-flags-unleash.feature
# PURPOSE: BDD acceptance tests for Unleash feature flags platform (AT-E3-006)
# TAGS: @epic-3, @at-e3-006, @feature-flags, @unleash, @openfeature
# ============================================================================
@epic-3 @at-e3-006 @feature-flags @unleash
Feature: Feature Flags Platform (Unleash) Deployment
  As a platform engineer
  I want Unleash deployed with OpenFeature support
  So that we can implement gradual rollouts, A/B testing, and kill switches

  Background:
    Given the Fawkes platform is deployed
    And the PostgreSQL operator is running
    And the database cluster "db-unleash-dev" exists

  @deployment @local
  Scenario: Unleash deployment is healthy
    Given Unleash is deployed in namespace "fawkes"
    When I check the Unleash deployment status
    Then the deployment "unleash" should have 2 ready replicas
    And all pods should be in "Running" state
    And all pods should pass readiness checks

  @database @local
  Scenario: Unleash can connect to PostgreSQL database
    Given Unleash pods are running
    When I check Unleash database connectivity
    Then Unleash should be connected to PostgreSQL cluster "db-unleash-dev"
    And the database should contain Unleash schema tables
    And database migrations should be complete

  @api @local
  Scenario: Unleash API is accessible
    Given Unleash is deployed and healthy
    When I access the Unleash API health endpoint
    Then the health check should return status "200"
    And the response should indicate "healthy" status
    And the API version should be exposed

  @ui @local
  Scenario: Unleash UI is accessible via ingress
    Given Unleash ingress is configured
    When I access "https://unleash.fawkes.idp"
    Then the Unleash UI should load successfully
    And TLS certificate should be valid
    And I should see the Unleash login page

  @feature-flags @local
  Scenario: Create and retrieve a feature flag
    Given I am authenticated to Unleash API with admin token
    When I create a new feature flag "test-feature-flag"
    And I enable the flag for "development" environment
    Then the flag should be created successfully
    And I should be able to retrieve the flag via API
    And the flag should show as "enabled" in development

  @rollout-strategies @local
  Scenario: Configure gradual rollout strategy
    Given a feature flag "gradual-rollout-test" exists
    When I configure a "gradual rollout" strategy at "25%"
    And I evaluate the flag for 100 random users
    Then approximately 25% of users should see the feature enabled
    And 75% of users should see the feature disabled
    And the distribution should be consistent across evaluations

  @openfeature @local
  Scenario: OpenFeature SDK integration with Unleash
    Given Unleash is deployed and accessible
    When I initialize OpenFeature SDK with Unleash provider
    And I set Unleash URL to "https://unleash.fawkes.idp/api"
    Then the OpenFeature provider should connect successfully
    And I should be able to evaluate feature flags via OpenFeature API
    And the SDK should return consistent results with Unleash API

  @monitoring @local
  Scenario: Unleash exposes Prometheus metrics
    Given Unleash is running
    When I access the Prometheus metrics endpoint
    Then metrics should be exposed at "/internal-backstage/prometheus"
    And I should see "unleash_feature_toggles_total" metric
    And I should see "unleash_client_requests_total" metric
    And ServiceMonitor should be configured for Prometheus scraping

  @security @local
  Scenario: Unleash API requires authentication
    Given Unleash API is accessible
    When I attempt to access "/api/admin/features" without authentication
    Then I should receive a "401 Unauthorized" response
    When I access the same endpoint with valid API token
    Then I should receive a "200 OK" response
    And I should get the list of features

  @resilience @local
  Scenario: Unleash survives pod restarts
    Given Unleash has 2 running replicas
    And a feature flag "persistence-test" exists
    When I delete one Unleash pod
    Then Kubernetes should recreate the pod automatically
    And the service should remain available during restart
    And the feature flag "persistence-test" should still exist
    And flag configurations should be preserved

  @resource-utilization @local
  Scenario: Unleash resource usage is within limits
    Given Unleash has been running for at least 5 minutes
    When I check Unleash pod resource usage
    Then CPU usage should be below 70% of requested resources
    And memory usage should be below 70% of requested resources
    And no pods should be in "OOMKilled" state

  @at-e3-006 @acceptance @local
  Scenario: AT-E3-006 Complete Acceptance Test
    Given all Unleash components are deployed
    And PostgreSQL database cluster is healthy
    And Unleash pods are running (2 replicas)
    And Unleash UI is accessible via ingress
    When I create a test feature flag via API
    And I configure a gradual rollout strategy
    And I test OpenFeature SDK integration
    And I verify Prometheus metrics are exposed
    Then all feature flag operations should succeed
    And resource utilization should be <70%
    And AT-E3-006 should pass
