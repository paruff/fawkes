@e2e @integration @critical
Feature: End-to-End Platform Integration Testing
  As a platform engineer
  I want to validate the complete Fawkes platform workflow
  So that I can ensure all components integrate properly from scaffold to deploy to metrics

  Background:
    Given the Fawkes platform is fully deployed
    And all core components are healthy:
      | component        | namespace          |
      | argocd           | fawkes             |
      | backstage        | fawkes             |
      | jenkins          | fawkes             |
      | prometheus       | monitoring         |
      | grafana          | monitoring         |
      | devlake          | fawkes-devlake     |
      | harbor           | fawkes             |
      | sonarqube        | fawkes             |
    And the golden path templates are available
    And no manual interventions are configured

  @scaffold @golden-path
  Scenario: Complete workflow - Scaffold new Python service
    Given I want to create a new Python microservice called "e2e-test-service"
    When I use the golden path Python template
    Then the following resources should be created:
      | resource            | location                              |
      | GitHub repository   | paruff/e2e-test-service              |
      | Jenkinsfile         | e2e-test-service/Jenkinsfile         |
      | Dockerfile          | e2e-test-service/Dockerfile          |
      | K8s manifests       | e2e-test-service/k8s/                |
      | ArgoCD app          | platform/apps/e2e-test-service/      |
      | catalog-info.yaml   | e2e-test-service/catalog-info.yaml   |
    And the repository should contain working source code
    And the Jenkinsfile should use the golden path pipeline
    And the catalog-info.yaml should be valid

  @build @cicd
  Scenario: Complete workflow - Build and test via Jenkins
    Given a scaffolded service "e2e-test-service" exists
    And the service has a Jenkinsfile using goldenPathPipeline
    When I commit code changes and push to the main branch
    Then Jenkins should automatically trigger a build
    And the build should execute these stages in order:
      | stage             | expected_result |
      | Checkout          | success         |
      | Build             | success         |
      | Unit Tests        | success         |
      | Secrets Scan      | success         |
      | SAST (SonarQube)  | success         |
      | Container Scan    | success         |
      | Docker Build      | success         |
      | Docker Push       | success         |
    And the build should complete in under 10 minutes
    And build metrics should be sent to DevLake
    And the container image should be pushed to Harbor
    And the container image should pass Trivy security scan

  @security @quality-gates
  Scenario: Complete workflow - Security scanning and quality gates
    Given a Jenkins build is running for "e2e-test-service"
    When the security scanning stages execute
    Then Gitleaks should scan for secrets and find none
    And SonarQube should analyze code quality
    And the SonarQube quality gate should pass
    And Trivy should scan the container image
    And no HIGH or CRITICAL vulnerabilities should be found
    And all security scan reports should be archived
    And security metrics should be tracked

  @deploy @gitops
  Scenario: Complete workflow - GitOps deployment via ArgoCD
    Given Jenkins has successfully built "e2e-test-service"
    And the container image is pushed to Harbor with tag "{{GIT_SHA}}"
    When Jenkins updates the GitOps repository with the new image tag
    Then ArgoCD should detect the Git repository change within 3 minutes
    And ArgoCD should sync the application "e2e-test-service-dev"
    And the sync should complete successfully
    And the application should reach "Healthy" status
    And the deployment should have 2 ready replicas
    And the service should be accessible via ingress
    And ArgoCD should send deployment event to DevLake
    And no manual intervention should be required

  @observability @metrics
  Scenario: Complete workflow - DORA metrics collection
    Given the "e2e-test-service" has been deployed via ArgoCD
    When I query DevLake for DORA metrics
    Then the following metrics should be recorded:
      | metric                     | source    | should_exist |
      | Commit timestamp           | GitHub    | true         |
      | Build start time           | Jenkins   | true         |
      | Build completion time      | Jenkins   | true         |
      | Build status               | Jenkins   | true         |
      | Quality gate status        | SonarQube | true         |
      | Deployment timestamp       | ArgoCD    | true         |
      | Deployment status          | ArgoCD    | true         |
    And I should be able to calculate "Deployment Frequency"
    And I should be able to calculate "Lead Time for Changes"
    And I should be able to calculate "Change Failure Rate"
    And metrics should be visible in Grafana dashboards

  @health @monitoring
  Scenario: Complete workflow - Application health and monitoring
    Given the "e2e-test-service" is deployed and running
    When I check the application health endpoints
    Then the "/health" endpoint should return 200 OK
    And the "/metrics" endpoint should expose Prometheus metrics
    And Prometheus should be scraping the service metrics
    And Grafana should have the service in its dashboards
    And logs should be flowing to the centralized logging system
    And distributed tracing should be capturing requests

  @catalog @backstage
  Scenario: Complete workflow - Service catalog registration
    Given the "e2e-test-service" is deployed
    When I access the Backstage developer portal
    Then the service "e2e-test-service" should be in the catalog
    And the catalog entry should show:
      | property        | value               |
      | Type            | service             |
      | Owner           | platform-team       |
      | Lifecycle       | experimental        |
      | System          | fawkes-samples      |
    And the catalog should link to the GitHub repository
    And the catalog should link to the ArgoCD application
    And the catalog should show deployment status
    And the catalog should show CI/CD pipeline status
    And TechDocs should be generated and accessible

  @cleanup @lifecycle
  Scenario: Complete workflow - Service cleanup and lifecycle
    Given the "e2e-test-service" test is complete
    When I delete the ArgoCD application
    Then all Kubernetes resources should be removed
    And the namespace should be cleaned up
    And the test should leave no residual resources
    And the platform should be ready for the next test

  @integration @all-components
  Scenario: Validate all platform components are integrated
    Given the complete platform is deployed
    Then the following integrations should be working:
      | source       | target       | integration_type | validation                    |
      | GitHub       | Jenkins      | webhook          | Push triggers build           |
      | Jenkins      | DevLake      | webhook          | Build events recorded         |
      | Jenkins      | Harbor       | api              | Images pushed successfully    |
      | Jenkins      | SonarQube    | api              | Quality analysis completed    |
      | ArgoCD       | DevLake      | webhook          | Deployment events recorded    |
      | ArgoCD       | Kubernetes   | api              | Applications synced           |
      | Backstage    | GitHub       | api              | Repositories discovered       |
      | Backstage    | ArgoCD       | api              | App status visible            |
      | Backstage    | Jenkins      | api              | Build status visible          |
      | Prometheus   | Apps         | scrape           | Metrics collected             |
      | Grafana      | Prometheus   | api              | Dashboards show data          |
      | DevLake      | Grafana      | api              | DORA metrics visualized       |

  @performance @sla
  Scenario: Platform performance meets SLA requirements
    Given the platform is handling the E2E test workflow
    Then the following performance metrics should be met:
      | metric                          | target        | measurement |
      | Build time (Python small)       | < 5 minutes   | P95         |
      | Deployment time                 | < 2 minutes   | P95         |
      | ArgoCD sync time                | < 30 seconds  | P95         |
      | GitOps drift detection          | < 3 minutes   | Maximum     |
      | Backstage catalog refresh       | < 5 minutes   | Maximum     |
      | Metrics collection latency      | < 1 minute    | P95         |
    And cluster resource utilization should be < 70%
    And no platform components should be failing

  @failure @resilience
  Scenario: Platform handles component failures gracefully
    Given the E2E test workflow is running
    When a temporary network issue occurs
    Then Jenkins should retry transient failures
    And ArgoCD should continue reconciliation
    And metrics collection should buffer events
    And the workflow should eventually complete successfully
    And error handling should be logged appropriately

  @validation @acceptance
  Scenario: All acceptance criteria met for E2E testing
    Given the E2E test suite has been executed
    Then the full workflow test (scaffold → deploy → metrics) should pass
    And all platform components should be integrated
    And no manual interventions should have been required
    And E2E test automation should be repeatable
    And test execution time should be under 20 minutes
    And test reports should be generated automatically
    And the test should clean up after itself
