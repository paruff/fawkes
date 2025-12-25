# Deprecated: AKS module moved

This folder is deprecated. The Azure Terraform for AKS and related services has been consolidated under `infra/azure`.

Use `infra/azure` for:

- AKS cluster and node pools
- VNet/Subnet networking
- Log Analytics
- Container Registry (ACR)
- Key Vault
- Storage accounts
- Backup/DNS (optional)

Ignite uses `infra/azure` automatically:

```zsh
./scripts/ignite.sh -p azure --location "East US" --cluster-name fawkes-dev dev
```
