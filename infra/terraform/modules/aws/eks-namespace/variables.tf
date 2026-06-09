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
