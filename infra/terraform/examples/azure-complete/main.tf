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

locals {
  tags = {
    platform    = "fawkes"
    managed_by  = "terraform"
    environment = var.environment
  }
}

# Create Azure Resource Group
module "resource_group" {
  source = "../../modules/azure-resource-group"

  name     = "fawkes-${var.environment}-rg"
  location = var.location
  tags     = local.tags
}

# Create Virtual Network and Subnet
module "network" {
  source = "../../modules/azure-network"

  vnet_name           = "fawkes-${var.environment}-vnet"
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = ["10.0.0.0/16"]

  subnet_name             = "aks-subnet"
  subnet_address_prefixes = ["10.0.1.0/24"]

  tags = local.tags
}

# Create AKS Cluster
module "aks_cluster" {
  source = "../../modules/azure-aks-cluster"

  cluster_name        = "fawkes-${var.environment}-aks"
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.network.subnet_id

  node_vm_size = "Standard_B2ms"
  node_count   = 3

  network_plugin = "azure"
  service_cidr   = "10.1.0.0/16"
  dns_service_ip = "10.1.0.10"

  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

  tags = local.tags
}

# Deploy ArgoCD to AKS Cluster
# Note: This requires local kubeconfig to be configured after AKS is created
# Run: az aks get-credentials --resource-group <rg> --name <cluster>
# Then apply this separately or use null_resource with local-exec
