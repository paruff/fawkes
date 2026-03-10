// Type declaration for jest-axe
// jest-axe does not ship TypeScript declarations in the version currently installed.
declare module 'jest-axe' {
  import { AxeResults } from 'axe-core';

  export interface JestAxeConfigureOptions {
    globalOptions?: Record<string, unknown>;
    impactLevels?: string[];
  }

  export interface AxeMatchers {
    toHaveNoViolations(): void;
  }

  export function axe(html: Element | string, options?: Record<string, unknown>): Promise<AxeResults>;
  export function configureAxe(options?: JestAxeConfigureOptions): typeof axe;
  export const toHaveNoViolations: { toHaveNoViolations: () => { pass: boolean; message: () => string } };
}
