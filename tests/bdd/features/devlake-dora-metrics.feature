# tests/bdd/features/devlake-dora-metrics.feature

@devlake @dora @observability @analytics
Feature: DevLake DORA Metrics Visualization
  As an Application Developer
  I want to view the five DORA metrics live in the Developer Portal
  So that I can quickly assess my service's performance and identify bottlenecks

  Background:
    Given I have kubectl configured for the cluster
    And the DevLake application is deployed in the fawkes-devlake namespace
    And ArgoCD is configured as the primary deployment source

  # ============================================================
  # Acceptance Criteria: Data Ingestion
  # ============================================================
  @data-ingestion @argocd
  Scenario: Data Ingestion from ArgoCD
    Given the ArgoCD collector is configured and running
    And GitHub collector is configured for commit data
    When a new application sync event occurs in ArgoCD
    Then DevLake successfully ingests the sync event
    And the raw data is stored in the metrics database
    And the deployment is correlated with the source commit

  @data-ingestion @jenkins
  Scenario: CI Build Data Ingestion from Jenkins
    Given the Jenkins collector is configured and running
    When a Golden Path pipeline completes a build
    Then DevLake successfully ingests the build event
    And the build metrics are stored for rework analysis

  @data-ingestion @incidents
  Scenario: Incident Data Ingestion from Observability
    Given the incident webhook is configured
    When an alert fires in the observability platform
    Then DevLake receives the incident event via webhook
    And the incident is stored for CFR and MTTR calculation

  # ============================================================
  # Acceptance Criteria: Metric 1 - Deployment Frequency
  # ============================================================
  @deployment-frequency @dora-metric
  Scenario: Deployment Frequency Calculation
    Given DevLake has ingested 10 successful ArgoCD sync events for Service A over 7 days
    When an Application Developer views the DevLake dashboard for Service A
    Then the Deployment Frequency metric is calculated as approximately 1.43 deployments per day
    And the metric rating is displayed based on DORA benchmarks

  @deployment-frequency @empty-data
  Scenario: Deployment Frequency with No Deployments
    Given DevLake has no deployment records for Service B
    When an Application Developer views the DevLake dashboard for Service B
    Then the Deployment Frequency metric displays "N/A"
    And no error is shown to the user

  # ============================================================
  # Acceptance Criteria: Metric 2 - Lead Time for Changes
  # ============================================================
  @lead-time @dora-metric
  Scenario: Lead Time for Changes Calculation
    Given DevLake correlates a commit timestamp with its ArgoCD sync completion
    And the commit was made at 09:00 and deployed at 13:15
    When an Application Developer views the Lead Time for Changes metric
    Then the Lead Time is calculated and displayed as "4 hours 15 minutes"
    And the metric rating reflects DORA performance level

  @lead-time @multi-commit
  Scenario: Lead Time with Multiple Commits
    Given a deployment contains commits from 3 different developers
    When an Application Developer views the Lead Time for Changes
    Then the Lead Time is calculated from the first commit in the deployment
    And individual commit lead times are available for drill-down

  # ============================================================
  # Acceptance Criteria: Metrics 3 & 4 - CFR and MTTR
  # ============================================================
  @cfr @dora-metric
  Scenario: Change Failure Rate Calculation
    Given DevLake has recorded 20 ArgoCD syncs in the past 30 days
    And 2 syncs resulted in production incidents
    When an Application Developer views the Change Failure Rate metric
    Then the CFR is calculated and displayed as 10%
    And the metric rating indicates "High" performer level

  @mttr @dora-metric
  Scenario: Mean Time to Restore Calculation
    Given a production incident was created at 14:00
    And a successful restore ArgoCD sync occurred at 14:45
    When an Application Developer views the MTTR metric
    Then the incident contributes 45 minutes to the MTTR calculation
    And the overall MTTR reflects all resolved incidents

  @cfr-mttr @incident-lifecycle
  Scenario: Incident Lifecycle Tracking
    Given a deployment fails in production creating a CFR event
    When a subsequent successful restore deployment is recorded
    Then the Change Failure Rate is updated to include the failure
    And the Mean Time to Restore is updated with the resolution time

  # ============================================================
  # Acceptance Criteria: Metric 5 - Operational Performance
  # ============================================================
  @operational-performance @dora-metric
  Scenario: Operational Performance Display
    Given Application A has a 99.9% uptime SLO
    And real-time health data shows 99.95% availability
    When an Application Developer views the expanded DORA report
    Then the Operational Performance metric shows current SLO adherence
    And P99 latency and error rate metrics are visible

  # ============================================================
  # Visualization and Access
  # ============================================================
  @grafana @dashboards
  Scenario: DORA Dashboard Access
    Given the DevLake Grafana dashboards are deployed
    When a developer navigates to the DORA Overview dashboard
    Then all five DORA metrics are visible on a single page
    And metrics can be filtered by team and time range
    And drill-down links are available for each metric

  @grafana @dashboards @team-filtering
  Scenario: Team-level Filtering in DORA Dashboard
    Given the DevLake Grafana dashboards are deployed
    And multiple teams have deployment data
    When a developer selects a specific team filter
    Then only metrics for the selected team are displayed
    And service dropdown is filtered to show only services from that team
    And 30-day trending data is visible by default

  @grafana @dashboards @benchmarks
  Scenario: DORA Benchmark Comparison
    Given the DevLake Grafana dashboards are deployed
    When a developer views the DORA dashboard
    Then a benchmark comparison panel is visible
    And current metric values are compared against DORA performance levels
    And Elite, High, Medium, and Low benchmark thresholds are displayed
    And the dashboard shows performance improvement recommendations

  @backstage @integration
  Scenario: Backstage Developer Portal Integration
    Given the DevLake plugin is configured in Backstage
    And a service has DevLake annotations in its catalog-info.yaml
    When a developer views the service entity page
    Then a "DORA Metrics" tab is visible
    And the five metrics are displayed with performance ratings
    And a link to the full Grafana dashboard is available

  # ============================================================
  # Jenkins CI Rework Metrics (Complementary)
  # ============================================================
  @jenkins @rework-metrics
  Scenario: CI Rework Metrics Display
    Given Jenkins has recorded build events for Service C
    And 5 out of 50 builds were retries of the same commit
    When a developer views the CI metrics dashboard
    Then the Rework Rate is displayed as 10%
    And Build Success Rate and Quality Gate Pass Rate are visible

  @jenkins @quality-gate
  Scenario: Quality Gate Tracking
    Given Jenkins records SonarQube quality gate results
    When a developer views the quality metrics
    Then the Quality Gate Pass Rate trend is displayed
    And failed quality gates are linked to SonarQube reports

  # ============================================================
  # Edge Cases and Error Handling
  # ============================================================
  @edge-case @graceful-degradation
  Scenario: Graceful Handling of Missing Data Sources
    Given the GitHub collector is temporarily unavailable
    When a developer views the DORA dashboard
    Then available metrics are still displayed
    And a warning indicates which data source is unavailable
    And last known values are shown with a staleness indicator

  @edge-case @high-cardinality
  Scenario: Performance with Many Services
    Given DevLake tracks 100+ services across 20 teams
    When a developer loads the DORA dashboard
    Then the page loads within 3 seconds
    And pagination is available for large result sets
    And team-level filtering reduces data volume
