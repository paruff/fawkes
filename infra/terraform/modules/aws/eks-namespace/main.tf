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
