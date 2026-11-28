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

variable "release_name" {
  description = "Helm release name for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "chart_repo" {
  description = "Helm chart repository that contains the ArgoCD chart"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "chart_name" {
  description = "Chart name in the helm repository"
  type        = string
  default     = "argo-cd"
}

variable "chart_version" {
  description = "Exact argo-cd chart version (ADR-040); 10.20.0 is Argo CD v3.6.3"
  type        = string
  default     = "10.20.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.chart_version))
    error_message = "chart_version must be an exact version such as 10.20.0 (ADR-040)."
  }
}

variable "namespace" {
  description = "Kubernetes namespace to install ArgoCD into"
  type        = string
  default     = "argocd"
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file used by Kubernetes and Helm providers"
  type        = string
}
