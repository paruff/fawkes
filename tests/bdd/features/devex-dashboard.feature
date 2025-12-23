Feature: DevEx Dashboard
  As a platform engineer
  I want to view comprehensive developer experience metrics across all SPACE dimensions
  So that I can understand and improve developer satisfaction and productivity

  Background:
    Given the SPACE metrics service is running
    And Grafana is configured with Prometheus datasource
    And the DevEx dashboard is deployed

  @devex @dashboard
  Scenario: View DevEx dashboard
    Given I navigate to Grafana
    When I open the "Developer Experience (DevEx) Dashboard"
    Then I should see the dashboard with title "Developer Experience (DevEx) Dashboard"
    And I should see the following sections:
      | Section Name                      |
      | DevEx Overview                    |
      | SATISFACTION                      |
      | PERFORMANCE                       |
      | ACTIVITY                          |
      | COMMUNICATION & COLLABORATION     |
      | EFFICIENCY & FLOW                 |
      | HISTORICAL TRENDS                 |

  @devex @health-score
  Scenario: Overall DevEx health score is visible
    Given the SPACE metrics service has data
    When I view the "DevEx Overview" section
    Then I should see "Overall DevEx Health Score" stat
    And the score should be between 0 and 100
    And I should see "SPACE Dimensions Status" bar gauge
    And the bar gauge should show all 5 dimensions

  @devex @satisfaction
  Scenario: Satisfaction metrics are displayed
    Given the SPACE metrics service has satisfaction data
    When I view the "SATISFACTION" section
    Then I should see "Net Promoter Score (NPS)" gauge
    And I should see "Platform Satisfaction Rating" stat
    And I should see "Survey Response Rate" stat
    And I should see "Burnout Percentage" stat
    And I should see "NPS Trend (30 days)" time series
    And the NPS gauge should be between -100 and 100

  @devex @performance
  Scenario: Performance metrics show DORA indicators
    Given the SPACE metrics service has performance data
    When I view the "PERFORMANCE" section
    Then I should see "Deployment Frequency" stat
    And I should see "Lead Time for Changes" gauge
    And I should see "Change Failure Rate" gauge
    And I should see "Build Success Rate" stat
    And all metrics should have appropriate thresholds

  @devex @activity
  Scenario: Activity metrics show developer engagement
    Given the SPACE metrics service has activity data
    When I view the "ACTIVITY" section
    Then I should see "Active Developers" stat
    And I should see "Commits (7d)" stat
    And I should see "Pull Requests (7d)" stat
    And I should see "Code Reviews (7d)" stat
    And I should see "AI Tool Adoption" stat
    And I should see "Platform Engagement" stat

  @devex @communication
  Scenario: Communication metrics show collaboration quality
    Given the SPACE metrics service has communication data
    When I view the "COMMUNICATION & COLLABORATION" section
    Then I should see "Avg Review Time" gauge
    And I should see "Comments per PR" stat
    And I should see "Cross-Team PRs" stat
    And I should see "Knowledge Sharing" stat
    And the review time gauge should show hours

  @devex @efficiency
  Scenario: Efficiency metrics show flow and friction
    Given the SPACE metrics service has efficiency data
    When I view the "EFFICIENCY & FLOW" section
    Then I should see "Flow State Achievement" stat
    And I should see "Valuable Work Time" gauge
    And I should see "Friction Incidents (30d)" stat
    And I should see "Cognitive Load" gauge
    And the cognitive load gauge should be on a 1-5 scale

  @devex @trending
  Scenario: Historical trends show metric evolution
    Given the SPACE metrics service has historical data
    When I view the "HISTORICAL TRENDS" section
    Then I should see "DevEx Health Score Trend (30 days)" time series
    And I should see "SPACE Dimensions Trend (30 days)" time series
    And I should see "Deployment Frequency Trend (30 days)" time series
    And I should see "Lead Time Trend (30 days)" time series
    And I should see "Friction Incidents Trend (30 days)" time series
    And all trends should show the last 30 days of data

  @devex @filtering
  Scenario: Team-level filtering works
    Given there are multiple teams with metrics
    When I open the team dropdown
    Then I should see "All" option
    And I should see individual team options
    When I select a specific team
    Then all panels should update to show only that team's metrics

  @devex @thresholds
  Scenario: Metrics have appropriate color thresholds
    Given the DevEx dashboard is loaded
    When I view any metric panel
    Then metrics below target should be red or orange
    And metrics at target should be yellow
    And metrics exceeding target should be green

  @devex @annotations
  Scenario: Dashboard includes deployment and incident annotations
    Given deployments and incidents have occurred
    When I view time series panels
    Then I should see green markers for deployments
    And I should see red markers for incidents
    And markers should include relevant metadata

  @devex @alerting
  Scenario: Alert rules are configured for critical metrics
    Given the DevEx alerting rules are deployed
    When I check Prometheus alert rules
    Then I should see "DevExHealthScoreLow" alert
    And I should see "NPSScoreLow" alert
    And I should see "HighFrictionIncidents" alert
    And I should see "HighCognitiveLoad" alert
    And I should see "HighBurnoutRate" alert
    And alerts should trigger on appropriate thresholds

  @devex @refresh
  Scenario: Dashboard auto-refreshes metrics
    Given the DevEx dashboard is open
    And the refresh interval is set to 5 minutes
    When I wait for the refresh interval
    Then the dashboard should automatically update with new data
    And the "Updated" timestamp should change

  @devex @export
  Scenario: Dashboard can be exported
    Given the DevEx dashboard is loaded
    When I access the share menu
    Then I should be able to export the dashboard JSON
    And I should be able to create a snapshot
    And I should be able to generate a shareable link

  @devex @privacy
  Scenario: Dashboard respects privacy requirements
    Given the DevEx dashboard displays metrics
    Then individual developer data should not be visible
    And metrics should be aggregated at team level
    And no personal identifiers should appear in panels
