import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Spacer.css';

export interface SpacerProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Add flexible space between elements
 * 
 * @component
 * @example
 * ```tsx
 * <Spacer>Content</Spacer>
 * ```
 */
export const Spacer = React.forwardRef<HTMLDivElement, SpacerProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-spacer', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Spacer.displayName = 'Spacer';
