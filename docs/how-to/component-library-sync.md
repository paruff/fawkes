# Component Library Sync with Penpot

This document describes how the Fawkes Design System components are synchronized with Penpot designs.

## Overview

The component library sync ensures that:
1. Design system components match Penpot designs
2. Component documentation includes design references
3. Storybook includes embedded design previews
4. Discrepancies are detected and reported

## Architecture

```
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│   Penpot    │──────►│  Sync Service│──────►│   Design    │
│   Designs   │       │  (Jenkins)   │       │   System    │
└─────────────┘       └──────────────┘       └─────────────┘
       │                      │                      │
       │                      ▼                      │
       │              ┌──────────────┐               │
       │              │  Validation  │               │
       │              │   Reports    │               │
       │              └──────────────┘               │
       │                      │                      │
       └──────────────────────┴──────────────────────┘
                              │
                              ▼
                      ┌──────────────┐
                      │  Mattermost  │
                      │ Notification │
                      └──────────────┘
```

## Sync Process

### 1. Discovery Phase

**Frequency**: Every hour (configurable)

**Steps**:
1. Fetch list of projects from Penpot API
2. Identify projects tagged with `design-system`
3. Extract all components and their properties
4. Build component inventory

**Jenkins Job**: `penpot-component-discovery`

```groovy
// Jenkinsfile for discovery
pipeline {
    agent any
    triggers {
        cron('0 * * * *')  // Every hour
    }
    stages {
        stage('Fetch Penpot Projects') {
            steps {
                script {
                    sh '''
                        curl -H "Authorization: Token ${PENPOT_API_TOKEN}" \
                             https://penpot.fawkes.local/api/rpc/command/get-projects \
                             > penpot-projects.json
                    '''
                }
            }
        }
        stage('Extract Components') {
            steps {
                script {
                    sh '''
                        python3 scripts/extract-penpot-components.py \
                            --input penpot-projects.json \
                            --output penpot-components.json
                    '''
                }
            }
        }
        stage('Store Inventory') {
            steps {
                archiveArtifacts artifacts: 'penpot-components.json'
            }
        }
    }
}
```

### 2. Mapping Phase

**Purpose**: Match Penpot components to Design System components

**Mapping File**: `platform/apps/backstage/plugins/penpot-viewer.yaml`

**Mapping Logic**:
```python
# Example mapping logic
def map_components(penpot_components, design_system_components):
    mappings = []
    
    for penpot_comp in penpot_components:
        # Try exact name match
        ds_comp = find_by_name(design_system_components, penpot_comp['name'])
        
        if ds_comp:
            mappings.append({
                'penpot': penpot_comp,
                'designSystem': ds_comp,
                'status': 'mapped'
            })
        else:
            # Try fuzzy match
            ds_comp = fuzzy_match(design_system_components, penpot_comp['name'])
            if ds_comp:
                mappings.append({
                    'penpot': penpot_comp,
                    'designSystem': ds_comp,
                    'status': 'fuzzy-mapped',
                    'confidence': 0.85
                })
            else:
                mappings.append({
                    'penpot': penpot_comp,
                    'designSystem': None,
                    'status': 'unmapped'
                })
    
    return mappings
```

### 3. Validation Phase

**Checks Performed**:

1. **Name Consistency**
   - Penpot component name matches Design System component name
   - Variants are consistently named

2. **Property Validation**
   - Props in Penpot match component API
   - Required props are present
   - Prop types are compatible

3. **Design Token Validation**
   - Colors match design token values
   - Spacing uses token scale
   - Typography uses defined scales
   - Border radius matches tokens

4. **Size Validation**
   - Component dimensions are reasonable
   - Touch targets meet minimum size (44x44px)
   - Responsive breakpoints align

