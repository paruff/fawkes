# =============================================================================
# eks-app-namespace module
# Creates a Kubernetes namespace with optional resource quota and network policy
# =============================================================================

locals {
  default_labels = {
    "app.kubernetes.io/part-of"    = "fawkes"
    "app.kubernetes.io/managed-by" = "terraform"
  }
  labels = merge(local.default_labels, var.labels)
}

# ---------------------------------------------------------------------------
# Namespace
# ---------------------------------------------------------------------------
resource "kubernetes_namespace" "app" {
  metadata {
    name   = var.namespace
    labels = local.labels
  }
}

# ---------------------------------------------------------------------------
# Resource Quota (optional)
# ---------------------------------------------------------------------------
resource "kubernetes_resource_quota" "app" {
  count = var.resource_quota != null ? 1 : 0

  metadata {
    name      = "${var.namespace}-quota"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = var.resource_quota.requests_cpu
      "requests.memory" = var.resource_quota.requests_memory
      "limits.cpu"      = var.resource_quota.limits_cpu
      "limits.memory"   = var.resource_quota.limits_memory
      "pods"            = var.resource_quota.pods
    }
  }
}

# ---------------------------------------------------------------------------
# Network Policy — default deny-all (optional)
# ---------------------------------------------------------------------------
resource "kubernetes_network_policy" "default_deny" {
  count = var.network_policy ? 1 : 0

  metadata {
    name      = "default-deny-all"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}
