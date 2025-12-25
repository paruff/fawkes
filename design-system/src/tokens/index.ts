/**
 * Design Tokens - Main Export
 *
 * Central export for all design tokens
 */

export { colors } from './colors';
export type { ColorScale, ColorShade } from './colors';

export { typography } from './typography';
export type { FontFamily, FontSize, FontWeight, LineHeight, LetterSpacing } from './typography';

export { spacing } from './spacing';
export type { Spacing } from './spacing';

export { shadows } from './shadows';
export type { Shadow } from './shadows';

export { radii } from './radii';
export type { Radius } from './radii';

export { zIndices } from './zIndices';
export type { ZIndex } from './zIndices';

export { breakpoints } from './breakpoints';
export type { Breakpoint } from './breakpoints';

// Combined tokens object
export const tokens = {
  colors: require('./colors').colors,
  typography: require('./typography').typography,
  spacing: require('./spacing').spacing,
  shadows: require('./shadows').shadows,
  radii: require('./radii').radii,
  zIndices: require('./zIndices').zIndices,
  breakpoints: require('./breakpoints').breakpoints,
};
