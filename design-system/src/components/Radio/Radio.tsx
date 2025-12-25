import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Radio.css';

export interface RadioProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Radio button input
 *
 * @component
 * @example
 * ```tsx
 * <Radio>Content</Radio>
 * ```
 */
export const Radio = React.forwardRef<HTMLDivElement, RadioProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-radio', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Radio.displayName = 'Radio';
