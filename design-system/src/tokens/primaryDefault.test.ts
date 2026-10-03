/**
 * The default primary colour is Indigo 600 (#4f46e5, 6.29:1 on white).
 * Indigo 500 (#6366f1) is 4.47:1 and fails WCAG AA text contrast.
 */
import { readFileSync } from 'fs';
import { join } from 'path';
import { colors } from './colors';

const read = (rel: string): string => readFileSync(join(__dirname, '..', rel), 'utf8');

const globalCss = read('styles/global.css');
const buttonCss = read('components/Button/Button.css');

const resolveVar = (name: string): string => {
  const match = globalCss.match(new RegExp(`--${name}:\\s*(#[0-9a-fA-F]{6})`));
  if (!match) throw new Error(`--${name} not defined in global.css`);
  return match[1].toLowerCase();
};

const ruleColor = (selector: string, prop: string): string => {
  const escaped = selector.replace(/[.:()]/g, '\\$&');
  const rule = buttonCss.match(new RegExp(`${escaped}\\s*\\{([^}]*)\\}`));
  if (!rule) throw new Error(`rule ${selector} not found in Button.css`);
  const decl = rule[1].match(new RegExp(`${prop}:\\s*([^;]+);`));
  if (!decl) throw new Error(`${prop} not found in ${selector}`);
  const v = decl[1].trim().match(/^var\(--([\w-]+)\)$/);
  return v ? resolveVar(v[1]) : decl[1].trim().toLowerCase();
};

const luminance = (hex: string): number => {
  const [r, g, b] = [1, 3, 5].map((i) => {
    const c = parseInt(hex.slice(i, i + 2), 16) / 255;
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};

const contrastOnWhite = (hex: string): number => 1.05 / (luminance(hex) + 0.05);

describe('default primary colour is Indigo 600', () => {
  it('marks 600, not 500, as the main primary in colors.ts', () => {
    const src = read('tokens/colors.ts');
    expect(src).toMatch(/600: '#4f46e5', \/\/ Main primary color/);
    expect(src).not.toMatch(/500: '#6366f1', \/\/ Main primary color/);
    expect(colors.primary[600]).toBe('#4f46e5');
  });

  it('keeps the indigo scale values unchanged', () => {
    expect(colors.primary[500]).toBe('#6366f1');
    expect(colors.primary[700]).toBe('#4338ca');
  });

  it('defines the 700 CSS variable used for hover', () => {
    expect(resolveVar('fawkes-primary-700')).toBe(colors.primary[700]);
  });

  it('primary button fill, hover and focus ring use 600/700/600', () => {
    expect(ruleColor('.fawkes-button--primary', 'background-color')).toBe('#4f46e5');
    expect(ruleColor('.fawkes-button--primary:hover:not(:disabled)', 'background-color')).toBe(
      '#4338ca'
    );
    expect(buttonCss).toMatch(/outline: 2px solid var\(--fawkes-primary-600\)/);
  });

  it('white text on every primary button state meets 4.5:1', () => {
    const fill = ruleColor('.fawkes-button--primary', 'background-color');
    const hover = ruleColor('.fawkes-button--primary:hover:not(:disabled)', 'background-color');
    expect(contrastOnWhite(fill)).toBeGreaterThanOrEqual(4.5);
    expect(contrastOnWhite(hover)).toBeGreaterThanOrEqual(4.5);
  });
});
