import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Select.css';

export interface SelectProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Dropdown select field
 * 
 * @component
 * @example
 * ```tsx
 * <Select>Content</Select>
 * ```
 */
export const Select = React.forwardRef<HTMLDivElement, SelectProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-select', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Select.displayName = 'Select';
