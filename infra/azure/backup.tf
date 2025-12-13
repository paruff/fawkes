# ============================================================================
# FILE: infra/azure/backup.tf
# PURPOSE: Azure Backup configuration for persistent volumes
#          Provides automated backup and recovery for AKS persistent storage
# ============================================================================

# Recovery Services Vault for backup storage
resource "azurerm_recovery_services_vault" "aks_backup" {
  name                = "${var.cluster_name}-backup-vault"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku                 = "Standard"
  
  # Soft delete retention (7-90 days)
  soft_delete_enabled = true
  
  tags = merge(var.tags, {
    component = "backup"
    purpose   = "persistent-volume-backup"
  })
}

# Backup policy for daily backups with retention
resource "azurerm_backup_policy_vm" "daily_backup" {
  name                = "${var.cluster_name}-daily-backup-policy"
  resource_group_name = azurerm_resource_group.aks_rg.name
  recovery_vault_name = azurerm_recovery_services_vault.aks_backup.name

  # Time zone for backup schedule
  timezone = var.backup_timezone

  # Daily backup at specified time
  backup {
    frequency = "Daily"
    time      = var.backup_time
  }

  # Retention policy for daily backups
  retention_daily {
    count = var.backup_retention_daily
  }

  # Weekly retention
  retention_weekly {
    count    = var.backup_retention_weekly
    weekdays = ["Sunday"]
  }

  # Monthly retention (optional, commented out by default)
  # retention_monthly {
  #   count    = 12
  #   weekdays = ["Sunday"]
  #   weeks    = ["First"]
  # }
}

# Disk snapshot backup policy for managed disks
resource "azurerm_data_protection_backup_policy_disk" "disk_backup_policy" {
  name     = "${var.cluster_name}-disk-backup-policy"
  vault_id = azurerm_data_protection_backup_vault.disk_backup_vault.id

  # Backup schedule - every 4 hours
  backup_repeating_time_intervals = ["R/2023-05-01T00:00:00+00:00/PT4H"]

  # Retention rules
  default_retention_duration = "P7D"

  retention_rule {
    name     = "Daily"
    duration = "P7D"
    priority = 25
    criteria {
      absolute_criteria = "FirstOfDay"
    }
  }

  retention_rule {
    name     = "Weekly"
    duration = "P4W"
    priority = 20
    criteria {
      absolute_criteria = "FirstOfWeek"
    }
  }
}

# Data Protection Backup Vault for disk backups
resource "azurerm_data_protection_backup_vault" "disk_backup_vault" {
  name                = "${var.cluster_name}-disk-backup-vault"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  datastore_type      = "VaultStore"
  redundancy          = var.backup_storage_redundancy

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    component = "backup"
    purpose   = "disk-snapshot-backup"
  })
}

# Role assignment for backup vault to read disks
resource "azurerm_role_assignment" "backup_vault_disk_reader" {
  scope                = azurerm_resource_group.aks_rg.id
  role_definition_name = "Disk Backup Reader"
  principal_id         = azurerm_data_protection_backup_vault.disk_backup_vault.identity[0].principal_id
}

# Role assignment for backup vault to create snapshots
resource "azurerm_role_assignment" "backup_vault_disk_snapshot" {
  scope                = azurerm_resource_group.aks_rg.id
  role_definition_name = "Disk Snapshot Contributor"
  principal_id         = azurerm_data_protection_backup_vault.disk_backup_vault.identity[0].principal_id
}

# Action Group for backup alerts
resource "azurerm_monitor_action_group" "backup_alerts" {
  name                = "${var.cluster_name}-backup-alerts"
  resource_group_name = azurerm_resource_group.aks_rg.name
  short_name          = "bkpalert"

  email_receiver {
    name          = "platform-team"
    email_address = var.backup_alert_email
  }

  tags = var.tags
}

# Alert rule for backup failures
resource "azurerm_monitor_metric_alert" "backup_failure" {
  name                = "${var.cluster_name}-backup-failure-alert"
  resource_group_name = azurerm_resource_group.aks_rg.name
  scopes              = [azurerm_recovery_services_vault.aks_backup.id]
  description         = "Alert when backup jobs fail"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.RecoveryServices/vaults"
    metric_name      = "BackupHealthEvent"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 0

    dimension {
      name     = "HealthStatus"
      operator = "Include"
      values   = ["Failed"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.backup_alerts.id
  }

  tags = var.tags
}

# Storage account for backup staging (optional, for certain backup scenarios)
resource "azurerm_storage_account" "backup_staging" {
  name                     = replace("${var.cluster_name}bkpstg", "-", "")
  resource_group_name      = azurerm_resource_group.aks_rg.name
  location                 = azurerm_resource_group.aks_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = merge(var.tags, {
    component = "backup"
    purpose   = "backup-staging"
  })
}

# Container for backup staging
resource "azurerm_storage_container" "backup_staging" {
  name                  = "backup-staging"
  storage_account_name  = azurerm_storage_account.backup_staging.name
  container_access_type = "private"
}
