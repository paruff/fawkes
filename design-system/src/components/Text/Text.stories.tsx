import type { Meta, StoryObj } from '@storybook/react';
import { Text } from './Text';

const meta: Meta<typeof Text> = {
  title: 'Components/Typography/Text',
  component: Text,
  parameters: {
    layout: 'padded',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof Text>;

export const Default: Story = {
  args: {
    children: 'This is body text',
  },
};

export const Paragraph: Story = {
  args: {
    children: 'This is a longer paragraph of text that demonstrates how the Text component renders longer content.',
  },
};
