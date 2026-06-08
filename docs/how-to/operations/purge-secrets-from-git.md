# Purge Secrets from Git History

> **Status**: HUMAN-ONLY — requires coordinated force-push
> **Issue**: #684
> **Created**: June 8, 2026

## Why This Is Human-Only

- Requires **force-push** to `main` — breaks all open PRs
- All contributors must re-clone or reset their local repos
- Must coordinate with any CI/CD systems that cache the old history
- BFG Repo-Cleaner must be run locally with repo access

## Pre-Flight Checklist

- [ ] All open PRs are merged or closed
- [ ] Team notified of upcoming force-push
- [ ] CI/CD caches cleared (GitHub Actions, any mirrors)
- [ ] Backup of repo created: `gh repo fork paruff/fawkes --clone=false`

## Steps

### 1. Identify secrets to purge

```bash
# Find all plaintext Secret resources
grep -rn "password:" platform/apps/ | grep -v "CHANGE_ME" | grep -v "#"

# Find committed .env files or key material
git log --all --diff-filter=A --name-only -- '*.env' '*.pem' '*.key'
```

### 2. Install BFG Repo-Cleaner

```bash
# macOS
brew install bfg

# Or download JAR
curl -L -o bfg.jar https://rtyley.github.io/bfg-repo-cleaner/downloads/bfg-1.14.0.jar
```

### 3. Clone a fresh mirror

```bash
git clone --mirror git@github.com:paruff/fawkes.git fawkes-mirror
cd fawkes-mirror
```

### 4. Run BFG to remove secrets

```bash
# Remove specific files
bfg --delete-files 'db-backstage-credentials.yaml'
bfg --delete-files 'secrets.yaml'

# Or replace passwords in files
bfg --replace-text passwords.txt
# passwords.txt format:
# password123==>REPLACED
# changeme-admin-password==>REPLACED
```

### 5. Clean up and force-push

```bash
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force
```

### 6. Post-push

- [ ] Force all contributors: `git fetch origin && git reset --hard origin/main`
- [ ] Update any mirrors or caches
- [ ] Verify CI passes on next PR
- [ ] Close issue #684

## Prevention (Future)

- Enable `checkov` or `trivy` secret scanning in CI
- Add Kyverno policy to reject plaintext K8s Secrets without `sealed-secrets` annotation
- Use Sealed Secrets (see `platform/apps/sealed-secrets/`) for all production secrets
