import React from 'react';
import { cn } from '../../utils';
import { BaseComponentProps } from '../../types';
import './Modal.css';

export interface ModalProps extends BaseComponentProps {
  /** Children elements */
  children?: React.ReactNode;
}

/**
 * Modal dialog
 *
 * @component
 * @example
 * ```tsx
 * <Modal>Content</Modal>
 * ```
 */
export const Modal = React.forwardRef<HTMLDivElement, ModalProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('fawkes-modal', className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Modal.displayName = 'Modal';
