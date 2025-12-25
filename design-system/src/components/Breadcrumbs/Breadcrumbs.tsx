import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Breadcrumbs.css';

export interface BreadcrumbsProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Breadcrumb navigation
 *
 * @component
 * @example
 * ```tsx
 * <Breadcrumbs>Content</Breadcrumbs>
 * ```
 */
export const Breadcrumbs = React.forwardRef<HTMLDivElement, BreadcrumbsProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-breadcrumbs', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Breadcrumbs.displayName = 'Breadcrumbs';
