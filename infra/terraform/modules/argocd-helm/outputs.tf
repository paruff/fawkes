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

output "release_name" {
  description = "The name of the Helm release"
  value       = helm_release.argocd.name
}

output "release_version" {
  description = "The version of the Helm release"
  value       = helm_release.argocd.version
}

output "release_status" {
  description = "The status of the Helm release"
  value       = helm_release.argocd.status
}

output "namespace" {
  description = "The namespace where ArgoCD is installed"
  value       = helm_release.argocd.namespace
}

output "admin_password_b64" {
  description = "Base64-encoded ArgoCD initial admin password (sensitive)"
  value       = data.kubernetes_secret.argocd_initial_admin_secret.data["password"]
  sensitive   = true
}

output "admin_password" {
  description = "Decoded ArgoCD initial admin password (sensitive)"
  value       = try(base64decode(data.kubernetes_secret.argocd_initial_admin_secret.data["password"]), "")
  sensitive   = true
}
