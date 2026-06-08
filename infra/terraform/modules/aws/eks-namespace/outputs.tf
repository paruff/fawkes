output "namespace_name" {
  description = "Name of the created Kubernetes namespace"
  value       = kubernetes_namespace.app.metadata[0].name
}

output "namespace_uid" {
  description = "UID of the created Kubernetes namespace"
  value       = kubernetes_namespace.app.metadata[0].uid
}
