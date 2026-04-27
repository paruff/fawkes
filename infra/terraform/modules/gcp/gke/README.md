# GCP GKE Module

Manages a Google Kubernetes Engine (GKE) cluster with configurable node pools, networking, security, and monitoring.

## Usage

```hcl
module "gke" {
  source     = "../../modules/gcp/gke"
  cluster_name = "fawkes-gke"
  location     = "us-central1"
  project_id   = "my-gcp-project"

  network_id                    = module.vpc.network_id
  subnetwork_id                 = module.vpc.subnet_self_links["gke-subnet"]
  pods_secondary_range_name     = "pods"
  services_secondary_range_name = "services"

  node_pools = [
    {
      name           = "default-pool"
      machine_type   = "e2-standard-4"
      min_node_count = 1
      max_node_count = 10
    }
  ]

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
| google | >= 5.0.0 |
| google-beta | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the GKE cluster | `string` | n/a | yes |
| location | GCP region or zone | `string` | n/a | yes |
| project_id | GCP project ID | `string` | n/a | yes |
| network_id | VPC network ID | `string` | n/a | yes |
| subnetwork_id | Subnetwork ID | `string` | n/a | yes |
| pods_secondary_range_name | Secondary range name for pods | `string` | n/a | yes |
| services_secondary_range_name | Secondary range name for services | `string` | n/a | yes |
| cluster_description | Description of the cluster | `string` | `""` | no |
| enable_autopilot | Enable GKE Autopilot mode | `bool` | `false` | no |
| kubernetes_version | Kubernetes version | `string` | `null` | no |
| logging_components | GKE logging components | `list(string)` | `["SYSTEM_COMPONENTS","WORKLOADS"]` | no |
| monitoring_components | GKE monitoring components | `list(string)` | `["SYSTEM_COMPONENTS"]` | no |
| enable_managed_prometheus | Enable Google Cloud Managed Prometheus | `bool` | `true` | no |
| enable_network_policy | Enable network policy enforcement | `bool` | `true` | no |
| binary_authorization_mode | Binary Authorization mode | `string` | `"PROJECT_SINGLETON_POLICY_ENFORCE"` | no |
| datapath_provider | Datapath provider | `string` | `"ADVANCED_DATAPATH"` | no |
| enable_private_cluster | Enable private cluster | `bool` | `true` | no |
| enable_private_endpoint | Enable private endpoint | `bool` | `false` | no |
| enable_private_nodes | Enable private nodes | `bool` | `true` | no |
| master_ipv4_cidr_block | IPv4 CIDR for the master network (/28) | `string` | `"172.16.0.0/28"` | no |
| enable_master_global_access | Enable master global access | `bool` | `false` | no |
| master_authorized_networks | Authorized networks for master access | `list(object)` | `[]` | no |
| maintenance_start_time | Start time for maintenance window | `string` | `"03:00"` | no |
| release_channel | Release channel | `string` | `"REGULAR"` | no |
| enable_http_load_balancing | Enable HTTP load balancing addon | `bool` | `true` | no |
| enable_horizontal_pod_autoscaling | Enable HPA addon | `bool` | `true` | no |
| enable_gce_persistent_disk_csi_driver | Enable GCE PD CSI driver | `bool` | `true` | no |
| enable_security_posture | Enable security posture management | `bool` | `true` | no |
| vulnerability_mode | Vulnerability scanning mode | `string` | `"VULNERABILITY_DISABLED"` | no |
| node_pools | List of node pools | `list(object)` | `[]` | no |
| tags | Labels to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the GKE cluster |
| cluster_name | The name of the GKE cluster |
| cluster_endpoint | The endpoint (sensitive) |
| cluster_ca_certificate | The CA certificate (sensitive) |
| cluster_master_version | The Kubernetes master version |
| cluster_location | The location |
| cluster_region | The region |
| workload_identity_pool | Workload Identity pool |
| node_pool_names | List of node pool names |
| node_pool_service_accounts | Map of node pool names to service account emails |

## Validation Rules

- Cluster name must be 1–40 characters, start with lowercase letter, contain only lowercase letters, numbers, or hyphens
- Master IPv4 CIDR block must be a valid /28 CIDR
- Binary authorization mode must be `DISABLED` or `PROJECT_SINGLETON_POLICY_ENFORCE`
- Datapath provider must be `DATAPATH_PROVIDER_UNSPECIFIED`, `LEGACY_DATAPATH`, or `ADVANCED_DATAPATH`
- Release channel must be `UNSPECIFIED`, `RAPID`, `REGULAR`, or `STABLE`
- Vulnerability mode must be `VULNERABILITY_DISABLED`, `VULNERABILITY_BASIC`, or `VULNERABILITY_ENTERPRISE`
- Maintenance start time must be in `HH:MM` format
- All master authorized network CIDRs must be valid
