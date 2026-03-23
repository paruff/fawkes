# Documentation Style Guide

This guide defines writing conventions for Fawkes documentation. Consistent style
makes the docs easier to read, maintain, and search — and signals to readers that
the content is trustworthy and well-maintained.

## Writing Principles

**Write for your reader, not yourself.** Assume the reader is a capable developer
who is new to this specific topic. Do not assume they know your team's history or
internal jargon.

**Active voice.** Write "Run the command" not "The command should be run". Active
voice is shorter, clearer, and easier to translate.

**Second person.** Address the reader as "you". "You can configure..." not
"One can configure..." or "Users can configure...".

**Be concrete.** Prefer specific, working examples over abstract descriptions.
Show the actual command, the real file path, the exact error message.

**Be brief.** If something can be said in 10 words, don't use 30. Long sentences
obscure meaning. Short paragraphs are easier to scan.

## Headings

Use title case for top-level headings (`# Title Case`). Use sentence case for all
other headings (`## Sentence case`).

Do not skip heading levels — `###` must follow `##`, not `#`.

Every page starts with exactly one `# H1` heading matching the page title.

## Code Blocks

Always specify the language for syntax highlighting:

````markdown
```bash
kubectl get pods -n fawkes
```
````

Use `bash` for shell commands, `yaml` for Kubernetes manifests, `python` for Python,
`hcl` for Terraform. Do not use `shell` or `sh` — use `bash`.

Include a comment at the top of multi-line scripts to describe what they do:

```bash
# Deploy all platform components to local cluster
make deploy-local COMPONENT=all
```

## Links

Use descriptive link text — never "click here" or "this link":

```markdown
✅ See [GitOps Strategy](../explanation/architecture/gitops-strategy.md)
❌ See [this](../explanation/architecture/gitops-strategy.md)
```

All internal links are relative paths. Never use absolute URLs for links within docs.

## Admonitions

Use Material admonitions to call out important information:

```markdown
!!! note
    This only applies to Azure deployments.

!!! warning
    Running this command will delete the namespace and all its resources.

!!! tip
    You can skip this step if you are using the sandbox environment.
```

Use `note` for context, `warning` for destructive or irreversible actions,
`tip` for shortcuts, `info` for supplementary information.

## Page Structure

Every page should follow this structure:
1. `# Title` — What this page is about (one sentence implied by the title)
2. Opening paragraph — What the reader will learn or be able to do
3. Body — Headings, prose, code examples
4. "## See Also" or "## Related Documentation" — 2–4 links to related pages

## Terminology

| Preferred | Avoid |
|-----------|-------|
| "Kubernetes cluster" | "K8s cluster" (in running text) |
| "GitOps" | "gitops", "git-ops" |
| "ArgoCD" | "Argo CD", "Argo" |
| "Backstage" | "backstage" (lowercase) |
| "Fawkes platform" | "the platform" (ambiguous) |

## See Also

- [Contributing](contributing.md)
- [Documentation Quality Pattern](patterns/documentation-quality.md)
- [MkDocs](tools/mkdocs.md)
