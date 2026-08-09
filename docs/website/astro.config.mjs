import { defineConfig } from 'astro/config';

// Builds the CoastalFlowField Astro island into public/astro-island for the Vue host.
// base must align with SITE_BASE when deploying under a GitHub Pages project path.
const siteBase = process.env.SITE_BASE || '/';
const islandBase = `${siteBase.replace(/\/?$/, '/')}astro-island`;

export default defineConfig({
  srcDir: './src/frameworks/astro',
  outDir: './public/astro-island',
  publicDir: './astro-public',
  base: islandBase,
  build: {
    format: 'directory',
  },
  vite: {
    css: {
      postcss: {},
    },
  },
});
