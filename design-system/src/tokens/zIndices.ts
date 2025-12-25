/**
 * Design Tokens - Z-Index
 *
 * Z-index layering system
 */

export const zIndices = {
  hide: -1,
  base: 0,
  dropdown: 1000,
  sticky: 1100,
  overlay: 1200,
  modal: 1300,
  popover: 1400,
  toast: 1500,
  tooltip: 1600,
} as const;

export type ZIndex = keyof typeof zIndices;
