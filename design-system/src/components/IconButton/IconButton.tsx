import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './IconButton.css';

export interface IconButtonProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Button with only an icon
 * 
 * @component
 * @example
 * ```tsx
 * <IconButton>Content</IconButton>
 * ```
 */
export const IconButton = React.forwardRef<HTMLDivElement, IconButtonProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-iconbutton', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

IconButton.displayName = 'IconButton';
