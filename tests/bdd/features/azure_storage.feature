# tests/bdd/features/azure_storage.feature

@smoke @azure @storage @white-belt
Feature: Azure Persistent Storage Configuration (AT-E1-003)
  As a platform engineer
  I want to configure Azure persistent storage with Disk and Files
  So that applications can reliably store and access data

  Background:
    Given an AKS cluster exists in Azure
    And kubectl is configured for the cluster
    And the storage manifests are applied

  @dora-deployment-frequency @AT-E1-003
  Scenario: Storage classes are configured and available
    When I run "kubectl get storageclass"
    Then the output should contain "azure-disk-premium"
    And the output should contain "azure-disk-standard"
    And the output should contain "azure-file"
    And "azure-disk-premium" should be the default storage class

  @AT-E1-003
  Scenario: Azure Disk Premium StorageClass configuration
    When I inspect the "azure-disk-premium" storage class
    Then it should use provisioner "disk.csi.azure.com"
    And it should have parameter "skuName" set to "Premium_LRS"
    And it should have parameter "cachingMode" set to "ReadOnly"
    And volume expansion should be enabled
    And reclaim policy should be "Delete"
    And volume binding mode should be "WaitForFirstConsumer"

  @AT-E1-003
  Scenario: Azure Disk Standard StorageClass configuration
    When I inspect the "azure-disk-standard" storage class
    Then it should use provisioner "disk.csi.azure.com"
    And it should have parameter "skuName" set to "StandardSSD_LRS"
    And volume expansion should be enabled
    And reclaim policy should be "Delete"
    And volume binding mode should be "WaitForFirstConsumer"

  @AT-E1-003
  Scenario: Azure Files StorageClass configuration
    When I inspect the "azure-file" storage class
    Then it should use provisioner "file.csi.azure.com"
    And it should have parameter "skuName" set to "Standard_LRS"
    And it should have parameter "protocol" set to "smb"
    And volume expansion should be enabled
    And reclaim policy should be "Delete"
    And volume binding mode should be "Immediate"

  @AT-E1-003
  Scenario: Create and bind PVC with Premium Disk
    Given I apply the test manifests from "tests/integration/azure-storage-test.yaml"
    When I create a PVC named "test-azure-disk-premium" in namespace "storage-test"
    Then the PVC should be bound within 5 minutes
    And a PersistentVolume should be provisioned
    And the volume should be an Azure Premium Disk

  @AT-E1-003
  Scenario: Create and bind PVC with Standard Disk
    Given I apply the test manifests from "tests/integration/azure-storage-test.yaml"
    When I create a PVC named "test-azure-disk-standard" in namespace "storage-test"
    Then the PVC should be bound within 5 minutes
    And a PersistentVolume should be provisioned
    And the volume should be an Azure Standard Disk

  @AT-E1-003
  Scenario: Create and bind PVC with Azure Files
    Given I apply the test manifests from "tests/integration/azure-storage-test.yaml"
    When I create a PVC named "test-azure-file" in namespace "storage-test"
    Then the PVC should be bound within 5 minutes
    And a PersistentVolume should be provisioned
    And the volume should be an Azure File Share

  @AT-E1-003
  Scenario: Write and read data from Premium Disk
    Given I apply the test manifests from "tests/integration/azure-storage-test.yaml"
    And the PVC "test-azure-disk-premium" is bound
    When pod "test-disk-premium-writer" writes data to the volume
    And I wait for the pod to complete
    Then I should be able to read the data from the volume
    And the data should match what was written

  @AT-E1-003
  Scenario: Write and read data from Standard Disk
    Given I apply the test manifests from "tests/integration/azure-storage-test.yaml"
    And the PVC "test-azure-disk-standard" is bound
    When pod "test-disk-standard-writer" writes data to the volume
    And I wait for the pod to complete
    Then I should be able to read the data from the volume
    And the data should match what was written

  @AT-E1-003
  Scenario: Multiple pods can access Azure Files simultaneously (ReadWriteMany)
    Given I apply the test manifests from "tests/integration/azure-storage-test.yaml"
    And the PVC "test-azure-file" is bound
    When pod "test-file-writer-1" writes data to the volume
    And pod "test-file-writer-2" writes data to the volume
    Then both pods should be able to write simultaneously
    And both pods should see each other's files

  @AT-E1-003
  Scenario: Volume expansion works for Premium Disk
    Given I apply the test manifests from "tests/integration/azure-storage-test.yaml"
    And the PVC "test-azure-disk-premium" is bound with size "5Gi"
    When I expand the PVC to "10Gi"
    Then the PVC capacity should be updated to "10Gi" within 5 minutes
    And the file system should be resized automatically
    And the pod should have access to the expanded storage

  @AT-E1-003
  Scenario: Volume expansion works for Azure Files
    Given I apply the test manifests from "tests/integration/azure-storage-test.yaml"
    And the PVC "test-azure-file" is bound with size "10Gi"
    When I expand the PVC to "20Gi"
    Then the PVC capacity should be updated to "20Gi" within 5 minutes
    And all pods mounting the share should see the expanded storage

  @AT-E1-003
  Scenario: Volume snapshot can be created from Premium Disk
    Given I apply the test manifests from "tests/integration/azure-storage-test.yaml"
    And the PVC "test-azure-disk-premium" has data written to it
    When I create a VolumeSnapshot named "test-disk-premium-snapshot"
    Then the snapshot should become ready within 5 minutes
    And the snapshot should contain the data from the PVC

  @AT-E1-003
  Scenario: Volume can be restored from snapshot
    Given I apply the test manifests from "tests/integration/azure-storage-test.yaml"
    And a VolumeSnapshot "test-disk-premium-snapshot" exists
    When I create a new PVC "test-disk-premium-restored" from the snapshot
    Then the new PVC should be bound within 5 minutes
    And the restored volume should contain the original data

  @AT-E1-003 @performance
  Scenario: Premium Disk has acceptable performance
    Given I apply the test manifests from "tests/integration/azure-storage-test.yaml"
    And the PVC "test-azure-disk-premium" is bound
    When I run a sequential write test with 1GB of data
    Then the throughput should be at least 50 MB/s
    And the write should complete within 30 seconds

  @AT-E1-003 @performance
  Scenario: Standard Disk has acceptable performance
    Given I apply the test manifests from "tests/integration/azure-storage-test.yaml"
    And the PVC "test-azure-disk-standard" is bound
    When I run a sequential write test with 500MB of data
    Then the throughput should be at least 20 MB/s
    And the write should complete within 30 seconds

  @AT-E1-003
  Scenario: Azure Backup is configured
    Given I have access to the Azure subscription
    When I check the Recovery Services vault
    Then a vault named "<cluster-name>-backup-vault" should exist
    And a backup policy for daily backups should be configured
    And the policy should retain 7 daily backups
    And the policy should retain 4 weekly backups

  @AT-E1-003
  Scenario: Backup policies are applied to tagged volumes
    Given a PVC with backup tag "backup=enabled" exists
    When I check the backup configuration in Azure
    Then the underlying disk should be protected by backup policy
    And backup jobs should run according to schedule

  @AT-E1-003
  Scenario: Backup alerts are configured
    When I check the Azure Monitor configuration
    Then an action group for backup alerts should exist
    And a metric alert for backup failures should be configured
    And the alert should send notifications to the platform team

  @AT-E1-003
  Scenario: Storage classes have appropriate tags for backup
    When I inspect the storage class configurations
    Then each storage class should include tag "backup=enabled"
    And each storage class should include tag "platform=fawkes"
    And each storage class should include tag "managed-by=kubernetes"

  @AT-E1-003 @cleanup
  Scenario: Cleanup test resources
    Given test resources exist in namespace "storage-test"
    When I run the cleanup script
    Then all test PVCs should be deleted
    And all test pods should be deleted
    And the namespace "storage-test" should be deleted
    And the underlying Azure resources should be cleaned up

  @cost-optimization
  Scenario: Storage costs are acceptable
    Given storage classes are deployed
    When I estimate the cost of 100GB Premium SSD
    Then the monthly cost should be documented
    And cost optimization recommendations should be provided

  @disaster-recovery
  Scenario: Storage backup and recovery is documented
    When I check the storage documentation
    Then it should explain how to create snapshots
    And it should explain how to restore from snapshots
    And it should document the backup retention policy
    And it should provide examples of disaster recovery procedures
