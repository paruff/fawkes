Feature: Product Analytics Platform
  As a platform team member
  I want to track platform usage and feature adoption
  So that I can make data-driven decisions about platform improvements

  Background:
    Given the Plausible analytics platform is deployed
    And the PostgreSQL database is healthy
    And the ClickHouse database is healthy
    And Plausible is accessible at "https://plausible.fawkes.idp"

  @local
  Scenario: Analytics platform is deployed and healthy
    When I check the Plausible deployment status
    Then the Plausible pods should be running
    And the ClickHouse pods should be running
    And the PostgreSQL cluster should be healthy
    And all services should be accessible

  @local
  Scenario: Privacy-compliant configuration
    Given I access the Plausible configuration
    Then cookie-less tracking should be enabled
    And GDPR compliance should be configured
    And registration should be disabled
    And failed login attempts should not be logged
    And the configuration should not collect personal data

  @local
  Scenario: Backstage instrumented with analytics
    Given I access the Backstage app-config
    When I check the analytics configuration
    Then Plausible should be configured as the analytics provider
    And the tracking domain should be "backstage.fawkes.idp"
    And the script source should be "https://plausible.fawkes.idp/js/script.js"
    And the proxy endpoint should be configured for "/plausible/api"

  @local
  Scenario: Dashboard is accessible
    Given I navigate to "https://plausible.fawkes.idp"
    When I log in with admin credentials
    Then I should see the Plausible dashboard
    And I should be able to view real-time visitor data
    And I should be able to view page views
    And I should be able to access site settings

  @local
  Scenario: Custom events can be tracked
    Given I have added "backstage.fawkes.idp" as a site
    When I configure custom events:
      | Event Name           | Description                    |
      | Deploy Application   | User deploys a new application |
      | Create Service       | User creates a new service     |
      | View Documentation   | User views documentation       |
      | Run Pipeline         | User triggers a CI/CD pipeline |
    Then the custom events should be registered
    And I should be able to track these events from Backstage

  @local
  Scenario: Tracking script loads correctly
    Given Backstage is configured with Plausible
    When I navigate to the Backstage homepage
    Then the Plausible tracking script should load
    And the script size should be less than 1KB
    And no cookies should be set
    And page views should be recorded

  @local
  Scenario: Custom event tracking works
    Given I am on the Backstage homepage
    And the Plausible tracking script is loaded
    When I trigger a custom event "Deploy Application"
    Then the event should be sent to Plausible
    And the event should appear in the dashboard within 30 seconds
    And the event properties should be captured

  @local
  Scenario: Real-time metrics display
    Given the Plausible dashboard is open
    When page views are generated on Backstage
    Then the real-time visitor count should update
    And the current page views should be displayed
    And the visitor chart should show activity

  @local
  Scenario: Data retention policies configured
    Given I access the site settings
    When I configure data retention
    Then I should be able to set retention period options:
      | Period      |
      | 6 months    |
      | 1 year      |
      | 2 years     |
      | Indefinite  |
    And the selected retention policy should be enforced

  @local
  Scenario: Dashboard shows top pages
    Given analytics data has been collected
    When I view the dashboard
    Then I should see "Top Pages" section
    And the most visited pages should be listed
    And page view counts should be displayed
    And trends should show increase or decrease

  @local
  Scenario: Dashboard shows traffic sources
    Given analytics data has been collected
    When I view the dashboard
    Then I should see "Top Sources" section
    And traffic sources should be categorized:
      | Source Type |
      | Direct      |
      | Referral    |
      | Search      |
    And source percentages should be displayed

  @local
  Scenario: Dashboard shows device breakdown
    Given analytics data has been collected
    When I view the dashboard
    Then I should see device breakdown
    And devices should be categorized:
      | Device Type |
      | Desktop     |
      | Mobile      |
      | Tablet      |
    And usage percentages should be shown

  @local
  Scenario: Dashboard shows browser distribution
    Given analytics data has been collected
    When I view the dashboard
    Then I should see browser distribution
    And popular browsers should be listed
    And browser versions should be tracked
    And usage percentages should be displayed

  @local
  Scenario: Goals and conversions tracking
    Given I have configured goals
    When I add a conversion goal "Complete Deployment"
    Then the goal should be tracked
    And conversion rates should be calculated
    And I should see goal completion trends

  @local
  Scenario: API access for programmatic queries
    Given I have API credentials
    When I query the Plausible API for "/api/v1/stats/aggregate"
    Then I should receive aggregated statistics
    And the response should include:
      | Metric        |
      | visitors      |
      | pageviews     |
      | bounce_rate   |
      | visit_duration|
    And the data should be in JSON format

  @local
  Scenario: No personal data collection
    Given users are visiting Backstage
    When I review the collected data
    Then no IP addresses should be stored
    And no user identifiers should be tracked
    And no cookies should be used
    And all data should be anonymized and aggregated

  @local
  Scenario: Cross-site tracking is disabled
    Given Plausible is configured
    When I check the tracking configuration
    Then cross-site tracking should be disabled
    And each site should have isolated data
    And no third-party data sharing should occur

  @local
  Scenario: Performance requirements met
    Given I navigate to the Plausible dashboard
    When the dashboard loads
    Then the page should load within 3 seconds
    And API queries should respond within 1 second
    And the tracking script should not impact page load time

  @local
  Scenario: High availability validated
    Given Plausible is deployed with HA configuration
    When I check the deployment status
    Then there should be at least 2 Plausible pods running
    And there should be 3 PostgreSQL replicas
    And pod anti-affinity should be configured
    And the service should remain available during pod restarts

  @local
  Scenario: Monitoring and alerting configured
    Given Plausible is deployed
    When I check the monitoring configuration
    Then health check endpoints should be configured
    And Prometheus should be scraping metrics
    And alerts should be configured for service degradation
    And logs should be collected and searchable