**Validation Script**:
```python
# scripts/validate-component-sync.py
import json
from typing import Dict, List

def validate_design_tokens(penpot_component: Dict, design_system_component: Dict) -> List[str]:
    """Validate that design tokens are used consistently."""
    issues = []
    
    # Check colors
    penpot_colors = extract_colors(penpot_component)
    for color in penpot_colors:
        if not is_design_token(color):
            issues.append(f"Color {color} is not a design token")
    
    # Check spacing
    penpot_spacing = extract_spacing(penpot_component)
    for spacing in penpot_spacing:
        if not is_spacing_token(spacing):
            issues.append(f"Spacing {spacing} is not a design token")
    
    return issues

def validate_accessibility(penpot_component: Dict) -> List[str]:
    """Validate accessibility requirements."""
    issues = []
    
    # Check color contrast
    if not meets_contrast_ratio(penpot_component, min_ratio=4.5):
        issues.append("Color contrast ratio below 4.5:1")
    
    # Check touch targets
    size = get_component_size(penpot_component)
    if size['width'] < 44 or size['height'] < 44:
        issues.append(f"Touch target too small: {size['width']}x{size['height']}px (min 44x44px)")
    
    return issues

def validate_component(penpot_component: Dict, design_system_component: Dict) -> Dict:
    """Run all validations on a component."""
    return {
        'component': penpot_component['name'],
        'token_issues': validate_design_tokens(penpot_component, design_system_component),
        'accessibility_issues': validate_accessibility(penpot_component),
        'mapping_confidence': calculate_mapping_confidence(penpot_component, design_system_component)
    }
```

### 4. Sync Phase

**Actions**:

1. **Update Component Metadata**
   - Add Penpot design ID to component files
   - Update design preview URLs
   - Add design version tags

2. **Update Storybook Documentation**
   - Embed Penpot design previews
   - Add links to source designs
   - Include design specifications

3. **Generate Design Specs**
   - Extract component measurements
   - Document spacing and sizing
   - List color and typography values

**Storybook Integration**:
```typescript
// Example: Adding Penpot preview to Storybook
import React from 'react';
import { Meta, Story } from '@storybook/react';
import { Button, ButtonProps } from './Button';

export default {
  title: 'Components/Button',
  component: Button,
  parameters: {
    penpot: {
      designId: 'project-123/file-456',
      page: 'Buttons',
      frame: 'Primary Button',
    },
    design: {
      type: 'penpot',
      url: 'https://penpot.fawkes.local/workspace/project-123/file-456',
    },
  },
} as Meta;

const Template: Story<ButtonProps> = (args) => <Button {...args} />;

export const Primary = Template.bind({});
Primary.args = {
  variant: 'primary',
  children: 'Primary Button',
};
```

### 5. Reporting Phase

**Report Generation**:

```yaml
# Example sync report
sync_report:
  timestamp: "2024-12-24T10:00:00Z"
  penpot_components: 45
  design_system_components: 42
  
  mapping_summary:
    mapped: 38
    fuzzy_mapped: 4
    unmapped: 3
  
  validation_summary:
    passed: 35
    warnings: 7
    errors: 0
  
  issues:
    - component: "Alert/Info"
      type: "warning"
      message: "Color #1E90FF is not a design token"
      
    - component: "Button/Large"
      type: "warning"
      message: "Height 48px doesn't match design token scale"
      
    - component: "IconButton"
      type: "unmapped"
      message: "No matching Design System component found"
  
  recommendations:
    - "Add IconButton to Design System"
    - "Update Alert/Info to use tokens.colors.info[500]"
    - "Review Button size variants"
```

**Notification**:
```json
{
  "channel": "#design-system",
  "text": "🎨 Component Sync Report - 2024-12-24",
  "attachments": [
    {
      "color": "warning",
      "fields": [
        {
          "title": "Summary",
          "value": "38 mapped, 4 fuzzy, 3 unmapped"
        },
        {
          "title": "Issues",
          "value": "7 warnings, 0 errors"
        }
      ],
      "actions": [
        {
          "type": "button",
          "text": "View Full Report",
          "url": "https://jenkins.fawkes.local/job/penpot-sync/lastBuild"
        }
      ]
    }
  ]
}
```

