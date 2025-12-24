import type { Meta, StoryObj } from '@storybook/react';
import { Alert } from './Alert';

const meta: Meta<typeof Alert> = {
  title: 'Components/Feedback/Alert',
  component: Alert,
  parameters: {
    layout: 'padded',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof Alert>;

export const Default: Story = {
  args: {
    children: 'This is an alert message',
  },
};

export const WithCustomContent: Story = {
  args: {
    children: (
      <>
        <strong>Alert!</strong> Something important happened.
      </>
    ),
  },
};
