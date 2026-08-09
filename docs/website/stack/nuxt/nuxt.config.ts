// Nuxt configuration for the docs website (Vue counterpart to Next.js).
// Canonical config lives here; docs/website/nuxt.config.ts re-exports it
// (same pattern as eslint.config.js → stack/eslint/).
//
// Analogy: github-pages keeps Next config under stack/next/ with a root re-export.

import { defineNuxtConfig } from 'nuxt/config';

export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },
  ssr: true,
  // Static generation suitable for GitHub Pages-style hosting
  nitro: {
    preset: 'static',
  },
  app: {
    baseURL: process.env.NUXT_APP_BASE_URL || '/',
    head: {
      title: 'Mobile Fortress',
      meta: [
        { name: 'description', content: 'Mobile Fortress documentation (Nuxt surface)' },
      ],
    },
  },
  typescript: {
    strict: true,
    typeCheck: false,
  },
});
