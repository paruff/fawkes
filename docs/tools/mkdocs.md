# MkDocs

[MkDocs](https://www.mkdocs.org/) is a fast, simple static site generator for project
documentation, written in Python. Fawkes uses MkDocs with the
[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) theme to build and
serve this documentation site.

## How Fawkes Uses MkDocs

All documentation lives under `docs/` and is configured in `mkdocs.yml` at the repository
root. The navigation structure, theme settings, and Markdown extensions are all declared
there.

```bash
# Serve docs locally with live reload
mkdocs serve

# Build static site (outputs to site/)
mkdocs build

# Build with --strict: warnings become errors
mkdocs build --strict
```

## Material Theme

The Material theme provides:
- Responsive navigation with tabs and sections
- Dark/light mode toggle
- Full-text search
- Code syntax highlighting
- Admonitions (`!!! note`, `!!! warning`, etc.)
- Mermaid diagram rendering

## Key Configuration

```yaml
# mkdocs.yml (excerpt)
site_name: Fawkes
theme:
  name: material
  features:
    - navigation.tabs
    - navigation.indexes
    - search.suggest
validation:
  nav:
    not_found: warn   # Nav entries to missing files are warnings
  links:
    not_found: warn   # Broken internal links are warnings
```

## Strict Mode and CI

The `scripts/check-docs.sh` script runs `mkdocs build --strict`, which treats any
warning as an error. CI will fail if:
- A nav entry points to a missing file
- An internal link in a doc file points to a missing page
- A nav page has fewer than 200 words

## Diátaxis Framework

Fawkes organises documentation using
[Diátaxis](https://diataxis.fr/): Tutorials, How-To Guides, Explanation, and Reference.
New pages should be placed in the appropriate section.

## See Also

- [Documentation Style Guide](../style-guide.md)
- [Contributing](../contributing.md)
- [Docusaurus](docusaurus.md)
