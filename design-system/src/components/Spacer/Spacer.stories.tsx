import type { Meta, StoryObj } from '@storybook/react';
import { Spacer } from './Spacer';

const meta: Meta<typeof Spacer> = {
  title: 'Components/Layout/Spacer',
  component: Spacer,
  parameters: {
    layout: 'padded',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof Spacer>;

export const Default: Story = {
  args: {
    children: 'Spacer component',
  },
};
