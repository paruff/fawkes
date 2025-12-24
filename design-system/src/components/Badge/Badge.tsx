import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Badge.css';

export interface BadgeProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Badge for counts or status
 * 
 * @component
 * @example
 * ```tsx
 * <Badge>Content</Badge>
 * ```
 */
export const Badge = React.forwardRef<HTMLDivElement, BadgeProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-badge', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Badge.displayName = 'Badge';
