import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Button.css';

export interface ButtonProps extends BaseComponentProps, React.ButtonHTMLAttributes<HTMLButtonElement> {
  /** Button visual variant */
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  /** Button size */
  size?: 'sm' | 'md' | 'lg';
  /** Full width button */
  fullWidth?: boolean;
  /** Loading state */
  isLoading?: boolean;
  /** Disabled state */
  disabled?: boolean;
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      children,
      variant = 'primary',
      size = 'md',
      fullWidth = false,
      isLoading = false,
      disabled = false,
      className,
      type = 'button',
      ...props
    },
    ref
  ) => {
    return (
      <button
        ref={ref}
        type={type}
        disabled={disabled || isLoading}
        className={cn(
          'fawkes-button',
          `fawkes-button--${variant}`,
          `fawkes-button--${size}`,
          {
            'fawkes-button--full-width': fullWidth,
            'fawkes-button--loading': isLoading,
          },
          className
        )}
        aria-busy={isLoading}
        {...props}
      >
        {isLoading ? <span className="fawkes-button__spinner" aria-label="Loading" /> : children}
      </button>
    );
  }
);

Button.displayName = 'Button';
