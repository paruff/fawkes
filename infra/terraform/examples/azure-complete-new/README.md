# Azure Complete Example (New Module Structure)

This example uses the new module structure with base modules and provider-specific implementations.

## Module References

- `azure/resource-group` - Azure Resource Group
- `azure/network` - Azure Virtual Network
- `azure/kubernetes-cluster` - Azure AKS cluster

## Differences from Old Example

The old example (`azure-complete`) uses deprecated module paths:
- `azure-resource-group` → `azure/resource-group`
- `azure-network` → `azure/network`
- `azure-aks-cluster` → `azure/kubernetes-cluster`

Both examples are functionally identical. Use this one for new deployments.

See [REFACTORING.md](../../modules/REFACTORING.md) for migration details.

