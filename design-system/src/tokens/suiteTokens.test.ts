import { execFileSync } from 'child_process';
import { readFileSync } from 'fs';
import path from 'path';

// design-system/tokens.json is a vendored copy of https://ufawkes.dev/design/tokens.json (#2311).
const root = path.resolve(__dirname, '../../..');
const tokens = JSON.parse(readFileSync(path.join(root, 'design-system/tokens.json'), 'utf8'));

describe('suite tokens', () => {
  it('shared colour scales match the vendored tokens', () => {
    const run = () =>
      execFileSync('python3', ['scripts/check-design-token-sync.py', 'design-system/tokens.json'], {
        cwd: root,
        stdio: 'pipe',
      });
    expect(run).not.toThrow();
  });

  it('danger button is Red 700 with a white label', () => {
    const css = readFileSync(path.join(root, 'design-system/src/components/Button/Button.css'), 'utf8');
    const red700: string = tokens.color.red['700'];
    for (const selector of ['.fawkes-button--danger {', '.fawkes-button--danger:hover:not(:disabled) {']) {
      const rule = css.slice(css.indexOf(selector), css.indexOf('}', css.indexOf(selector)));
      expect(rule).toContain(`background-color: ${red700};`);
    }
  });
});
