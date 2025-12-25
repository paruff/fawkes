import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Table.css';

export interface TableProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Data table
 *
 * @component
 * @example
 * ```tsx
 * <Table>Content</Table>
 * ```
 */
export const Table = React.forwardRef<HTMLDivElement, TableProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-table', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Table.displayName = 'Table';
