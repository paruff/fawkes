@at-e3-003 @feedback @multi-channel
Feature: Multi-Channel Feedback System (AT-E3-003)
  As a platform team
  I want a complete multi-channel feedback system
  So that users can provide feedback through their preferred channel
  And all feedback is centralized and actionable

  Background:
    Given I have kubectl configured for the cluster
    And the feedback service is deployed in namespace "fawkes"

  @deployment @backstage-widget
  Scenario: Backstage widget is functional
    When I check for the feedback-service deployment in namespace "fawkes"
    Then the deployment "feedback-service" should exist
    And the deployment should have at least 1 ready replica
    And the feedback service should be healthy
    And the feedback database cluster "db-feedback-dev" should exist
    And the database cluster should be ready
    And the Backstage proxy should be configured for "/feedback/api"

  @cli-tool
  Scenario: CLI tool is working
    Given the feedback-cli code exists in the repository
    When I check the CLI tool structure
    Then the CLI should have a "submit" command
    And the CLI should have a "list" command
    And the CLI should have proper configuration management
    And the CLI setup.py should exist

  @mattermost-bot @responsive
  Scenario: Mattermost bot is responsive
    When I check for the feedback-bot deployment in namespace "fawkes"
    Then the deployment "feedback-bot" should exist
    And the deployment should have at least 1 ready replica
    And the feedback-bot service should exist
    And the bot should have sentiment analysis capabilities
    And the bot should have auto-categorization capabilities

  @automation @issue-creation
  Scenario: Automation creates GitHub issues from feedback
    When I check for the feedback-automation CronJob in namespace "fawkes"
    Then the CronJob "feedback-automation" should exist
    And the CronJob should be scheduled to run every 15 minutes
    And the feedback service should have an automation endpoint
    And the automation should be configured to process validated feedback
    And the automation should have GitHub integration capability

  @analytics @dashboard @grafana
  Scenario: Analytics dashboard shows feedback data
    Given Grafana is deployed in namespace "monitoring"
    When I check for the feedback analytics dashboard
    Then the dashboard file "feedback-analytics.json" should exist
    And the dashboard JSON should be valid
    And the dashboard should have NPS metrics
    And the dashboard should have sentiment analysis panels
    And the dashboard should have feedback volume metrics
    And the dashboard should have rating distribution panels

  @integration @end-to-end
  Scenario: All feedback channels are integrated
    Given all feedback components are deployed
    When I check the system integration
    Then the feedback-service should expose Prometheus metrics
    And the feedback-bot should expose Prometheus metrics
    And the feedback service should be accessible to the bot
    And the automation should be able to reach the feedback service
    And the dashboard should be configured to query feedback metrics
    And BDD tests should exist for all feedback channels

  @observability @metrics
  Scenario: Feedback system has comprehensive observability
    When I check observability configuration
    Then ServiceMonitors should exist for feedback-service
    And ServiceMonitors should exist for feedback-bot
    And the feedback service should expose metrics endpoint
    And the bot should expose metrics endpoint
    And metrics should include feedback_submissions_total
    And metrics should include feedback_sentiment_score
    And metrics should include nps_score

  @security @resources
  Scenario: Feedback system has proper resource limits and security
    When I check security configuration
    Then the feedback-service should have CPU and memory limits
    And the feedback-bot should have CPU and memory limits
    And all components should run as non-root
    And all components should have security contexts defined
    And secrets should be properly managed

  @data-flow
  Scenario: Feedback flows through all channels correctly
    Given a user submits feedback via Backstage widget
    When the feedback is processed by the system
    Then the feedback should be stored in the database
    And the feedback should be visible in CLI tool queries
    And the feedback should appear in analytics dashboard
    And high-priority feedback should trigger automation
    And metrics should be updated in Prometheus

  @channels @completeness
  Scenario: All required feedback channels are operational
    When I verify all feedback channels
    Then the Backstage widget channel should be functional
    And the CLI tool channel should be functional
    And the Mattermost bot channel should be functional
    And the automation channel should be functional
    And the analytics dashboard should be functional
    And all channels should be integrated with the central service
