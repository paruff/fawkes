import type { Meta, StoryObj } from '@storybook/react';
import { Tabs } from './Tabs';

const meta: Meta<typeof Tabs> = {
  title: 'Components/Navigation/Tabs',
  component: Tabs,
  parameters: {
    layout: 'padded',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof Tabs>;

export const Default: Story = {
  args: {
    children: 'Tab content',
  },
};
