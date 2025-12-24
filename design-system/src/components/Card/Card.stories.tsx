import type { Meta, StoryObj } from '@storybook/react';
import { Card } from './Card';

const meta: Meta<typeof Card> = {
  title: 'Components/Display/Card',
  component: Card,
  parameters: {
    layout: 'padded',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof Card>;

export const Default: Story = {
  args: {
    children: 'This is a card component with some content inside.',
  },
};

export const WithRichContent: Story = {
  args: {
    children: (
      <div style={{ padding: '16px' }}>
        <h3>Card Title</h3>
        <p>This card contains multiple elements including a title and paragraph text.</p>
        <button>Action Button</button>
      </div>
    ),
  },
};
