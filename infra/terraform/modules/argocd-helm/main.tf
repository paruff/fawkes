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

terraform {
  required_version = ">= 1.6.0"

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
}

resource "helm_release" "argocd" {
  name             = var.release_name
  repository       = var.chart_repo
  chart            = var.chart_name
  version          = var.chart_version != "" ? var.chart_version : null
  namespace        = var.namespace
  create_namespace = var.create_namespace
  skip_crds        = var.skip_crds

  values = concat(
    [file("${path.module}/values.yaml")],
    var.values_override != "" ? [var.values_override] : []
  )

  timeout       = var.timeout
  atomic        = var.atomic
  recreate_pods = var.recreate_pods
}

data "kubernetes_secret" "argocd_initial_admin_secret" {
  depends_on = [helm_release.argocd]
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.namespace
  }
}
