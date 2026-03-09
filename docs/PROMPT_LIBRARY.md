# Prompt Library — Fawkes IDP

> DORA AI Cap 2: Versioned, task-specific prompts. Update when a prompt produces
> repeated bad output and add a changelog entry.
> Because Fawkes is polyglot, prompts are organised by language/domain.

---

## Go — New Service Function (TDD)

**Context to open:** `services/{name}/`, `docs/API_SURFACE.md`, your failing test

```
Implement the Go function {{FUNCTION_NAME}} in services/{{service}}/{{file}}.go
to make this failing test pass.

Rules:
- Read AGENTS.md → Go Service Rules first
- Exported function requires godoc comment
- Errors wrapped with fmt.Errorf("{{function}}: %w", err) — never discarded
- No global mutable state
- Explicit return types
- Use table-driven test pattern if writing additional tests

Failing test:
{{PASTE_TEST}}
```

**Red flags:** Global var → reject. Missing godoc → reject. `_ = err` → reject.

---

## Go — Code Review

```
@review-agent Review this Go service change for Fawkes.
Read AGENTS.md → Go Service Rules and docs/ARCHITECTURE.md first.

Check:
1. ARCHITECTURE: Does this service call another service directly (should use API)? Cross-layer imports?
2. ERRORS: Are all errors wrapped with context? Any silently discarded?
3. TESTS: Table-driven? Edge cases (zero, empty, negative)? Test coverage for error paths?
4. GODOC: All exported types and functions documented?
5. DEPS: Any new go.mod dependency? If yes — flag for human approval.

For each finding: file, line, description, corrected code.
End with: "Ready for human review? YES / NO"
```

---

## Terraform — New Module

**Context:** Existing modules in `infra/`, `.tflint.hcl`

```
Create a new Terraform module in infra/{{module-name}}/ for {{purpose}}.

Rules:
- Read AGENTS.md → IaC Rules and .github/instructions/terraform.instructions.md first
- File structure: main.tf, variables.tf, outputs.tf, versions.tf
- Every variable needs description and type
- No hardcoded regions, account IDs, or credentials
- Required tags on all taggable resources: Project=fawkes, Environment=var.environment, ManagedBy=terraform
- Pinned provider versions in versions.tf
- Module must pass: terraform fmt -check, terraform validate, tflint

Module purpose: {{describe what the module provisions}}
Inputs needed: {{list inputs}}
Outputs needed: {{list outputs}}
```

---

## Terraform — Security Review

```
@security-agent Security review for this Terraform change.

Check:
1. SECRETS: Any hardcoded credentials, API keys, or account IDs?
2. IAM: Are permissions least-privilege? Any wildcard (*) actions or resources?
3. ENCRYPTION: Is encryption at rest enabled for storage resources?
4. NETWORK: Are security groups minimally scoped? No 0.0.0.0/0 on sensitive ports?
5. LOGGING: Is CloudTrail / audit logging enabled for sensitive resources?
6. PUBLIC ACCESS: Any S3 bucket, RDS, or EC2 with public access not explicitly required?

Change:
{{PASTE_TERRAFORM}}

For each finding: CRITICAL / HIGH / MEDIUM, resource, risk, corrected HCL.
```

---

## Helm — New Chart or Values Update

**Context:** `charts/`, existing `values.yaml` files

```
{{Create a new Helm chart / Update the values for}} {{chart-name}} in Fawkes.

Rules:
- Read .github/instructions/helm-platform.instructions.md first
- Required labels on all Deployment/Pod templates: app, version, component, managed-by: fawkes
- Required resource limits on every container
- No latest image tags — use {{ .Values.image.tag }} defaulting to chart appVersion
- Environment-specific values in override files, not base values.yaml
- Must pass: helm lint, helm template | kubectl apply --dry-run=client -f -

Purpose: {{describe what the chart deploys}}
Key configuration needed: {{list key values}}
```

---

## DORA Metrics — New Query / Dashboard Panel

**Context:** Existing DevLake config in `platform/apps/`, `docs/playbooks/dora-metrics-implementation/`

```
Write a DevLake / SQL query to calculate {{metric}} for the Fawkes platform.

Context:
- Data source: DevLake with GitHub, Jenkins, ArgoCD connectors
- Metric: {{metric name — e.g. "lead time for changes", "rework rate", "deployment frequency"}}
- Time window: {{e.g. last 30 days, last 90 days}}
- Scope: {{e.g. all services, services/score-transformer only}}

DORA 2025 definition of this metric: {{paste definition if non-standard}}

Output format needed: {{e.g. Grafana panel JSON, raw SQL, Python script}}

Reference: docs/METRICS.md for threshold definitions (elite / high / medium / low).
```

---

## Debugging — Helm Template Rendering

```
This Helm template renders incorrectly. Explain why and provide the corrected template.

Expected output: {{describe what the rendered YAML should look like}}
Actual output or error: {{paste error or rendered output}}

Template:
{{PASTE_TEMPLATE}}

Values used:
{{PASTE_VALUES}}

Check: Go template syntax, required vs optional values, type conversions (quote, int, bool).
```

---

## Debugging — ArgoCD Sync Failure

```
This ArgoCD Application is failing to sync. Explain why and provide the fix.

Application manifest: {{paste Application yaml}}
Sync error message: {{paste error from ArgoCD UI or CLI}}

Check:
1. Does the targetRevision branch/tag exist?
2. Does the chart path exist at that revision?
3. Are there Kubernetes API version deprecations (check kubectl deprecations)?
4. Are there Kyverno policy violations blocking admission?
5. Are image tags valid and the registry accessible from the cluster?
```

---

## Documentation — New How-To Guide (Diataxis)

**Context:** Existing guides in `docs/how-to/`, `mkdocs.yml`

```
Write a new Diataxis how-to guide for: {{task}}

Diataxis how-to rules:
- Title starts with a verb: "Configure X", "Deploy Y", "Rotate Z"
- Assumes the reader knows the basics — no tutorial-style explanations
- Steps are numbered, specific, and actionable
- Includes: Prerequisites section, Step-by-step instructions, Verification step
- Does NOT include: conceptual explanations (those go in explanation/), reference tables (those go in reference/)

Task: {{describe what the user is trying to accomplish}}
Audience: {{application developer / platform engineer / maintainer}}
Tools used: {{kubectl, terraform, helm, ArgoCD UI, etc.}}
```

---

## Changelog

| Date | Prompt Changed | Reason |
|---|---|---|
| 2026-03 | Initial library | Fawkes copilot template adoption |
