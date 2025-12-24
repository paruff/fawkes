import React from 'react';

export interface BaseComponentProps {
  /** Custom CSS class name */
  className?: string;
  /** Custom inline styles */
  style?: React.CSSProperties;
  /** Data test ID for testing */
  'data-testid'?: string;
}
