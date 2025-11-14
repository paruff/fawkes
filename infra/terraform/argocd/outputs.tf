output "argocd_release_name" {
  description = "Helm release name created"
  value       = helm_release.argocd.name
}

output "argocd_admin_password_b64" {
  description = "Base64-encoded ArgoCD initial admin password (sensitive)"
  value       = data.kubernetes_secret.argocd_initial_admin_secret.data["password"]
  sensitive   = true
}

output "argocd_admin_password" {
  description = "Decoded ArgoCD initial admin password (sensitive)"
  value       = base64decode(data.kubernetes_secret.argocd_initial_admin_secret.data["password"])
  sensitive   = true
}
