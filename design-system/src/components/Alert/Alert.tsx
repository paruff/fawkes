import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Alert.css';

export interface AlertProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Alert message component
 *
 * @component
 * @example
 * ```tsx
 * <Alert>Content</Alert>
 * ```
 */
export const Alert = React.forwardRef<HTMLDivElement, AlertProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-alert', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Alert.displayName = 'Alert';
