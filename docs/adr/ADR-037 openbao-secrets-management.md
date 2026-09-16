# ADR-037: OpenBao for Secrets Management

## Status

Accepted, not yet implemented - 2026-09-16

`platform/apps/` still deploys `vault`/`vault-csi-driver` as of this date. This ADR
records the decision to migrate; the migration itself is future work, tracked separately
(no issue number assigned as of this writing — file one before starting the cutover).

## Context

[ADR-015](ADR-015%20vault%20deployment.md) chose HashiCorp Vault for centralized secrets
management in HA mode with Kubernetes Auth, Vault Agent Sidecar, and CSI Secret Store
Driver injection. `AGENTS.md` §5 already states "Vault replaced with OpenBao (MPL-2.0)"
as platform policy, ahead of the actual cutover — this ADR is the decision record that
statement was missing.

### Why Move Off HashiCorp Vault

HashiCorp re-licensed Vault (and its other products) from MPL 2.0 to the Business Source
License (BSL) in August 2023. BSL is not OSI-approved open source: it restricts
competing commercial use and converts to MPL only after a delay period per release.
Fawkes is built as an open-source reference IDP (`AGENTS.md` §1) — shipping a BSL-licensed
core dependency conflicts with that positioning regardless of Fawkes' own non-competing
use case.

OpenBao is the Linux Foundation-governed fork of Vault's last MPL-2.0-licensed release,
maintained by ex-HashiCorp and community contributors, API-compatible with Vault's
Kubernetes Auth Method, Agent Sidecar, and CSI Provider interfaces that ADR-015 already
depends on.

## Decision

**OpenBao replaces HashiCorp Vault as Fawkes' secrets management backend.**

- API compatibility means ADR-015's architecture (HA mode, Kubernetes Auth Method, Agent
  Sidecar injection, CSI Secret Store Driver, coexistence with External Secrets Operator)
  carries over largely unchanged — this is a binary/Helm-chart swap, not a re-architecture.
- Migration path: deploy OpenBao alongside Vault, migrate secrets, cut over consumers
  (ESO `SecretStore` references, CSI `SecretProviderClass` references), then decommission
  Vault — mirroring this session's DevLake decommission pattern (parallel run, live-prune,
  not a hard cutover).
- No hardcoded credentials in Git or CI either way (`AGENTS.md` §5) — this constraint is
  unchanged by the migration.

## Consequences

### Positive

- Removes a BSL dependency from an open-source reference platform.
- No architectural rework — ADR-015's HA/Auth/injection design is reused as-is.

### Negative

- Migration effort: secrets re-provisioned, consumers re-pointed, a cutover window where
  both systems must be reconciled.
- OpenBao's plugin/community ecosystem is younger than Vault's — enterprise Vault features
  (some namespaces/replication tooling) may lag or differ.

## Related Decisions

- Supersedes (pending implementation) [ADR-015: HashiCorp Vault](ADR-015%20vault%20deployment.md)
- `AGENTS.md` §5 "Secrets Management (OpenBao)" — states the target policy this ADR
  formalizes
