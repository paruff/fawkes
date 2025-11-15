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
