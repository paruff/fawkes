import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Divider.css';

export interface DividerProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Visual divider
 *
 * @component
 * @example
 * ```tsx
 * <Divider>Content</Divider>
 * ```
 */
export const Divider = React.forwardRef<HTMLDivElement, DividerProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-divider', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Divider.displayName = 'Divider';
