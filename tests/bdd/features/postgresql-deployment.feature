# tests/bdd/features/postgresql-deployment.feature

@database @postgresql
Feature: PostgreSQL Database Service Deployment
  As a platform engineer
  I want to deploy a highly available PostgreSQL cluster
  So that platform and application services have a reliable relational data store

  Background:
    Given I have kubectl configured for the cluster
    And the CloudNativePG Operator is installed

  @cluster-provisioning
  Scenario: Provision Focalboard database with 3 replicas
    Given the CloudNativePG Operator is running
    When a Custom Resource is applied to provision the focalboard database with 3 replicas
    Then the Operator must provision a 3-node HA cluster
    And persistent storage should be allocated for each node
    And credentials should be stored in Kubernetes Secrets

  @high-availability
  Scenario: HA failover within RTO
    Given the PostgreSQL cluster is running with 1 primary and 2 replicas
    When the primary node Pod is forcefully terminated
    Then a replica must be promoted to primary within 90 seconds
    And existing connections should be able to reconnect to the new primary

  @secure-connection
  Scenario: TLS encrypted database connection
    Given a platform application attempts to connect to the database
    When the application uses the provided connection string and credentials
    Then the connection must establish using TLS encryption
    And the SSL mode should be enforced

  @backup-restore @local
  Scenario: Database backup and restore capability
    Given a successful backup configuration is in place
    When a critical table is accidentally dropped
    Then the Platform Engineer must be able to initiate a restore
    And the database should recover to a point-in-time state

  @access-control
  Scenario: Read-only user access to replica nodes
    Given a service requires read access to the database
    When the service uses read-only credentials
    Then the service should connect only to replica nodes
    And write operations should be rejected
