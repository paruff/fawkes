# tests/bdd/features/datahub-deployment.feature

@datahub @data-catalog @data-platform
Feature: DataHub Data Catalog Deployment
  As a platform engineer
  I want to deploy DataHub as the centralized data catalog and lineage tracking system
  So that teams can discover, understand, and govern all data assets across the platform

  Background:
    Given I have kubectl configured for the cluster
    And the PostgreSQL Operator is installed and running
    And the DataHub PostgreSQL database cluster is deployed
    And OpenSearch is deployed and accessible

  @service-deployment @access @AT-E2-003
  Scenario: Service Deployment & Access
    Given the platform is healthy
    When the DataHub deployment is applied
    Then the DataHub GMS service must be accessible
    And the DataHub Frontend service must be accessible via the platform URL
    And the service must return a successful HTTP 200 status

  @api-health @graphql
  Scenario: GraphQL API Health
    Given DataHub is deployed and running
    When I query the GraphQL health endpoint
    Then the API must return a valid response
    And the response must indicate the service is healthy

  @metadata-storage @postgresql
  Scenario: Metadata Storage with PostgreSQL
    Given DataHub is deployed and running
    When metadata is ingested into DataHub
    Then the metadata must be stored in the PostgreSQL database
    And the metadata must be retrievable via the API

  @search-indexing @opensearch
  Scenario: Search Indexing with OpenSearch
    Given DataHub is deployed and running
    And metadata has been ingested
    When I perform a search query through the UI
    Then OpenSearch must return relevant results
    And the results must be displayed in the DataHub UI

  @ingestion @postgres-connector
  Scenario: PostgreSQL Metadata Ingestion
    Given DataHub is deployed and running
    And a PostgreSQL database with tables exists
    When I run the PostgreSQL ingestion recipe
    Then the database schema must be ingested successfully
    And tables must be visible in the DataHub UI
    And columns and data types must be captured correctly

  @authentication @basic-auth
  Scenario: Basic Authentication (MVP)
    Given DataHub is deployed with basic authentication
    When a user accesses the DataHub URL
    Then they must be able to log in with default credentials
    And they should see the DataHub home page

  @lineage @data-flow
  Scenario: Data Lineage Visualization
    Given DataHub is deployed and running
    And metadata with lineage information has been ingested
    When I navigate to a dataset in the UI
    Then I must see the lineage tab
    And the lineage graph must show upstream and downstream dependencies

  @resource-limits @stability
  Scenario: Resource Allocation and Stability
    Given DataHub is deployed
    When I check the deployment resource specifications
    Then the GMS deployment must specify resource requests and limits
    And the Frontend deployment must specify resource requests and limits
    And the deployments should target 70% resource utilization

  @monitoring @metrics
  Scenario: Prometheus Metrics Exposure
    Given DataHub is deployed and running
    When Prometheus scrapes the DataHub metrics endpoints
    Then the DataHub metrics should be collected successfully
    And they should be available in Grafana dashboards

  @high-availability @postgresql
  Scenario: PostgreSQL High Availability
    Given DataHub is deployed with PostgreSQL backend
    When I check the PostgreSQL cluster configuration
    Then the cluster must have at least 3 instances
    And the cluster must support automatic failover
    And the cluster must have read-write and read-only services

  @data-governance @tags
  Scenario: Data Governance with Tags
    Given DataHub is deployed and running
    And a dataset exists in the catalog
    When I add tags like "PII" and "Critical" to the dataset
    Then the tags must be saved successfully
    And I must be able to search for datasets by tag

  @api-integration @rest
  Scenario: REST API Integration
    Given DataHub is deployed and running
    When I send a POST request to the metadata ingestion endpoint
    Then the API must accept the metadata
    And the metadata must be stored and searchable
    And the API must return a success status code

  @ui-navigation @search
  Scenario: UI Search and Discovery
    Given DataHub is deployed and running
    And multiple datasets have been ingested
    When I search for a dataset by name in the UI
    Then the search must return relevant results
    And I must be able to navigate to the dataset details page
    And I must see the schema, description, and other metadata

  @ingestion-automation @cronjobs @AT-E2-003
  Scenario: Automated Metadata Ingestion
    Given DataHub is deployed and running
    When I check for ingestion CronJobs
    Then the PostgreSQL ingestion CronJob must exist with daily schedule
    And the Kubernetes ingestion CronJob must exist with hourly schedule
    And the Git/CI ingestion CronJob must exist with 6-hour schedule
    And all CronJobs must have proper RBAC configuration
    And ingestion credentials must be configured in Secrets

  @ingestion-postgres @metadata-extraction
  Scenario: PostgreSQL Metadata Ingestion
    Given DataHub is deployed and running
    And PostgreSQL databases exist (Backstage, Harbor, SonarQube)
    When the PostgreSQL ingestion job runs
    Then database schemas must be ingested into DataHub
    And table metadata must be visible in the UI
    And column definitions and data types must be captured
    And relationships between tables must be extracted

  @ingestion-kubernetes @resource-tracking
  Scenario: Kubernetes Resources Ingestion
    Given DataHub is deployed and running
    And Kubernetes resources exist in platform namespaces
    When the Kubernetes ingestion job runs
    Then Deployments, Services, and ConfigMaps must be ingested
    And ownership annotations must be extracted and linked to Backstage
    And resource relationships must be tracked
    And Kubernetes resources must be searchable in DataHub

  @ingestion-git-ci @pipeline-lineage
  Scenario: GitHub and Jenkins Metadata Ingestion
    Given DataHub is deployed and running
    And GitHub repositories and Jenkins jobs exist
    When the Git/CI ingestion job runs
    Then GitHub repositories must be ingested with branches and commits
    And Jenkins jobs must be ingested with build history
    And pipeline lineage must link jobs to repositories
    And DORA metrics data must be extracted from builds

  @metadata-lineage @end-to-end
  Scenario: End-to-End Metadata Lineage Visibility
    Given DataHub is deployed and running
    And all ingestion jobs have completed successfully
    When I navigate to a service in the DataHub UI
    Then I must see lineage showing:
      | Source Type | Example |
      | Database Tables | PostgreSQL tables used by the service |
      | GitHub Repository | Source code repository |
      | Jenkins Pipeline | CI/CD pipeline that builds the service |
      | Container Image | Docker image in Harbor registry |
      | Kubernetes Resources | Deployment and Service in K8s |
    And the lineage graph must show upstream and downstream dependencies
    And I must be able to navigate between related entities
