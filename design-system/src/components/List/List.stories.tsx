import type { Meta, StoryObj } from '@storybook/react-vite';
import { List } from './List';

const meta: Meta<typeof List> = {
  title: 'Components/Data/List',
  component: List,
  parameters: {
    layout: 'padded',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof List>;

export const Default: Story = {
  args: {
    children: 'List items',
  },
};
