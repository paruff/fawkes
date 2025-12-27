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

variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-2"

  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "ca-central-1", "eu-west-1", "eu-west-2", "eu-west-3",
      "eu-central-1", "eu-north-1", "ap-northeast-1", "ap-northeast-2",
      "ap-southeast-1", "ap-southeast-2", "ap-south-1", "sa-east-1"
    ], var.region)
    error_message = "Region must be a valid AWS region."
  }
}

variable "environment" {
  description = "Deployment environment tag (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner tag for resources."
  type        = string
  default     = "fawkes"
}

variable "extra_tags" {
  description = "Additional tags to merge into all resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "eks_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[0-9]|30)$", var.eks_version))
    error_message = "EKS version must be a valid Kubernetes version (e.g., 1.28, 1.29, 1.30)."
  }
}

variable "ssh_ingress_cidr_one" {
  description = "CIDR block allowed to SSH to worker group 1 management SG."
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_ingress_cidr_two" {
  description = "CIDR block allowed to SSH to worker group 2 management SG."
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_ingress_cidrs" {
  description = "List of CIDR blocks allowed to SSH to all workers."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "egress_cidr_block" {
  description = "CIDR block for egress rules."
  type        = string
  default     = "0.0.0.0/0"
}

variable "worker_group_1_instance_type" {
  description = "Instance type for worker group 1."
  type        = string
  default     = "t3.medium"
}

variable "worker_group_2_instance_type" {
  description = "Instance type for worker group 2."
  type        = string
  default     = "t3.medium"
}

variable "worker_group_1_capacity" {
  description = "Desired node count for worker group 1."
  type        = number
  default     = 2

  validation {
    condition     = var.worker_group_1_capacity >= 1 && var.worker_group_1_capacity <= 100
    error_message = "Worker group 1 capacity must be between 1 and 100."
  }
}

variable "worker_group_2_capacity" {
  description = "Desired node count for worker group 2."
  type        = number
  default     = 1

  validation {
    condition     = var.worker_group_2_capacity >= 1 && var.worker_group_2_capacity <= 100
    error_message = "Worker group 2 capacity must be between 1 and 100."
  }
}

variable "worker_group_1_min_size" {
  description = "Minimum node count for worker group 1 autoscaling."
  type        = number
  default     = 2
}

variable "worker_group_1_max_size" {
  description = "Maximum node count for worker group 1 autoscaling."
  type        = number
  default     = 5
}

variable "worker_group_2_min_size" {
  description = "Minimum node count for worker group 2 autoscaling."
  type        = number
  default     = 1
}

variable "worker_group_2_max_size" {
  description = "Maximum node count for worker group 2 autoscaling."
  type        = number
  default     = 3
}

variable "map_roles" {
  description = "Additional IAM roles to add to EKS cluster access entries."
  type = list(object({
    rolearn = string
    groups  = list(string)
  }))
  default = []

  validation {
    condition     = alltrue([for role in var.map_roles : can(regex("^arn:aws:iam::[0-9]{12}:role/[a-zA-Z0-9+=,.@_-]+$", role.rolearn))])
    error_message = "All role ARNs must be valid AWS IAM role ARNs."
  }
}

variable "map_users" {
  description = "Additional IAM users to add to EKS cluster access entries."
  type = list(object({
    userarn = string
    groups  = list(string)
  }))
  default = []

  validation {
    condition     = alltrue([for user in var.map_users : can(regex("^arn:aws:iam::[0-9]{12}:user/[a-zA-Z0-9+=,.@_-]+$", user.userarn))])
    error_message = "All user ARNs must be valid AWS IAM user ARNs."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for EKS secrets encryption. If null, encryption is disabled."
  type        = string
  default     = null
}
