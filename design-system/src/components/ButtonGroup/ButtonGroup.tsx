import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './ButtonGroup.css';

export interface ButtonGroupProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Group multiple buttons together
 * 
 * @component
 * @example
 * ```tsx
 * <ButtonGroup>Content</ButtonGroup>
 * ```
 */
export const ButtonGroup = React.forwardRef<HTMLDivElement, ButtonGroupProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-buttongroup', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

ButtonGroup.displayName = 'ButtonGroup';
