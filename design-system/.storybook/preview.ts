import type { Preview } from '@storybook/react';
import '../src/styles/global.css';

const preview: Preview = {
  parameters: {
    actions: { argTypesRegex: '^on[A-Z].*' },
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
    options: {
      storySort: {
        order: [
          'Introduction',
          'Design Tokens',
          'Components',
          ['Layout', 'Typography', 'Forms', 'Feedback', 'Navigation', 'Display', 'Data'],
        ],
      },
    },
  },
};

export default preview;
