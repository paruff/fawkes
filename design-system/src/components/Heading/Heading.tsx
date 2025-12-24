import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Heading.css';

export interface HeadingProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Semantic heading component (h1-h6)
 * 
 * @component
 * @example
 * ```tsx
 * <Heading>Content</Heading>
 * ```
 */
export const Heading = React.forwardRef<HTMLDivElement, HeadingProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-heading', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Heading.displayName = 'Heading';
