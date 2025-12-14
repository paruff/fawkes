# Using TechDocs in Backstage

## Overview

TechDocs is a documentation solution built into Backstage that enables documentation-as-code. Documentation is written in Markdown, built with MkDocs, and rendered directly in the Backstage UI alongside your services in the catalog.

## Why TechDocs?

- **Single Source of Truth**: Documentation lives in the same repository as your code
- **Version Control**: Documentation is versioned with your code using Git
- **Easy Discovery**: Docs are automatically linked to services in the Backstage catalog
- **Consistent Experience**: All services have documentation in the same format
- **No Separate Systems**: No need to maintain a separate wiki or documentation site

## Architecture

The Fawkes platform uses TechDocs with the following configuration:

- **Builder**: `local` - Documentation is built on-demand within Backstage
- **Generator**: MkDocs with Material theme
- **Publisher**: `local` - Built docs are stored in the Backstage pod's filesystem
- **Storage**: `/app/techdocs` volume mount

## Quick Start

### For New Services

When you create a new service using one of the golden path templates (Python, Java, or Node.js), TechDocs is automatically configured with:

- `mkdocs.yml` - MkDocs configuration file
- `docs/` directory with sample documentation:
  - `index.md` - Service overview
  - `getting-started.md` - Installation and setup guide
  - `api.md` - API reference
  - `development.md` - Development guidelines
- `catalog-info.yaml` with `backstage.io/techdocs-ref: dir:.` annotation

### For Existing Services

To add TechDocs to an existing service:

1. **Create mkdocs.yml** in your repository root:

```yaml
site_name: 'your-service-name'
site_description: 'Description of your service'

nav:
  - Home: index.md
  - Getting Started: getting-started.md
  - API Reference: api.md
  - Development: development.md

theme:
  name: material
  features:
    - navigation.tabs
    - navigation.sections
    - navigation.top
    - search.suggest
    - search.highlight
  palette:
    - scheme: default
      primary: indigo
      accent: amber

plugins:
  - search

markdown_extensions:
  - admonition
  - attr_list
  - pymdownx.details
  - pymdownx.superfences
  - pymdownx.tabbed
```

2. **Create docs/ directory** with Markdown files:

```bash
mkdir -p docs
touch docs/index.md
touch docs/getting-started.md
touch docs/api.md
touch docs/development.md
```

3. **Add TechDocs annotation** to your `catalog-info.yaml`:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: your-service
  description: Your service description
  annotations:
    backstage.io/techdocs-ref: dir:.  # This points to the current directory
spec:
  type: service
  lifecycle: production
  owner: your-team
```

4. **Commit and push** your changes:

```bash
git add mkdocs.yml docs/ catalog-info.yaml
git commit -m "Add TechDocs documentation"
git push
```

5. **View in Backstage**: Navigate to your service in the Backstage catalog and click the "Docs" tab.

## Writing Documentation

### MkDocs Basics

TechDocs uses [MkDocs](https://www.mkdocs.org/) with the [Material theme](https://squidfunk.github.io/mkdocs-material/). Documentation is written in Markdown.

### Directory Structure

```
your-service/
├── mkdocs.yml          # MkDocs configuration
├── docs/
│   ├── index.md        # Homepage
│   ├── getting-started.md
│   ├── api.md
│   ├── development.md
│   ├── images/         # Store images here
│   │   └── diagram.png
│   └── assets/         # Store other assets
│       └── styles.css
├── catalog-info.yaml   # Backstage catalog entry
└── README.md          # GitHub README (separate from docs)
```

### Markdown Extensions

The following Markdown extensions are enabled:

#### Admonitions

```markdown
!!! note
    This is a note

!!! warning
    This is a warning

!!! danger
    This is a danger alert
```

#### Code Blocks with Syntax Highlighting

````markdown
```python
def hello_world():
    print("Hello, World!")
```
````

#### Tabbed Content

```markdown
=== "Python"
    ```python
    print("Hello")
    ```

=== "JavaScript"
    ```javascript
    console.log("Hello");
    ```
```

#### Collapsible Sections

```markdown
??? "Click to expand"
    Hidden content here
```

### Navigation

Configure navigation in `mkdocs.yml`:

```yaml
nav:
  - Home: index.md
  - Getting Started:
    - Installation: getting-started/installation.md
    - Configuration: getting-started/configuration.md
  - API Reference: api.md
  - Development: development.md