## Configuration

### Sync Schedule

Configure sync frequency in Jenkins:

```groovy
triggers {
    // Run every hour
    cron('0 * * * *')
    
    // Or run on Penpot webhook (future)
    // genericTrigger(...)
}
```

### Mapping Rules

Define custom mapping rules:

```yaml
# .penpot-sync-config.yaml
mapping:
  rules:
    # Exact match
    - type: exact
      priority: 1
      
    # Prefix match (Button/* → Button)
    - type: prefix
      priority: 2
      pattern: "^([^/]+)/.*"
      
    # Fuzzy match with similarity threshold
    - type: fuzzy
      priority: 3
      threshold: 0.8
      
  exclusions:
    # Ignore these Penpot components
    - "Template/*"
    - "Archive/*"
    - "Draft/*"
```

### Validation Rules

Configure validation strictness:

```yaml
validation:
  design_tokens:
    enabled: true
    level: warning  # warning | error
    
  accessibility:
    enabled: true
    level: error
    min_contrast_ratio: 4.5
    min_touch_target: 44
    
  component_api:
    enabled: true
    level: warning
    enforce_required_props: true
```

## Manual Sync

Trigger sync manually:

```bash
# Via Jenkins
curl -X POST https://jenkins.fawkes.local/job/penpot-sync/build \
  --user $JENKINS_USER:$JENKINS_TOKEN

# Via kubectl (run sync job)
kubectl create job --from=cronjob/penpot-sync penpot-sync-manual -n fawkes
```

## Troubleshooting

### Sync Job Failing

**Check logs**:
```bash
kubectl logs -n fawkes jobs/penpot-sync
```

**Common issues**:
1. **API token expired**: Regenerate token in Penpot
2. **Network connectivity**: Check Penpot service is reachable
3. **Invalid mapping config**: Validate YAML syntax

### Components Not Mapping

**Reasons**:
1. **Name mismatch**: Check component names in Penpot vs. Design System
2. **Missing tags**: Ensure Penpot project is tagged with `design-system`
3. **Exclusion rules**: Check if component is excluded in config

**Fix**:
```yaml
# Add explicit mapping
mappings:
  - penpotComponent: "Icon Button"
    designSystemComponent: "IconButton"
```

### False Validation Errors

**Adjust thresholds**:
```yaml
validation:
  design_tokens:
    color_tolerance: 5  # Allow 5% color difference
    spacing_tolerance: 2  # Allow 2px spacing difference
```

## Best Practices

1. **Consistent Naming**: Use same component names in Penpot and Design System
2. **Tag Projects**: Tag Penpot projects with `design-system` for easy filtering
3. **Use Components**: Build Penpot designs from component library
4. **Document Changes**: Add comments in Penpot when making design changes
5. **Review Reports**: Regularly review sync reports and address issues
6. **Keep Mapping Updated**: Update mapping configuration as components evolve

## Future Enhancements

1. **Real-time Sync**: Use Penpot webhooks for immediate sync
2. **Bidirectional Sync**: Update Penpot when Design System changes
3. **Automated PRs**: Create PRs to fix validation issues
4. **Visual Regression**: Compare rendered components to Penpot designs
5. **AI-Assisted Mapping**: Use ML to suggest component mappings

## Resources

- [Penpot API Documentation](https://penpot.app/api/doc)
- [Design System Guide](../design/design-system.md)
- [Component Mapping Config](../../platform/apps/backstage/plugins/penpot-viewer.yaml)
- [Sync Job Definition](../../platform/apps/jenkins/jobs/penpot-sync.groovy)

## Support

- **Slack**: #design-system
- **Issues**: [GitHub Issues](https://github.com/paruff/fawkes/issues)
- **Office Hours**: Tuesdays 2-3pm
