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

variable "namespace" {
  description = "Kubernetes namespace to create"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,61}[a-z0-9]$", var.namespace))
    error_message = "Namespace must be a valid DNS label (lowercase, alphanumeric and hyphens, 3-63 chars)."
  }
}

variable "labels" {
  description = "Additional labels to apply to the namespace"
  type        = map(string)
  default     = {}
}

variable "resource_quota" {
  description = "Optional resource quota for the namespace"
  type = object({
    requests_cpu    = optional(string, "4")
    requests_memory = optional(string, "8Gi")
    limits_cpu      = optional(string, "8")
    limits_memory   = optional(string, "16Gi")
    pods            = optional(string, "20")
  })
  default = null
}

variable "network_policy" {
  description = "Whether to create a default deny-all NetworkPolicy"
  type        = bool
  default     = false
}

variable "manage_namespace" {
  description = "Whether this module creates the Kubernetes namespace. Set false when a GitOps controller (e.g. ArgoCD with CreateNamespace=true) already owns it and this module is only used for IRSA."
  type        = bool
  default     = true
}

variable "create_irsa_role" {
  description = "Whether to create an IAM role assumable by a Kubernetes ServiceAccount via IRSA"
  type        = bool
  default     = false
}

variable "service_account_name" {
  description = "Kubernetes ServiceAccount name the IRSA role trusts (required if create_irsa_role is true)"
  type        = string
  default     = null
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster's IAM OIDC provider, e.g. module.eks.oidc_provider_arn (required if create_irsa_role is true)"
  type        = string
  default     = null
}

variable "oidc_provider_url" {
  description = "Issuer URL of the EKS cluster's OIDC provider without the https:// prefix, e.g. module.eks.oidc_provider (required if create_irsa_role is true)"
  type        = string
  default     = null
}

variable "iam_policy_arns" {
  description = "IAM policy ARNs to attach to the IRSA role"
  type        = list(string)
  default     = []
}

variable "iam_role_name" {
  description = "Name for the IRSA IAM role. Defaults to \"<namespace>-<service_account_name>-irsa\" if not set"
  type        = string
  default     = null
}
