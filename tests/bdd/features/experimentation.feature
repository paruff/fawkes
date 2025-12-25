# ============================================================================
# FILE: tests/bdd/features/experimentation.feature
# PURPOSE: BDD acceptance tests for Experimentation Framework (AT-E3-012)
# TAGS: @epic-3, @at-e3-012, @experimentation, @ab-testing
# ============================================================================
@epic-3 @at-e3-012 @experimentation @ab-testing
Feature: Experimentation Framework Deployment
  As a product manager
  I want an A/B testing framework with statistical analysis
  So that I can run data-driven experiments and optimize features

  Background:
    Given the Fawkes platform is deployed
    And the PostgreSQL operator is running
    And the database cluster "db-experiment-dev" exists

  @deployment @local
  Scenario: Experimentation service deployment is healthy
    Given Experimentation service is deployed in namespace "fawkes"
    When I check the Experimentation deployment status
    Then the deployment "experimentation" should have 2 ready replicas
    And all pods should be in "Running" state
    And all pods should pass readiness checks

  @database @local
  Scenario: Experimentation service can connect to PostgreSQL database
    Given Experimentation pods are running
    When I check Experimentation database connectivity
    Then Experimentation should be connected to PostgreSQL cluster "db-experiment-dev"
    And the database should contain Experimentation schema tables
    And tables "experiments", "assignments", and "events" should exist

  @api @local
  Scenario: Experimentation API is accessible
    Given Experimentation service is deployed and healthy
    When I access the Experimentation API health endpoint
    Then the health check should return status "200"
    And the response should indicate "healthy" status
    And the service name should be "experimentation"

  @ui @local
  Scenario: Experimentation API is accessible via ingress
    Given Experimentation ingress is configured
    When I access "https://experimentation.fawkes.idp/health"
    Then the API should respond successfully
    And TLS certificate should be valid

  @experiment-crud @local
  Scenario: Create and retrieve an experiment
    Given I am authenticated to Experimentation API with admin token
    When I create a new experiment "feature-test-1" with:
      | name          | Feature Test 1                             |
      | description   | Testing new feature vs control            |
      | hypothesis    | New feature increases conversion by 10%   |
      | variants      | control:0.5, new-feature:0.5              |
      | metrics       | conversion, signup                         |
    Then the experiment should be created successfully
    And I should be able to retrieve the experiment via API
    And the experiment status should be "draft"

  @experiment-lifecycle @local
  Scenario: Start and stop an experiment
    Given an experiment "lifecycle-test" exists in "draft" status
    When I start the experiment
    Then the experiment status should change to "running"
    And the "started_at" timestamp should be set
    When I stop the experiment
    Then the experiment status should change to "stopped"
    And the "stopped_at" timestamp should be set

  @variant-assignment @local
  Scenario: Assign variant to user using consistent hashing
    Given an experiment "assignment-test" is in "running" status
    When I request variant assignment for user "user123"
    Then I should receive a variant assignment
    And the variant should be either "control" or "variant-a"
    When I request assignment for the same user again
    Then I should receive the same variant as before

  @traffic-allocation @local
  Scenario: Traffic allocation controls experiment participation
    Given an experiment "traffic-test" with 20% traffic allocation
    When I request assignments for 100 different users
    Then approximately 20 users should receive assignments
    And approximately 80 users should not be included in the experiment

  @event-tracking @local
  Scenario: Track conversion events for assigned users
    Given an experiment "tracking-test" is running
    And user "user456" is assigned to variant "control"
    When I track a "conversion" event for user "user456"
    Then the event should be recorded successfully
    And the event should be associated with the correct assignment
    And the event should have default value of 1.0

  @statistical-analysis @local
  Scenario: Calculate conversion rates for variants
    Given an experiment "stats-test" has collected sample data:
      | variant     | assignments | conversions |
      | control     | 100         | 10          |
      | variant-a   | 100         | 15          |
    When I request statistical analysis for the experiment
    Then the analysis should show:
      | variant     | conversion_rate |
      | control     | 0.10            |
      | variant-a   | 0.15            |
    And confidence intervals should be calculated for each variant

  @statistical-significance @local
  Scenario: Detect statistically significant results
    Given an experiment "significance-test" has sufficient data:
      | variant     | assignments | conversions |
      | control     | 500         | 45          |
      | variant-a   | 500         | 75          |
    When I request statistical analysis
    Then the p-value should be less than 0.05
    And statistical significance should be "true"
    And a winner should be declared
    And the recommendation should suggest rolling out the winner

  @sample-size @local
  Scenario: Provide recommendations based on sample size
    Given an experiment "sample-test" with target sample size 1000
    And the experiment has only 50 samples per variant
    When I request statistical analysis
    Then the recommendation should suggest continuing the experiment
    And the recommendation should mention minimum sample size requirement

  @metrics @local
  Scenario: Experimentation service exposes Prometheus metrics
    Given Experimentation service is running
    When I access the Prometheus metrics endpoint at "/metrics"
    Then I should see "experimentation_experiments_total" metric
    And I should see "experimentation_variant_assignments_total" metric
    And I should see "experimentation_events_total" metric
    And I should see "experimentation_significant_results_total" metric

  @integration-unleash @local
  Scenario: Integration with Unleash feature flags
    Given Unleash is deployed and accessible
    And an experiment "unleash-integration" is running
    When I check the Unleash URL configuration
    Then the configuration should point to Unleash API
    And I should be able to use feature flags to control experiment traffic

  @integration-plausible @local
  Scenario: Integration with Plausible analytics
    Given Plausible is deployed and accessible
    And an experiment "plausible-integration" is running
    When I check the Plausible URL configuration
    Then the configuration should point to Plausible API
    And experiment events can be cross-referenced with Plausible data

  @resource-utilization @local
  Scenario: Experimentation service resource usage is within limits
    Given Experimentation service has been running for at least 5 minutes
    When I check Experimentation pod resource usage
    Then CPU usage should be below 70% of requested resources
    And memory usage should be below 70% of requested resources
    And no pods should be in "OOMKilled" state

  @resilience @local
  Scenario: Experimentation service survives pod restarts
    Given Experimentation service has 2 running replicas
    And an experiment "resilience-test" exists with assignments
    When I delete one Experimentation pod
    Then Kubernetes should recreate the pod automatically
    And the service should remain available during restart
    And the experiment data should be preserved
    And existing assignments should remain consistent

  @at-e3-012 @acceptance @local
  Scenario: AT-E3-012 Complete Acceptance Test
    Given all Experimentation components are deployed:
      | component           | status   |
      | PostgreSQL cluster  | healthy  |
      | Experimentation API | healthy  |
      | Ingress             | configured |
    When I create a new experiment via API
    And I start the experiment
    And I assign variants to 100 users
    And I track conversion events for assigned users
    And I request statistical analysis
    Then the experiment should have variant assignments
    And conversion events should be tracked correctly
    And statistical analysis should be performed successfully
    And Prometheus metrics should be exposed
    And resource utilization should be <70%
    And AT-E3-012 should pass
