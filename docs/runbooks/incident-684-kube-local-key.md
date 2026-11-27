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
| Fix `.gitleaks.toml`: `[extend] useDefault = true`, drop blanket path allowlists, add rule-scoped allowlists | Done 2026-11-27 | agent |

## Full history scan, 2026-11-27

**Decision (owner, [#684](https://github.com/paruff/fawkes/issues/684)): no further history rewrite.**
The repo is public, so anything pushed is already out, and a force-push breaks every clone and fork.

`gitleaks git --redact` (8.30.1, default rules) over `main` (2,958 commits) found 69 hits and no
live credential:

| Finding | Verdict |
| --- | --- |
| Docs and README examples (curl auth headers, default logins, sample API keys) | Examples |
| `*-sealed.yaml` | SealedSecret ciphertext |
| `platform/apps/ingress-nginx/test-ingress.yaml` private key | Self-signed test certificate, removed from `main` |
| `platform/apps/jenkins/values.yaml` | Plugin version strings, file removed |
| `infra/platform/k8s-eks/prometheus/additional-scrape-configs*.yaml` | Scrape config without credentials, removed |
| `scripts/`, `services/ai-code-review/prompts/security.txt` | Test fixtures and a local default login |
| `platform/apps/tekton/eventlistener-github-skeleton.yaml` (`secretToken`) | Local-dev-only value, still on `main` |
| `platform/apps/devlake/devlake-application.yaml` (MySQL passwords; an admin password in history only) | Local-dev-only values, MySQL ones still on `main` |
| `platform/apps/postgresql/db-sonarqube-credentials.yaml` | Local-dev-only values, still on `main` |

The last three are **not** allowlisted. They are replaced under
[#1797](https://github.com/paruff/fawkes/issues/1797); until then a scan reports them and the
`Security & Terraform Validation` workflow (not a required check) fails. They are committed local-dev
defaults, not credentials for any shared system, so nothing is rotated.

Still open from the kubeconfig incident above: the Docker Desktop reset and the GitHub Support request.
Off `main`, the all-ref scan found no kubeconfig reachable from a remote branch or tag.

To repeat the scan:

```bash
gitleaks git --redact --log-opts=origin/main .
```

## Prevention

- `.gitleaks.toml` loads the default rules. Before this it had none, so every run that loaded it
  passed while checking nothing. `tests/unit/test_gitleaks_config.py` guards this.
- The `gitleaks` pre-commit hook checks staged changes on developer machines.
- `Security & Terraform Validation` scans the checked-out tree on pull requests and pushes to `main`.
- Gap: the `gitleaks` step in `.github/workflows/pre-commit.yml` scans only staged changes, and CI
  has none, so that step checks nothing.
- Gap: GitHub secret scanning is on (no alerts on 2026-11-27), but push protection is off.
