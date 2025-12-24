import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Pagination.css';

export interface PaginationProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Pagination controls
 * 
 * @component
 * @example
 * ```tsx
 * <Pagination>Content</Pagination>
 * ```
 */
export const Pagination = React.forwardRef<HTMLDivElement, PaginationProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-pagination', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Pagination.displayName = 'Pagination';
