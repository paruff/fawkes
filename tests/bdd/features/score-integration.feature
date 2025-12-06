# ============================================================================
# FILE: tests/bdd/features/score-integration.feature
# PURPOSE: BDD tests for SCORE workload specification integration
# ============================================================================
Feature: SCORE Workload Specification Integration
  As a developer using the Fawkes Golden Path
  I want to define my application using the SCORE specification
  So that I can achieve workload portability and simplified configuration

  Background:
    Given the Fawkes platform is operational
    And the SCORE transformer component is deployed

  @score @workload-definition
  Scenario: Workload Definition with SCORE
    Given a developer scaffolds a new service using the Golden Path template
    When they review the generated files
    Then a score.yaml file is present
    And the score.yaml defines application parameters
    And the score.yaml defines required resource components

  @score @simplified-config
  Scenario: Simplified Configuration via SCORE
    Given a score.yaml file with memory limit of 256Mi
    When a developer modifies the containers.resources.limits.memory field to 512Mi
    Then the change is automatically reflected in the generated Deployment manifest
    And the developer does not need to modify raw Kubernetes YAML

  @score @portability
  Scenario: Portability Test - Dev to Prod
    Given a score.yaml file is created for the Dev environment
    When the score.yaml file is deployed to the Prod environment
    Then the application is successfully deployed
    And the Kubernetes manifests reference Prod-specific resources
    And the Vault address matches the Prod environment
    And the Ingress hostname matches the Prod environment

  @score @translation
  Scenario: Translation from SCORE to Kubernetes
    Given a valid score.yaml file with container and service definitions
    When the SCORE transformer processes the file
    Then a Kubernetes Deployment manifest is generated
    And a Kubernetes Service manifest is generated
    And a Kubernetes Ingress manifest is generated
    And all manifests contain the score.dev/source annotation

  @score @resources @database
  Scenario: Database Resource Provisioning
    Given a score.yaml file requesting a postgres resource
    When the SCORE transformer processes the file
    Then an ExternalSecret manifest is generated for database credentials
    And the Deployment manifest includes DATABASE_URL environment variable
    And the environment variable references the ExternalSecret

  @score @resources @cache
  Scenario: Cache Resource Provisioning
    Given a score.yaml file requesting a redis resource
    When the SCORE transformer processes the file
    Then an ExternalSecret manifest is generated for cache credentials
    And the Deployment manifest includes REDIS_URL environment variable

  @score @resources @volume
  Scenario: Volume Resource Provisioning
    Given a score.yaml file requesting a volume resource with 5Gi storage
    When the SCORE transformer processes the file
    Then a PersistentVolumeClaim manifest is generated
    And the PVC requests 5Gi of storage
    And the Deployment manifest includes a volume mount

  @score @autoscaling
  Scenario: Horizontal Pod Autoscaling via SCORE Extensions
    Given a score.yaml with autoscaling enabled in extensions.fawkes
    And minReplicas is set to 2
    And maxReplicas is set to 10
    When the SCORE transformer processes the file
    Then a HorizontalPodAutoscaler manifest is generated
    And the HPA targets the correct Deployment
    And the HPA min/max replicas match the score.yaml configuration

  @score @observability
  Scenario: Observability Annotations from SCORE
    Given a score.yaml with observability.metrics enabled in extensions.fawkes
    And the metrics port is 9090
    When the SCORE transformer processes the file
    Then the Deployment manifest includes Prometheus scrape annotations
    And the prometheus.io/port annotation is "9090"
    And the Service exposes port 9090 for metrics

  @score @security
  Scenario: Security Context from SCORE
    Given a score.yaml with security.runAsNonRoot set to true
    And security.runAsUser is set to 65534
    When the SCORE transformer processes the file
    Then the Deployment manifest includes a pod securityContext
    And the securityContext.runAsNonRoot is true
    And the securityContext.runAsUser is 65534

  @score @backwards-compatibility
  Scenario: Backwards Compatibility with Non-SCORE Applications
    Given an application repository without a score.yaml file
    And the repository contains traditional Kubernetes manifests
    When the application is deployed via the Golden Path pipeline
    Then the deployment succeeds
    And the traditional Kubernetes manifests are used
    And no SCORE transformation is attempted

  @score @validation
  Scenario: SCORE File Validation
    Given an invalid score.yaml file with missing apiVersion
    When the SCORE transformer attempts to process the file
    Then the transformation fails with a validation error
    And the error message indicates the missing apiVersion field

  @score @environment-interpolation
  Scenario: Environment Variable Interpolation
    Given a score.yaml with route.host set to "my-service.${ENVIRONMENT}.fawkes.idp"
    When the file is processed for the staging environment
    Then the generated Ingress manifest has host "my-service.staging.fawkes.idp"
    And when processed for prod environment
    Then the generated Ingress manifest has host "my-service.prod.fawkes.idp"

  @score @adr-linkage
  Scenario: ADR Documentation Linkage
    Given a consultant reads the Golden Path documentation
    When they review the section on workload portability
    Then the documentation includes a link to ADR-030
    And the ADR explains the strategic rationale for SCORE adoption
