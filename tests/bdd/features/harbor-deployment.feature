# tests/bdd/features/harbor-deployment.feature

@harbor @container-registry @security
Feature: Harbor Container Registry Deployment
  As a platform engineer
  I want to deploy Harbor container registry with security scanning
  So that development teams have a secure place to store and scan container images

  Background:
    Given I have kubectl configured for the cluster
    And the ingress-nginx controller is deployed and running
    And the CloudNativePG Operator is installed

  @database
  Scenario: Harbor PostgreSQL database is provisioned
    Given the CloudNativePG Operator is running
    When the Harbor database cluster is deployed
    Then the PostgreSQL cluster "db-harbor-dev" should exist in namespace "fawkes"
    And the cluster should have 3 instances
    And the database credentials secret "db-harbor-credentials" should exist

  @namespace
  Scenario: Harbor deployed in fawkes namespace
    When I check for the fawkes namespace
    Then the namespace "fawkes" should exist
    And the namespace "fawkes" should be Active

  @pods @health
  Scenario: Harbor pods are running
    Given Harbor is deployed in namespace "fawkes"
    When I check the Harbor pods
    Then the following pods should be running in namespace "fawkes":
      | component               |
      | harbor-core            |
      | harbor-portal          |
      | harbor-registry        |
      | harbor-jobservice      |
      | harbor-trivy           |
    And all Harbor pods should be in Ready state within 300 seconds

  @ui @ingress @accessibility
  Scenario: Harbor UI accessible via ingress
    Given Harbor is deployed with ingress enabled
    When I check the ingress configuration in namespace "fawkes"
    Then an ingress should exist for "harbor"
    And the ingress should have host "harbor.127.0.0.1.nip.io"
    And the ingress should use ingressClassName "nginx"
    And the Harbor UI should be accessible at "http://harbor.127.0.0.1.nip.io"

  @authentication
  Scenario: Harbor admin login
    Given Harbor UI is accessible
    When I attempt to login with admin credentials
    Then I should successfully authenticate
    And I should see the Harbor dashboard

  @security @trivy
  Scenario: Trivy scanner is enabled and functional
    Given Harbor is deployed in namespace "fawkes"
    When I check the Trivy scanner pod
    Then the pod with label "component=trivy" should be running
    And the Trivy scanner should be registered in Harbor

  @projects
  Scenario: Default projects are created
    Given Harbor is deployed and accessible
    When I query Harbor API for projects
    Then the "library" project should exist
    And the project should be publicly accessible for reading

  @image-push
  Scenario: Push container image to Harbor
    Given Harbor is deployed and accessible
    And I am logged in with Docker CLI
    When I tag a test image "hello-world:latest" as "harbor.127.0.0.1.nip.io/library/hello-world:test"
    And I push the image to Harbor
    Then the image should be successfully pushed
    And the image should be visible in the Harbor UI
    And the image should be automatically scanned by Trivy

  @image-scan
  Scenario: Automatic vulnerability scanning on push
    Given Harbor is deployed with Trivy enabled
    And a container image is pushed to Harbor
    When I query the scan results via Harbor API
    Then the scan results should show vulnerability counts
    And the scan should have completed status

  @robot-account
  Scenario: Create robot account for CI/CD
    Given Harbor is deployed and accessible
    And I am logged in as admin
    When I create a robot account "robot$cicd" with push/pull permissions
    Then the robot account should be created
    And I should receive a token for authentication
    And the robot account should be able to push images

  @monitoring
  Scenario: Harbor metrics exposed for Prometheus
    Given Harbor is deployed in namespace "fawkes"
    When I check for ServiceMonitor resources
    Then a ServiceMonitor for Harbor should exist
    And Prometheus should be scraping Harbor metrics

  @redis @cache
  Scenario: Redis cache is functional
    Given Harbor is deployed with internal Redis
    When I check Redis pod status in namespace "fawkes"
    Then the Redis pod should be running
    And Harbor core should be able to connect to Redis

  @persistence
  Scenario: Harbor persistent storage is configured
    Given Harbor is deployed in namespace "fawkes"
    When I check the PersistentVolumeClaims
    Then PVCs should exist for:
      | component               |
      | harbor-registry        |
      | harbor-jobservice      |
      | harbor-trivy           |
    And all PVCs should be Bound

  @replication @future
  Scenario: Harbor replication capability (future)
    Given Harbor is deployed and accessible
    When I configure a replication policy
    Then Harbor should support multi-registry replication
    And artifacts should be replicated to target registry

  @api
  Scenario: Harbor REST API is functional
    Given Harbor is deployed and accessible
    When I query the Harbor API endpoint "/api/v2.0/systeminfo"
    Then I should receive a valid JSON response
    And the response should contain Harbor version information
