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

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

// kubectl config and aws-auth outputs removed in eks module v19

output "region" {
  description = "AWS region."
  value       = var.region
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster (used for IRSA)."
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider" {
  description = "OIDC provider hostname (issuer without https://)."
  value       = module.eks.oidc_provider
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider (needed for IRSA role trust policies)."
  value       = module.eks.oidc_provider_arn
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of autoscaling group names for managed node groups."
  value       = module.eks.eks_managed_node_groups_autoscaling_group_names
}
