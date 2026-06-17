# Gitignore Audit — paruff/fawkes

**Date:** 2026-06-13
**Total tracked files:** 2,326
**.gitignore lines:** 236

---

## 1. What .gitignore Covers Well

| Category  | Patterns                                                      | Status            |
| --------- | ------------------------------------------------------------- | ----------------- |
| Terraform | `*.tfstate*`, `.terraform/`, `*.tfplan`, `*.tfvars`           | Working correctly |
| Python    | `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `build/`, `dist/` | Working correctly |
| Node      | `node_modules/`, `dist/`, `build/`                            | Working correctly |
| IDE       | `.idea/`, `.vscode/` (with exceptions), `*.swp`, `*.swo`      | Working correctly |
| OS        | `.DS_Store`, `Thumbs.db`                                      | Working correctly |
| Helm      | `*.tgz`, `Chart.lock`                                         | Working correctly |
| Logs      | `*.log`                                                       | Working correctly |
| Secrets   | `kubeconfig*`, `*.pem`, `*.key`, `*.crt`                      | Working correctly |

---

## 2. Tracked Files Matching Sensitive Patterns

### Safe (intentionally tracked)

| File                                   | Reason                                             |
| -------------------------------------- | -------------------------------------------------- |
| `.secrets.baseline`                    | detect_secrets config, no actual secrets           |
| `services/ai-code-review/.env.example` | Documented template with placeholder values        |
| `.vscode/settings.json`                | Intentionally allowlisted (shared project config)  |
| `.vscode/extensions.json`              | Intentionally allowlisted (shared recommendations) |
| `go.sum` (3 files)                     | Required for Go module verification                |
| `design-system/package-lock.json`      | Required for reproducible Node installs            |

### Kubernetes Secret Manifests (15 files)

All contain placeholder values (`changeme`, `CHANGE_ME_*`, empty strings). Risk levels:

| Risk            | Files                                                                                                                                                                                                                                                                                                                                                           |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **SAFE**        | `platform/apps/backstage/secrets.yaml`, `platform/apps/feedback-bot/secret.yaml`, `platform/apps/feedback-service/secrets.yaml`, `platform/apps/friction-bot/secret.yaml`, `platform/apps/jenkins/credentials-secrets.yaml`, `platform/apps/jenkins/jenkins-admin-secret.yaml`, `platform/apps/jenkins/secrets.yaml`, `services/smart-alerting/k8s/secret.yaml` |
| **LOW RISK**    | `extensions/data-platform/data-quality/secret.yaml`, `extensions/data-platform/datahub/datahub-frontend-secret.yaml`, `platform/apps/devex-survey-automation/secrets.yaml`                                                                                                                                                                                      |
| **MEDIUM RISK** | `platform/apps/hasura/secret.yaml` (guessable pattern), `platform/apps/space-metrics/secrets.yaml` (changeme in connection string), `services/ai-code-review/k8s/secret.yaml` (bare "changeme"), `services/nps/k8s/secret.yaml` (changeme passwords)                                                                                                            |

---

## 3. Tracked Files That Should NOT Be Ignored

These are correctly tracked despite matching some patterns:

| File                              | Why OK                               |
| --------------------------------- | ------------------------------------ |
| `go.sum`                          | Go module integrity verification     |
| `design-system/package-lock.json` | Reproducible Node installs           |
| `.vscode/settings.json`           | Shared project config (allowlisted)  |
| `.vscode/extensions.json`         | Shared recommendations (allowlisted) |

---

## 4. Large Files (potential repo size concern)

16 PNG images over 1MB:

| File                                       | Size            |
| ------------------------------------------ | --------------- |
| `docs/assets/images/fawkes-idp.png`        | 1.6 MB          |
| `docs/assets/images/icons/5F416F5A-...png` | 1.5 MB          |
| `docs/assets/images/icons/5CB6C0F1-...png` | 1.3 MB          |
| `docs/assets/images/icons/mttr.png`        | 1.3 MB          |
| _(12 more icon PNGs)_                      | 1.0–1.2 MB each |

---

## 5. Issues Found

| #   | Issue                                                                       | Severity |
| --- | --------------------------------------------------------------------------- | -------- |
| 1   | 15 K8s Secret YAMLs tracked (fragile pattern)                               | MEDIUM   |
| 2   | 16 PNG images over 1MB each                                                 | LOW      |
| 3   | `.gitignore` has remnants from Chef/Berkshelf/Vagrant template (lines 1–76) | LOW      |
| 4   | Duplicate/overlapping patterns (`*.tfstate`, `dist/`, `build/`)             | LOW      |

---

## 6. Recommended .gitignore Additions

| Pattern      | Justification                                                           |
| ------------ | ----------------------------------------------------------------------- |
| `scratch/`   | Working directory for temporary files                                   |
| `reports/`   | Generated test reports                                                  |
| `audit/`     | Generated audit reports                                                 |
| `*.backup.*` | Backup files (currently caught by `data/issues/` but pattern is useful) |

### Note on K8s Secrets

The 15 tracked Secret YAMLs are a fragile pattern. Consider adding a pre-commit hook that blocks commits of K8s Secret files containing non-placeholder values, or moving to `secret.yaml.example` templates with actual secrets gitignored.

---

## 7. No Critical Issues Found

- No tracked `.env` files with real secrets
- No tracked `.tfstate`, `.pem`, `.key`, `.crt`, or private key material
- No tracked `node_modules/`, `__pycache__/`, `.terraform/`, or build artifacts
- No tracked IDE-specific files beyond intentionally shared ones
