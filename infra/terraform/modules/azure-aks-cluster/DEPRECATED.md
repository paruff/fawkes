# ⚠️ DEPRECATED MODULE

> **This module is deprecated and will be removed in a future release.**

## Status

**Deprecated** — do not use for new configurations.

## Canonical Replacement

Use `infra/terraform/modules/azure/kubernetes-cluster` instead.

```hcl
# Before (deprecated)
module "aks" {
  source              = "./modules/azure-aks-cluster"
  cluster_name        = "fawkes-aks"
  location            = "eastus2"
  resource_group_name = module.rg.name
  subnet_id           = module.network.subnet_id
  node_vm_size        = "Standard_B2ms"
  node_count          = 3
}

# After (canonical)
module "aks" {
  source              = "./modules/azure/kubernetes-cluster"
  cluster_name        = "fawkes-aks"
  location            = "eastus2"
  resource_group_name = module.rg.name
  subnet_id           = module.network.subnet_id
  node_vm_size        = "Standard_B2ms"
  node_count          = 3
}
```

## Migration Guide

See [`REFACTORING.md`](../REFACTORING.md) for the full step-by-step migration guide.

## Deprecation Timeline

| Date | Action |
|------|--------|
| 2025-01-10 | Module marked as deprecated |
| 2025-07-31 | Module scheduled for removal |

## Why Deprecated?

This standalone module duplicates `infra/terraform/modules/azure/kubernetes-cluster/`, which
is the canonical implementation aligned with the multi-cloud module hierarchy introduced in
Task 4.1.1. The canonical module extends the base module with validation rules and provider-specific
enhancements.

## Support

For questions or migration assistance:
- Review [`../azure/kubernetes-cluster/README.md`](../azure/kubernetes-cluster/README.md)
- Consult [`../REFACTORING.md`](../REFACTORING.md)
- Open an issue referencing **FAW-BUG-08**
