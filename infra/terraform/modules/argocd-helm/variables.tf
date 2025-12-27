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

  validation {
    condition     = length(var.release_name) >= 1 && length(var.release_name) <= 53
    error_message = "Release name must be between 1 and 53 characters (DNS-1123 subdomain)."
  }

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.release_name))
    error_message = "Release name must consist of lowercase alphanumeric characters or hyphens, and must start and end with alphanumeric."
  }
}

variable "chart_repo" {
  description = "Helm chart repository that contains the ArgoCD chart"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"

  validation {
    condition     = can(regex("^https?://", var.chart_repo))
    error_message = "Chart repository must be a valid HTTP or HTTPS URL."
  }
}

variable "chart_name" {
  description = "Chart name in the helm repository"
  type        = string
  default     = "argo-cd"

  validation {
    condition     = length(var.chart_name) > 0
    error_message = "Chart name cannot be empty."
  }
}

variable "chart_version" {
  description = "Optional chart version pin (leave empty for latest)"
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Kubernetes namespace to install ArgoCD into"
  type        = string
  default     = "argocd"

  validation {
    condition     = length(var.namespace) >= 1 && length(var.namespace) <= 63
    error_message = "Namespace must be between 1 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must consist of lowercase alphanumeric characters or hyphens."
  }
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file used by Kubernetes and Helm providers"
  type        = string

  validation {
    condition     = length(var.kubeconfig_path) > 0
    error_message = "Kubeconfig path cannot be empty."
  }
}

variable "timeout" {
  description = "Timeout in seconds for Helm operations"
  type        = number
  default     = 600

  validation {
    condition     = var.timeout >= 60 && var.timeout <= 3600
    error_message = "Timeout must be between 60 and 3600 seconds."
  }
}

variable "atomic" {
  description = "If true, roll back on failure"
  type        = bool
  default     = true
}

variable "recreate_pods" {
  description = "Force pods to be recreated during upgrade"
  type        = bool
  default     = true
}

variable "create_namespace" {
  description = "Create namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "skip_crds" {
  description = "Skip CRD installation (not recommended)"
  type        = bool
  default     = false
}
