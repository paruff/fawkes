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
  description = "Optional chart version pin (leave empty for latest)"
  type        = string
  default     = ""
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
