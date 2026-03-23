# Docusaurus

[Docusaurus](https://docusaurus.io/) is an open-source documentation platform built
with React, developed and used by Meta. It is designed for product documentation sites
and developer portals, with first-class support for MDX (Markdown + JSX components),
versioned docs, and i18n.

## Docusaurus vs MkDocs

Fawkes uses MkDocs for the main platform documentation site. Docusaurus is relevant as
an alternative for teams that prefer a React-based approach or need interactive
documentation components.

| Feature | Docusaurus | MkDocs |
|---------|-----------|--------|
| Language | JavaScript/React | Python |
| MDX support | ✅ | ❌ |
| Versioned docs | ✅ Built-in | Plugin required |
| Backstage TechDocs | Plugin available | ✅ Native |
| Build speed | Slower | Fast |
| Customisation | High (React) | Moderate (themes) |

## When to Use Docusaurus

Consider Docusaurus for service-level documentation when:
- Your team is JavaScript-heavy and prefers React tooling
- You need interactive documentation components (live code editors, prop tables)
- You require multiple documentation versions for an API with breaking changes

## Backstage TechDocs Integration

Backstage TechDocs natively supports MkDocs. A Docusaurus plugin exists but requires
additional configuration. If you are adding docs to the Backstage catalog, MkDocs is
the lower-friction choice.

## Quick Setup

```bash
npx create-docusaurus@latest my-service-docs classic
cd my-service-docs
npm run start   # live preview at http://localhost:3000
npm run build   # static output in build/
```

## See Also

- [MkDocs](mkdocs.md)
- [Using TechDocs](../how-to/techdocs-usage.md)
- [Documentation Quality Pattern](../patterns/documentation-quality.md)
