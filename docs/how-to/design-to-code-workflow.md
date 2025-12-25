# Design-to-Code Workflow with Penpot

This guide describes the end-to-end workflow for using Penpot designs in the Fawkes platform, from initial design to code implementation.

## Overview

The Fawkes platform integrates Penpot, an open-source design tool, to enable seamless collaboration between designers and developers. The workflow ensures that designs are discoverable, reviewable, and directly accessible from the developer portal.

## Architecture

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   Penpot     │◄─────►│   Backstage  │◄─────►│    Design    │
│  Design Tool │       │    Portal    │       │    System    │
└──────────────┘       └──────────────┘       └──────────────┘
       │                       │                       │
       │                       │                       │
       ▼                       ▼                       ▼
  Designs &               Component             React Components
  Assets                  Catalog               & Storybook
```

## Workflow Steps

### 1. Design Phase

**Actor**: Designer

**Tools**: Penpot

**Steps**:

1. **Access Penpot**: Navigate to https://penpot.fawkes.local
2. **Create Project**: Create a new project for your feature/component
3. **Design Components**: Create mockups using design system tokens
   - Use consistent colors from the design tokens
   - Apply standard spacing values
   - Follow typography guidelines
4. **Create Variants**: Design different states (hover, active, disabled)
5. **Add Interactions**: Define click targets and navigation flows
6. **Export Assets**: Export icons, images, and other assets
7. **Share Design**: Share the project with the team for review

**Best Practices**:

- Use component libraries to ensure consistency
- Name layers clearly for developer handoff
- Add annotations and comments for complex interactions
- Create a cover page with design specifications

### 2. Design Review

**Actor**: Team (Designers, Developers, Product)

**Tools**: Penpot, Mattermost

**Steps**:

1. **Share Link**: Designer shares Penpot project link in Mattermost
2. **Review Session**: Team reviews designs collaboratively
3. **Add Comments**: Stakeholders add comments directly in Penpot
4. **Iterate**: Designer makes changes based on feedback
5. **Approve**: Team approves the final design

**Review Checklist**:

- [ ] Designs follow brand guidelines
- [ ] All interactions are clearly defined
- [ ] Components map to design system components
- [ ] Accessibility considerations are addressed
- [ ] Mobile/responsive views are included
- [ ] Edge cases are considered

### 3. Developer Handoff

**Actor**: Designer

**Tools**: Penpot, GitHub

**Steps**:

1. **Get Design ID**:

   - Open the design file in Penpot
   - Copy the project ID and file ID from the URL
   - Format: `{project-id}/{file-id}`

2. **Update Component Catalog**:

   ```yaml
   # catalog-info.yaml
   apiVersion: backstage.io/v1alpha1
   kind: Component
   metadata:
     name: user-profile
     description: User profile component
     annotations:
       penpot.io/design-id: "abc123/def456"
       penpot.io/design-page: "Desktop View"
       penpot.io/design-version: "v2.0"
   spec:
     type: website
     lifecycle: production
     owner: platform-team
   ```

3. **Export Design Specs**:

   - Export design tokens (colors, spacing, typography)
   - Export assets (icons, images) to `/assets` directory
   - Document component specifications in README

4. **Create Issue**: Create a GitHub issue with design link and specifications

**Deliverables**:

- Component specifications document
- Exported assets
- Annotated catalog-info.yaml
- GitHub issue with acceptance criteria

### 4. Implementation

**Actor**: Developer

**Tools**: Backstage, VS Code, Design System

**Steps**:

1. **View Design in Backstage**:

   - Navigate to component in Backstage catalog
   - Click "Design" tab to view embedded Penpot design
   - Review all design states and interactions

2. **Map to Design System Components**:

   ```tsx
   // Check component mapping
   // Penpot "Button/Primary" → Design System Button variant="primary"

   import { Button, Card, Input } from "@fawkes/design-system";

   function UserProfile() {
     return (
       <Card>
         <Input label="Name" />
         <Button variant="primary">Save</Button>
       </Card>
     );
   }
   ```

3. **Implement with Design Tokens**:

   ```tsx
   import { tokens } from "@fawkes/design-system";

   const styles = {
     container: {
       padding: tokens.spacing[4], // From Penpot spacing
       backgroundColor: tokens.colors.neutral[50], // From Penpot colors
       borderRadius: tokens.radii.md, // From Penpot border radius
     },
   };
   ```

4. **Export Assets from Penpot**:

   - Select element in Penpot
   - Click "Export" → Choose format (SVG, PNG)
   - Download and add to project assets

5. **Test Implementation**:
   - Verify all design states (default, hover, active, disabled)
   - Test interactions and animations
   - Check responsive behavior
   - Run accessibility tests

**Development Checklist**:

- [ ] All design states implemented
- [ ] Design tokens used consistently
- [ ] Assets exported and optimized
- [ ] Interactions match design specs
- [ ] Accessibility requirements met
- [ ] Responsive design working
- [ ] Cross-browser testing complete

### 5. Component Library Sync

**Actor**: Automated Process

**Tools**: Jenkins, Penpot API, Design System

**Steps**:

1. **Automated Detection**:

   - Jenkins job runs hourly
   - Detects new or updated Penpot components
   - Compares with design system components

2. **Validation**:

   - Checks component mapping configuration
   - Validates design tokens match
   - Identifies missing or outdated components

3. **Update Storybook**:

   - Generates updated Storybook documentation
   - Adds Penpot design preview to each component
   - Links to source design files

4. **Notification**:
   - Posts to Mattermost #design-system channel
   - Lists updated components
   - Flags any discrepancies

**Sync Configuration**:

```yaml
# .penpot-sync.yaml
sync:
  enabled: true
  interval: "1h"
  projects:
    - id: "abc123"
      name: "Fawkes Design System"
  validation:
    enforceTokens: true
    warnUnmapped: true
  notifications:
    mattermost:
      channel: "#design-system"
