Feature: AI-Powered Anomaly Detection
  As a platform operator
  I want AI-powered anomaly detection for metrics and logs
  So that I can proactively detect and resolve issues

  Background:
    Given the anomaly detection service is deployed
    And Prometheus is collecting metrics
    And the ML models are initialized

  @local @smoke
  Scenario: Anomaly detection service is healthy
    When I query the health endpoint
    Then the service status should be "UP"
    And Prometheus should be connected
    And ML models should be loaded

  @local
  Scenario: Detect error rate spike anomaly
    Given historical error rate data is available
    When the error rate suddenly spikes to 50%
    And the detection cycle runs
    Then an anomaly should be detected
    And the anomaly severity should be "high" or "critical"
    And the anomaly confidence should be greater than 70%

  @local
  Scenario: Detect CPU usage spike
    Given historical CPU usage data is available
    When CPU usage suddenly increases by 200%
    And the detection cycle runs
    Then an anomaly should be detected
    And the anomaly metric should contain "cpu"
    And the anomaly should have an expected value

  @local
  Scenario: Root cause analysis for critical anomaly
    Given an anomaly is detected with severity "critical"
    When root cause analysis is triggered
    Then likely causes should be identified
    And remediation suggestions should be provided
    And relevant runbook links should be included

  @local
  Scenario: Low false positive rate
    Given the anomaly detection has been running for 1 hour
    When I query the detection statistics
    Then the false positive rate should be less than 5%

  @local
  Scenario: Multiple anomaly detection algorithms
    When I query the models endpoint
    Then at least 4 detection algorithms should be available
    And the algorithms should include "Isolation Forest"
    And the algorithms should include "Statistical Z-Score"
    And the algorithms should include "IQR Method"

  @local
  Scenario: Query recent anomalies
    Given anomalies have been detected
    When I query the anomalies API
    Then I should receive a list of anomalies
    And each anomaly should have an ID
    And each anomaly should have a timestamp
    And each anomaly should have a severity level

  @local
  Scenario: Filter anomalies by severity
    Given anomalies with different severity levels exist
    When I query anomalies filtered by severity "critical"
    Then all returned anomalies should have severity "critical"

  @local
  Scenario: Alerting integration
    Given an anomaly with severity "critical" is detected
    Then an alert should be sent to Alertmanager
    And the alert should include the anomaly details
    And the anomaly should be marked as alerted

  @local
  Scenario: Correlated metrics detection
    Given multiple metrics are being monitored
    When anomalies occur in related metrics at the same time
    And root cause analysis is performed
    Then the correlated metrics should be identified
    And the correlation should be included in the RCA

  @dev @integration
  Scenario: End-to-end anomaly detection workflow
    Given the platform is running normally
    When a deployment causes increased error rates
    And the anomaly detection service monitors the metrics
    Then the anomaly should be detected within 5 minutes
    And root cause analysis should be automatically triggered
    And the likely cause should mention "deployment"
    And an alert should be sent
    And remediation suggestions should be provided

  @dev
  Scenario: Prometheus metrics exposure
    When I query the metrics endpoint
    Then Prometheus metrics should be exposed
    And the metrics should include "anomaly_detection_total"
    And the metrics should include "anomaly_detection_false_positive_rate"
    And the metrics should include "anomaly_detection_models_loaded"
