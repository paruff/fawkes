# ============================================================================
# FILE: tests/bdd/features/nasa_tlx_cognitive_load.feature
# PURPOSE: BDD tests for NASA-TLX Cognitive Load Assessment Tool
# ============================================================================

Feature: NASA-TLX Cognitive Load Assessment Tool
  As a platform developer
  I want to submit cognitive load assessments after completing platform tasks
  So that the platform team can measure and improve developer experience

  Background:
    Given the DevEx Survey Automation service is deployed
    And the NASA-TLX assessment endpoint is available at "/nasa-tlx"
    And the NASA-TLX API endpoint is available at "/api/v1/nasa-tlx/submit"

  @nasa-tlx @assessment
  Scenario: Developer submits NASA-TLX assessment after deployment
    Given I just completed a "deployment" task
    When I access the NASA-TLX assessment page with task_type "deployment"
    Then I should see a form with 6 cognitive load dimensions
    And each dimension should have a slider from 0 to 100
    And I should see fields for:
      | field              |
      | Mental Demand      |
      | Physical Demand    |
      | Temporal Demand    |
      | Performance        |
      | Effort             |
      | Frustration        |
    And I should see an optional duration field
    And I should see an optional comment field

  @nasa-tlx @submission
  Scenario: Successfully submit NASA-TLX assessment
    Given I am on the NASA-TLX assessment page for task_type "pr_review"
    When I rate the dimensions as:
      | dimension       | value |
      | mental_demand   | 45.0  |
      | physical_demand | 15.0  |
      | temporal_demand | 30.0  |
      | performance     | 85.0  |
      | effort          | 40.0  |
      | frustration     | 20.0  |
    And I enter duration as "20" minutes
    And I submit the assessment
    Then the assessment should be stored successfully
    And I should see a success message
    And the overall workload score should be calculated
    And Prometheus metrics should be updated

  @nasa-tlx @validation
  Scenario: Validate NASA-TLX dimension ranges
    Given I am submitting a NASA-TLX assessment
    When I try to submit with invalid values:
      | dimension       | value  | expected_result |
      | mental_demand   | 150.0  | rejected        |
      | physical_demand | -10.0  | rejected        |
      | frustration     | 50.0   | accepted        |
    Then only valid values should be accepted

  @nasa-tlx @privacy
  Scenario: NASA-TLX assessments respect privacy
    Given multiple developers submit NASA-TLX assessments
    When analytics are generated
    Then individual responses should not be identifiable
    And aggregations should only show team-level data
    And users can opt-out of assessments

  @nasa-tlx @integration
  Scenario: NASA-TLX integrated with platform workflows
    Given I complete a deployment via Jenkins
    When the deployment finishes successfully
    Then I should receive a prompt to complete a NASA-TLX assessment
    And the assessment should be pre-filled with task details:
      | field     | value               |
      | task_type | deployment          |
      | task_id   | jenkins-build-1234  |

  @nasa-tlx @analytics
  Scenario: View NASA-TLX analytics in DevEx dashboard
    Given NASA-TLX assessments have been submitted for various task types
    When I access the DevEx dashboard
    Then I should see NASA-TLX cognitive load metrics
    And I should see workload by task type
    And I should see trends over time
    And I should see which dimensions are most demanding
    And I should see average performance scores

  @nasa-tlx @metrics
  Scenario: NASA-TLX Prometheus metrics are exposed
    Given NASA-TLX assessments have been submitted
    When I query the /metrics endpoint
    Then I should see the following metrics:
      | metric                            |
      | devex_nasa_tlx_submissions_total  |
      | devex_nasa_tlx_overall_workload   |
      | devex_nasa_tlx_mental_demand      |
      | devex_nasa_tlx_frustration        |
      | devex_nasa_tlx_performance        |
    And metrics should be labeled by task_type

  @nasa-tlx @alerts
  Scenario: Alert on high cognitive load
    Given NASA-TLX assessments show high workload for "incident_response"
    When the average overall workload exceeds 70 for a task type
    Then an alert should be triggered
    And the platform team should be notified
    And the alert should include which dimensions are highest

  @nasa-tlx @task-types
  Scenario Outline: NASA-TLX for different platform tasks
    Given I completed a "<task_type>" task
    When I submit a NASA-TLX assessment for "<task_type>"
    Then the assessment should be categorized correctly
    And analytics should group by task type

    Examples:
      | task_type          |
      | deployment         |
      | pr_review          |
      | incident_response  |
      | build              |
      | debug              |
      | configuration      |
      | onboarding         |

  @nasa-tlx @backstage
  Scenario: NASA-TLX accessible from Backstage portal
    Given I am logged into Backstage
    When I navigate to the Developer Experience section
    Then I should see a link to "Submit Cognitive Load Assessment"
    And clicking the link should open the NASA-TLX form
    And my user_id should be automatically populated

  @nasa-tlx @mattermost
  Scenario: NASA-TLX via Mattermost bot
    Given I have completed a platform task
    When I send "/nasa-tlx deployment" command in Mattermost
    Then the bot should provide a link to the assessment form
    And the link should be pre-populated with my user_id
    And the link should be pre-populated with task_type "deployment"

  @nasa-tlx @data-retention
  Scenario: NASA-TLX data retention policy
    Given NASA-TLX assessments are older than 90 days
    When the data retention job runs
    Then individual assessment details should be archived
    But aggregated metrics should be retained
    And users should be able to export their data on request

  @nasa-tlx @reporting
  Scenario: Generate NASA-TLX cognitive load report
    Given 30 days of NASA-TLX assessment data exists
    When I request a cognitive load report
    Then the report should include:
      | section                          |
      | Overall workload summary         |
      | Workload by task type            |
      | Most demanding dimensions        |
      | Trend analysis                   |
      | Top pain points                  |
      | Recommendations for improvements |

  @nasa-tlx @comparison
  Scenario: Compare cognitive load before and after improvements
    Given NASA-TLX data exists for "deployment" tasks from 4 weeks ago
    And a platform improvement was made 2 weeks ago
    When I compare cognitive load metrics
    Then I should see the difference in workload scores
    And I should see which dimensions improved
    And I should see statistical significance of changes
