import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Spinner.css';

export interface SpinnerProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Loading spinner
 * 
 * @component
 * @example
 * ```tsx
 * <Spinner>Content</Spinner>
 * ```
 */
export const Spinner = React.forwardRef<HTMLDivElement, SpinnerProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-spinner', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Spinner.displayName = 'Spinner';
