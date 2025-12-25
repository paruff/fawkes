import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Switch.css';

export interface SwitchProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Toggle switch component
 *
 * @component
 * @example
 * ```tsx
 * <Switch>Content</Switch>
 * ```
 */
export const Switch = React.forwardRef<HTMLDivElement, SwitchProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-switch', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Switch.displayName = 'Switch';
