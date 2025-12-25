import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Tabs.css';

export interface TabsProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Tab navigation component
 *
 * @component
 * @example
 * ```tsx
 * <Tabs>Content</Tabs>
 * ```
 */
export const Tabs = React.forwardRef<HTMLDivElement, TabsProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-tabs', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Tabs.displayName = 'Tabs';
