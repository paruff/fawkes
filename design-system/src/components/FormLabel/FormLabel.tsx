import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './FormLabel.css';

export interface FormLabelProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Label for form fields
 *
 * @component
 * @example
 * ```tsx
 * <FormLabel>Content</FormLabel>
 * ```
 */
export const FormLabel = React.forwardRef<HTMLDivElement, FormLabelProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-formlabel', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

FormLabel.displayName = 'FormLabel';
