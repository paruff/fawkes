# ============================================================================
# FILE: tests/bdd/features/discovery-metrics.feature
# PURPOSE: BDD acceptance tests for Discovery Metrics Dashboard (Issue #105)
# TAGS: @epic-3, @issue-105, @discovery-metrics, @dashboard
# ============================================================================
@epic-3 @issue-105 @discovery-metrics @dashboard
Feature: Discovery Metrics Dashboard Deployment
  As a platform product manager
  I want a dashboard tracking discovery activities
  So that I can measure interviews, insights, experiments, and ROI

  Background:
    Given the Fawkes platform is deployed
    And the PostgreSQL operator is running
    And the database cluster "db-discovery-dev" exists

  @deployment @local
  Scenario: Discovery Metrics service deployment is healthy
    Given Discovery Metrics service is deployed in namespace "fawkes"
    When I check the Discovery Metrics deployment status
    Then the deployment "discovery-metrics" should have 2 ready replicas
    And all pods should be in "Running" state
    And all pods should pass readiness checks

  @database @local
  Scenario: Discovery Metrics service can connect to PostgreSQL database
    Given Discovery Metrics pods are running
    When I check Discovery Metrics database connectivity
    Then Discovery Metrics should be connected to PostgreSQL cluster "db-discovery-dev"
    And the database should contain Discovery Metrics schema tables
    And tables "interviews", "discovery_insights", "experiments", "feature_validations", and "team_performance" should exist

  @api @local
  Scenario: Discovery Metrics API is accessible
    Given Discovery Metrics service is deployed and healthy
    When I access the Discovery Metrics API health endpoint
    Then the health check should return status "200"
    And the response should indicate "healthy" status
    And the service name should be "discovery-metrics"

  @ui @local
  Scenario: Discovery Metrics API is accessible via ingress
    Given Discovery Metrics ingress is configured
    When I access "https://discovery-metrics.fawkes.idp/health"
    Then the API should respond successfully
    And TLS certificate should be valid

  @api-docs @local
  Scenario: API documentation is available
    Given Discovery Metrics service is deployed
    When I access the API documentation at "/docs"
    Then the Swagger UI should be displayed
    And all API endpoints should be documented
    And endpoints for interviews, insights, experiments, and features should be listed

  @interview-tracking @local
  Scenario: Create and track an interview
    Given I have access to Discovery Metrics API
    When I create a new interview with:
      | participant_role | Backend Engineer          |
      | participant_team | Platform Team             |
      | interviewer      | Product Manager           |
      | scheduled_date   | 2025-12-25T10:00:00Z     |
      | notes            | Discovery interview notes |
    Then the interview should be created successfully
    And I should be able to retrieve the interview via API
    And the interview status should be "scheduled"

  @interview-completion @local
  Scenario: Complete an interview and generate insights
    Given an interview exists with status "scheduled"
    When I update the interview with:
      | status             | completed              |
      | completed_date     | 2025-12-25T11:00:00Z  |
      | duration_minutes   | 45                     |
      | insights_generated | 3                      |
    Then the interview should be marked as "completed"
    And the completion metrics should be recorded
    And the interview should appear in the last 7 days metrics

  @insight-capture @local
  Scenario: Capture discovery insight from interview
    Given a completed interview exists
    When I create a discovery insight with:
      | title        | Deployment process is confusing   |
      | description  | New developers struggle to deploy |
      | category     | Developer Experience              |
      | priority     | high                              |
      | source       | interview                         |
    Then the insight should be created successfully
    And the insight status should be "draft"
    And the insight should be linked to the interview

  @insight-validation @local
  Scenario: Validate discovery insight
    Given an insight exists in "draft" status
    When I update the insight to "validated" status
    And I set the validated_date to current timestamp
    Then the insight status should be "validated"
    And the time_to_validation_days should be calculated
    And the insight should appear in validated insights metrics

  @experiment-tracking @local
  Scenario: Create and track an experiment
    Given a validated insight exists
    When I create an experiment with:
      | name              | Deployment wizard test            |
      | description       | Testing guided deployment flow    |
      | hypothesis        | Wizard reduces deployment errors  |
      | success_criteria  | Error rate drops by 50%          |
    Then the experiment should be created successfully
    And the experiment status should be "planned"
    And the experiment should be linked to the insight

  @experiment-completion @local
  Scenario: Complete experiment with ROI calculation
    Given an experiment is in "running" status
    When I complete the experiment with:
      | status         | completed                            |
      | end_date       | 2025-12-30T00:00:00Z                |
      | results        | Error rate reduced by 60%           |
      | validated      | true                                 |
      | roi_percentage | 150                                  |
    Then the experiment status should be "completed"
    And the ROI should be recorded as 150%
    And the experiment should be marked as validated

  @feature-validation @local
  Scenario: Track feature validation through lifecycle
    Given an experiment is completed and validated
    When I create a feature validation with:
      | feature_name | Deployment Wizard          |
      | description  | Guided deployment workflow |
    Then the feature status should be "proposed"
    When I update the feature status through the lifecycle:
      | proposed  | 2025-12-20 |
      | validated | 2025-12-27 |
      | building  | 2025-12-28 |
      | shipped   | 2026-01-05 |
    Then the time_to_validate_days should be calculated
    And the time_to_ship_days should be calculated
    And the feature should appear in shipped features metrics

  @feature-adoption @local
  Scenario: Track feature adoption rate
    Given a feature is in "shipped" status
    When I update the feature with adoption metrics:
      | adoption_rate      | 75.5 |
      | user_satisfaction  | 4.2  |
    Then the adoption rate should be recorded as 75.5%
    And the user satisfaction score should be 4.2
    And the metrics should contribute to average feature adoption rate

  @team-performance @local
  Scenario: Calculate team performance metrics
    Given team "Platform Team" has conducted discovery activities
    When I create a team performance record for the period:
      | team_name            | Platform Team    |
      | period_start         | 2025-12-01       |
      | period_end           | 2025-12-31       |
      | interviews_conducted | 12               |
      | insights_generated   | 8                |
      | experiments_run      | 3                |
      | features_validated   | 2                |
      | features_shipped     | 1                |
    Then the team performance should be recorded
    And the discovery velocity should be calculated
    And the metrics should be available for team comparison

  @statistics @local
  Scenario: Retrieve discovery statistics
    Given discovery activities have been tracked
    When I request the discovery statistics endpoint
    Then I should receive aggregated statistics including:
      | total_interviews     |
      | completed_interviews |
      | total_insights       |
      | validated_insights   |
      | total_experiments    |
      | completed_experiments|
      | total_features       |
      | validated_features   |
      | shipped_features     |
      | validation_rate      |
    And all percentages should be calculated correctly

  @metrics-export @local
  Scenario: Prometheus metrics are exposed
    Given Discovery Metrics service is running
    When I access the "/metrics" endpoint
    Then Prometheus metrics should be available
    And metrics should include "discovery_interviews_total"
    And metrics should include "discovery_insights_total"
    And metrics should include "discovery_experiments_total"
    And metrics should include "discovery_features_validated"
    And metrics should include "discovery_validation_rate"
    And metrics should include "discovery_avg_time_to_validation_days"

  @metrics-scraping @local
  Scenario: ServiceMonitor enables Prometheus scraping
    Given Discovery Metrics service is deployed
    And Prometheus operator is installed
    When I check the ServiceMonitor configuration
    Then the ServiceMonitor "discovery-metrics" should exist in namespace "fawkes"
    And it should target the Discovery Metrics service
    And the scrape interval should be 30 seconds
    And Prometheus should be successfully scraping metrics

  @dashboard @local
  Scenario: Grafana dashboard is deployed
    Given Grafana is deployed with dashboard provisioning
    When I check for the Discovery Metrics dashboard
    Then the dashboard "Discovery Metrics Dashboard" should exist in Grafana
    And the dashboard should be tagged with "discovery", "metrics", "interviews", "insights", "experiments"

  @dashboard-panels @local
  Scenario: Dashboard displays discovery overview panels
    Given the Discovery Metrics dashboard is loaded
    When I view the "Discovery Overview" section
    Then I should see panels for:
      | Total Interviews    |
      | Total Insights      |
      | Total Experiments   |
      | Features Validated  |
      | Features Shipped    |
      | Validation Rate     |
    And all panels should display current values

  @dashboard-trends @local
  Scenario: Dashboard shows activity trends
    Given the Discovery Metrics dashboard is loaded
    When I view the "Discovery Activity Trends" section
    Then I should see time series for:
      | Interviews Trend (Last 30 Days) |
      | Insights Trend (Last 30 Days)   |
    And trends should show historical data

  @dashboard-status @local
  Scenario: Dashboard shows status breakdowns
    Given the Discovery Metrics dashboard is loaded
    When I view the "Status Breakdown" section
    Then I should see pie charts for:
      | Interviews by Status  |
      | Insights by Status    |
      | Experiments by Status |
      | Features by Status    |
    And charts should show distribution percentages

  @dashboard-insights @local
  Scenario: Dashboard shows insights analysis
    Given the Discovery Metrics dashboard is loaded
    When I view the "Insights Analysis" section
    Then I should see visualizations for:
      | Insights by Category |
      | Insights by Source   |
    And categories should be grouped correctly

  @dashboard-performance @local
  Scenario: Dashboard shows performance metrics
    Given the Discovery Metrics dashboard is loaded
    When I view the "Performance Metrics" section
    Then I should see metrics for:
      | Avg Time to Validation |
      | Avg Time to Ship       |
      | Feature Adoption Rate  |
      | Avg Experiment ROI     |
    And metrics should have appropriate thresholds and colors

  @dashboard-recent @local
  Scenario: Dashboard shows recent activity
    Given the Discovery Metrics dashboard is loaded
    When I view the "Recent Activity" section
    Then I should see counts for:
      | Interviews (Last 7 Days)  |
      | Interviews (Last 30 Days) |
      | Insights (Last 7 Days)    |
      | Insights (Last 30 Days)   |
    And recent activity should be highlighted

  @dashboard-refresh @local
  Scenario: Dashboard auto-refreshes
    Given the Discovery Metrics dashboard is loaded
    When I wait for the refresh interval
    Then the dashboard should automatically update
    And the refresh interval should be 30 seconds
    And new data should be displayed without manual refresh

  @validation-rate @local
  Scenario: Validation rate calculation is accurate
    Given there are 10 total insights
    And 7 insights are validated or implemented
    When I check the validation rate metric
    Then the validation rate should be 70%
    And the metric should be exposed in Prometheus
    And the metric should be displayed in the dashboard

  @roi-calculation @local
  Scenario: Average ROI calculation is accurate
    Given there are completed experiments with ROI:
      | Experiment A | 120% |
      | Experiment B | 80%  |
      | Experiment C | 150% |
    When I check the average experiment ROI metric
    Then the average ROI should be approximately 116.67%
    And the metric should be available in the dashboard

  @time-metrics @local
  Scenario: Time-based metrics are calculated correctly
    Given an insight was captured on 2025-12-20
    And the insight was validated on 2025-12-27
    When I check the time_to_validation_days
    Then it should be 7 days
    And the metric should contribute to the average validation time

  @resource-usage @local
  Scenario: Discovery Metrics service meets resource targets
    Given Discovery Metrics service is deployed
    When I check resource usage for Discovery Metrics pods
    Then CPU usage should be less than 70% of limits
    And memory usage should be less than 70% of limits
    And the service should maintain stable resource consumption

  @high-availability @local
  Scenario: Discovery Metrics service is highly available
    Given Discovery Metrics has 2 replicas
    When I simulate one pod failure
    Then the service should remain available
    And requests should be handled by the remaining pod
    And the failed pod should be automatically recreated
    And PodDisruptionBudget should prevent both pods from being down

  @resilience @local
  Scenario: Discovery Metrics handles database connection issues
    Given Discovery Metrics service is running
    When the database connection is temporarily lost
    Then the service should continue running
    And health checks should report unhealthy database
    When the database connection is restored
    Then the service should automatically reconnect
    And health checks should report healthy status

  @integration @local
  Scenario: Discovery Metrics integrates with continuous discovery workflow
    Given the continuous discovery workflow is in place
    When a product manager conducts user interviews
    And captures insights from those interviews
    And runs experiments to validate insights
    And tracks features through to shipment
    Then all activities should be recorded in Discovery Metrics
    And the Grafana dashboard should reflect the end-to-end workflow
    And metrics should enable data-driven decision making

  @backstage-integration @local
  Scenario: Discovery Metrics dashboard is accessible from Backstage
    Given Backstage is deployed
    And the Grafana component exists in Backstage catalog
    When I view the Grafana component in Backstage
    Then I should see a link to "Discovery Metrics Dashboard"
    And clicking the link should open the dashboard in Grafana

  @documentation @local
  Scenario: Discovery Metrics service has complete documentation
    Given I navigate to the service documentation
    Then I should find README files for:
      | services/discovery-metrics/README.md          |
      | platform/apps/discovery-metrics/README.md     |
    And documentation should include API endpoints
    And documentation should include deployment instructions
    And documentation should include metrics reference
    And documentation should include troubleshooting guide
