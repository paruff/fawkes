# Security Plane Quick Start Guide

Get your repository secured in under 10 minutes!

## Prerequisites

- GitHub repository with code
- GitHub Actions enabled
- Admin access to repository

## Step 1: Copy Security Plane Files (2 minutes)

```bash
# Clone Fawkes repository (if not already)
git clone https://github.com/paruff/fawkes.git /tmp/fawkes

# Navigate to your repository
cd /path/to/your/repo

# Copy security plane directory
cp -r /tmp/fawkes/.security-plane .

# Commit the files
git add .security-plane
git commit -m "feat: add security plane configuration"
git push
```

## Step 2: Add Security Workflow (3 minutes)

Create `.github/workflows/security.yml`:

```yaml
name: Security Checks

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

permissions:
  contents: read
  security-events: write
  packages: write
  id-token: write

jobs:
  security:
    name: Security Plane
    uses: paruff/fawkes/.github/workflows/security-plane-adoption.yml@main
    with:
      enforcement-mode: advisory
      image-name: ${{ github.repository }}
      enable-signing: false
      enable-sbom: true
    permissions:
      contents: read
      security-events: write
      packages: write
      id-token: write
```

Commit and push:

```bash
git add .github/workflows/security.yml
git commit -m "feat: add security workflow"
git push
```

## Step 3: Verify Security Scan (2 minutes)

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Find the **Security Checks** workflow
4. Click on the latest run
5. Review the security scan results

✅ You should see:
- Secret scanning results
- Vulnerability scan results
- Policy check results
- SBOM generation (if applicable)

## Step 4: Review Results (3 minutes)

### Check GitHub Security Tab

1. Go to **Security** → **Code scanning**
2. Review any vulnerabilities found
3. Click on each alert for details

### Check Workflow Summary

1. In the Actions tab, click on your workflow run
2. Scroll to **Summary**
3. Review security badges and counts

### Common First Results

**✅ Good News**:
- "No secrets found"
- "All policy checks passed"
- "SBOM generated successfully"

**⚠️ Action Needed**:
- "Found X critical vulnerabilities"
- "Policy violations detected"
- "Secrets found in code"

## Next Steps

### If You Have Issues to Fix

1. **Review the findings** in GitHub Security tab
2. **Prioritize by severity**: Critical → High → Medium → Low
3. **Use issue templates** to track remediation:
   ```bash
   # Create issue from template
   gh issue create --template security-vulnerability.md
   ```
4. **Fix and re-scan**:
   ```bash
   # Make fixes
   git add .
   git commit -m "fix: address security vulnerabilities"
   git push
   ```

### If Everything Passes

Congratulations! 🎉 Consider:

1. **Enable stricter mode** after 1-2 weeks:
   ```yaml
   enforcement-mode: strict
   fail-on-critical: true
   ```

2. **Add security badge** to README.md:
   ```markdown
   ![Security](https://github.com/your-org/your-repo/workflows/Security%20Checks/badge.svg)
   ```

3. **Train team members** on security practices
4. **Schedule regular security reviews**

## Testing Locally (Optional)

Install tools for local testing:

### Install Conftest (Policy Testing)

```bash
# macOS
brew install conftest

# Linux
wget https://github.com/open-policy-agent/conftest/releases/download/v0.49.1/conftest_0.49.1_Linux_x86_64.tar.gz
tar xzf conftest_0.49.1_Linux_x86_64.tar.gz
sudo mv conftest /usr/local/bin/
```

Test policies locally:

```bash
conftest test k8s/*.yaml -p .security-plane/policies/
conftest test Dockerfile -p .security-plane/policies/
```

### Install Trivy (Vulnerability Scanning)

```bash
# macOS
brew install trivy

# Linux
wget https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.tar.gz
tar xzf trivy_0.48.0_Linux-64bit.tar.gz
sudo mv trivy /usr/local/bin/
```

Scan locally:

```bash
trivy fs . --severity HIGH,CRITICAL
trivy image myimage:tag
```

### Install Gitleaks (Secret Scanning)

```bash
# macOS
brew install gitleaks

# Linux
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_linux_x64.tar.gz
tar xzf gitleaks_8.18.1_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/
```

Scan locally:

```bash
gitleaks detect --source . --verbose
```

## Troubleshooting

### Workflow Fails Immediately

**Issue**: Workflow fails before any scans run

**Solution**:
1. Check workflow syntax: `yamllint .github/workflows/security.yml`
2. Verify permissions in workflow file
3. Ensure repository has Actions enabled

### Too Many False Positives

**Issue**: Legitimate code flagged as security issue

**Solution**:
1. Create `.security-plane/exemptions.yaml`
2. Add specific exemptions with justification
3. Re-run workflow

### SBOM Generation Fails

**Issue**: SBOM generation reports errors

**Solution**:
1. Ensure you have a package manifest (package.json, requirements.txt, etc.)
2. Check Syft supports your language
3. Try different SBOM format in workflow config

### Scans Take Too Long

**Issue**: Security workflow runs for more than 10 minutes

**Solution**:
1. Add `.trivyignore` to exclude large directories
2. Use workflow caching for scan databases
3. Run scans in parallel jobs

## Getting Help

- 📖 **Full Documentation**: [.security-plane/README.md](.security-plane/README.md)
- 🔧 **Onboarding Guide**: [.security-plane/onboarding/ONBOARDING.md](.security-plane/onboarding/ONBOARDING.md)
- 📋 **Reference Architecture**: [docs/security-plane/reference-architecture.md](docs/security-plane/reference-architecture.md)
- 💬 **Slack**: #fawkes-security
- 🐛 **GitHub Issues**: https://github.com/paruff/fawkes/issues

## What's Next?

After successfully onboarding:

1. **Week 1-2**: Run in advisory mode, catalog issues
2. **Week 3-4**: Fix critical and high-severity issues
3. **Week 5-6**: Enable progressive enforcement
4. **Week 7+**: Move to strict mode for production

See [Adoption Patterns](docs/security-plane/adoption-patterns.md) for detailed timeline.

---

**🎉 Congratulations on securing your repository!**

*You're now protected against secrets leaks, vulnerabilities, and security misconfigurations.*
