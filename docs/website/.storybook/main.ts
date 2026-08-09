import type { StorybookConfig } from "@storybook/react-vite";

// Documents Mobile Fortress's React island component(s) in isolation — the
// same UnitRosterBoard component the design hub's HomeView.tsx mounts live.
// Built standalone into public/storybook/
// (see package.json's build-storybook / prebuild) and linked from the site,
// rather than embedded as an island itself.
const config: StorybookConfig = {
  stories: ["../stories/**/*.stories.@(ts|tsx)"],
  framework: {
    name: "@storybook/react-vite",
    options: {},
  },
  addons: ["@storybook/addon-docs", "@storybook/addon-a11y"],
  viteFinal: async (viteConfig) => {
    viteConfig.base = process.env.SITE_BASE ? `${process.env.SITE_BASE}storybook/` : "/storybook/";
    return viteConfig;
  },
};

export default config;
