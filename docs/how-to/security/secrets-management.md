# Secrets Management and Detection

This guide explains how Fawkes prevents secrets from being committed to version control and how to handle secrets properly in your applications.

## Overview

Fawkes uses multiple layers of defense to prevent secrets from being exposed:

1. **Pre-commit hooks** - Catch secrets before they're committed locally
2. **CI/CD pipeline scanning** - Detect secrets in every build
3. **Container scanning** - Check container images for embedded secrets
4. **Documentation and training** - Educate developers on best practices

---

## Tools Used

### Gitleaks

**Primary secrets detection tool** used in both pre-commit hooks and CI/CD pipelines.

- Detects 100+ types of secrets (API keys, passwords, tokens, private keys)
- Configurable via `.gitleaks.toml`
- Fast and accurate with low false-positive rate

### detect-secrets (Yelp)

**Baseline-based secret detection** for managing known false positives.

- Uses `.secrets.baseline` to track known non-secret values
- Complementary to Gitleaks for additional coverage

### detect-private-key

**Specialized detection** for SSH private keys and certificates.

---

## How It Works

### Pre-commit Protection

When you commit code locally, pre-commit hooks automatically scan for secrets:

```bash
git add myfile.py
git commit -m "Add feature"
# ⚡ Pre-commit hooks run automatically
# ✅ Gitleaks: Passed
# ✅ detect-secrets: Passed
# ✅ detect-private-key: Passed
```

If secrets are detected, the commit is **blocked**:

```bash
❌ Gitleaks detected secrets:
   - AWS Access Key in config.yaml:12
   - GitHub Token in setup.sh:45

Your commit has been blocked. Please remove secrets and try again.
```

### Pipeline Protection

Every Jenkins pipeline includes a **Secrets Scan** stage:

```groovy
stage('Secrets Scan') {
    steps {
        container('gitleaks') {
            // Gitleaks scans entire repository
            sh 'gitleaks detect --source . --verbose'
        }
    }
}
```

**Pipeline fails immediately** if secrets are detected, preventing deployment of vulnerable code.

### What Gets Detected

Common secrets that are automatically detected:

- **API Keys**: AWS, Azure, GCP, GitHub, Slack, etc.
- **Passwords**: Database passwords, service credentials
- **Private Keys**: SSH keys, SSL certificates, JWT secrets
- **Tokens**: OAuth tokens, personal access tokens, session tokens
- **Connection Strings**: Database URLs with embedded credentials
- **Environment Variables**: Hardcoded secrets in ENV declarations

---

## Best Practices

### ✅ DO: Use Secret Management Tools

**HashiCorp Vault** (recommended for Fawkes):

```yaml
# Kubernetes pod with Vault integration
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "my-app"
    vault.hashicorp.com/agent-inject-secret-config: "secret/data/my-app"
spec:
  serviceAccountName: my-app
```

**External Secrets Operator** (for cloud providers):

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secrets
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: my-app-secrets
  data:
    - secretKey: api_key
      remoteRef:
        key: /my-app/api-key
```

### ✅ DO: Use Environment Variables

```bash
# In Dockerfile (reference only, not the value)
ENV API_KEY=""

# Inject at runtime via Kubernetes
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    env:
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: my-app-secrets
          key: api-key
```

### ✅ DO: Use Configuration Files (Gitignored)

```bash
# .gitignore
.env
.env.local
secrets.yaml
credentials.json
*.pem
*.key
```

```python
# Load from environment or file
import os
from pathlib import Path

# Prefer environment variables
api_key = os.getenv('API_KEY')

# Fallback to gitignored file
if not api_key:
    secrets_file = Path('.env')
    if secrets_file.exists():
        # Load from file (not in Git)
        pass
```

### ❌ DON'T: Hardcode Secrets

```python
# ❌ NEVER DO THIS
api_key = "sk-1234567890abcdef"  # DETECTED BY GITLEAKS
db_password = "MySecretPass123"   # DETECTED BY GITLEAKS
```

```yaml
# ❌ NEVER DO THIS
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
stringData:
  password: "hardcoded-secret"  # DETECTED BY GITLEAKS
```

### ❌ DON'T: Commit Example Secrets

Even in example code, avoid realistic-looking secrets:

```bash
# ❌ BAD - Looks like real AWS key
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE

# ✅ GOOD - Clearly a placeholder
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_HERE
```

---

## Configuration

### Gitleaks Configuration

Edit `.gitleaks.toml` to customize detection rules:

```toml
title = "Fawkes Gitleaks Configuration"

[allowlist]
description = "Allow placeholders used in educational materials"
regexes = [
  '''PLACEHOLDER_BASE64_VALUE''',
  '''CHANGEME_NOT_COMMITTED''',
  '''YOUR_.*_HERE''',
]
paths = [
  '''tests/.*''',
  '''.*test.*\.py''',
  '''examples/.*''',
]
```

### Baseline for False Positives

If Gitleaks detects a false positive, add it to the baseline:

```bash
# Generate new baseline
detect-secrets scan > .secrets.baseline

# Update existing baseline
detect-secrets scan --baseline .secrets.baseline
```

### Pre-commit Configuration

Enable/disable secret scanning in `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.1
    hooks:
      - id: gitleaks
        name: Detect secrets with Gitleaks
        
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        name: Detect secrets
        args: ['--baseline', '.secrets.baseline']
