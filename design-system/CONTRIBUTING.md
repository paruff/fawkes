# Contributing to Fawkes Design System

Thank you for your interest in contributing to the Fawkes Design System! This document provides guidelines and best practices for contributing.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Component Guidelines](#component-guidelines)
- [Accessibility Guidelines](#accessibility-guidelines)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)

## Code of Conduct

Please be respectful and professional in all interactions. We are committed to providing a welcoming and inclusive environment for all contributors.

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm 8+
- Git

### Setup

```bash
# Clone the repository
git clone https://github.com/paruff/fawkes.git
cd fawkes/design-system

# Install dependencies
npm install

# Start Storybook for development
npm run storybook
```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/component-name
```

### 2. Develop Your Component

Create your component in `src/components/ComponentName/`:

```
src/components/ComponentName/
├── ComponentName.tsx       # Component implementation
├── ComponentName.css       # Component styles
├── ComponentName.stories.tsx  # Storybook stories
├── ComponentName.test.tsx  # Tests
└── index.ts               # Exports
```

### 3. Run Tests Locally

```bash
# Run all tests
npm test

# Run accessibility tests
npm run test:a11y

# Run Storybook
npm run storybook
```

### 4. Build the Package

```bash
npm run build
```

## Component Guidelines

### Component Structure

```tsx
import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './ComponentName.css';

export interface ComponentNameProps extends BaseComponentProps {
  /** Prop description */
  variant?: 'primary' | 'secondary';
}

export const ComponentName = React.forwardRef<HTMLDivElement, ComponentNameProps>(
  ({ children, variant = 'primary', className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-component-name', `fawkes-component-name--${variant}`, className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

ComponentName.displayName = 'ComponentName';
```

### Naming Conventions

- **Components**: PascalCase (e.g., `Button`, `FormField`)
- **Props**: camelCase (e.g., `isDisabled`, `onClick`)
- **CSS classes**: kebab-case with `fawkes-` prefix (e.g., `fawkes-button`, `fawkes-button--primary`)

### Props

- Always extend `BaseComponentProps` for common props
- Use TypeScript interfaces for all props
- Document all props with JSDoc comments
- Provide sensible defaults
- Use union types for variant props

## Accessibility Guidelines

All components MUST meet WCAG 2.1 AA standards:

### Requirements

1. **Semantic HTML**: Use appropriate HTML elements
2. **ARIA Attributes**: Add ARIA when needed
3. **Keyboard Navigation**: Full keyboard support
4. **Focus Management**: Visible focus indicators
5. **Color Contrast**: Meet contrast ratios (4.5:1 for normal text, 3:1 for large text)
6. **Screen Readers**: Test with screen readers

### Example

```tsx
<button
  type="button"
  disabled={isDisabled}
  aria-label="Close dialog"
  aria-pressed={isPressed}
>
  {children}
</button>
```

## Testing Requirements

### Unit Tests

```tsx
import { render, screen } from '@testing-library/react';
import { ComponentName } from './ComponentName';

describe('ComponentName', () => {
  it('renders children correctly', () => {
    render(<ComponentName>Content</ComponentName>);
    expect(screen.getByText('Content')).toBeInTheDocument();
  });
});
```

### Accessibility Tests

```tsx
import { axe } from 'jest-axe';

it('has no accessibility violations', async () => {
  const { container } = render(<ComponentName>Content</ComponentName>);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

### Coverage

- Minimum 80% code coverage
- All user interactions tested
- All variants tested
- Accessibility tests required

## Documentation

### Storybook Stories

Create comprehensive Storybook stories:

```tsx
import type { Meta, StoryObj } from '@storybook/react';
import { ComponentName } from './ComponentName';

const meta: Meta<typeof ComponentName> = {
  title: 'Components/Category/ComponentName',
  component: ComponentName,
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary'],
    },
  },
};

export default meta;
type Story = StoryObj<typeof ComponentName>;

export const Primary: Story = {
  args: {
    children: 'Primary Example',
    variant: 'primary',
  },
};
```

### Component Documentation

Include:
- Description of the component's purpose
- Usage examples
- Props API documentation
- Accessibility considerations
- Related components

## Submitting Changes

### Pull Request Process

1. **Update tests** - Ensure all tests pass
2. **Update documentation** - Add/update Storybook stories
3. **Run linters** - `npm run lint && npm run format`
4. **Build the package** - Ensure `npm run build` succeeds
5. **Create PR** - Submit a pull request with:
   - Clear description of changes
   - Screenshots for UI changes
   - Link to related issues

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] New component
- [ ] Bug fix
- [ ] Enhancement
- [ ] Documentation

## Checklist
- [ ] Tests added/updated
- [ ] Storybook stories added/updated
- [ ] Accessibility verified
- [ ] Documentation updated
- [ ] Build succeeds
- [ ] Linters pass
```

## Design Tokens

When adding or modifying design tokens:

1. **Update the token file** in `src/tokens/`
2. **Update global CSS** if needed
3. **Document the token** in Storybook
4. **Ensure backward compatibility** or provide migration guide

## Questions?

- Open an issue on GitHub
- Reach out to the platform team
- Check existing issues and PRs

Thank you for contributing to the Fawkes Design System! 🎉
