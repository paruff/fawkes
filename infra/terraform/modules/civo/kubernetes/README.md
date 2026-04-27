# Civo Kubernetes Module

Manages a Civo Kubernetes (K3s) cluster with configurable node pools, marketplace applications, and networking.

## Usage

```hcl
module "kubernetes" {
  source       = "../../modules/civo/kubernetes"
  cluster_name = "fawkes-k8s"
  location     = "NYC1"

  node_vm_size = "g4s.kube.medium"
  node_count   = 3

  network_id  = module.network.network_id
  firewall_id = module.network.firewall_id

  tags = {
    environment = "dev"
    platform    = "fawkes"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| civo | >= 1.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the Kubernetes cluster | `string` | n/a | yes |
| location | Civo region (NYC1, LON1, FRA1, PHX1) | `string` | n/a | yes |
| node_count | Number of nodes in the default pool | `number` | `3` | no |
| node_vm_size | VM size for the default node pool | `string` | `"g4s.kube.medium"` | no |
| kubernetes_version | Kubernetes (K3s) version | `string` | `null` | no |
| network_id | Network ID for the cluster | `string` | `null` | no |
| firewall_id | Firewall ID for the cluster | `string` | `null` | no |
| cni_plugin | CNI plugin (flannel or cilium) | `string` | `"flannel"` | no |
| node_pool_label | Label for the default node pool | `string` | `"default-pool"` | no |
| additional_node_pools | Additional node pools | `list(object)` | `[]` | no |
| marketplace_apps | Marketplace applications to install | `list(object)` | `[]` | no |
| size_preset | Size preset (small, medium, large) | `string` | `null` | no |
| tags | Tags to apply to cluster resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the Kubernetes cluster |
| cluster_name | The name of the Kubernetes cluster |
| cluster_endpoint | The API endpoint (sensitive) |
| kubeconfig | Kubeconfig for connecting to the cluster (sensitive) |
| cluster_status | Status of the cluster |
| cluster_version | Kubernetes version |
| master_ip | Master node IP address (sensitive) |
| dns_entry | DNS entry for the cluster |
| network_id | Network ID of the cluster |
| firewall_id | Firewall ID of the cluster |
| node_pool_ids | IDs of additional node pools |
| installed_applications | List of installed marketplace applications |
| created_at | Timestamp when the cluster was created |
| region | Region where the cluster is deployed |

## Validation Rules

- Cluster name must be 1–63 characters, start and end with alphanumeric, contain only alphanumerics and hyphens
- Location must be one of: `NYC1`, `LON1`, `FRA1`, `PHX1`
- Node count must be 1–100
- Node VM size must be a valid Civo instance size (e.g., `g4s.kube.small`, `g4s.kube.medium`, `g4s.kube.large`)
- CNI plugin must be `flannel` or `cilium`
- All additional node pool counts must be 1–100
- Size preset must be `null`, `small`, `medium`, or `large`

## Size Presets

| Preset | VM Size | Node Count |
|--------|---------|------------|
| small | g4s.kube.small | 2 |
| medium | g4s.kube.medium | 3 |
| large | g4s.kube.large | 5 |