```

---

## Handling Detected Secrets

### If Pre-commit Blocks Your Commit

1. **Identify the secret** in the output
2. **Remove or replace** the secret:
   - Use environment variable reference
   - Use secret management tool
   - Add to `.gitignore` if it's a local config file
3. **Update .gitleaks.toml** if it's a false positive
4. **Try committing again**

```bash
# Fix the issue
vim config.yaml  # Remove hardcoded secret

# Commit again
git add config.yaml
git commit -m "Add feature (secrets removed)"
```

### If Pipeline Fails on Secrets Scan

1. **Download the Gitleaks report** from Jenkins artifacts
2. **Review detected secrets** in `gitleaks-report.json`
3. **Fix the issues** in your code
4. **Push the fix**:

```bash
git add .
git commit -m "fix: Remove hardcoded secrets"
git push
```

### If You Accidentally Committed a Secret

**CRITICAL**: If a real secret was committed to Git history:

1. **Rotate the secret immediately** - Assume it's compromised
2. **Remove from Git history**:

```bash
# Use BFG Repo-Cleaner or git filter-branch
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch config/secrets.yaml" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (requires admin privileges)
git push origin --force --all
```

3. **Update secret stores** (Vault, AWS Secrets Manager)
4. **Notify security team** if it's a production secret

---

## Testing Secret Detection

### Test Locally

```bash
# Run Gitleaks on your code
gitleaks detect --source . --verbose

# Run pre-commit hooks manually
pre-commit run --all-files

# Test specific hook
pre-commit run gitleaks --all-files
```

### Test in Pipeline

Add a test file with a fake secret to verify detection:

```python
# test_secrets_detection.py
def test_pipeline_blocks_secrets():
    """This should fail in CI/CD"""
    fake_aws_key = "AKIAIOSFODNN7EXAMPLE"  # Gitleaks will catch this
```

Commit and push - the pipeline should **fail** on the Secrets Scan stage.

---

## Integration Examples

### Python Application

```python
import os
from pathlib import Path
from dotenv import load_dotenv

# Load from .env file (gitignored)
load_dotenv()

# Get secrets from environment
DATABASE_URL = os.getenv('DATABASE_URL')
API_KEY = os.getenv('API_KEY')

if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable is required")
```

### Node.js Application

```javascript
// Load from .env file (gitignored)
require('dotenv').config();

// Get secrets from environment
const dbUrl = process.env.DATABASE_URL;
const apiKey = process.env.API_KEY;

if (!dbUrl) {
  throw new Error('DATABASE_URL environment variable is required');
}
```

### Go Application

```go
package main

import (
    "os"
    "github.com/joho/godotenv"
)

func main() {
    // Load from .env file (gitignored)
    godotenv.Load()
    
    // Get secrets from environment
    dbUrl := os.Getenv("DATABASE_URL")
    apiKey := os.Getenv("API_KEY")
    
    if dbUrl == "" {
        panic("DATABASE_URL environment variable is required")
    }
}
```

### Java Application

```java
public class Config {
    private static final String DB_URL = System.getenv("DATABASE_URL");
    private static final String API_KEY = System.getenv("API_KEY");
    
    static {
        if (DB_URL == null || DB_URL.isEmpty()) {
            throw new IllegalStateException("DATABASE_URL environment variable is required");
        }
    }
}
```

---

## FAQ

### Q: Can I disable secret scanning for a specific commit?

**A:** You can skip pre-commit hooks with `git commit --no-verify`, but this is **strongly discouraged**. The pipeline will still fail if secrets are detected.

### Q: What if I need to commit a test fixture with a fake secret?

**A:** Add it to the allowlist in `.gitleaks.toml`:

```toml
[allowlist]
paths = [
  '''tests/fixtures/.*''',
]
```

### Q: How do I update the secrets baseline?

**A:** Run:

```bash
detect-secrets scan --baseline .secrets.baseline
```

Review changes carefully before committing.

### Q: What's the performance impact?

**A:** Minimal:
- Pre-commit: ~2-5 seconds for typical changes
- Pipeline: ~10-20 seconds for full repository scan

### Q: Can I use TruffleHog instead of Gitleaks?

**A:** Yes, but Gitleaks is the default. To add TruffleHog:

```yaml
# .pre-commit-config.yaml
- repo: https://github.com/trufflesecurity/trufflehog
  rev: v3.63.0
  hooks:
    - id: trufflehog
      name: TruffleHog secret scan
      args: ['filesystem', '.', '--json']
```

---

## Resources

- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [HashiCorp Vault for Kubernetes](../../../platform/apps/vault/README.md)
- [External Secrets Operator](../../../platform/apps/external-secrets/README.md)
- [Pre-commit Hooks Setup](../../PRE-COMMIT.md)
- [Fawkes Security Architecture](../../architecture.md#security-architecture)

---

## Support

- **Found a secret in code?** Remove it and rotate immediately
- **False positive?** Update `.gitleaks.toml` allowlist
- **Questions?** Open a GitHub Discussion or contact the security team

---

**Remember**: Secrets in Git history are **permanent** and **compromised**. Prevention is the only secure approach. 🔒
