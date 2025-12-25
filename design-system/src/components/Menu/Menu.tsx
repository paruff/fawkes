import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Menu.css';

export interface MenuProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Dropdown menu
 *
 * @component
 * @example
 * ```tsx
 * <Menu>Content</Menu>
 * ```
 */
export const Menu = React.forwardRef<HTMLDivElement, MenuProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-menu', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Menu.displayName = 'Menu';
