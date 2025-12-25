import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Card.css';

export interface CardProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Card container component
 *
 * @component
 * @example
 * ```tsx
 * <Card>Content</Card>
 * ```
 */
export const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-card', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Card.displayName = 'Card';
