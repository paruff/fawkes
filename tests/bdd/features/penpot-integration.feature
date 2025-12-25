Feature: Penpot Design Tool Integration
  As a designer and developer
  I want to integrate Penpot design tool with the platform
  So that I can collaborate on designs and implement them efficiently

  Background:
    Given the Fawkes platform is deployed
    And Penpot is configured in the cluster

  @design-tool @penpot @deployment
  Scenario: Penpot is deployed and accessible
    Given I check the Penpot deployment
    When I verify the Penpot pods are running
    Then the "penpot-backend" pod should be in "Running" state
    And the "penpot-frontend" pod should be in "Running" state
    And the "penpot-exporter" pod should be in "Running" state
    And the "penpot-redis" pod should be in "Running" state
    And the Penpot backend service should be available at "http://penpot-backend.fawkes.svc:6060"
    And the Penpot frontend service should be available at "http://penpot-frontend.fawkes.svc:80"

  @design-tool @penpot @database
  Scenario: Penpot database is configured
    Given the PostgreSQL cluster is running
    When I check for the Penpot database
    Then a database named "penpot" should exist
    And the database should have a user "penpot"
    And the Penpot backend should be able to connect to the database

  @design-tool @penpot @storage
  Scenario: Penpot has persistent storage configured
    Given Penpot is deployed
    When I check the storage configuration
    Then a PersistentVolumeClaim "penpot-data" should exist
    And the PVC should be bound to a volume
    And the volume should be mounted at "/opt/data" in the backend pod

  @design-tool @penpot @ingress
  Scenario: Penpot is accessible via ingress
    Given the ingress controller is deployed
    When I check the Penpot ingress configuration
    Then an ingress resource "penpot" should exist in namespace "fawkes"
    And the ingress should route "penpot.fawkes.local" to the frontend service
    And the ingress should route "penpot.fawkes.local/api" to the backend service
    And the ingress should have TLS configured

  @design-tool @backstage @plugin
  Scenario: Backstage has Penpot plugin configured
    Given Backstage is running
    When I check the Backstage configuration
    Then the app-config should include proxy endpoint "/penpot/api"
    And the proxy should target "http://penpot-backend.fawkes.svc:6060/api/"
    And the Penpot plugin ConfigMap should exist

  @design-tool @backstage @annotation
  Scenario: Components can reference Penpot designs
    Given a component exists in the Backstage catalog
    When I add the annotation "penpot.io/design-id" with value "test-project/test-file"
    Then the component metadata should include the Penpot design reference
    And developers should be able to view the design in Backstage

  @design-tool @component-mapping
  Scenario: Component mapping is configured
    Given the Penpot plugin is configured
    When I check the component mapping configuration
    Then the ConfigMap "penpot-component-mapping" should exist
    And it should contain mappings for at least 10 design system components
    And each mapping should specify a Penpot component name
    And each mapping should specify a Design System component name

  @design-tool @workflow @documentation
  Scenario: Design-to-code workflow is documented
    Given the documentation site is available
    When I navigate to the "how-to" section
    Then I should find a "design-to-code-workflow.md" document
    And it should describe the complete workflow from design to implementation
    And it should include sections for designers, developers, and QA
    And it should provide troubleshooting guidance

  @design-tool @argocd
  Scenario: Penpot is managed by ArgoCD
    Given ArgoCD is deployed
    When I check for Penpot application in ArgoCD
    Then an Application "penpot" should exist in namespace "argocd"
    And the application should be synced
    And the application health should be "Healthy"
    And the application should auto-sync on changes

  @design-tool @resources
  Scenario: Penpot resource limits are configured
    Given Penpot is deployed
    When I check the resource configuration
    Then the "penpot-backend" should have CPU limit of "1000m"
    And the "penpot-backend" should have memory limit of "2Gi"
    And the "penpot-frontend" should have CPU limit of "500m"
    And the "penpot-frontend" should have memory limit of "512Mi"
    And the "penpot-redis" should have CPU limit of "200m"
    And the "penpot-redis" should have memory limit of "256Mi"

  @design-tool @health-check
  Scenario: Penpot health checks are configured
    Given Penpot is running
    When I check the pod health probes
    Then the backend should have a liveness probe on "/api/_health"
    And the backend should have a readiness probe on "/api/_health"
    And the frontend should have a liveness probe on "/"
    And the frontend should have a readiness probe on "/"

  @design-tool @export
  Scenario: Design assets can be exported
    Given Penpot exporter service is running
    When I request an export from Penpot
    Then the exporter should be accessible at port 6061
    And it should support SVG export format
    And it should support PNG export format
    And exported assets should be stored in the persistent volume

  @design-tool @access-control
  Scenario: Access controls are configured
    Given Penpot is deployed
    When I check the authentication configuration
    Then password authentication should be enabled
    And new user registration should be enabled
    And email verification should be disabled for local development
    And the admin user should be able to manage teams and projects

  @design-tool @integration-test
  Scenario: Complete design-to-code workflow works end-to-end
    Given Penpot is accessible at "https://penpot.fawkes.local"
    And Backstage is accessible at "https://backstage.fawkes.local"
    And the Design System is accessible at "https://design-system.fawkes.local"
    When a designer creates a new design in Penpot
    And the design ID is added to a component's catalog-info.yaml
    And the component is refreshed in Backstage
    Then the design should be viewable in the component's Design tab
    And the design should match the component mapping configuration
    And developers should be able to reference the design during implementation

  @design-tool @validation
  Scenario: Design tool integration passes acceptance criteria
    Given all Penpot services are deployed and healthy
    And the Backstage plugin is configured
    And the design-to-code workflow is documented
    And component library mapping is configured
    And access controls are set up
    When I run the AT-E3-004 validation script
    Then all acceptance criteria should pass
    And the design tool should be ready for team use
