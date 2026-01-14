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

output "network_id" {
  description = "The ID of the network"
  value       = civo_network.main.id
}

output "network_name" {
  description = "The name/label of the network"
  value       = civo_network.main.label
}

output "network_cidr" {
  description = "CIDR block of the network"
  value       = civo_network.main.cidr_v4
}

output "network_status" {
  description = "Status of the network"
  value       = civo_network.main.status
}

output "default" {
  description = "Whether this is the default network"
  value       = civo_network.main.default
}

output "region" {
  description = "Region where the network is deployed"
  value       = civo_network.main.region
}

output "firewall_id" {
  description = "ID of the firewall"
  value       = var.create_firewall ? civo_firewall.main[0].id : null
}

output "firewall_name" {
  description = "Name of the firewall"
  value       = var.create_firewall ? civo_firewall.main[0].name : null
}

output "ingress_rule_ids" {
  description = "IDs of ingress firewall rules"
  value       = { for k, v in civo_firewall_rule.ingress : k => v.id }
}

output "egress_rule_ids" {
  description = "IDs of egress firewall rules"
  value       = { for k, v in civo_firewall_rule.egress : k => v.id }
}

output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = var.create_load_balancer ? civo_loadbalancer.main[0].id : null
}

output "load_balancer_hostname" {
  description = "Hostname of the load balancer"
  value       = var.create_load_balancer ? civo_loadbalancer.main[0].hostname : null
}

output "load_balancer_public_ip" {
  description = "Public IP address of the load balancer"
  value       = var.create_load_balancer ? civo_loadbalancer.main[0].public_ip : null
}

output "load_balancer_private_ip" {
  description = "Private IP address of the load balancer"
  value       = var.create_load_balancer ? civo_loadbalancer.main[0].private_ip : null
}

output "load_balancer_state" {
  description = "State of the load balancer"
  value       = var.create_load_balancer ? civo_loadbalancer.main[0].state : null
}

output "reserved_ip_id" {
  description = "ID of the reserved IP"
  value       = var.create_load_balancer && var.create_reserved_ip ? civo_reserved_ip.loadbalancer[0].id : null
}

output "reserved_ip_address" {
  description = "Reserved IP address"
  value       = var.create_load_balancer && var.create_reserved_ip ? civo_reserved_ip.loadbalancer[0].ip : null
}
