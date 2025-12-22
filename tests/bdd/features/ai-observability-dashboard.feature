Feature: AI Observability Dashboard
  As a platform operator
  I want to view AI-powered anomaly detection and smart alerting metrics
  So that I can understand system intelligence and anomaly trends

  Background:
    Given the anomaly detection service is running
    And the smart alerting service is running
    And Grafana is configured with Prometheus datasource

  Scenario: View AI observability dashboard
    Given I navigate to Grafana
    When I open the "AI Observability Dashboard"
    Then I should see the dashboard with title "AI Observability Dashboard"
    And I should see the following sections:
      | Section Name                  |
      | Active Anomalies Feed         |
      | Anomaly Detection Performance |
      | Smart Alert Groups            |
      | Root Cause Analysis           |
      | Historical Trends             |

  Scenario: Real-time anomaly feed displays active anomalies
    Given there are 5 active anomalies detected
    When I view the "Active Anomalies Feed" section
    Then I should see "Active Anomalies Count" showing "5"
    And I should see a table with anomaly details
    And each anomaly should display:
      | Field     |
      | Metric    |
      | Severity  |
      | Count     |

  Scenario: Anomaly detection accuracy metrics visible
    Given the anomaly detection service has metrics
    When I view the "Anomaly Detection Performance" section
    Then I should see "Anomaly Detection Accuracy" gauge
    And I should see "False Positive Rate" stat
    And I should see "ML Models Loaded" stat
    And the accuracy should be above 95%
    And the false positive rate should be below 5%

  Scenario: Smart alert groups visualization
    Given there are 3 active alert groups
    And 10 alerts have been suppressed
    When I view the "Smart Alert Groups" section
    Then I should see "Active Alert Groups" showing "3"
    And I should see "Alerts Suppressed" showing "10"
    And I should see "Alert Fatigue Reduction" gauge
    And I should see alert groups by service pie chart

  Scenario: Alert reduction rate tracking
    Given the smart alerting system has been running for 7 days
    And alert fatigue reduction is 55%
    When I view the "Smart Alert Groups" section
    Then I should see "Alert Fatigue Reduction" showing "55%"
    And the gauge should be in the green threshold
    And I should see "Alert Reduction Rate Trend" time series

  Scenario: Root cause analysis success metrics
    Given 20 root cause analyses have been performed
    And 16 were successful
    When I view the "Root Cause Analysis" section
    Then I should see "Root Cause Analysis Success Rate" showing "80%"
    And I should see "RCA Executions" showing "20"
    And I should see "RCA Status Distribution" pie chart
    And the success rate should be in the green threshold

  Scenario: Historical anomaly trends visible
    Given anomaly detection has been running for 7 days
    When I view the "Historical Trends" section
    Then I should see "Historical Anomaly Trends (7 Days)" time series
    And the chart should show anomaly counts by severity
    And I should see trends for critical, high, medium, and low severity

  Scenario: Time to detection metrics
    Given anomaly detection latency is being tracked
    When I view the "Active Anomalies Feed" section
    Then I should see "Mean Time to Detection" gauge
    And the value should be less than 60 seconds
    And the gauge should be in the green threshold

  Scenario: Filter anomalies by severity
    Given there are anomalies with different severities
    When I select "critical" from the severity filter
    Then I should only see critical anomalies in the feed
    And the stats should update to show only critical counts

  Scenario: Filter anomalies by metric type
    Given there are anomalies for different metrics
    When I select a specific metric from the metric filter
    Then I should only see anomalies for that metric
    And the timeline should update accordingly

  Scenario: View anomaly timeline interface
    Given I navigate to the anomaly timeline at "http://anomaly-detection.local/timeline"
    Then I should see the "AI Anomaly Detection Timeline" page
    And I should see statistics for critical, high, medium, and low anomalies
    And I should see a timeline of recent anomalies

  Scenario: Timeline shows correlated events
    Given there is an anomaly with correlated events
    When I view the anomaly in the timeline
    Then I should see tags indicating "Has Events"
    And when I click on the anomaly
    Then I should see the correlated events section
    And it should display recent deployments and config changes

  Scenario: Timeline shows root cause analysis
    Given there is an anomaly with root cause analysis
    When I click on the anomaly in the timeline
    Then I should see "Root Cause Analysis" section
    And I should see likely causes listed
    And I should see remediation suggestions
    And I should see runbook links if available

  Scenario: Filter timeline by time range
    Given the timeline is displaying anomalies
    When I select "Last 6 Hours" from the time range filter
    Then I should only see anomalies from the last 6 hours
    And the statistics should update accordingly

  Scenario: Filter timeline by severity
    Given the timeline is displaying anomalies
    When I select "high" from the severity filter
    Then I should only see high severity anomalies
    And other severity anomalies should be hidden

  Scenario: Auto-refresh timeline data
    Given the timeline is open
    And I wait for 35 seconds
    Then the timeline should automatically refresh
    And the "Last Updated" timestamp should be updated

  Scenario: Dashboard annotations for critical anomalies
    Given there is a critical anomaly detected
    When I view the AI observability dashboard
    Then I should see an annotation on the timeline
    And the annotation should be marked with a red icon
    And it should display "Critical anomaly: <metric>"

  Scenario: Alert grouping efficiency metrics
    Given 50 individual alerts were received
    And they were grouped into 8 alert groups
    When I view the smart alert groups section
    Then I should see "Alert Grouping Efficiency" showing "8"
    And I should see the suppression reasons pie chart
    And it should show distribution of why alerts were suppressed

  Scenario: Model performance tracking
    Given 5 ML models are loaded
    When I view the anomaly detection performance section
    Then I should see "ML Models Loaded" showing "5"
    And the value should be in the green threshold
    And I should see processing time percentiles (P50, P95, P99)

  @acceptance @at-e2-009
  Scenario: AT-E2-009 - AI Observability Dashboard validates all requirements
    Given the Fawkes platform is running
    And the anomaly detection service is operational
    And the smart alerting service is operational
    When I access the AI observability dashboard
    Then the dashboard should display:
      | Metric                          | Requirement         |
      | Active anomalies feed           | Real-time updates   |
      | Anomaly detection accuracy      | > 95%               |
      | Smart alert groups              | Active and recent   |
      | Alert reduction rate            | > 50%               |
      | Root cause success rate         | Visible             |
      | AI model performance            | All metrics visible |
      | Time to detection               | < 60s average       |
    And I should be able to view the anomaly timeline
    And the timeline should show correlated events
    And root cause analysis should be available for anomalies
    And I should be able to filter by service, severity, and type
