import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Link.css';

export interface LinkProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Styled link component
 *
 * @component
 * @example
 * ```tsx
 * <Link>Content</Link>
 * ```
 */
export const Link = React.forwardRef<HTMLDivElement, LinkProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-link', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Link.displayName = 'Link';
