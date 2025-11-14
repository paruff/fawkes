output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

// kubectl config and aws-auth outputs removed in eks module v19

output "region" {
  description = "AWS region."
  value       = var.region
}
