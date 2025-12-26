# Fawkes Design System

A comprehensive design system with reusable components, design tokens, and style guide for the Fawkes platform.

## Features

✅ **30+ Production-Ready Components** - Buttons, forms, navigation, feedback, and more
✅ **Design Tokens** - Consistent colors, typography, spacing across the platform
✅ **Fully Accessible** - WCAG 2.1 AA compliant with ARIA support
✅ **TypeScript First** - Full type safety and IntelliSense support
✅ **Storybook Documentation** - Interactive component playground and documentation
✅ **Tested** - Jest + React Testing Library + accessibility tests
✅ **Tree-shakeable** - Import only what you need

## Installation

```bash
npm install @fawkes/design-system
```

## Usage

```tsx
import { Button, Card, Alert } from '@fawkes/design-system';

function App() {
  return (
    <Card>
      <Alert variant="success">Welcome to Fawkes!</Alert>
      <Button variant="primary" size="large">
        Get Started
      </Button>
    </Card>
  );
}
```

## Design Tokens

Use design tokens for consistent styling:

```tsx
import { tokens } from '@fawkes/design-system';

const styles = {
  color: tokens.colors.primary[500],
  fontSize: tokens.typography.fontSize.lg,
  spacing: tokens.spacing[4],
};
```

## Development

```bash
# Install dependencies
npm install

# Run Storybook
npm run storybook

# Run tests
npm test

# Run accessibility tests
npm run test:a11y

# Build the library
npm run build
```

## Components

### Layout

- Container
- Grid
- Stack
- Spacer
- Box

### Typography

- Heading
- Text
- Code

### Forms

- Button
- IconButton
- ButtonGroup
- Input
- Select
- Checkbox
- Radio
- Switch
- Textarea
- FormField
- FormLabel
- FormHelperText
- FormErrorMessage

### Feedback

- Alert
- Toast
- Spinner
- Progress
- Badge
- Skeleton

### Navigation

- Tabs
- Breadcrumbs
- Pagination
- Menu
- Link

### Display

- Card
- Avatar
- Chip
- Tooltip
- Modal
- Drawer
- Divider
- Image

### Data

- Table
- List

## Accessibility

All components follow WCAG 2.1 AA standards:

- Semantic HTML
- ARIA attributes
- Keyboard navigation
- Screen reader support
- Focus management
- Color contrast ratios

## Browser Support

- Chrome (last 2 versions)
- Firefox (last 2 versions)
- Safari (last 2 versions)
- Edge (last 2 versions)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution guidelines.

## License

MIT License - see [LICENSE](../LICENSE) for details.

## Links

- [Storybook](http://design-system.fawkes.local) - Interactive component documentation
- [GitHub Repository](https://github.com/paruff/fawkes)
- [Issue Tracker](https://github.com/paruff/fawkes/issues)
