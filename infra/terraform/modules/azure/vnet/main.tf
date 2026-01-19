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
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  dns_servers = var.dns_servers

  tags = merge(
    var.tags,
    {
      Name = var.vnet_name
      Cost = "shared"
    }
  )
}

# Public Subnets
resource "azurerm_subnet" "public" {
  for_each             = { for idx, subnet in var.public_subnets : subnet.name => subnet }
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes

  service_endpoints = lookup(each.value, "service_endpoints", [])

  dynamic "delegation" {
    for_each = lookup(each.value, "delegations", [])
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

# Private Subnets
resource "azurerm_subnet" "private" {
  for_each             = { for idx, subnet in var.private_subnets : subnet.name => subnet }
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes

  service_endpoints = lookup(each.value, "service_endpoints", [])

  dynamic "delegation" {
    for_each = lookup(each.value, "delegations", [])
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

# Network Security Groups for Public Subnets
resource "azurerm_network_security_group" "public" {
  for_each            = { for idx, subnet in var.public_subnets : subnet.name => subnet }
  name                = "${each.value.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Name = "${each.value.name}-nsg"
      Cost = "shared"
    }
  )
}

# Network Security Groups for Private Subnets
resource "azurerm_network_security_group" "private" {
  for_each            = { for idx, subnet in var.private_subnets : subnet.name => subnet }
  name                = "${each.value.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Name = "${each.value.name}-nsg"
      Cost = "shared"
    }
  )
}

# NSG Rules for Public Subnets
resource "azurerm_network_security_rule" "public" {
  for_each = {
    for rule in flatten([
      for subnet_name, subnet in { for idx, s in var.public_subnets : s.name => s } : [
        for rule_name, rule in lookup(subnet, "nsg_rules", {}) : {
          key             = "${subnet_name}-${rule_name}"
          nsg_name        = "${subnet_name}-nsg"
          name            = rule_name
          priority        = rule.priority
          direction       = rule.direction
          access          = rule.access
          protocol        = rule.protocol
          source_port_range = rule.source_port_range
          destination_port_range = rule.destination_port_range
          source_address_prefix = rule.source_address_prefix
          destination_address_prefix = rule.destination_address_prefix
        }
      ]
    ]) : rule.key => rule
  }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = each.value.nsg_name

  depends_on = [azurerm_network_security_group.public]
}

# NSG Rules for Private Subnets
resource "azurerm_network_security_rule" "private" {
  for_each = {
    for rule in flatten([
      for subnet_name, subnet in { for idx, s in var.private_subnets : s.name => s } : [
        for rule_name, rule in lookup(subnet, "nsg_rules", {}) : {
          key             = "${subnet_name}-${rule_name}"
          nsg_name        = "${subnet_name}-nsg"
          name            = rule_name
          priority        = rule.priority
          direction       = rule.direction
          access          = rule.access
          protocol        = rule.protocol
          source_port_range = rule.source_port_range
          destination_port_range = rule.destination_port_range
          source_address_prefix = rule.source_address_prefix
          destination_address_prefix = rule.destination_address_prefix
        }
      ]
    ]) : rule.key => rule
  }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = each.value.nsg_name

  depends_on = [azurerm_network_security_group.private]
}

# Associate NSG with Public Subnets
resource "azurerm_subnet_network_security_group_association" "public" {
  for_each                  = { for idx, subnet in var.public_subnets : subnet.name => subnet }
  subnet_id                 = azurerm_subnet.public[each.key].id
  network_security_group_id = azurerm_network_security_group.public[each.key].id
}

# Associate NSG with Private Subnets
resource "azurerm_subnet_network_security_group_association" "private" {
  for_each                  = { for idx, subnet in var.private_subnets : subnet.name => subnet }
  subnet_id                 = azurerm_subnet.private[each.key].id
  network_security_group_id = azurerm_network_security_group.private[each.key].id
}

# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "${var.vnet_name}-nat-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.nat_gateway_zones

  tags = merge(
    var.tags,
    {
      Name = "${var.vnet_name}-nat-pip"
      Cost = "shared"
    }
  )
}

# NAT Gateway
resource "azurerm_nat_gateway" "main" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "${var.vnet_name}-nat"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
  zones               = var.nat_gateway_zones

  idle_timeout_in_minutes = var.nat_gateway_idle_timeout

  tags = merge(
    var.tags,
    {
      Name = "${var.vnet_name}-nat"
      Cost = "shared"
    }
  )
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "main" {
  count                = var.enable_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

# Associate NAT Gateway with Private Subnets
resource "azurerm_subnet_nat_gateway_association" "private" {
  for_each       = var.enable_nat_gateway ? { for idx, subnet in var.private_subnets : subnet.name => subnet } : {}
  subnet_id      = azurerm_subnet.private[each.key].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

# Network Watcher (required for Flow Logs)
data "azurerm_network_watcher" "main" {
  count               = var.enable_flow_logs ? 1 : 0
  name                = var.network_watcher_name != null ? var.network_watcher_name : "NetworkWatcher_${var.location}"
  resource_group_name = var.network_watcher_resource_group != null ? var.network_watcher_resource_group : "NetworkWatcherRG"
}

# Storage Account for Flow Logs
resource "azurerm_storage_account" "flow_logs" {
  count                    = var.enable_flow_logs && var.flow_logs_storage_account_id == null ? 1 : 0
  name                     = replace("${var.vnet_name}flowlogs", "-", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = merge(
    var.tags,
    {
      Name = "${var.vnet_name}-flow-logs"
      Cost = "monitoring"
    }
  )
}

# NSG Flow Logs for Public Subnets
resource "azurerm_network_watcher_flow_log" "public" {
  for_each                  = var.enable_flow_logs ? { for idx, subnet in var.public_subnets : subnet.name => subnet } : {}
  network_watcher_name      = data.azurerm_network_watcher.main[0].name
  resource_group_name       = data.azurerm_network_watcher.main[0].resource_group_name
  name                      = "${each.key}-flow-log"
  network_security_group_id = azurerm_network_security_group.public[each.key].id
  storage_account_id        = var.flow_logs_storage_account_id != null ? var.flow_logs_storage_account_id : azurerm_storage_account.flow_logs[0].id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.flow_logs_retention_days
  }

  dynamic "traffic_analytics" {
    for_each = var.enable_traffic_analytics && var.log_analytics_workspace_id != null ? [1] : []
    content {
      enabled               = true
      workspace_id          = var.log_analytics_workspace_id
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_workspace_resource_id
      interval_in_minutes   = var.traffic_analytics_interval
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${each.key}-flow-log"
      Cost = "monitoring"
    }
  )
}

# NSG Flow Logs for Private Subnets
resource "azurerm_network_watcher_flow_log" "private" {
  for_each                  = var.enable_flow_logs ? { for idx, subnet in var.private_subnets : subnet.name => subnet } : {}
  network_watcher_name      = data.azurerm_network_watcher.main[0].name
  resource_group_name       = data.azurerm_network_watcher.main[0].resource_group_name
  name                      = "${each.key}-flow-log"
  network_security_group_id = azurerm_network_security_group.private[each.key].id
  storage_account_id        = var.flow_logs_storage_account_id != null ? var.flow_logs_storage_account_id : azurerm_storage_account.flow_logs[0].id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = var.flow_logs_retention_days
  }

  dynamic "traffic_analytics" {
    for_each = var.enable_traffic_analytics && var.log_analytics_workspace_id != null ? [1] : []
    content {
      enabled               = true
      workspace_id          = var.log_analytics_workspace_id
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_workspace_resource_id
      interval_in_minutes   = var.traffic_analytics_interval
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${each.key}-flow-log"
      Cost = "monitoring"
    }
  )
}
