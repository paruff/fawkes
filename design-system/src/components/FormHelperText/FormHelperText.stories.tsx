import type { Meta, StoryObj } from '@storybook/react';
import { FormHelperText } from './FormHelperText';

const meta: Meta<typeof FormHelperText> = {
  title: 'Components/Forms/FormHelperText',
  component: FormHelperText,
  parameters: {
    layout: 'centered',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof FormHelperText>;

export const Default: Story = {
  args: {
    children: 'This is helper text for the form field',
  },
};
