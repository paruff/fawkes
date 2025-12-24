import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Progress.css';

export interface ProgressProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Progress bar
 * 
 * @component
 * @example
 * ```tsx
 * <Progress>Content</Progress>
 * ```
 */
export const Progress = React.forwardRef<HTMLDivElement, ProgressProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-progress', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Progress.displayName = 'Progress';
