import type { Meta, StoryObj } from "@storybook/react-vite";
import UnitRosterBoard from "../src/frameworks/react/UnitRosterBoard";

const meta: Meta<typeof UnitRosterBoard> = {
  title: "framework-islands/react/UnitRosterBoard",
  component: UnitRosterBoard,
};
export default meta;

type Story = StoryObj<typeof UnitRosterBoard>;

export const Default: Story = {};
