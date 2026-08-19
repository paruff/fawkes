---
name: security-fix-guardrails
description: Use before implementing any issue labeled type-security or comp-security, or any fix touching auth, RBAC, secrets, IAM, security groups, network policy, or crypto.
---

# Security Fix Guardrails

Most `type-security` issues in this repo are mechanical and safe to fix
directly: add a missing `securityContext` block, bump a dependency to a
patched version, add encryption/`readOnlyRootFilesystem` to a Terraform or
K8s resource. Fix those the same way as any other issue — root cause, small
diff, verify.

A smaller set need a human in the loop before or instead of an auto-fix.
Route to that path whenever the issue or the fix touches:

- Authentication, authorization, or RBAC logic
- Secrets, credentials, tokens, or any `ConfigMap`/`Secret` handling
- IAM policies, security groups, network ingress/egress rules
- Cryptographic code (hashing, signing, encryption implementations)
- Anything already flagged in the issue as "inspect before fixing" or similar

For these: still do the investigation and propose the fix, but say so
explicitly in the PR description or comment — call out that it's a
security-sensitive change needing manual review rather than opening it as if
it were routine. Never merge a security-sensitive change yourself even if
`/oc` has write access to open PRs.

## Repo-specific rules that already cover this

- `AGENTS.md` §9: any `infra/` change requires a second human reviewer —
  applies to every Terraform security fix (SG rules, IAM, encryption), not
  just infra changes in general.
- `AGENTS.md` §12: "Auth, RBAC, secrets, or any infra-touching change" is
  security-sensitive by default.
- Never widen a `try`/`except` or add a broad exception handler to make a
  security scanner finding disappear — that hides the finding, it doesn't
  fix it. If a scanner flag looks like a false positive, say so and explain
  why instead of suppressing it.

## Verifying a security fix specifically

Beyond the normal test/lint run (see `verify-before-done`):
- For a CVE/dependency bump: confirm the new version range actually excludes
  the vulnerable version (check the advisory, don't just bump and assume).
- For a K8s/Terraform hardening change: run `helm template`/`terraform plan`
  and confirm the rendered output actually has the intended field — a
  misplaced YAML key silently no-ops the fix.
