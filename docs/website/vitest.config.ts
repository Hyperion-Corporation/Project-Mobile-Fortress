import { defineConfig } from 'vitest/config';
import vue from '@vitejs/plugin-vue';
import { fileURLToPath } from 'node:url';

export default defineConfig({
  plugins: [vue()],
  test: {
    environment: 'jsdom',
    setupFiles: [fileURLToPath(new URL('./test/vitest.setup.ts', import.meta.url))],
    include: [
      'test/unit/**/*.{test,spec}.{ts,tsx}',
      'test/integration/**/*.{test,spec}.{ts,tsx}',
    ],
    globals: true,
  },
});
