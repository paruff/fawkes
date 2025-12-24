import type { Meta, StoryObj } from '@storybook/react';
import { Container } from './Container';

const meta: Meta<typeof Container> = {
  title: 'Components/Layout/Container',
  component: Container,
  parameters: {
    layout: 'fullscreen',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof Container>;

export const Default: Story = {
  args: {
    children: 'This content is inside a container',
  },
};