```

### 6. Quality Assurance

**Actor**: QA Engineer

**Tools**: Backstage, Browser DevTools, Percy

**Steps**:

1. **Visual Comparison**:

   - Open component in Backstage
   - Compare implementation with Penpot design side-by-side
   - Check pixel-perfect alignment

2. **Interaction Testing**:

   - Test all interactive states
   - Verify animations and transitions
   - Check keyboard navigation

3. **Accessibility Testing**:

   - Run axe accessibility scanner
   - Test with screen reader
   - Verify color contrast ratios
   - Test keyboard-only navigation

4. **Responsive Testing**:

   - Test on different screen sizes
   - Verify mobile touch interactions
   - Check tablet layouts

5. **Cross-browser Testing**:
   - Test on Chrome, Firefox, Safari, Edge
   - Document any browser-specific issues

**QA Checklist**:

- [ ] Visual design matches Penpot mockup
- [ ] All interactive states work correctly
- [ ] Accessibility standards met (WCAG 2.1 AA)
- [ ] Responsive design working across devices
- [ ] Cross-browser compatibility verified
- [ ] Performance acceptable (load time, animations)

### 7. Deployment & Documentation

**Actor**: DevOps Engineer

**Tools**: ArgoCD, Jenkins, Storybook

**Steps**:

1. **Deploy to Staging**:

   ```bash
   # Automatically deployed via ArgoCD
   kubectl get pods -n fawkes-staging -l app=user-profile
   ```

2. **Update Storybook**:

   - Storybook automatically rebuilds
   - New component documentation published
   - Design preview embedded in stories

3. **Update Documentation**:

   - Add usage examples to component README
   - Document props and variants
   - Include design rationale

4. **Promote to Production**:
   ```bash
   # After validation, promote to production
   argocd app sync user-profile --prune
   ```

**Documentation Template**:

```markdown
# User Profile Component

## Overview

Displays user information with editable fields.

## Design

