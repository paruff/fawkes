import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Grid.css';

export interface GridProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * A flexible grid layout system
 *
 * @component
 * @example
 * ```tsx
 * <Grid>Content</Grid>
 * ```
 */
export const Grid = React.forwardRef<HTMLDivElement, GridProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-grid', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Grid.displayName = 'Grid';
