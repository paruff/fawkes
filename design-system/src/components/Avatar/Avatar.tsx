import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Avatar.css';

export interface AvatarProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * User avatar
 * 
 * @component
 * @example
 * ```tsx
 * <Avatar>Content</Avatar>
 * ```
 */
export const Avatar = React.forwardRef<HTMLDivElement, AvatarProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-avatar', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Avatar.displayName = 'Avatar';
