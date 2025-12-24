import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './FormErrorMessage.css';

export interface FormErrorMessageProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Error message for form validation
 * 
 * @component
 * @example
 * ```tsx
 * <FormErrorMessage>Content</FormErrorMessage>
 * ```
 */
export const FormErrorMessage = React.forwardRef<HTMLDivElement, FormErrorMessageProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-formerrormessage', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

FormErrorMessage.displayName = 'FormErrorMessage';
