Feature: Research Insights Dashboard
  As a product manager or researcher
  I want to view research insights metrics and trends
  So that I can understand insight validation rates, time-to-action, and category distribution

  Background:
    Given the insights service is running
    And the insights database contains research data
    And Grafana is configured with Prometheus datasource
    And Prometheus is scraping insights metrics

  @local
  Scenario: View research insights dashboard
    Given I navigate to Grafana
    When I open the "Research Insights Dashboard"
    Then I should see the dashboard with title "Research Insights Dashboard"
    And I should see the following sections:
      | Section Name              |
      | Research Insights Overview|
      | Insights by Status        |
      | Insights by Category      |
      | Validation Metrics        |
      | Tag Analytics             |
      | Trend Analysis            |

  @local
  Scenario: Overview metrics display correctly
    Given the insights service has 50 total insights
    And 35 insights are validated (published)
    And 5 insights were published in the last 7 days
    And 20 insights were published in the last 30 days
    When I view the "Research Insights Overview" section
    Then I should see "Total Research Insights" showing "50"
    And I should see "Validated Insights" showing "35"
    And I should see "Published (Last 7 Days)" showing "5"
    And I should see "Published (Last 30 Days)" showing "20"
    And I should see "Total Categories" stat
    And I should see "Total Tags" stat

  @local
  Scenario: Status distribution visualization
    Given insights exist with the following statuses:
      | Status    | Count |
      | draft     | 10    |
      | published | 35    |
      | archived  | 5     |
    When I view the "Insights by Status" section
    Then I should see a pie chart with status distribution
    And I should see "Insights Status Over Time" time series
    And the chart should show "draft" with 10 insights
    And the chart should show "published" with 35 insights
    And the chart should show "archived" with 5 insights

  @local
  Scenario: Category analytics display
    Given insights are distributed across categories:
      | Category          | Count |
      | User Experience   | 15    |
      | Platform Adoption | 12    |
      | Performance       | 10    |
      | Security          | 8     |
      | Uncategorized     | 5     |
    When I view the "Insights by Category" section
    Then I should see a bar gauge showing insights per category
    And I should see a donut chart with category distribution
    And I should be able to filter by category using the dropdown

  @local
  Scenario: Validation rate by category
    Given the "User Experience" category has 75% validation rate
    And the "Platform Adoption" category has 60% validation rate
    When I view the "Validation Metrics" section
    Then I should see "Validation Rate by Category" bar gauge
    And "User Experience" should show 75% in green
    And "Platform Adoption" should show 60% in yellow
    And I should see color thresholds:
      | Color  | Threshold |
      | Red    | < 50%     |
      | Yellow | 50-75%    |
      | Green  | ≥ 75%     |

  @local
  Scenario: Time to action metrics
    Given the "User Experience" category has average time to action of 36 hours
    And the "Performance" category has average time to action of 120 hours
    When I view the "Validation Metrics" section
    Then I should see "Time to Action (Hours)" bar gauge
    And "User Experience" should show 36 hours in green
    And "Performance" should show 120 hours in orange
    And I should see color thresholds:
      | Color  | Threshold       |
      | Green  | < 48 hours      |
      | Yellow | 48-168 hours    |
      | Orange | 168-336 hours   |
      | Red    | > 336 hours     |

  @local
  Scenario: Tag usage analytics
    Given the following tags have usage counts:
      | Tag                | Usage Count |
      | platform-adoption  | 20          |
      | user-feedback      | 18          |
      | performance        | 15          |
      | security           | 12          |
      | deployment         | 10          |
    When I view the "Tag Analytics" section
    Then I should see "Top Tags by Usage" bar gauge
    And I should see "Tag Usage Distribution" donut chart
    And "platform-adoption" should be the most used tag
    And the charts should show the top 10 tags

  @local
  Scenario: Published insights trends
    Given insights have been published over the last 30 days
    When I view the "Trend Analysis" section
    Then I should see "Published Insights Trend (7 Days)" time series
    And I should see "Published Insights Trend (30 Days)" time series
    And both charts should show smooth line interpolation
    And the trends should display historical data points

  @local
  Scenario: Dashboard auto-refresh
    Given I am viewing the Research Insights Dashboard
    When 30 seconds elapse
    Then the dashboard should auto-refresh
    And the metrics should update with latest data

  @local
  Scenario: Filter insights by category
    Given insights exist in multiple categories
    When I select "User Experience" from the category filter
    Then all panels should filter to show only "User Experience" data
    And the validation rate should show only for "User Experience"
    And the time to action should show only for "User Experience"

  @local
  Scenario: Dashboard accessible from Backstage
    Given I am logged into Backstage
    When I navigate to the Grafana component page
    Then I should see a link to "Research Insights Dashboard"
    And clicking the link should open the dashboard in a new tab
    And the dashboard should display with proper authentication

  @local
  Scenario: Metrics scraped from database
    Given the insights database has recent data updates
    When Prometheus scrapes the insights service metrics endpoint
    Then the metrics should reflect current database state
    And the metrics should be available within 30 seconds
    And the dashboard should display updated values on next refresh

  @dev @prod
  Scenario: Dashboard performance
    Given I navigate to the Research Insights Dashboard
    When the dashboard loads
    Then the page should load within 3 seconds
    And all panels should render within 5 seconds
    And queries should execute without timeout errors
