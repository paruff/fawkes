import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Checkbox.css';

export interface CheckboxProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Checkbox input
 * 
 * @component
 * @example
 * ```tsx
 * <Checkbox>Content</Checkbox>
 * ```
 */
export const Checkbox = React.forwardRef<HTMLDivElement, CheckboxProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-checkbox', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Checkbox.displayName = 'Checkbox';
