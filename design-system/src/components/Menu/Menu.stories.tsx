import type { Meta, StoryObj } from '@storybook/react';
import { Menu } from './Menu';

const meta: Meta<typeof Menu> = {
  title: 'Components/Navigation/Menu',
  component: Menu,
  parameters: {
    layout: 'centered',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof Menu>;

export const Default: Story = {
  args: {
    children: 'Menu items',
  },
};
