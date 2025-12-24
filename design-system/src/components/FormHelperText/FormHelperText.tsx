import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './FormHelperText.css';

export interface FormHelperTextProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Helper text for form fields
 * 
 * @component
 * @example
 * ```tsx
 * <FormHelperText>Content</FormHelperText>
 * ```
 */
export const FormHelperText = React.forwardRef<HTMLDivElement, FormHelperTextProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-formhelpertext', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

FormHelperText.displayName = 'FormHelperText';
