# tests/bdd/features/golden-path-tekton.feature
#
# Phase 1 (#1804) golden path: the Tekton pipeline that replaced Jenkins as
# this platform's CI engine (see tests/bdd/features/archive/jenkins/ for the
# retired Jenkins-based predecessor). Scenarios here check real state on the
# live cluster - they are written to fail for the right reason when a stage
# genuinely isn't working yet, not to pass unconditionally.

@golden-path @tekton @ci @phase1
Feature: Golden Path Tekton Pipeline
  As a Platform Engineer
  I want the golden-path Tekton pipeline to build, scan, and promote commits
  So that a commit to a service repo reaches staging with basic observability and DORA data

  Background:
    Given I have kubectl configured for the "fawkes" namespace

  @smoke @infra
  Scenario: Tekton Pipelines and Triggers controllers are healthy
    When I check the tekton-pipelines-controller and tekton-triggers-controller deployments
    Then both deployments have all replicas available

  @pipeline-definition
  Scenario: The golden-path Pipeline defines the required stages in order
    When I inspect the "golden-path" Pipeline definition
    Then it defines tasks "fetch-source, lint-and-test, build-and-push, scan-image, gitops-promote" in that order
    And the "scan-image" task fails on CRITICAL or HIGH severity vulnerabilities
    And the "scan-image" task has a step timeout configured

  @proven @build-and-push
  Scenario: A completed PipelineRun has successfully built and pushed an image
    When I find the most recent "build-and-push" TaskRun for the "golden-path" pipeline
    Then it completed with reason "Succeeded"

  @webhook
  Scenario: The GitHub EventListener is reachable inside the cluster
    When I check the "github-listener" EventListener's pod
    Then the pod is Running and ready

  @end-to-end @slow
  Scenario: A fresh commit flows through build, scan, and promotion
    Given a fresh PipelineRun is triggered for the "golden-path" pipeline
    When I wait for the PipelineRun to finish
    Then the "fetch-source", "lint-and-test", "build-and-push" tasks succeed
    And the "gitops-promote" task only runs if "scan-image" succeeded
