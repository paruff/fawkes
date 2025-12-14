Feature: TechDocs Plugin in Backstage
  As a developer
  I want to view documentation in Backstage using TechDocs
  So that I can easily access and maintain documentation as code

  Background:
    Given Backstage is deployed with TechDocs plugin enabled
    And the catalog contains entities with techdocs-ref annotations

  @techdocs @plugin
  Scenario: TechDocs plugin is enabled in Backstage
    Given I have access to the Backstage app-config.yaml
    When I check the TechDocs configuration
    Then the TechDocs builder should be set to "local"
    And the TechDocs generator should be configured to run "local"
    And the TechDocs publisher should be set to "local"
    And the publish directory should be "/app/techdocs"

  @techdocs @volume
  Scenario: TechDocs volume is mounted in Backstage pods
    Given Backstage pods are running in the cluster
    When I check the Backstage deployment configuration
    Then the deployment should have a "techdocs" volume
    And the volume should be mounted at "/app/techdocs"
    And the volume should be writable

  @techdocs @catalog
  Scenario: Catalog entities have TechDocs annotations
    Given the Fawkes platform catalog is loaded
    When I check the Backstage component in the catalog
    Then it should have the annotation "backstage.io/techdocs-ref"
    And the annotation value should be "dir:./docs"

  @techdocs @template
  Scenario: Service templates include documentation structure
    Given I have the Python service template
    When I check the template skeleton
    Then it should contain a "mkdocs.yml" file
    And it should contain a "docs" directory
    And the docs directory should contain "index.md"
    And the docs directory should contain "getting-started.md"
    And the docs directory should contain "api.md"
    And the docs directory should contain "development.md"

  @techdocs @template
  Scenario: Template catalog-info includes TechDocs annotation
    Given I have a service template skeleton
    When I check the catalog-info.yaml in the skeleton
    Then it should have the annotation "backstage.io/techdocs-ref"
    And the annotation should point to "dir:."

  @techdocs @rendering
  Scenario: TechDocs can generate documentation from mkdocs
    Given a service repository with mkdocs.yml and docs directory
    And the repository is registered in the Backstage catalog
    When TechDocs processes the documentation
    Then the documentation should be generated successfully
    And the generated docs should be stored in /app/techdocs
    And the docs should be accessible via the Backstage UI

  @techdocs @ui
  Scenario: Documentation is accessible in Backstage UI
    Given I am logged into Backstage
    And the Fawkes platform component exists in the catalog
    When I navigate to the component's documentation tab
    Then I should see the rendered documentation
    And the documentation should have proper navigation
    And images and links should work correctly

  @techdocs @templates @integration
  Scenario: New service created from template has working TechDocs
    Given I use the Python service template to create a new service
    When the service is scaffolded and registered in the catalog
    Then the service should have documentation files
    And the documentation should be viewable in Backstage
    And the documentation should render without errors

  @techdocs @validation
  Scenario: TechDocs configuration is validated at deployment
    Given I am deploying Backstage with TechDocs enabled
    When the Backstage pods start
    Then the TechDocs backend plugin should load successfully
    And the logs should not contain TechDocs errors
    And the health check should pass
