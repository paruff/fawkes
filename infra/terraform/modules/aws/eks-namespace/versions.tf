# =============================================================================
# Terraform module: eks-app-namespace
# Purpose: Create a namespaced environment for a Fawkes service on EKS
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25.0"
    }
  }
}
