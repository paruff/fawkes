Feature: SPACE Metrics Collection
  As a platform engineer
  I want to collect SPACE framework metrics
  So that I can measure and improve developer experience

  Background:
    Given the SPACE metrics service is deployed
    And the database is initialized

  @local @space-metrics
  Scenario: SPACE metrics service is healthy
    When I check the health endpoint
    Then the service should respond with status "healthy"
    And the response should include service name "space-metrics"

  @local @space-metrics
  Scenario: All 5 SPACE dimensions are accessible
    When I request SPACE metrics
    Then I should receive data for all 5 dimensions
    And the dimensions should include "satisfaction"
    And the dimensions should include "performance"
    And the dimensions should include "activity"
    And the dimensions should include "communication"
    And the dimensions should include "efficiency"

  @local @space-metrics
  Scenario: Satisfaction metrics are collected
    When I request satisfaction dimension metrics
    Then I should receive satisfaction data
    And the data should include "nps_score"
    And the data should include "satisfaction_rating"
    And the data should include "response_count"

  @local @space-metrics
  Scenario: Performance metrics are collected
    When I request performance dimension metrics
    Then I should receive performance data
    And the data should include "deployment_frequency"
    And the data should include "lead_time_hours"
    And the data should include "change_failure_rate"

  @local @space-metrics
  Scenario: Activity metrics are collected
    When I request activity dimension metrics
    Then I should receive activity data
    And the data should include "commits_count"
    And the data should include "pull_requests_count"
    And the data should include "active_developers_count"

  @local @space-metrics
  Scenario: Communication metrics are collected
    When I request communication dimension metrics
    Then I should receive communication data
    And the data should include "avg_review_time_hours"
    And the data should include "cross_team_prs"

  @local @space-metrics
  Scenario: Efficiency metrics are collected
    When I request efficiency dimension metrics
    Then I should receive efficiency data
    And the data should include "flow_state_days"
    And the data should include "valuable_work_percentage"
    And the data should include "friction_incidents"

  @local @space-metrics
  Scenario: Pulse survey submission works
    When I submit a pulse survey response
      | valuable_work_percentage | 70.0 |
      | flow_state_days          | 3.0  |
      | cognitive_load           | 3.0  |
    Then the survey should be accepted
    And I should receive a success confirmation

  @local @space-metrics
  Scenario: Friction logging works
    When I log a friction incident
      | title       | Slow CI builds                    |
      | description | Jenkins builds taking 30+ minutes |
      | severity    | high                              |
    Then the friction incident should be logged
    And I should receive a success confirmation

  @local @space-metrics
  Scenario: DevEx health score is calculated
    When I request the DevEx health score
    Then I should receive a health score between 0 and 100
    And the response should include a status indicator

  @local @space-metrics
  Scenario: Prometheus metrics are exposed
    When I request Prometheus metrics
    Then the metrics should include "space_devex_health_score"
    And the metrics should include "space_nps_score"
    And the metrics should include "space_deployment_frequency"
    And the metrics should include "space_commits_total"

  @local @space-metrics @privacy
  Scenario: Privacy compliance is enforced
    When I request aggregated metrics
    Then individual developer data should not be exposed
    And metrics should be aggregated for teams of 5+ developers
    And no personal identifiers should be in the response
