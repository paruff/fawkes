import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Toast.css';

export interface ToastProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Toast notification
 * 
 * @component
 * @example
 * ```tsx
 * <Toast>Content</Toast>
 * ```
 */
export const Toast = React.forwardRef<HTMLDivElement, ToastProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-toast', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Toast.displayName = 'Toast';
