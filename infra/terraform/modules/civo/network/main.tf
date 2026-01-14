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
    civo = {
      source  = "civo/civo"
      version = ">= 1.0.0"
    }
  }
}

# Civo Network
resource "civo_network" "main" {
  label  = var.network_name
  region = var.location

  # CIDR block for the network
  cidr_v4 = var.cidr_block

  # Tags - Civo doesn't support tags on networks directly, but we track them
}

# Firewall for the network
resource "civo_firewall" "main" {
  count = var.create_firewall ? 1 : 0

  name       = "${var.network_name}-firewall"
  network_id = civo_network.main.id
  region     = var.location

  # Don't create default rules if custom rules are provided
  create_default_rules = length(var.firewall_rules) == 0
}

# Custom firewall rules
resource "civo_firewall_rule" "ingress" {
  for_each = var.create_firewall ? { for idx, rule in var.firewall_rules : idx => rule if rule.direction == "ingress" } : {}

  firewall_id = civo_firewall.main[0].id
  protocol    = each.value.protocol
  start_port  = each.value.start_port
  end_port    = each.value.end_port != null ? each.value.end_port : each.value.start_port
  cidr        = each.value.cidr_blocks
  direction   = "ingress"
  label       = each.value.label != null ? each.value.label : "Rule ${each.key}"
  action      = each.value.action
}

resource "civo_firewall_rule" "egress" {
  for_each = var.create_firewall ? { for idx, rule in var.firewall_rules : idx => rule if rule.direction == "egress" } : {}

  firewall_id = civo_firewall.main[0].id
  protocol    = each.value.protocol
  start_port  = each.value.start_port
  end_port    = each.value.end_port != null ? each.value.end_port : each.value.start_port
  cidr        = each.value.cidr_blocks
  direction   = "egress"
  label       = each.value.label != null ? each.value.label : "Rule ${each.key}"
  action      = each.value.action
}

# Load Balancer (if enabled)
resource "civo_loadbalancer" "main" {
  count = var.create_load_balancer ? 1 : 0

  hostname                       = var.load_balancer_hostname
  protocol                       = var.load_balancer_protocol
  port                           = var.load_balancer_port
  max_request_size               = var.load_balancer_max_request_size
  policy                         = var.load_balancer_policy
  health_check_path              = var.load_balancer_health_check_path
  fail_timeout                   = var.load_balancer_fail_timeout
  max_conns                      = var.load_balancer_max_conns
  ignore_invalid_backend_tls     = var.load_balancer_ignore_invalid_backend_tls
  enable_proxy_protocol          = var.load_balancer_enable_proxy_protocol

  network_id = civo_network.main.id
  region     = var.location

  # Backends configuration
  dynamic "backend" {
    for_each = var.load_balancer_backends
    content {
      ip                = backend.value.ip
      protocol          = backend.value.protocol
      source_port       = backend.value.source_port
      target_port       = backend.value.target_port
      health_check_port = backend.value.health_check_port
    }
  }

  # Firewall ID
  firewall_id = var.create_firewall ? civo_firewall.main[0].id : var.firewall_id

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

# Reserved IP for Load Balancer (optional)
resource "civo_reserved_ip" "loadbalancer" {
  count = var.create_load_balancer && var.create_reserved_ip ? 1 : 0

  name   = "${var.network_name}-lb-ip"
  region = var.location
}

# Local variables
locals {
  default_cidr = "10.0.0.0/16"
}
