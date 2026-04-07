import type { Meta, StoryObj } from '@storybook/react-vite';
import { Breadcrumbs } from './Breadcrumbs';

const meta: Meta<typeof Breadcrumbs> = {
  title: 'Components/Navigation/Breadcrumbs',
  component: Breadcrumbs,
  parameters: {
    layout: 'padded',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof Breadcrumbs>;

export const Default: Story = {
  args: {
    children: 'Home / Category / Page',
  },
};
