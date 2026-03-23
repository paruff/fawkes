# Documentation Quality Pattern

Good documentation is a platform feature. The DORA 2025 report identifies documentation
quality as a direct enabler of developer experience and, through it, of software delivery
performance. A developer who can self-serve from documentation is a developer who can
stay in flow.

## Docs as Code

Fawkes treats documentation with the same rigour as application code:

- **Version-controlled** — All docs live in the `docs/` directory in Git
- **Reviewed** — Documentation changes go through pull requests
- **Tested** — `mkdocs build --strict` runs in CI; broken links and missing pages fail the build
- **Continuously deployed** — The documentation site rebuilds on every merge to `main`

## The Diátaxis Framework

Fawkes organises documentation according to [Diátaxis](https://diataxis.fr/), a
four-quadrant model for technical documentation:

| Type | Answers | Examples |
|------|---------|---------|
| **Tutorial** | "How do I learn?" | Deploy your first service |
| **How-To Guide** | "How do I do X?" | Rotate Vault secrets |
| **Reference** | "What is X?" | API endpoints, CLI flags |
| **Explanation** | "Why does X work this way?" | GitOps strategy, Zero trust model |

Every new page must fit into one of these four quadrants. "Tutorial-style how-to guides"
or "reference that explains concepts" are a sign the content should be split.

## Writing Principles

- **Active voice** and second person: "Run the command" not "The command should be run"
- **Show, don't just tell** — include working code examples with copy buttons
- **Link generously** — connect concepts to their tutorials and how-to guides
- **Keep it current** — a doc that describes the wrong thing is worse than no doc

## CI Enforcement

The `scripts/check-docs.sh` script enforces:
1. Every nav entry points to a file with ≥ 200 words
2. No nav page contains only a heading and "TODO"
3. `mkdocs build --strict` exits 0 (zero broken links, zero missing files)

## TechDocs Integration

Service-level documentation lives in each service repository alongside code and
appears in the Backstage software catalog via TechDocs. Each service's `catalog-info.yaml`
points to its `mkdocs.yml`.

## See Also

- [MkDocs](../tools/mkdocs.md)
- [Documentation Style Guide](../style-guide.md)
- [Contributing](../contributing.md)