```

### Images and Assets

Store images in `docs/images/` and reference them:

```markdown
![Architecture Diagram](images/architecture.png)
```

## Best Practices

### Documentation Structure

1. **index.md** - Overview and introduction
   - What is this service?
   - Key features
   - Quick links

2. **getting-started.md** - Installation and setup
   - Prerequisites
   - Installation steps
   - First-time configuration
   - Verification

3. **api.md** - API reference
   - Endpoints
   - Request/response formats
   - Authentication
   - Examples

4. **development.md** - Development guidelines
   - Development setup
   - Testing
   - Contributing
   - Code style

### Writing Tips

- **Write for your audience**: Consider who will read your docs (developers, operators, users)
- **Keep it up-to-date**: Update docs when you change code
- **Use examples**: Code examples are more useful than descriptions
- **Include diagrams**: Visual aids help explain complex concepts
- **Link to related docs**: Create connections between related documentation
- **Version your docs**: Keep documentation in sync with code versions

### Code Examples

Always include working code examples:

```python
# Good - Complete, working example
import requests

response = requests.get('https://api.example.com/users')
users = response.json()

for user in users:
    print(f"User: {user['name']}")
```

### API Documentation

Use consistent format for API endpoints:

```markdown
### GET /api/users

Retrieve a list of users.

**Parameters**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| page | integer | No | Page number (default: 1) |
| limit | integer | No | Items per page (default: 10) |

**Response**

```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  ],
  "total": 100,
  "page": 1
}
```

**Status Codes**

- `200 OK`: Success
- `400 Bad Request`: Invalid parameters
- `401 Unauthorized`: Authentication required
```

## Testing Locally

### Install MkDocs

```bash
pip install mkdocs mkdocs-material
```

### Build Documentation

```bash
# Build static site
mkdocs build

# Serve locally with live reload
mkdocs serve
```

Visit `http://localhost:8000` to preview your documentation.

### Validate

Check for broken links and issues:

```bash
# Check for broken links
mkdocs build --strict
```

## Troubleshooting

### Documentation Not Appearing in Backstage

1. **Check annotation**: Verify `backstage.io/techdocs-ref` annotation exists in `catalog-info.yaml`
2. **Verify catalog registration**: Ensure your component is registered in the Backstage catalog
3. **Check mkdocs.yml**: Ensure `mkdocs.yml` is valid YAML
4. **Check logs**: Look at Backstage backend logs for TechDocs errors

### Build Errors

Common issues:

- **Missing files**: Referenced files in `nav` must exist
- **Invalid YAML**: Check `mkdocs.yml` syntax
- **Missing plugins**: Ensure all plugins in `mkdocs.yml` are supported
- **Image paths**: Use relative paths from the `docs/` directory

### Styling Issues

- Material theme requires specific markdown extensions
- Check that all extensions in `mkdocs.yml` are spelled correctly
- Some features require specific Material theme versions

## Advanced Configuration

### Custom Theme Colors

```yaml
theme:
  name: material
  palette:
    - scheme: default
      primary: blue
      accent: indigo
    - scheme: slate  # Dark mode
      primary: blue
      accent: indigo
```

### Enable Dark Mode Toggle

```yaml
theme:
  name: material
  palette:
    - scheme: default
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
    - scheme: slate
      toggle:
        icon: material/brightness-4
        name: Switch to light mode
```

### Enable Search

```yaml
plugins:
  - search:
      lang: en
      separator: '[\s\-]+'
```

### Add Custom CSS

1. Create `docs/assets/extra.css`
2. Add to `mkdocs.yml`:

```yaml
extra_css:
  - assets/extra.css
```

### Include Code from External Files

```markdown
```python title="example.py"
--8<-- "examples/example.py"
```
```

Requires:

```yaml
markdown_extensions:
  - pymdownx.snippets
```

## Migration from Other Systems

### From Confluence/Wiki

1. Export pages as Markdown
2. Clean up Confluence-specific formatting
3. Organize into logical sections
4. Add to `docs/` directory
5. Update `mkdocs.yml` navigation

### From README

If you have extensive README.md files:

1. Keep high-level overview in README.md (for GitHub)
2. Move detailed documentation to `docs/`
3. Link from README to TechDocs in Backstage

## Resources

- [MkDocs Documentation](https://www.mkdocs.org/)
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- [Backstage TechDocs](https://backstage.io/docs/features/techdocs/techdocs-overview)
- [Markdown Guide](https://www.markdownguide.org/)
- [Fawkes Architecture](../architecture.md)

## Getting Help

- Check the [Backstage TechDocs documentation](https://backstage.io/docs/features/techdocs/techdocs-overview)
- Ask in the platform team channel
- Create an issue in the Fawkes repository
- Review examples in existing services

## Examples

See TechDocs in action:

- [Fawkes Platform Documentation](https://backstage.fawkes.idp/catalog/default/system/fawkes-platform/docs) - This documentation!
- [Python Service Template](https://github.com/paruff/fawkes/tree/main/templates/python-service/skeleton/docs) - Template documentation structure
