import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Skeleton.css';

export interface SkeletonProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Skeleton loader
 *
 * @component
 * @example
 * ```tsx
 * <Skeleton>Content</Skeleton>
 * ```
 */
export const Skeleton = React.forwardRef<HTMLDivElement, SkeletonProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-skeleton', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Skeleton.displayName = 'Skeleton';
