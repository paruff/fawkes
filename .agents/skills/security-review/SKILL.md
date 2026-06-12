---
name: security-review
description: "Pre-merge security checklist covering secrets, dependencies, auth, data handling, and fawkes suite gates. Use when reviewing a PR for security issues or hardening a change before merge."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Security Review

> **Load trigger:** `"load security-review skill"` > **DORA:** Cap 1 (AI Policy)
> **Token cost:** Low

## Pre-Merge Security Checklist

### Secrets Gate (block on any finding)

- [ ] No hardcoded API keys, tokens, passwords in diff
- [ ] `.env` files not committed
- [ ] No private keys, certs, or `.p12` files
- [ ] `.gitignore` covers `.env.*`, `*.pem`, `*.key`, `secrets/`
- [ ] GitHub Actions secrets accessed via `${{ secrets.NAME }}` not inline

### Dependency Gate (review each new dep)

- [ ] Each new dependency pinned to exact version
- [ ] New deps documented in PR description with justification
- [ ] PM sign-off noted if dep adds native binary or increases bundle > 10%
- [ ] No known-deprecated packages (verify in language ecosystem registry)

### Auth/Authz Gate

- [ ] New routes have authentication guards
- [ ] Authorization checks are server-side, not client-side only
- [ ] Token storage follows platform convention (httpOnly cookie or secure storage)
- [ ] No auth bypasses for test convenience left in production paths

### Data Gate

- [ ] No PII in log statements
- [ ] No PII in OTEL span attributes (user IDs OK, names/emails not OK)
- [ ] Database queries parameterized (no string concatenation with user input)
- [ ] Data handling complies with AGENTS.md §1 data policy

### fawkes Suite Gate

- [ ] New dependencies appear in SBOM output (Syft)
- [ ] New container images signed via Cosign
- [ ] `.gitleaks.toml` covers new secret patterns if any were introduced
- [ ] Kyverno policies satisfied for new Kubernetes resources

## Quick Remediation Reference

| Finding             | Fix                                                          |
| ------------------- | ------------------------------------------------------------ |
| Hardcoded secret    | Remove, rotate credential, add to `.gitignore`, use env var  |
| Unpinned action     | Pin to commit SHA: `uses: actions/checkout@11bd71901...`     |
| Missing auth guard  | Add middleware at router level, not per-handler              |
| PII in logs         | Replace with ID or hash; add lint rule to prevent recurrence |
| Missing SBOM update | Re-run Syft after dependency change                          |
