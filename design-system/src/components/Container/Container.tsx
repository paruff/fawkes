import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Container.css';

export interface ContainerProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * A responsive container component
 * 
 * @component
 * @example
 * ```tsx
 * <Container>Content</Container>
 * ```
 */
export const Container = React.forwardRef<HTMLDivElement, ContainerProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-container', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Container.displayName = 'Container';
