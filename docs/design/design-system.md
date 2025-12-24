# Fawkes Design System

## Overview

The Fawkes Design System is a comprehensive component library built for the Fawkes Internal Product Delivery Platform. It provides 40+ production-ready React components, design tokens, and accessibility features.

## Quick Links

- **Storybook**: [http://design-system.fawkes.local](http://design-system.fawkes.local)
- **Source Code**: [design-system/](../../design-system/)
- **npm Package**: `@fawkes/design-system`

## Features

✅ **40+ Components** - Comprehensive coverage of UI needs  
✅ **Design Tokens** - Centralized design decisions  
✅ **Accessibility** - WCAG 2.1 AA compliant  
✅ **TypeScript** - Full type safety  
✅ **Tested** - Unit, integration, and accessibility tests  
✅ **Documented** - Interactive Storybook documentation  

## Installation

```bash
npm install @fawkes/design-system
```

## Usage

```tsx
import { Button, Card, Alert } from '@fawkes/design-system';

function MyApp() {
  return (
    <Card>
      <Alert variant="success">Welcome to Fawkes!</Alert>
      <Button variant="primary" size="lg">
        Get Started
      </Button>
    </Card>
  );
}
```

## Component Categories

### Layout (5 components)
- **Container** - Responsive container
- **Grid** - Grid layout system
- **Stack** - Vertical/horizontal stacking
- **Spacer** - Flexible spacing
- **Box** - Generic box component

### Typography (3 components)
- **Heading** - Semantic headings (h1-h6)
- **Text** - Text with variants
- **Code** - Code display

### Forms (13 components)
- **Button** - Primary action button
- **IconButton** - Icon-only button
- **ButtonGroup** - Grouped buttons
- **Input** - Text input field
- **Select** - Dropdown select
- **Checkbox** - Checkbox input
- **Radio** - Radio button
- **Switch** - Toggle switch
- **Textarea** - Multi-line input
- **FormField** - Complete form field
- **FormLabel** - Form labels
- **FormHelperText** - Helper text
- **FormErrorMessage** - Error messages

### Feedback (6 components)
- **Alert** - Alert messages
- **Toast** - Toast notifications
- **Spinner** - Loading spinner
- **Progress** - Progress bar
- **Badge** - Status badge
- **Skeleton** - Loading skeleton

### Navigation (5 components)
- **Tabs** - Tab navigation
- **Breadcrumbs** - Breadcrumb trail
- **Pagination** - Pagination controls
- **Menu** - Dropdown menu
- **Link** - Styled links

### Display (8 components)
- **Card** - Card container
- **Avatar** - User avatar
- **Chip** - Chip/tag component
- **Tooltip** - Tooltip overlay
- **Modal** - Modal dialog
- **Drawer** - Slide-out drawer
- **Divider** - Visual divider
- **Image** - Optimized image

### Data (2 components)
- **Table** - Data table
- **List** - List component

## Design Tokens

The design system uses centralized design tokens:

```typescript
import { tokens } from '@fawkes/design-system';

// Colors
const primary = tokens.colors.primary[500];

// Typography
const headingSize = tokens.typography.fontSize['2xl'];

// Spacing
const margin = tokens.spacing[4];

// Shadows
const shadow = tokens.shadows.lg;
```

### Token Categories

- **Colors** - Brand, semantic, and neutral colors
- **Typography** - Font families, sizes, weights, line heights
- **Spacing** - Consistent spacing scale
- **Shadows** - Box shadow values
- **Radii** - Border radius values
- **Z-Indices** - Layering system
- **Breakpoints** - Responsive breakpoints

## Accessibility

All components follow WCAG 2.1 AA standards:

- ✅ Semantic HTML
- ✅ ARIA attributes
- ✅ Keyboard navigation
- ✅ Screen reader support
- ✅ Focus management
- ✅ Color contrast compliance

### Testing Accessibility

```bash
# Run accessibility tests
cd design-system
npm run test:a11y
```

## Development

### Prerequisites

- Node.js 18+
- npm 8+

### Setup

```bash
cd design-system
npm install
npm run storybook
```

### Testing

```bash
# Unit tests
npm test

# Accessibility tests
npm run test:a11y

# Coverage
npm run test:coverage
```

### Building

```bash
npm run build
```

## Deployment

The design system's Storybook is deployed to the Fawkes cluster:

```bash
# Deploy via ArgoCD
kubectl apply -f platform/apps/design-system-application.yaml

# Check status
kubectl get pods -n fawkes -l app=design-system-storybook
```

## Acceptance Testing

Validate the design system implementation:

```bash
# Run acceptance test AT-E3-004
make validate-at-e3-004

# Or directly
./scripts/validate-at-e3-004.sh
```

## Contributing

See [CONTRIBUTING.md](../../design-system/CONTRIBUTING.md) for contribution guidelines.

## Architecture Decision Records

See the following ADRs for design decisions:

- ADR-XXX: Design System Architecture
- ADR-XXX: Component API Design
- ADR-XXX: Accessibility Standards

## Related

- [Backstage Integration](../integrations.md#design-system)
- [Platform Components](../reference/components.md)
- [UI/UX Guidelines](./ui-ux-guidelines.md)

## Support

- GitHub Issues: [paruff/fawkes/issues](https://github.com/paruff/fawkes/issues)
- Documentation: [design-system.fawkes.local](http://design-system.fawkes.local)
- Platform Team: platform-team@fawkes.io
