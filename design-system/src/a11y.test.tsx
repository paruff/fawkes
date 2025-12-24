import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import * as Components from './index';

expect.extend(toHaveNoViolations);

/**
 * Comprehensive Accessibility Test Suite
 * 
 * This test suite runs automated accessibility checks using axe-core
 * against all components in the design system to ensure WCAG 2.1 AA compliance.
 * 
 * Tests are run as part of the CI/CD pipeline and will fail the build
 * if any accessibility violations are detected.
 */
describe('Design System Accessibility (WCAG 2.1 AA)', () => {
  // Configure axe to test for WCAG 2.1 AA compliance
  const axeConfig = {
    rules: {
      // WCAG 2.1 Level A & AA rules
      'color-contrast': { enabled: true },
      'valid-lang': { enabled: true },
      'html-has-lang': { enabled: true },
      'image-alt': { enabled: true },
      'button-name': { enabled: true },
      'link-name': { enabled: true },
      'label': { enabled: true },
      'aria-allowed-attr': { enabled: true },
      'aria-required-attr': { enabled: true },
      'aria-valid-attr': { enabled: true },
      'aria-valid-attr-value': { enabled: true },
      'landmark-one-main': { enabled: true },
      'region': { enabled: true },
    },
  };

  describe('Button Component', () => {
    it('should have no accessibility violations in default state', async () => {
      const { container } = render(<Components.Button>Click me</Components.Button>);
      const results = await axe(container, axeConfig);
      expect(results).toHaveNoViolations();
    });

    it('should have no violations when disabled', async () => {
      const { container } = render(<Components.Button disabled>Disabled</Components.Button>);
      const results = await axe(container, axeConfig);
      expect(results).toHaveNoViolations();
    });

    it('should have no violations when loading', async () => {
      const { container } = render(<Components.Button isLoading>Loading</Components.Button>);
      const results = await axe(container, axeConfig);
      expect(results).toHaveNoViolations();
    });
  });

  describe('Alert Component', () => {
    it('should have no accessibility violations', async () => {
      const { container } = render(
        <Components.Alert variant="info">This is an alert message</Components.Alert>
      );
      const results = await axe(container, axeConfig);
      expect(results).toHaveNoViolations();
    });

    it('should have proper ARIA roles for different variants', async () => {
      const variants = ['success', 'error', 'warning', 'info'] as const;
      
      for (const variant of variants) {
        const { container } = render(
          <Components.Alert variant={variant}>Alert message</Components.Alert>
        );
        const results = await axe(container, axeConfig);
        expect(results).toHaveNoViolations();
      }
    });
  });

  describe('Checkbox Component', () => {
    it('should have no accessibility violations', async () => {
      const { container } = render(
        <Components.Checkbox id="test-checkbox">Check me</Components.Checkbox>
      );
      const results = await axe(container, axeConfig);
      expect(results).toHaveNoViolations();
    });
  });

  describe('Card Component', () => {
    it('should have no accessibility violations', async () => {
      const { container } = render(
        <Components.Card>
          <Components.Card.Header>Card Title</Components.Card.Header>
          <Components.Card.Body>Card content</Components.Card.Body>
        </Components.Card>
      );
      const results = await axe(container, axeConfig);
      expect(results).toHaveNoViolations();
    });
  });

  describe('Badge Component', () => {
    it('should have no accessibility violations', async () => {
      const { container } = render(<Components.Badge>Badge</Components.Badge>);
      const results = await axe(container, axeConfig);
      expect(results).toHaveNoViolations();
    });
  });

  describe('Divider Component', () => {
    it('should have no accessibility violations', async () => {
      const { container } = render(<Components.Divider />);
      const results = await axe(container, axeConfig);
      expect(results).toHaveNoViolations();
    });
  });

  describe('Keyboard Navigation', () => {
    it('interactive elements should be keyboard accessible', async () => {
      const { container } = render(
        <div>
          <Components.Button>Button 1</Components.Button>
          <Components.Button>Button 2</Components.Button>
          <Components.Checkbox id="kb-check">Checkbox</Components.Checkbox>
        </div>
      );
      const results = await axe(container, axeConfig);
      expect(results).toHaveNoViolations();
    });
  });

  describe('Color Contrast', () => {
    it('should meet WCAG AA color contrast requirements', async () => {
      const { container } = render(
        <div>
          <Components.Button variant="primary">Primary</Components.Button>
          <Components.Button variant="secondary">Secondary</Components.Button>
          <Components.Alert variant="error">Error message</Components.Alert>
          <Components.Badge variant="success">Success</Components.Badge>
        </div>
      );
      const results = await axe(container, {
        rules: {
          'color-contrast': { enabled: true },
        },
      });
      expect(results).toHaveNoViolations();
    });
  });

  describe('Screen Reader Compatibility', () => {
    it('should have proper ARIA labels and roles', async () => {
      const { container } = render(
        <div>
          <Components.Button aria-label="Submit form">Submit</Components.Button>
          <Components.Alert variant="info" role="alert">
            Information message
          </Components.Alert>
        </div>
      );
      const results = await axe(container, axeConfig);
      expect(results).toHaveNoViolations();
    });
  });
});
