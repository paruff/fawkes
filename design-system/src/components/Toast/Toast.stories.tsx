import type { Meta, StoryObj } from '@storybook/react';
import { Toast } from './Toast';

const meta: Meta<typeof Toast> = {
  title: 'Components/Feedback/Toast',
  component: Toast,
  parameters: {
    layout: 'centered',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof Toast>;

export const Default: Story = {
  args: {
    children: 'Toast notification message',
  },
};
