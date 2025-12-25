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
}

variable "environment" {
  description = "Deployment environment tag (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
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
}

variable "worker_group_2_capacity" {
  description = "Desired node count for worker group 2."
  type        = number
  default     = 1
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

  default = [
    {
      rolearn = "arn:aws:iam::66666666666:role/role1"
      groups  = ["system:masters"]
    },
  ]
}

variable "map_users" {
  description = "Additional IAM users to add to EKS cluster access entries."
  type = list(object({
    userarn = string
    groups  = list(string)
  }))

  default = [
    {
      userarn = "arn:aws:iam::66666666666:user/user1"
      groups  = ["system:masters"]
    },
    {
      userarn = "arn:aws:iam::66666666666:user/user2"
      groups  = ["system:masters"]
    },
  ]
}

variable "kms_key_arn" {
  description = "KMS key ARN for EKS secrets encryption. If null, encryption is disabled."
  type        = string
  default     = null
}
