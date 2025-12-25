# TechDocs Plugin Configuration

## Overview

This document describes the TechDocs plugin configuration for Backstage in the Fawkes platform.

## What is TechDocs?

TechDocs is Backstage's built-in documentation solution that enables documentation-as-code. It allows you to write documentation in Markdown alongside your code, and have it automatically rendered in the Backstage UI.

## Configuration Changes

### 1. Backstage Configuration

**File**: `platform/apps/backstage/app-config.yaml`

Updated TechDocs configuration:
- Builder: Changed from `external` to `local` for on-demand documentation generation
- Generator: Configured to run `local` within Backstage
- Publisher: Set to `local` with publish directory `/app/techdocs`

### 2. Deployment Configuration

**File**: `platform/apps/backstage/values.yaml`

Added volume configuration for TechDocs:
- Created `techdocs` emptyDir volume
- Mounted volume at `/app/techdocs` (read-write)
- This allows Backstage to generate and store documentation

### 3. Service Templates

Added TechDocs support to all service templates:

**Templates Updated**:
- `templates/python-service/skeleton/`
- `templates/java-service/skeleton/`
- `templates/nodejs-service/skeleton/`

**Files Added to Each Template**:
- `mkdocs.yml` - MkDocs configuration with Material theme
- `docs/index.md` - Service overview
- `docs/getting-started.md` - Installation and setup guide
- `docs/api.md` - API reference
- `docs/development.md` - Development guidelines

**Annotations**: All template `catalog-info.yaml` files already had the `backstage.io/techdocs-ref: dir:.` annotation.

### 4. Testing

**File**: `tests/bdd/features/backstage-techdocs.feature`

Added comprehensive BDD acceptance tests covering:
- TechDocs plugin configuration
- Volume mount verification
- Catalog annotation validation
- Template structure validation
- Documentation rendering

**File**: `tests/bdd/step_definitions/techdocs_steps.py`

Implemented step definitions for all TechDocs test scenarios.

### 5. Documentation

**File**: `docs/how-to/techdocs-usage.md`

Added comprehensive documentation covering:
- Quick start guide
- Writing documentation
- Best practices
- Troubleshooting
- Advanced configuration
- Migration guides

Updated `mkdocs.yml` to include the TechDocs usage guide in navigation.

## Acceptance Criteria

✅ **TechDocs plugin enabled**: Configuration updated in `app-config.yaml`

✅ **Documentation generator configured**: Local builder with proper volume mounts

✅ **Sample docs rendering correctly**: All templates include sample documentation

✅ **Docs integrated with templates**: mkdocs.yml, docs/ directory, and annotations added

## Verification

### Configuration Tests

Run the validation script to verify all configuration:

```bash
python -c "
import yaml
from pathlib import Path

# Verify TechDocs configuration
app_config_path = Path('platform/apps/backstage/app-config.yaml')
with open(app_config_path) as f:
    config = yaml.safe_load(f)
    app_config_data = config.get('data', {}).get('app-config.yaml', '')
    app_config_parsed = yaml.safe_load(app_config_data)
    techdocs = app_config_parsed.get('techdocs', {})

assert techdocs.get('builder') == 'local'
assert techdocs.get('generator', {}).get('runIn') == 'local'
assert techdocs.get('publisher', {}).get('type') == 'local'

print('✅ TechDocs configuration is correct')
"
```

### Template Tests

Verify templates have documentation:

```bash
for template in python-service java-service nodejs-service; do
    test -f templates/$template/skeleton/mkdocs.yml && \
    test -d templates/$template/skeleton/docs && \
    test -f templates/$template/skeleton/docs/index.md && \
    echo "✅ $template has TechDocs support" || \
    echo "❌ $template missing TechDocs files"
done
```

### BDD Tests

Run the BDD acceptance tests:

```bash
pytest tests/bdd/features/backstage-techdocs.feature -v
```

## Usage

### For Platform Users

When creating a new service from a template, documentation is automatically included. Simply:

1. Create service from template (Python, Java, or Node.js)
2. Customize the documentation in the `docs/` directory
3. Push changes to Git
4. View documentation in Backstage by navigating to your service and clicking the "Docs" tab

### For Existing Services

To add TechDocs to an existing service:

1. Copy `mkdocs.yml` from a template
2. Create `docs/` directory with Markdown files
3. Add `backstage.io/techdocs-ref: dir:.` annotation to `catalog-info.yaml`
4. Push to Git and refresh catalog in Backstage

See [TechDocs Usage Guide](../docs/how-to/techdocs-usage.md) for detailed instructions.

## Dependencies

This feature depends on:
- Issue #9: Backstage deployment (prerequisite)
- MkDocs with Material theme (included in Backstage)
- Proper volume mounts in Backstage deployment

## Related Documentation

- [TechDocs Usage Guide](../docs/how-to/techdocs-usage.md)
- [Architecture Documentation](../docs/architecture.md)
- [Backstage Official TechDocs Guide](https://backstage.io/docs/features/techdocs/techdocs-overview)

## Troubleshooting

### Documentation Not Rendering

1. Check that `backstage.io/techdocs-ref` annotation exists in `catalog-info.yaml`
2. Verify `mkdocs.yml` is valid YAML
3. Ensure `docs/` directory exists with at least `index.md`
4. Check Backstage logs for TechDocs errors

### Volume Mount Issues

If documentation generation fails:

```bash
# Check if volume is mounted correctly
kubectl describe pod -n fawkes -l app.kubernetes.io/name=backstage | grep techdocs -A 5

# Check volume permissions
kubectl exec -n fawkes deployment/backstage -- ls -la /app/techdocs
```

## Future Enhancements

Potential improvements:
- Add more Markdown extensions (mermaid diagrams, etc.)
- Configure external publisher (S3, GCS) for production
- Add documentation templates for different service types
- Integrate with CI/CD to validate documentation on PR
- Add documentation coverage metrics

## Maintenance

- Keep MkDocs and Material theme versions updated
- Review and update sample documentation regularly
- Monitor TechDocs usage and gather feedback
- Update troubleshooting guide based on common issues
