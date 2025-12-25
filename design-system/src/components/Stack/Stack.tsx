import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Stack.css';

export interface StackProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Stack items vertically or horizontally with consistent spacing
 * 
 * @component
 * @example
 * ```tsx
 * <Stack>Content</Stack>
 * ```
 */
export const Stack = React.forwardRef<HTMLDivElement, StackProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-stack', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Stack.displayName = 'Stack';
