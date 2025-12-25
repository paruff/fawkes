import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Chip.css';

export interface ChipProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Chip/tag component
 *
 * @component
 * @example
 * ```tsx
 * <Chip>Content</Chip>
 * ```
 */
export const Chip = React.forwardRef<HTMLDivElement, ChipProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-chip', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Chip.displayName = 'Chip';
