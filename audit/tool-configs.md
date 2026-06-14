# Tool Configuration Directory Audit — paruff/fawkes

**Date:** 2026-06-13
**Total config files:** 29 across `.trunk/`, `.vscode/`, and project root

---

## 1. `.trunk/` Directory

### Files

| File | Purpose |
|------|---------|
| `.trunk/trunk.yaml` | Trunk IO orchestrator config |
| `.trunk/.gitignore` | Trunk internal gitignore |
| `.trunk/configs/.shellcheckrc` | ShellCheck overrides (Trunk) |
| `.trunk/configs/.hadolint.yaml` | Hadolint overrides (Trunk) |
| `.trunk/configs/svgo.config.mjs` | SVGO config (Trunk) |
| `.trunk/configs/.yamllint.yaml` | yamllint overrides (Trunk) |
| `.trunk/configs/.markdownlint.yaml` | markdownlint overrides (Trunk) |

### `.trunk/trunk.yaml` Summary

- **CLI version:** 1.25.0
- **Plugins:** trunk-io/plugins v1.7.2
- **Runtimes:** go@1.21.0, node@22.16.0, python@3.10.8
- **Linters enabled:** actionlint, checkov, git-diff-check, hadolint, markdownlint, osv-scanner, oxipng, prettier, shellcheck, shfmt, svgo, tflint, trufflehog, yamllint (13 tools)
- **Git hooks disabled:** trunk-announce, trunk-check-pre-push, trunk-fmt-pre-commit

---

## 2. `.vscode/` Directory

### `.vscode/settings.json`
- Format on save enabled for all languages
- Python: black formatter, flake8 linting (deprecated settings)
- Go: gofmt, golangci-lint
- Shell: shell-format
- YAML/JSON/MD/JS/TS: prettier
- Terraform: hashicorp.terraform
- References `.prettierrc` and `.prettierignore`

### `.vscode/extensions.json`
15 recommended extensions: Python, Black, Pylance, Go, ShellFormat, ShellCheck, Prettier, YAML, Markdownlint, Terraform, Docker, Kubernetes, Gitleaks, Git Graph, EditorConfig.

### Classification

| File | Team-Shareable | Recommendation |
|------|---------------|----------------|
| `settings.json` | YES | Keep tracked — shared project settings |
| `extensions.json` | YES | Keep tracked — recommended extensions |

---

## 3. Overlapping / Conflicting Configs

### CRITICAL: Three tools have CONFLICTING configs between `.trunk/` and root

| Tool | Root Config | Trunk Config | Conflict |
|------|-------------|--------------|----------|
| **ShellCheck** | `.shellcheckrc`: severity=warning, disables SC2155/SC2034/SC1090/SC2046/SC2038/SC2183/SC2120 | `.trunk/configs/.shellcheckrc`: enable=all, disables SC2154 only | **DIFFERENT.** Trunk enables everything; root disables 7 rules. |
| **yamllint** | `.yamllint`: extends default, line-length 120, indentation, braces, truthy | `.trunk/configs/.yamllint.yaml`: quoted-strings, key-duplicates, octal-values (7 rules) | **DIFFERENT.** Completely different rule sets. |
| **markdownlint** | `.markdownlint.json`: disables 21 specific MD rules | `.trunk/configs/.markdownlint.yaml`: extends prettier style preset | **DIFFERENT.** Root disables most rules; Trunk uses a different preset. |

### OVERLAPPING: Same tool, multiple locations

| Tool | Locations | Issue |
|------|-----------|-------|
| **flake8** | `.flake8` + `pyproject.toml [tool.flake8]` | `.flake8` has 10 ignores; pyproject.toml has 2. Flake8 reads `.flake8` first — pyproject.toml section is dead config. |
| **GitGuardian** | `.gitguardian.yaml` + `.gitguardian.yml` | **IDENTICAL content.** One should be removed. |
| **prettier** | `.prettierrc` + `.vscode/settings.json` + `.trunk/trunk.yaml` | Consistent — VS Code points to `.prettierrc`, Trunk runs prettier using same config. |

### Single Source of Truth (OK)

| Tool | Config Location |
|------|----------------|
| ruff | `pyproject.toml [tool.ruff]` |
| black | `pyproject.toml [tool.black]` |
| isort | `pyproject.toml [tool.isort]` |
| pytest | `pyproject.toml [tool.pytest.ini_options]` |
| TFLint | `.tflint.hcl` |
| terraform-docs | `.terraform-docs.yml` |
| gitleaks | `.gitleaks.toml` |
| pre-commit | `.pre-commit-config.yaml` |
| editorconfig | `.editorconfig` |

---

## 4. Additional Issues

| # | Issue | Severity |
|---|-------|----------|
| 1 | `.trunk/configs/.shellcheckrc` conflicts with root `.shellcheckrc` | HIGH |
| 2 | `.trunk/configs/.yamllint.yaml` conflicts with root `.yamllint` | HIGH |
| 3 | `.trunk/configs/.markdownlint.yaml` conflicts with root `.markdownlint.json` | HIGH |
| 4 | `pyproject.toml [tool.flake8]` is dead config (flake8 reads `.flake8`) | MEDIUM |
| 5 | `.gitguardian.yaml` and `.gitguardian.yml` are identical duplicates | MEDIUM |
| 6 | `.trivyignore` is effectively empty (all issues resolved) | LOW |
| 7 | VS Code uses deprecated Python settings (`python.formatting.provider`, etc.) | LOW |
| 8 | Trunk declares `python@3.10.8` but `pyproject.toml` targets `py311` | LOW |
| 9 | Trunk disables `trunk-fmt-pre-commit` and `trunk-check-pre-push` hooks | LOW |

---

## 5. Consolidation Recommendations

### Trunk vs Standalone Conflict Resolution

**Recommendation:** Since the pre-commit hooks use the root config files (`.shellcheckrc`, `.yamllint`, `.markdownlint.json`) and Trunk is configured to run manually (hooks disabled), the **root configs are authoritative**. The `.trunk/configs/` overrides should either:

1. **Be removed** if Trunk is not actively used as a CI gate, OR
2. **Be synchronized** with the root configs to avoid confusion

### Specific Fixes

| Fix | Action | Priority |
|-----|--------|----------|
| Remove `.gitguardian.yaml` | Keep `.gitguardian.yml` (canonical) | MEDIUM |
| Remove `pyproject.toml [tool.flake8]` section | Dead config; `.flake8` is authoritative | MEDIUM |
| Sync or remove `.trunk/configs/` overrides | Align with root configs or delete | MEDIUM |
| Update VS Code deprecated settings | Use `ms-python.black-formatter.args` instead of `python.formatting.*` | LOW |
| Fix Trunk Python version | Change `python@3.10.8` to `python@3.11` | LOW |
