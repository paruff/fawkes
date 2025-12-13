# tests/bdd/features/azure_aks_provisioning.feature

@smoke @azure @white-belt
Feature: Azure AKS Infrastructure Provisioning (AT-E1-001)
  As a platform engineer
  I want to provision Azure AKS infrastructure with one command
  So that I can quickly set up the Fawkes platform on Azure

  Background:
    Given I have Azure CLI installed
    And I have Terraform installed
    And I have authenticated to Azure

  @dora-deployment-frequency @AT-E1-001
  Scenario: Provision Azure AKS cluster with Terraform
    Given I have Azure credentials configured
    And I am in the repository root directory
    When I run "terraform -chdir=infra/azure init"
    And I run "terraform -chdir=infra/azure validate"
    Then the Terraform validation should succeed
    And the configuration should include:
      | Component            |
      | Resource Group       |
      | Virtual Network      |
      | AKS Cluster          |
      | Container Registry   |
      | Key Vault            |
      | Storage Account      |
      | Log Analytics        |

  @dora-deployment-frequency @AT-E1-001
  Scenario: Deploy AKS cluster via ignite script
    Given I have Azure credentials configured
    And I have configured terraform.tfvars with unique names
    When I run "./scripts/ignite.sh --provider azure --only-cluster dev"
    Then the script completes successfully within 30 minutes
    And an AKS cluster named "fawkes-aks" is created
    And the cluster has at least 2 worker nodes
    And kubectl can connect to the cluster

  @AT-E1-001
  Scenario: Verify AKS cluster configuration
    Given an AKS cluster exists in Azure
    And kubectl is configured for the cluster
    When I check the cluster status
    Then all nodes should be in Ready state
    And the system node pool should have 2 nodes
    And the user node pool should have auto-scaling enabled
    And the cluster should use Azure CNI networking
    And the cluster should have managed identity enabled
    And Azure Monitor should be integrated

  @AT-E1-001
  Scenario: Verify Azure resource integrations
    Given an AKS cluster exists in Azure
    When I check Azure Container Registry integration
    Then the AKS cluster should have AcrPull role assigned
    When I check Key Vault integration
    Then the AKS cluster should have access to the Key Vault
    When I check Storage Account
    Then the Terraform state container should exist
    When I check Log Analytics
    Then the AKS cluster should be sending logs

  @AT-E1-001
  Scenario: Run InSpec compliance tests
    Given an AKS cluster exists in Azure
    And I have InSpec installed with azure plugin
    When I run "inspec exec infra/azure/inspec/ -t azure://"
    Then all critical InSpec controls should pass
    And the cluster should meet AT-E1-001 acceptance criteria

  @cost-optimization
  Scenario: Estimate Azure infrastructure costs
    Given I am in the repository root directory
    When I run "./scripts/azure-cost-estimate.sh"
    Then the script should complete successfully
    And the estimated monthly cost should be displayed
    And cost optimization suggestions should be provided if over budget

  @infrastructure @networking
  Scenario: Verify network configuration
    Given an AKS cluster exists in Azure
    When I check the network configuration
    Then the VNet should have address space "10.0.0.0/16"
    And the AKS subnet should have address prefix "10.0.1.0/24"
    And the service CIDR should be "10.1.0.0/16"
    And network policy should be enabled

  @infrastructure @security
  Scenario: Verify security configuration
    Given an AKS cluster exists in Azure
    When I check the security configuration
    Then RBAC should be enabled
    And Azure AD integration should be configured
    And managed identity should be in use
    And the cluster should not use service principals

  @infrastructure @monitoring
  Scenario: Verify monitoring and logging
    Given an AKS cluster exists in Azure
    When I check the monitoring configuration
    Then Azure Monitor should be enabled
    And Log Analytics workspace should exist
    And container insights should be collecting metrics
    And logs should be retained for at least 7 days

  @disaster-recovery
  Scenario: Verify backup and recovery capabilities
    Given an AKS cluster exists in Azure
    When I check the backup configuration
    Then Terraform state should be stored in Azure Storage
    And volume snapshots should be configured
    And all infrastructure should be defined as code in Git
