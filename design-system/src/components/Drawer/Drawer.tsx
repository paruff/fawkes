import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Drawer.css';

export interface DrawerProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Slide-out drawer
 * 
 * @component
 * @example
 * ```tsx
 * <Drawer>Content</Drawer>
 * ```
 */
export const Drawer = React.forwardRef<HTMLDivElement, DrawerProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-drawer', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Drawer.displayName = 'Drawer';
