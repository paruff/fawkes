import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Tooltip.css';

export interface TooltipProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Tooltip overlay
 * 
 * @component
 * @example
 * ```tsx
 * <Tooltip>Content</Tooltip>
 * ```
 */
export const Tooltip = React.forwardRef<HTMLDivElement, TooltipProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-tooltip', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Tooltip.displayName = 'Tooltip';
