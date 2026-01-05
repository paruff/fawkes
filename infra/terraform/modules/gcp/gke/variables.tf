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

# GCP GKE module variables extending base kubernetes-cluster module

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) >= 1 && length(var.cluster_name) <= 40
    error_message = "Cluster name must be between 1 and 40 characters."
  }

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.cluster_name))
    error_message = "Cluster name must start with a lowercase letter, followed by lowercase letters, numbers, or hyphens."
  }
}

variable "location" {
  description = "GCP region or zone for the GKE cluster"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "cluster_description" {
  description = "Description of the GKE cluster"
  type        = string
  default     = ""
}

variable "enable_autopilot" {
  description = "Enable GKE Autopilot mode (managed infrastructure)"
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = null
}

variable "network_id" {
  description = "VPC network ID for the cluster"
  type        = string
}

variable "subnetwork_id" {
  description = "Subnetwork ID for the cluster"
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the secondary IP range for pods"
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the secondary IP range for services"
  type        = string
}

variable "logging_components" {
  description = "GKE logging components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_components" {
  description = "GKE monitoring components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "enable_managed_prometheus" {
  description = "Enable Google Cloud Managed Service for Prometheus"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable network policy enforcement"
  type        = bool
  default     = true
}

variable "binary_authorization_mode" {
  description = "Binary Authorization evaluation mode"
  type        = string
  default     = "PROJECT_SINGLETON_POLICY_ENFORCE"

  validation {
    condition = contains([
      "DISABLED",
      "PROJECT_SINGLETON_POLICY_ENFORCE"
    ], var.binary_authorization_mode)
    error_message = "Binary authorization mode must be DISABLED or PROJECT_SINGLETON_POLICY_ENFORCE."
  }
}

variable "datapath_provider" {
  description = "Datapath provider for the cluster (DATAPATH_PROVIDER_UNSPECIFIED, LEGACY_DATAPATH, ADVANCED_DATAPATH)"
  type        = string
  default     = "ADVANCED_DATAPATH"

  validation {
    condition = contains([
      "DATAPATH_PROVIDER_UNSPECIFIED",
      "LEGACY_DATAPATH",
      "ADVANCED_DATAPATH"
    ], var.datapath_provider)
    error_message = "Datapath provider must be DATAPATH_PROVIDER_UNSPECIFIED, LEGACY_DATAPATH, or ADVANCED_DATAPATH."
  }
}

variable "enable_private_cluster" {
  description = "Enable private cluster configuration"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for the cluster"
  type        = bool
  default     = false
}

variable "enable_private_nodes" {
  description = "Enable private nodes (nodes have only private IP addresses)"
  type        = bool
  default     = true
}

variable "master_ipv4_cidr_block" {
  description = "IPv4 CIDR block for the master network"
  type        = string
  default     = "172.16.0.0/28"

  validation {
    condition     = can(cidrhost(var.master_ipv4_cidr_block, 0))
    error_message = "Master IPv4 CIDR block must be a valid CIDR."
  }

  validation {
    condition     = tonumber(split("/", var.master_ipv4_cidr_block)[1]) == 28
    error_message = "Master IPv4 CIDR block must be /28."
  }
}

variable "enable_master_global_access" {
  description = "Enable master global access"
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "List of CIDR blocks authorized to access the cluster master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []

  validation {
    condition = alltrue([
      for network in var.master_authorized_networks :
      can(cidrhost(network.cidr_block, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

variable "maintenance_start_time" {
  description = "Start time for daily maintenance window (HH:MM format)"
  type        = string
  default     = "03:00"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_start_time))
    error_message = "Maintenance start time must be in HH:MM format."
  }
}

variable "release_channel" {
  description = "Release channel for GKE cluster"
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Release channel must be UNSPECIFIED, RAPID, REGULAR, or STABLE."
  }
}

variable "enable_http_load_balancing" {
  description = "Enable HTTP load balancing addon"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable horizontal pod autoscaling addon"
  type        = bool
  default     = true
}

variable "enable_filestore_csi_driver" {
  description = "Enable Filestore CSI driver"
  type        = bool
  default     = false
}

variable "enable_gce_persistent_disk_csi_driver" {
  description = "Enable GCE Persistent Disk CSI driver"
  type        = bool
  default     = true
}

variable "enable_security_posture" {
  description = "Enable security posture management"
  type        = bool
  default     = true
}

variable "vulnerability_mode" {
  description = "Vulnerability scanning mode"
  type        = string
  default     = "VULNERABILITY_DISABLED"

  validation {
    condition     = contains(["VULNERABILITY_DISABLED", "VULNERABILITY_BASIC", "VULNERABILITY_ENTERPRISE"], var.vulnerability_mode)
    error_message = "Vulnerability mode must be VULNERABILITY_DISABLED, VULNERABILITY_BASIC, or VULNERABILITY_ENTERPRISE."
  }
}

variable "node_pools" {
  description = "List of node pools for Standard GKE clusters"
  type = list(object({
    name                        = string
    initial_node_count          = optional(number, 1)
    enable_autoscaling          = optional(bool, true)
    min_node_count              = optional(number, 1)
    max_node_count              = optional(number, 10)
    location_policy             = optional(string, "BALANCED")
    total_min_node_count        = optional(number, null)
    total_max_node_count        = optional(number, null)
    machine_type                = optional(string, "e2-medium")
    disk_size_gb                = optional(number, 100)
    disk_type                   = optional(string, "pd-standard")
    image_type                  = optional(string, "COS_CONTAINERD")
    service_account             = optional(string, null)
    oauth_scopes                = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    labels                      = optional(map(string), {})
    metadata                    = optional(map(string), {})
    network_tags                = optional(list(string), [])
    enable_secure_boot          = optional(bool, true)
    enable_integrity_monitoring = optional(bool, true)
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    spot             = optional(bool, false)
    preemptible      = optional(bool, false)
    auto_repair      = optional(bool, true)
    auto_upgrade     = optional(bool, true)
    max_surge        = optional(number, 1)
    max_unavailable  = optional(number, 0)
    upgrade_strategy = optional(string, "SURGE")
  }))
  default = []
}

variable "tags" {
  description = "Labels to apply to cluster resources"
  type        = map(string)
  default     = {}
}
