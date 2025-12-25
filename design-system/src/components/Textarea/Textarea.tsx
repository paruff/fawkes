import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Textarea.css';

export interface TextareaProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Multi-line text input
 *
 * @component
 * @example
 * ```tsx
 * <Textarea>Content</Textarea>
 * ```
 */
export const Textarea = React.forwardRef<HTMLDivElement, TextareaProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-textarea', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Textarea.displayName = 'Textarea';
