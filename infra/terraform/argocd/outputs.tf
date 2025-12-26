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
  # Guard decode in case provider returns non-UTF8 or unexpected format
  value       = try(base64decode(data.kubernetes_secret.argocd_initial_admin_secret.data["password"]), "")
  sensitive   = true
}
