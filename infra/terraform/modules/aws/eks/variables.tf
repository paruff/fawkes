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

# AWS EKS module variables extending base kubernetes-cluster module

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) >= 1 && length(var.cluster_name) <= 100
    error_message = "Cluster name must be between 1 and 100 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.cluster_name))
    error_message = "Cluster name must start and end with alphanumeric, and contain only alphanumerics and hyphens."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where EKS cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS nodes"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnets must be specified for high availability."
  }
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for EKS control plane ENIs"
  type        = list(string)
  default     = []
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[4-9]|[3-9][0-9]|[0-9]{3,})$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.24 or higher (format: 1.28)."
  }
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access (empty list allows all)"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.api_server_authorized_ip_ranges :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All IP ranges must be valid CIDR blocks."
  }
}

variable "cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition = alltrue([
      for log_type in var.cluster_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Cluster log types must be one of: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "cluster_log_retention_days" {
  description = "Number of days to retain cluster logs in CloudWatch"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cluster_log_retention_days)
    error_message = "Cluster log retention must be a valid CloudWatch Logs retention period."
  }
}

variable "node_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]

  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "At least one instance type must be specified."
  }
}

variable "node_capacity_type" {
  description = "Type of capacity for nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "Node capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "node_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20

  validation {
    condition     = var.node_disk_size >= 20 && var.node_disk_size <= 16384
    error_message = "Node disk size must be between 20 and 16384 GB."
  }
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.node_desired_size >= 1 && var.node_desired_size <= 1000
    error_message = "Node desired size must be between 1 and 1000."
  }
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.node_min_size >= 0 && var.node_min_size <= 1000
    error_message = "Node min size must be between 0 and 1000."
  }
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 10

  validation {
    condition     = var.node_max_size >= 1 && var.node_max_size <= 1000
    error_message = "Node max size must be between 1 and 1000."
  }
}

variable "node_max_unavailable" {
  description = "Maximum number of nodes unavailable during updates"
  type        = number
  default     = 1

  validation {
    condition     = var.node_max_unavailable >= 1
    error_message = "Node max unavailable must be at least 1."
  }
}

variable "node_labels" {
  description = "Key-value map of Kubernetes labels for nodes"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "List of Kubernetes taints to apply to nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "vpc_cni_addon_version" {
  description = "Version of the VPC CNI addon"
  type        = string
  default     = null
}

variable "coredns_addon_version" {
  description = "Version of the CoreDNS addon"
  type        = string
  default     = null
}

variable "kube_proxy_addon_version" {
  description = "Version of the kube-proxy addon"
  type        = string
  default     = null
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver addon"
  type        = bool
  default     = true
}

variable "ebs_csi_driver_addon_version" {
  description = "Version of the EBS CSI driver addon"
  type        = string
  default     = null
}

variable "enable_cluster_autoscaler" {
  description = "Enable IAM role for Cluster Autoscaler"
  type        = bool
  default     = true
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable IAM role for AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to EKS resources"
  type        = map(string)
  default     = {}
}
