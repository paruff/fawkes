# ⚠️ DEPRECATED MODULE

> **This module is deprecated and will be removed in a future release.**

## Status

**Deprecated** — do not use for new configurations.

## Canonical Replacement

Use `infra/terraform/modules/azure/network` instead.

```hcl
# Before (deprecated)
module "network" {
  source                  = "./modules/azure-network"
  vnet_name               = "fawkes-vnet"
  location                = "eastus2"
  resource_group_name     = module.rg.name
  address_space           = ["10.0.0.0/16"]
  subnet_name             = "aks-subnet"
  subnet_address_prefixes = ["10.0.1.0/24"]
}

# After (canonical)
module "network" {
  source                  = "./modules/azure/network"
  vnet_name               = "fawkes-vnet"
  location                = "eastus2"
  resource_group_name     = module.rg.name
  address_space           = ["10.0.0.0/16"]
  subnet_name             = "aks-subnet"
  subnet_address_prefixes = ["10.0.1.0/24"]
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

This standalone module duplicates `infra/terraform/modules/azure/network/`, which is the
canonical implementation aligned with the multi-cloud module hierarchy introduced in
Task 4.1.1. The canonical module extends the base module with validation rules and provider-specific
enhancements.

## Support

For questions or migration assistance:
- Review [`../azure/network/README.md`](../azure/network/README.md)
- Consult [`../REFACTORING.md`](../REFACTORING.md)
- Open an issue referencing **FAW-BUG-08**
