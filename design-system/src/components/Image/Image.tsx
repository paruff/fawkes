import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Image.css';

export interface ImageProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Optimized image component
 *
 * @component
 * @example
 * ```tsx
 * <Image>Content</Image>
 * ```
 */
export const Image = React.forwardRef<HTMLDivElement, ImageProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-image', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Image.displayName = 'Image';
