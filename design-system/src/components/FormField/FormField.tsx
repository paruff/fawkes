import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './FormField.css';

export interface FormFieldProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Complete form field with label and validation
 *
 * @component
 * @example
 * ```tsx
 * <FormField>Content</FormField>
 * ```
 */
export const FormField = React.forwardRef<HTMLDivElement, FormFieldProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-formfield', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

FormField.displayName = 'FormField';
