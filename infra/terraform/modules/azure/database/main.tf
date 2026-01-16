# Copyright (c) 2025  Philip Ruff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

# Random password for database admin
resource "random_password" "admin" {
  count   = var.admin_password == null ? 1 : 0
  length  = 32
  special = true
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  count               = var.engine == "postgresql" ? 1 : 0
  name                = var.server_name
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login    = var.admin_username
  administrator_password = var.admin_password != null ? var.admin_password : random_password.admin[0].result

  sku_name   = var.sku_name
  version    = var.engine_version
  storage_mb = var.storage_mb

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # High Availability
  dynamic "high_availability" {
    for_each = var.high_availability_mode != null ? [1] : []
    content {
      mode                      = var.high_availability_mode
      standby_availability_zone = var.standby_availability_zone
    }
  }

  # Maintenance Window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  zone = var.zone

  tags = merge(
    var.tags,
    {
      Name = var.server_name
      Cost = "database"
    }
  )
}

# MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "main" {
  count               = var.engine == "mysql" ? 1 : 0
  name                = var.server_name
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login    = var.admin_username
  administrator_password = var.admin_password != null ? var.admin_password : random_password.admin[0].result

  sku_name = var.sku_name
  version  = var.engine_version

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # High Availability
  dynamic "high_availability" {
    for_each = var.high_availability_mode != null ? [1] : []
    content {
      mode                      = var.high_availability_mode
      standby_availability_zone = var.standby_availability_zone
    }
  }

  # Maintenance Window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  # Storage
  storage {
    size_gb           = var.storage_mb / 1024
    auto_grow_enabled = var.storage_auto_grow_enabled
    iops              = var.storage_iops
  }

  zone = var.zone

  tags = merge(
    var.tags,
    {
      Name = var.server_name
      Cost = "database"
    }
  )
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  count     = var.engine == "postgresql" && var.create_database ? 1 : 0
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main[0].id
  charset   = var.charset
  collation = var.collation
}

# MySQL Database
resource "azurerm_mysql_flexible_database" "main" {
  count               = var.engine == "mysql" && var.create_database ? 1 : 0
  name                = var.database_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main[0].name
  charset             = var.charset
  collation           = var.collation
}

# PostgreSQL Configuration Parameters
resource "azurerm_postgresql_flexible_server_configuration" "main" {
  for_each  = var.engine == "postgresql" ? var.database_parameters : {}
  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main[0].id
  value     = each.value
}

# MySQL Configuration Parameters
resource "azurerm_mysql_flexible_server_configuration" "main" {
  for_each            = var.engine == "mysql" ? var.database_parameters : {}
  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main[0].name
  value               = each.value
}

# PostgreSQL Firewall Rules
resource "azurerm_postgresql_flexible_server_firewall_rule" "main" {
  for_each         = var.engine == "postgresql" ? { for idx, rule in var.firewall_rules : idx => rule } : {}
  name             = each.value.name
  server_id        = azurerm_postgresql_flexible_server.main[0].id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# MySQL Firewall Rules
resource "azurerm_mysql_flexible_server_firewall_rule" "main" {
  for_each            = var.engine == "mysql" ? { for idx, rule in var.firewall_rules : idx => rule } : {}
  name                = each.value.name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main[0].name
  start_ip_address    = each.value.start_ip_address
  end_ip_address      = each.value.end_ip_address
}

# Private Endpoint for PostgreSQL
resource "azurerm_private_endpoint" "postgresql" {
  count               = var.engine == "postgresql" && var.enable_private_endpoint ? 1 : 0
  name                = "${var.server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.server_name}-psc"
    private_connection_resource_id = azurerm_postgresql_flexible_server.main[0].id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.server_name}-pe"
      Cost = "database"
    }
  )
}

# Private Endpoint for MySQL
resource "azurerm_private_endpoint" "mysql" {
  count               = var.engine == "mysql" && var.enable_private_endpoint ? 1 : 0
  name                = "${var.server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.server_name}-psc"
    private_connection_resource_id = azurerm_mysql_flexible_server.main[0].id
    is_manual_connection           = false
    subresource_names              = ["mysqlServer"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.server_name}-pe"
      Cost = "database"
    }
  )
}

# Diagnostic Settings for PostgreSQL
resource "azurerm_monitor_diagnostic_setting" "postgresql" {
  count                      = var.engine == "postgresql" && var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.server_name}-diagnostics"
  target_resource_id         = azurerm_postgresql_flexible_server.main[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = ["PostgreSQLLogs"]
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = ["AllMetrics"]
    content {
      category = metric.value
      enabled  = true
    }
  }
}

# Diagnostic Settings for MySQL
resource "azurerm_monitor_diagnostic_setting" "mysql" {
  count                      = var.engine == "mysql" && var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.server_name}-diagnostics"
  target_resource_id         = azurerm_mysql_flexible_server.main[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = ["MySqlSlowLogs", "MySqlAuditLogs"]
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = ["AllMetrics"]
    content {
      category = metric.value
      enabled  = true
    }
  }
}

# Metric Alerts
resource "azurerm_monitor_metric_alert" "cpu" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.server_name}-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.engine == "postgresql" ? azurerm_postgresql_flexible_server.main[0].id : azurerm_mysql_flexible_server.main[0].id]
  description         = "Alert when CPU usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = var.engine == "postgresql" ? "Microsoft.DBforPostgreSQL/flexibleServers" : "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_alert_threshold
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.server_name}-cpu-alert"
      Cost = "monitoring"
    }
  )
}

resource "azurerm_monitor_metric_alert" "storage" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.server_name}-storage-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.engine == "postgresql" ? azurerm_postgresql_flexible_server.main[0].id : azurerm_mysql_flexible_server.main[0].id]
  description         = "Alert when storage usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = var.engine == "postgresql" ? "Microsoft.DBforPostgreSQL/flexibleServers" : "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.storage_alert_threshold
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.server_name}-storage-alert"
      Cost = "monitoring"
    }
  )
}

resource "azurerm_monitor_metric_alert" "memory" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.server_name}-memory-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.engine == "postgresql" ? azurerm_postgresql_flexible_server.main[0].id : azurerm_mysql_flexible_server.main[0].id]
  description         = "Alert when memory usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = var.engine == "postgresql" ? "Microsoft.DBforPostgreSQL/flexibleServers" : "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "memory_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.memory_alert_threshold
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.server_name}-memory-alert"
      Cost = "monitoring"
    }
  )
}
