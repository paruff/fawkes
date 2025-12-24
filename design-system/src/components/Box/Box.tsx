import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Box.css';

export interface BoxProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * A versatile box component for layout
 * 
 * @component
 * @example
 * ```tsx
 * <Box>Content</Box>
 * ```
 */
export const Box = React.forwardRef<HTMLDivElement, BoxProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-box', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Box.displayName = 'Box';
