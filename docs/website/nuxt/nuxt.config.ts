// Nuxt configuration for the docs website (Vue counterpart to Next.js).
// This package can host Nuxt islands / an alternate static site alongside
// the primary Vite + Vue SPA in the parent website package.
//
// Analogy: github-pages keeps Next config under next/; this repo keeps
// Nuxt under docs/website/nuxt/.

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
  dir: {
    pages: 'pages',
  },
});
