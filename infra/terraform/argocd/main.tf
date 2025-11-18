terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.11.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7.0, < 3.0.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "kubernetes" {
  # Explicitly point to kubeconfig provided by ignite.sh
  config_path = var.kubeconfig_path
}

/*
The helm provider will inherit kubeconfig from the environment or the
kubernetes provider; avoid specifying a nested `kubernetes {}` block here
because some provider versions expect different configuration shapes and
it can cause HCL parsing errors in older/newer provider combinations.
If you need to customize Kubernetes connection for Helm, set `kubeconfig`
or configure a separate provider alias.
*/

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

resource "helm_release" "argocd" {
  name       = var.release_name
  repository = var.chart_repo
  chart      = var.chart_name
  version    = var.chart_version != "" ? var.chart_version : null
  namespace  = var.namespace
  create_namespace = true
  # Install CRDs via Helm to shift CRD management from the bootstrap script to Terraform/Helm
  skip_crds = false

  # Use a small values file included in this module. Users can override by
  # providing their own values via the values override file path variable.
  values = [file("${path.module}/values.yaml")]

  timeout = 600
  atomic  = true
  recreate_pods = true
}

data "kubernetes_secret" "argocd_initial_admin_secret" {
  depends_on = [helm_release.argocd]
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.namespace
  }
}
