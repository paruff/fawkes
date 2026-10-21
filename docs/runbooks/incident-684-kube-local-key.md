# Incident #684: private key committed in `.kube.local.yaml`

## Summary

A Docker Desktop kubeconfig (`.kube.local.yaml`, client certificate + private key,
server `https://127.0.0.1:51726`) was committed to this public repo and stayed
tracked at HEAD until this change. Introduced in `353afabf` (2025-11-17); further
copies in `9a2a3bec` and `03d36dba` (2025-12-25/26, a different key).

Impact is limited to the Docker Desktop cluster on the machine that generated the
key (loopback address), but the key is public and must be treated as compromised.

## Why the scan missed it

`.gitleaks.toml` had no `[extend] useDefault = true`, so it ran with no rules, and
it allowlisted `tests/.*` and `.kube.local.yaml` outright. A full-history scan with
the default rules (2694 commits, `--max-target-megabytes 2`) reports 127 findings.

## Actions

| Step | Status | Owner |
| --- | --- | --- |
| Untrack file, add to `.gitignore` | Done in this PR | agent |
| Rotate: reset Kubernetes in Docker Desktop (regenerates certs/keys) | Pending | human |
| Purge from history (`git filter-repo --path .kube.local.yaml --invert-paths`), force-push, re-clone | Done 2026-10-16 for `main`, all other branches and tags. Everyone must re-clone | human |
| Ask GitHub Support to drop cached views and GC the old commits `353afabf`, `9a2a3bec`, `03d36dba`, still reachable from `refs/pull/*/head` (read-only refs) | Pending | human |
| Re-run `gitleaks detect --log-opts="--all"` on a fresh remote clone | Done 2026-10-16: 0 hits reachable from branches/tags; 3 remain only via `refs/pull/*` | agent |
| Fix `.gitleaks.toml`: `[extend] useDefault = true`, drop blanket path allowlists, add rule-scoped allowlists | Pending triage of the findings below | human |

## Other history findings needing triage (values not recorded here)

Mostly false positives: SealedSecret ciphertext (`*-sealed.yaml`), doc and README
curl/API-key examples. Review whether these are real or intended dev defaults:

- `platform/apps/devlake/devlake-application.yaml`, `devlake-db-credentials-dev.yaml`
- `platform/apps/postgresql/db-sonarqube-credentials.yaml`
- `platform/apps/tekton/eventlistener-github-skeleton.yaml`
- `platform/apps/jenkins/values.yaml`
- `platform/apps/ingress-nginx/test-ingress.yaml` (private-key)
- `infra/platform/k8s-eks/prometheus/additional-scrape-configs*.yaml`
- `scripts/test-check-secret-detection.sh`, `services/ai-code-review/prompts/security.txt` (test fixtures)
