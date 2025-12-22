Feature: Smart Alerting System
  As a platform engineer
  I want intelligent alert correlation and suppression
  So that alert noise is reduced and teams receive actionable notifications

  Background:
    Given the Smart Alerting service is deployed
    And Redis is available
    And suppression rules are loaded

  @local @alerting
  Scenario: Alert grouping by service and symptom
    Given I have multiple related alerts for the same service
    When I send the alerts to the Smart Alerting service
    Then the alerts should be grouped together
    And the group should have a calculated priority score
    And the alerts should be deduplicated

  @local @alerting
  Scenario: Flapping alert suppression
    Given I have an alert that fires repeatedly
    When I send the same alert 4 times within 10 minutes
    Then the 4th alert should be suppressed
    And the suppression reason should be "flapping"

  @local @alerting
  Scenario: Cascade alert suppression
    Given I have a root cause alert "DatabaseDown"
    And I have dependent alerts "HighLatency" and "ConnectionTimeout"
    When the root cause alert fires
    And the dependent alerts fire shortly after
    Then the dependent alerts should be suppressed
    And the suppression reason should include "cascade"

  @local @alerting
  Scenario: Priority-based routing
    Given I have alerts with different severity levels
    When critical alerts (P0) are received
    Then they should be routed to PagerDuty and Slack
    When high priority alerts (P1) are received
    Then they should be routed to Slack only
    When medium priority alerts (P2) are received
    Then they should be routed to Mattermost only

  @local @alerting
  Scenario: Alert fatigue reduction target
    Given the system has processed 100 alerts
    When I check the alert statistics
    Then the alert fatigue reduction should be greater than 50%
    And the false alert rate should be less than 10%

  @local @alerting
  Scenario: Service owner lookup
    Given an alert for service "api-gateway"
    When the alert is processed
    Then the service owner should be fetched from Backstage
    And the alert should be enriched with owner information

  @local @alerting
  Scenario: Context enrichment
    Given an alert is received
    When the alert is processed
    Then recent changes should be included in the context
    And relevant runbook links should be included
    And similar past incidents should be referenced

  @local @alerting
  Scenario: Alert group statistics
    Given alerts have been grouped and processed
    When I query the alert statistics API
    Then I should see total alerts received
    And I should see total alerts suppressed
    And I should see total alert groups created
    And I should see the fatigue reduction percentage
