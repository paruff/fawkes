import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Input.css';

export interface InputProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Text input field
 *
 * @component
 * @example
 * ```tsx
 * <Input>Content</Input>
 * ```
 */
export const Input = React.forwardRef<HTMLDivElement, InputProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-input', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Input.displayName = 'Input';
