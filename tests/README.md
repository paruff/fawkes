# Fawkes Tests

How to run the test suites, what they cover, and what to expect.

## Quick start

```bash
make test-all        # unit + BATS + BDD + integration
pytest tests/unit -q # fastest gate: pure unit tests, no cluster needed
./tests/bats/run-tests.sh  # shell-script tests (BATS)
```

## Suites

| Suite              | Command                            | Needs cluster | Covers                                              |
| ------------------ | ---------------------------------- | ------------- | --------------------------------------------------- |
| Unit               | `pytest tests/unit -q`             | No            | Python helpers, routing logic, RAG indexing (skipped without `weaviate-client`) |
| BATS (shell)       | `./tests/bats/run-tests.sh`        | No            | `scripts/` helpers: error handling, state, AKS auth |
| BDD acceptance     | `make test-bdd`                    | Partial       | Gherkin scenarios in `tests/bdd/features/` (45+ scenarios still lack step definitions — see KL-05 in `docs/KNOWN_LIMITATIONS.md`) |
| Integration        | `pytest tests/integration -v`      | **Yes**       | Live-cluster checks (ArgoCD apps, Prometheus, Grafana). Fails without `KUBECONFIG`; use `make validate` for local validation instead |
| E2E                | `make test-e2e-integration-dry-run`| Yes           | Scaffold → deploy → metrics flow (dry-run first)    |
| Terratest (Go)     | `make terraform-test`              | No (validate) | Terraform validation only; integration/E2E deploy real Azure resources (costs apply) |

## Expected output

- Unit: `N passed, M skipped` (RAG tests skip when `weaviate-client` is not installed — expected per KL-02).
- BATS: per-file `ok` lines; one known isolation failure (`install_kubelogin`) is tracked tech debt.
- Integration without a cluster: `kubectl`/ArgoCD "not found" failures are expected — they prove the tests detect missing infrastructure rather than passing silently.

See [test strategy](../docs/test-strategy.md) for tiers, and [PR standard](../docs/PR_STANDARD.md) for CI gates.
