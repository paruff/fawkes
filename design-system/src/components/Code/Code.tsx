import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Code.css';

export interface CodeProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Inline or block code display
 * 
 * @component
 * @example
 * ```tsx
 * <Code>Content</Code>
 * ```
 */
export const Code = React.forwardRef<HTMLDivElement, CodeProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-code', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Code.displayName = 'Code';
