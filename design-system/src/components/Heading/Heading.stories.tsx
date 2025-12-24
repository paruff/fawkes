import type { Meta, StoryObj } from '@storybook/react';
import { Heading } from './Heading';

const meta: Meta<typeof Heading> = {
  title: 'Components/Typography/Heading',
  component: Heading,
  parameters: {
    layout: 'padded',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof Heading>;

export const Default: Story = {
  args: {
    children: 'This is a heading',
  },
};

export const Level1: Story = {
  args: {
    children: 'Heading Level 1',
  },
};

export const Level2: Story = {
  args: {
    children: 'Heading Level 2',
  },
};

export const Level3: Story = {
  args: {
    children: 'Heading Level 3',
  },
};