- [View in Penpot](https://penpot.fawkes.local/workspace/abc123/def456)
- [Backstage Page](https://backstage.fawkes.local/catalog/default/component/user-profile)

## Usage

\`\`\`tsx
import { UserProfile } from '@fawkes/components';

<UserProfile userId="123" onSave={handleSave} />
\`\`\`

## Props

| Prop   | Type     | Default  | Description     |
| ------ | -------- | -------- | --------------- |
| userId | string   | required | User ID to load |
| onSave | function | -        | Save callback   |

## Variants

- Default: Standard user profile
- Compact: Reduced padding for lists
- ReadOnly: Display-only mode

## Accessibility

- ARIA labels on all inputs
- Keyboard navigation supported
- Screen reader optimized
```

## Tools Reference

### Penpot

- **URL**: https://penpot.fawkes.local
- **Purpose**: Design creation and collaboration
- **Key Features**: Real-time collaboration, version control, developer handoff

### Backstage

- **URL**: https://backstage.fawkes.local
- **Purpose**: Developer portal with embedded design viewer
- **Key Features**: Component catalog, design tab, TechDocs integration

### Design System

- **URL**: https://design-system.fawkes.local
- **Purpose**: Component library and documentation
- **Key Features**: 40+ components, design tokens, Storybook playground

### Component Mapping Tool

- **Location**: `/platform/apps/backstage/plugins/penpot-viewer.yaml`
- **Purpose**: Map Penpot components to design system components
- **Usage**: Auto-validates design implementation consistency

## Troubleshooting

### Design Not Showing in Backstage

**Problem**: Design tab is empty in Backstage

**Solution**:

1. Verify annotation in `catalog-info.yaml`:
   ```yaml
   annotations:
     penpot.io/design-id: "project-id/file-id"
   ```
2. Check that Penpot is accessible from Backstage pod:
   ```bash
   kubectl exec -n fawkes backstage-xxx -- curl http://penpot-backend.fawkes.svc:6060/api/_health
   ```
3. Check Backstage logs for errors:
   ```bash
   kubectl logs -n fawkes backstage-xxx | grep penpot
   ```

### Component Mapping Not Working

**Problem**: Design system components not syncing with Penpot

**Solution**:

1. Check component mapping configuration:
   ```bash
   kubectl get configmap -n fawkes penpot-component-mapping -o yaml
   ```
2. Verify Penpot component names match configuration
3. Check sync job logs:
   ```bash
   kubectl logs -n fawkes jobs/penpot-sync
   ```

### Assets Not Exporting

**Problem**: Cannot export assets from Penpot

**Solution**:

1. Verify Penpot exporter service is running:
   ```bash
   kubectl get pods -n fawkes -l component=exporter
   ```
2. Check exporter logs:
   ```bash
   kubectl logs -n fawkes penpot-exporter-xxx
   ```
3. Ensure asset storage volume is writable:
   ```bash
   kubectl exec -n fawkes penpot-backend-xxx -- ls -la /opt/data/assets
   ```

## Best Practices

### For Designers

1. **Use Component Libraries**: Build from existing design system components
2. **Name Consistently**: Use clear, descriptive names for layers and frames
3. **Document Decisions**: Add comments explaining design choices
4. **Think Responsive**: Design for multiple screen sizes
5. **Consider States**: Design all interactive states (hover, active, disabled)
6. **Accessibility First**: Ensure sufficient color contrast and touch targets

### For Developers

1. **Start with Design System**: Use existing components before building new ones
2. **Match Exactly**: Implement pixel-perfect designs when possible
3. **Use Design Tokens**: Never hardcode colors, spacing, or typography
4. **Test Thoroughly**: Test all states and responsive behavior
5. **Document Props**: Keep component documentation up to date
6. **Validate Accessibility**: Run automated and manual accessibility tests

### For Teams

1. **Review Together**: Hold design review sessions with full team
2. **Communicate Early**: Discuss technical constraints during design phase
3. **Maintain Library**: Regularly update component library
4. **Document Patterns**: Create reusable patterns for common scenarios
5. **Measure Quality**: Track design-to-implementation consistency
6. **Iterate Continuously**: Refine workflow based on team feedback

## Metrics

Track these metrics to measure workflow effectiveness:

- **Design Review Time**: Time from design completion to approval
- **Implementation Time**: Time from design approval to code completion
- **Design Accuracy**: Percentage of implementations matching design specs
- **Component Reuse**: Percentage of UI using design system components
- **Accessibility Score**: Automated accessibility test results
- **Sync Coverage**: Percentage of Penpot components mapped to design system

## Resources

- [Penpot Documentation](https://help.penpot.app/)
- [Backstage Plugin Development](https://backstage.io/docs/plugins/)
- [Design System Guide](../design/design-system.md)
- [Component Catalog](https://backstage.fawkes.local/catalog)
- [Storybook](https://design-system.fawkes.local)

## Support

- **Slack**: #design-tools, #design-system
- **Issues**: [GitHub Issues](https://github.com/paruff/fawkes/issues)
- **Office Hours**: Tuesdays 2-3pm (Design System Office Hours)
