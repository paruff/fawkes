import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './List.css';

export interface ListProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * List component
 *
 * @component
 * @example
 * ```tsx
 * <List>Content</List>
 * ```
 */
export const List = React.forwardRef<HTMLDivElement, ListProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-list', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

List.displayName = 'List';
