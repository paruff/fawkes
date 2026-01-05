# Base Kubernetes Cluster Module

This is a base module that defines common variables and outputs for Kubernetes clusters across all cloud providers (Azure, AWS, GCP, Civo).

## Purpose

This module provides:
- Common variable definitions with validation rules
- Standardized naming conventions (snake_case)
- Reusable patterns for provider-specific implementations
- Consistent output structure

## Usage

This module is not intended to be used directly. Instead, use provider-specific modules that extend this base:

- `../azure/kubernetes-cluster` - For Azure AKS
- `../aws/kubernetes-cluster` - For AWS EKS
- `../gcp/kubernetes-cluster` - For GCP GKE
- `../civo/kubernetes-cluster` - For Civo K3s

## Variables

### Required Variables

- `cluster_name` - Name of the Kubernetes cluster (1-63 chars, alphanumeric and hyphens)
- `location` - Cloud provider region/location
- `resource_group_name` - Resource group or organizational unit name

### Optional Variables

- `node_count` - Number of nodes (default: 3, range: 1-1000)
- `node_vm_size` - VM/instance size (provider-specific)
- `enable_rbac` - Enable Kubernetes RBAC (default: true)
- `network_plugin` - Network plugin (provider-specific)
- `service_cidr` - Service CIDR (default: "10.1.0.0/16")
- `dns_service_ip` - DNS service IP (default: "10.1.0.10")
- `api_server_authorized_ip_ranges` - Authorized IP ranges (default: [])
- `tags` - Tags/labels to apply (default: {})

## Outputs

- `cluster_id` - The cluster ID
- `cluster_name` - The cluster name
- `cluster_endpoint` - The cluster endpoint/FQDN
- `kube_config` - Kubernetes configuration (sensitive)

## Validation Rules

All variables include validation rules to catch configuration errors early:

- Cluster name length and format
- Node count range (1-1000)
- Valid CIDR blocks for service_cidr
- Valid IP address for dns_service_ip
- Valid CIDR blocks for api_server_authorized_ip_ranges

## Provider-Specific Extensions

Provider-specific modules should:
1. Define provider-specific variables
2. Use base module variables where possible
3. Map base variables to provider resources
4. Add provider-specific validation
5. Extend outputs with provider-specific information
