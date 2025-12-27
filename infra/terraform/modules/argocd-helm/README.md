# ArgoCD Helm Module

This module deploys ArgoCD to a Kubernetes cluster using Helm with proper validation and configuration.

## Features

- Deploys ArgoCD using official Helm chart
- Configurable release name and namespace
- Validates all input parameters
- Retrieves initial admin password
- Atomic deployment with rollback on failure
- Comprehensive outputs including admin credentials

## Usage

```hcl
module "argocd" {
  source = "../../modules/argocd-helm"

  release_name    = "argocd"
  namespace       = "argocd"
  chart_version   = "5.51.0"  # Optional: pin to specific version
  
  timeout       = 600
  atomic        = true
  recreate_pods = true
  
  # Optional: override default values
  values_override = <<-EOT
    global:
      domain: argocd.mycompany.com
    server:
      ingress:
        enabled: true
        hosts:
          - argocd.mycompany.com
  EOT
}

# Access admin password
output "argocd_admin_password" {
  value     = module.argocd.admin_password
  sensitive = true
}
```

**Note**: This module requires the Kubernetes and Helm providers to be configured by the caller. See the providers configuration example below.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| kubernetes | >= 2.11.0 |
| helm | >= 2.7.0, < 3.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| release_name | Helm release name for ArgoCD | `string` | `"argocd"` | no |
| chart_repo | Helm chart repository URL | `string` | `"https://argoproj.github.io/argo-helm"` | no |
| chart_name | Chart name in the repository | `string` | `"argo-cd"` | no |
| chart_version | Chart version (empty for latest) | `string` | `""` | no |
| namespace | Kubernetes namespace for ArgoCD | `string` | `"argocd"` | no |
| timeout | Timeout in seconds for Helm operations | `number` | `600` | no |
| atomic | Roll back on failure | `bool` | `true` | no |
| recreate_pods | Force pod recreation on upgrade | `bool` | `true` | no |
| create_namespace | Create namespace if it doesn't exist | `bool` | `true` | no |
| skip_crds | Skip CRD installation | `bool` | `false` | no |
| values_override | Additional Helm values (YAML) | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| release_name | The name of the Helm release |
| release_version | The version of the Helm release |
| release_status | The status of the Helm release |
| namespace | The namespace where ArgoCD is installed |
| admin_password_b64 | Base64-encoded admin password (sensitive) |
| admin_password | Decoded admin password (sensitive) |

## Validation Rules

- Release name: 1-53 characters, DNS-1123 subdomain format
- Namespace: 1-63 characters, lowercase alphanumerics and hyphens
- Chart repository must be valid HTTP/HTTPS URL
- Timeout must be between 60 and 3600 seconds
- YAML syntax validation for values_override

## Provider Configuration

This module requires the Kubernetes and Helm providers to be configured by the caller. Example:

```hcl
provider "kubernetes" {
  config_path = "~/.kube/config"
  # Or use other authentication methods like:
  # host                   = var.cluster_endpoint
  # client_certificate     = base64decode(var.client_certificate)
  # client_key             = base64decode(var.client_key)
  # cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "argocd" {
  source = "./modules/argocd-helm"
  # ... module configuration
}
```

## Post-Deployment

After deployment, access ArgoCD:

```bash
# Port forward to ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
terraform output -raw argocd_admin_password

# Login at https://localhost:8080
# Username: admin
# Password: <output from above>
```

## Customizing ArgoCD Configuration

You can customize ArgoCD by providing additional Helm values via the `values_override` variable:

```hcl
module "argocd" {
  source = "../../modules/argocd-helm"
  
  # ... other variables ...
  
  values_override = <<-EOT
    global:
      domain: argocd.example.com
    
    server:
      ingress:
        enabled: true
        ingressClassName: nginx
        hosts:
          - argocd.example.com
        tls:
          - secretName: argocd-tls
            hosts:
              - argocd.example.com
    
    configs:
      params:
        server.insecure: false  # Enable TLS
  EOT
}
```

The `values_override` will be merged with the default values.yaml in this module.
