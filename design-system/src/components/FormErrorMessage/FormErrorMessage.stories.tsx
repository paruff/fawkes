import type { Meta, StoryObj } from '@storybook/react';
import { FormErrorMessage } from './FormErrorMessage';

const meta: Meta<typeof FormErrorMessage> = {
  title: 'Components/Forms/FormErrorMessage',
  component: FormErrorMessage,
  parameters: {
    layout: 'centered',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof FormErrorMessage>;

export const Default: Story = {
  args: {
    children: 'This field is required',
  },
};
