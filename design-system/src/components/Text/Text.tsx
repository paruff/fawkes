import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Text.css';

export interface TextProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Text component with variants
 * 
 * @component
 * @example
 * ```tsx
 * <Text>Content</Text>
 * ```
 */
export const Text = React.forwardRef<HTMLDivElement, TextProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-text', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Text.displayName = 'Text';
