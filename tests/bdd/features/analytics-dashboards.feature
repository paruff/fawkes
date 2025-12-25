Feature: Analytics Dashboards
  As a platform team member
  I want comprehensive analytics dashboards
  So that I can understand usage trends, feature adoption, experiment results, and user segments

  Background:
    Given the analytics dashboard service is deployed
    And the service is accessible at "https://analytics.fawkes.idp"
    And Plausible analytics is running
    And the experimentation service is running
    And the feedback service is running

  @local
  Scenario: Analytics dashboard service is deployed and healthy
    When I check the analytics dashboard deployment status
    Then the analytics dashboard pods should be running
    And there should be at least 2 replicas
    And all pods should be in Ready state
    And the service should respond to health checks

  @local
  Scenario: Dashboard provides complete analytics data
    When I request the complete dashboard data via "/api/v1/dashboard?time_range=7d"
    Then the response should include usage trends
    And the response should include feature adoption metrics
    And the response should include experiment results
    And the response should include user segments
    And the response should include funnel data

  @local
  Scenario: Usage trends are tracked in real-time
    Given I request usage trends for "7d"
    Then I should see total user count
    And I should see active user count
    And I should see page view statistics
    And I should see average session duration
    And I should see bounce rate
    And I should see time series data for users over time
    And I should see time series data for page views over time
    And I should see top pages by view count
    And I should see traffic sources breakdown

  @local
  Scenario: Feature adoption metrics are available
    When I request feature adoption metrics for "30d"
    Then I should see total number of features
    And I should see adoption rate for each feature
    And I should see unique users per feature
    And I should see usage trends per feature
    And features should be marked as trending up, down, or stable
    And I should see the most adopted feature
    And I should see the least adopted feature
    And I should see historical adoption trends

  @local
  Scenario: Experiment results show statistical analysis
    When I request experiment results
    Then I should see all active experiments
    And each experiment should include:
      | Field                |
      | experiment_id        |
      | experiment_name      |
      | status               |
      | variant metrics      |
      | p_value             |
      | is_significant       |
      | recommendation       |
    And variant metrics should include conversion rates
    And variant metrics should include confidence intervals
    And winning variants should be identified

  @local
  Scenario: User segments show behavioral analysis
    When I request user segments for "30d"
    Then I should see total user count
    And I should see multiple user segments
    And each segment should include:
      | Field            |
      | segment_name     |
      | user_count       |
      | percentage       |
      | avg_engagement   |
      | characteristics  |
    And segments should include "Power Users"
    And segments should include "Regular Users"
    And segments should include "New Users"
    And segments should include "At Risk" users

  @local
  Scenario: Onboarding funnel shows conversion flow
    When I request funnel data for "onboarding"
    Then I should see funnel description
    And I should see 4 funnel steps:
      | Step               |
      | Sign Up            |
      | Profile Setup      |
      | First Template     |
      | First Deployment   |
    And each step should show users entered
    And each step should show users completed
    And each step should show completion rate
    And each step should show drop-off rate
    And I should see overall conversion rate
    And I should see average completion time

  @local
  Scenario: Deployment funnel tracks application deployments
    When I request funnel data for "deployment"
    Then I should see 4 deployment steps:
      | Step               |
      | Start Deployment   |
      | Configure Settings |
      | Build Complete     |
      | Deploy Success     |
    And the overall conversion rate should be above 85%
    And each step should show time to next step
    And drop-off points should be identified

  @local
  Scenario: Service creation funnel monitors new services
    When I request funnel data for "service_creation"
    Then I should see 4 service creation steps:
      | Step              |
      | Select Template   |
      | Configure Service |
      | Review & Create   |
      | Service Active    |
    And I should see conversion metrics for each step
    And bottlenecks should be identifiable

  @local
  Scenario: Dashboard updates in real-time
    Given I am viewing the dashboard
    When new analytics events occur
    Then the dashboard should update within 30 seconds
    And metrics should reflect the latest data
    And no page refresh should be required

  @local
  Scenario: Segment analysis provides actionable insights
    When I analyze user segments
    Then I should see segment size distribution
    And I should see engagement levels per segment
    And "Power Users" should have high engagement scores above 8
    And "At Risk" users should have low engagement scores below 3
    And segment characteristics should be clearly defined

  @local
  Scenario: Prometheus metrics are exported
    When I access the metrics endpoint at "/metrics"
    Then I should see usage metrics:
      | Metric                                  |
      | analytics_total_users                   |
      | analytics_active_users                  |
      | analytics_page_views_total              |
      | analytics_avg_session_duration_seconds  |
    And I should see feature metrics:
      | Metric                              |
      | analytics_feature_adoption_rate     |
      | analytics_feature_usage_total       |
      | analytics_feature_unique_users      |
    And I should see experiment metrics:
      | Metric                                |
      | analytics_active_experiments          |
      | analytics_experiment_conversion_rate  |
    And I should see segment metrics:
      | Metric                        |
      | analytics_segment_size        |
      | analytics_segment_engagement  |
    And I should see funnel metrics:
      | Metric                                 |
      | analytics_funnel_conversion_rate       |
      | analytics_funnel_step_completion_rate  |
      | analytics_funnel_drop_off_rate         |

  @local
  Scenario: Grafana dashboard visualizes analytics
    Given I access Grafana at "https://grafana.fawkes.idp"
    When I open the "Analytics Dashboard" dashboard
    Then I should see usage trends panels
    And I should see feature adoption visualizations
    And I should see experiment results charts
    And I should see user segment distribution
    And I should see funnel conversion gauges
    And I should see real-time metrics
    And all panels should load successfully
    And data should be up to date

  @local
  Scenario: Dashboard data can be exported
    When I request data export in "json" format for "30d"
    Then I should receive complete dashboard data
    And the data should be in JSON format
    And the data should include all metrics
    And the data should be downloadable

  @local
  Scenario: Export supports multiple formats
    When I request data export in "csv" format
    Then I should receive a success response
    And the export should be available

  @local
  Scenario: Time range filtering works correctly
    When I request dashboard data for different time ranges:
      | Time Range |
      | 1h         |
      | 24h        |
      | 7d         |
      | 30d        |
      | 90d        |
    Then each request should return appropriate data
    And metrics should be aggregated for the specified period
    And time series data should match the time range

  @local
  Scenario: Manual metrics refresh works
    When I trigger manual metrics refresh via POST "/api/v1/metrics/refresh"
    Then the metrics should be refreshed immediately
    And the response should confirm success
    And updated metrics should be available

  @local
  Scenario: Background refresh updates metrics automatically
    Given the service is running
    When 5 minutes pass
    Then metrics should be automatically refreshed
    And the latest data should be available
    And no manual intervention should be required

  @local
  Scenario: Service handles concurrent requests
    When I send 10 concurrent requests to the dashboard API
    Then all requests should succeed
    And responses should be consistent
    And response times should be acceptable (<2 seconds)

  @local
  Scenario: Cache improves performance
    Given I request dashboard data for "7d"
    When I request the same data again within 5 minutes
    Then the response should be served from cache
    And the response time should be faster (<100ms)
    And the data should be identical

  @local
  Scenario: Service integrates with multiple data sources
    When the service aggregates data
    Then it should fetch data from Plausible
    And it should fetch data from Experimentation service
    And it should fetch data from Feedback service
    And all data should be combined correctly
    And the aggregation should complete within 2 seconds

  @local
  Scenario: High availability is maintained
    Given the service is deployed with 2 replicas
    When I check the deployment configuration
    Then pod anti-affinity should be configured
    And pod disruption budget should allow at least 1 pod
    And the service should remain available during pod restarts

  @local
  Scenario: Resource usage is optimized
    When I check resource allocation
    Then CPU requests should be 200m
    And CPU limits should be 500m
    And memory requests should be 256Mi
    And memory limits should be 512Mi
    And actual usage should be within limits

  @local
  Scenario: Security best practices are followed
    When I inspect the deployment
    Then pods should run as non-root user
    And root filesystem should be read-only
    And privilege escalation should be disabled
    And all capabilities should be dropped
    And security context should be properly configured

  @local
  Scenario: Service monitoring is configured
    When I check monitoring configuration
    Then ServiceMonitor should be deployed
    And Prometheus should scrape metrics every 30 seconds
    And health check endpoints should be configured
    And liveness probe should be working
    And readiness probe should be working

  @local
  Scenario: CORS is properly configured
    When I check CORS configuration
    Then allowed origins should include Backstage
    And allowed origins should include Grafana
    And credentials should be allowed
    And allowed methods should include GET and POST

  @local
  Scenario: API documentation is available
    When I access the API root at "/docs"
    Then I should see OpenAPI documentation
    And all endpoints should be documented
    And example requests should be provided
    And response schemas should be defined
