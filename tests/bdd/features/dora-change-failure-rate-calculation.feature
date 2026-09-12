# tests/bdd/features/dora-change-failure-rate-calculation.feature
#
# #1947: Change Failure Rate calculation verified against known fixture
# deployment+incident data, deterministic and independent of any live
# cluster or DevLake instance.
#
# A CFR scenario already exists in devlake-dora-metrics.feature, but that
# feature's Background ("Given I have kubectl configured for the cluster")
# skips ALL of its scenarios - including that deterministic one - whenever
# no live cluster is reachable, which defeats the point of a fixture-based
# test. This file is deliberately separate and Background-free so it
# always runs, matching #1947's explicit "don't test this against a live
# DevLake instance" instruction.

@dora @cfr @dora-metric
Feature: DORA Change Failure Rate calculation from fixture data
  As a platform engineer
  I want the Change Failure Rate formula verified against known inputs
  So that the metric can be trusted once real deployment/incident data flows in

  Scenario: Change Failure Rate with some failed deployments
    Given 20 deployments were recorded in the reporting window
    And 2 of those deployments were followed by a production incident
    When the Change Failure Rate is calculated
    Then the Change Failure Rate is 10.0%

  Scenario: Change Failure Rate with no failed deployments
    Given 15 deployments were recorded in the reporting window
    And 0 of those deployments were followed by a production incident
    When the Change Failure Rate is calculated
    Then the Change Failure Rate is 0.0%

  Scenario: Change Failure Rate with every deployment failing
    Given 4 deployments were recorded in the reporting window
    And 4 of those deployments were followed by a production incident
    When the Change Failure Rate is calculated
    Then the Change Failure Rate is 100.0%

  Scenario: Change Failure Rate with zero deployments in the window
    Given 0 deployments were recorded in the reporting window
    And 0 of those deployments were followed by a production incident
    When the Change Failure Rate is calculated
    Then the Change Failure Rate calculation reports "no data" instead of a divide-by-zero result
